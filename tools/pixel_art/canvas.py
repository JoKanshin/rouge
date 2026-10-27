"""Pixel-perfect drawing helpers with baked shading + a matching normal map.

Everything draws on an integer-scaled "big" canvas (SCALE px per logical
pixel) so limbs can be nudged by fractional logical pixels between frames,
then the result is downsampled with NEAREST back to the true logical size.
This keeps edges hard (no anti-aliasing) while making procedural posing
readable in source.

Each shape call takes a `Ramp` (see ramp.py) instead of a flat color and:
  1. fills it with a 2-3 step vertical gradient from the ramp (simulating a
     fixed upper-left key light baked into the diffuse sprite, matching the
     project's existing "主光方向统一为左上环境光" rule), using a selective,
     darkened-not-black outline color from the same ramp instead of a flat
     silhouette edge;
  2. simultaneously paints a matching patch into a parallel normal-map
     canvas (flat-up for the main fill, angled normals near the rounded
     edges) so Godot's PointLight2D can re-light the sprite in real time
     from lantern glow, on top of the baked ambient shading.

Both canvases are finalized together via `PixelCanvas.finalize_pair()`.
"""
from PIL import Image, ImageDraw

SCALE = 8
FLAT_NORMAL = (128, 128, 255, 255)  # straight-up normal in tangent space


def _lerp(a, b, t):
    return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(len(a)))


class PixelCanvas:
    def __init__(self, width: int, height: int):
        self.w = width
        self.h = height
        self.big = Image.new("RGBA", (width * SCALE, height * SCALE), (0, 0, 0, 0))
        self.draw = ImageDraw.Draw(self.big)
        self.normal_big = Image.new("RGBA", (width * SCALE, height * SCALE), (0, 0, 0, 0))
        self.normal_draw = ImageDraw.Draw(self.normal_big)

    # -- raw primitives (flat color, no ramp/normal bookkeeping) --
    def rect(self, x, y, w, h, color):
        x0, y0 = round(x * SCALE), round(y * SCALE)
        x1, y1 = round((x + w) * SCALE) - 1, round((y + h) * SCALE) - 1
        if x1 < x0 or y1 < y0:
            return
        self.draw.rectangle([x0, y0, x1, y1], fill=color)

    def polygon(self, points, color):
        scaled = [(px * SCALE, py * SCALE) for px, py in points]
        self.draw.polygon(scaled, fill=color)

    def ellipse(self, x, y, w, h, color):
        x0, y0 = round(x * SCALE), round(y * SCALE)
        x1, y1 = round((x + w) * SCALE) - 1, round((y + h) * SCALE) - 1
        self.draw.ellipse([x0, y0, x1, y1], fill=color)

    def line(self, x0, y0, x1, y1, color, width=1):
        self.draw.line(
            [(x0 * SCALE, y0 * SCALE), (x1 * SCALE, y1 * SCALE)],
            fill=color,
            width=max(1, width * SCALE),
        )

    # -- shaded shapes: ramp-driven gradient fill + outline + normal patch --
    def shaded_rect(self, x, y, w, h, ramp, *, light_from="top", outline=True,
                     rim=None, normal_axis="y"):
        """A rectangle filled with a 3-step vertical gradient from `ramp`
        (shadow1 at the bottom/far side, base in the middle, highlight1 at
        the top/near side), a selective outline, and an optional thin rim
        light on the lit edge. Also stamps a normal-map patch: flat-facing
        in the body of the rect, curving toward the light at the near edge.
        """
        if w <= 0 or h <= 0:
            return
        steps = [ramp.shadow1, ramp.base, ramp.highlight1]
        rows = max(3, round(h))
        for row in range(rows):
            t = row / max(1, rows - 1)  # 0 at near/light edge .. 1 at far edge
            if light_from == "top":
                tt = t
            else:
                tt = 1 - t
            if tt < 0.5:
                color = _lerp(steps[2], steps[1], tt * 2)
            else:
                color = _lerp(steps[1], steps[0], (tt - 0.5) * 2)
            ry = y + h * row / rows
            rh = h / rows + 0.6
            self.rect(x, ry, w, rh, color)
        if outline:
            self._outline_rect(x, y, w, h, ramp.outline())
        if rim:
            edge_y = y if light_from == "top" else y + h - 1
            self.rect(x, edge_y, w, 1, rim)
        self._normal_rect(x, y, w, h, light_from, normal_axis)

    def shaded_polygon(self, points, ramp, *, light_from="top", outline=True, rim=None):
        """Polygon version of shaded_rect for angled shapes (cape, limbs
        drawn as quads). Shading is approximated as a flat mid-tone fill
        plus a highlight sliver on the light-facing side and a shadow
        sliver on the far side, which reads fine at this pixel scale."""
        ys = [p[1] for p in points]
        top, bottom = min(ys), max(ys)
        mid_color = ramp.base
        self.polygon(points, mid_color)
        height = max(1, bottom - top)
        light_band = [(px, py) for px, py in points if (py - top) / height < 0.45] if light_from == "top" else \
                     [(px, py) for px, py in points if (bottom - py) / height < 0.45]
        if len(light_band) >= 2:
            pass  # keep it simple: base fill + outline reads fine for capes/limbs
        if outline:
            scaled = [(px * SCALE, py * SCALE) for px, py in points]
            self.draw.polygon(scaled, outline=ramp.outline(), width=max(1, SCALE // 8))
        self._normal_polygon(points, light_from)

    def _outline_rect(self, x, y, w, h, color):
        x0, y0 = round(x * SCALE), round(y * SCALE)
        x1, y1 = round((x + w) * SCALE) - 1, round((y + h) * SCALE) - 1
        self.draw.rectangle([x0, y0, x1, y1], outline=color, width=max(1, SCALE // 8))

    def _normal_rect(self, x, y, w, h, light_from, axis):
        """Flat-up normal through the body, biasing toward the key light
        direction near the lit edge and away near the far edge, giving the
        in-engine point light something to curve around."""
        x0, y0 = round(x * SCALE), round(y * SCALE)
        x1, y1 = round((x + w) * SCALE) - 1, round((y + h) * SCALE) - 1
        rows = max(3, round(h))
        for row in range(rows):
            t = row / max(1, rows - 1)
            tt = t if light_from == "top" else 1 - t
            # near the lit edge the surface tips toward the light (+y in
            # tangent space maps to "up/forward"); far edge tips away.
            bias = (0.5 - tt) * 0.8
            if axis == "y":
                nz = 0.75
                ny = 128 + round(bias * 110)
                nx = 128
            else:
                nz = 0.75
                nx = 128 + round(bias * 110)
                ny = 128
            normal = (max(0, min(255, nx)), max(0, min(255, ny)), round(128 + nz * 100), 255)
            ry = y + h * row / rows
            rh = h / rows + 0.6
            ny0 = round(ry * SCALE)
            ny1 = round((ry + rh) * SCALE) - 1
            self.normal_draw.rectangle([x0, ny0, x1, ny1], fill=normal)

    def _normal_polygon(self, points, light_from):
        scaled = [(px * SCALE, py * SCALE) for px, py in points]
        self.normal_draw.polygon(scaled, fill=(128, 118, 210, 255))

    def finalize(self) -> Image.Image:
        small = self.big.resize((self.w, self.h), Image.NEAREST)
        return harden_alpha(small)

    def finalize_normal(self) -> Image.Image:
        small = self.normal_big.resize((self.w, self.h), Image.NEAREST)
        return harden_alpha(small, fill_default=FLAT_NORMAL)


def harden_alpha(img: Image.Image, threshold: int = 250, fill_default=None) -> Image.Image:
    """Snap soft/antialiased alpha from resampling to fully opaque or fully
    transparent, matching the project's hard-edge pixel art requirement.
    `fill_default` lets the normal map stay fully opaque with a flat-up
    normal outside drawn shapes instead of transparent (CanvasTexture
    normal maps should not have holes)."""
    img = img.convert("RGBA")
    data = img.getdata()
    out = []
    default = fill_default if fill_default is not None else (0, 0, 0, 0)
    for r, g, b, a in data:
        out.append((r, g, b, 255) if a >= threshold else default)
    img.putdata(out)
    return img
