"""Hue-shifted color ramp generator.

Flat pixel art just darkens/lightens one hue linearly, which is what made
the first pass look cheap. A painterly ramp instead rotates hue toward cool
in shadow and warm in highlight, and lets saturation peak in the midtones:

    shadow (cool, desaturating) -> base -> highlight (warm, bright)

Each material gets a `Ramp` built from one base color plus a few knobs, so
every sprite in the game pulls from the same lighting language instead of
inventing per-asset darken/lighten math.
"""
import colorsys


def _clamp(v, lo=0.0, hi=1.0):
    return max(lo, min(hi, v))


def hex_to_hsv(hex_color):
    r, g, b = hex_color
    return colorsys.rgb_to_hsv(r / 255.0, g / 255.0, b / 255.0)


def hsv_to_rgba(h, s, v, a=255):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, _clamp(s), _clamp(v))
    return (round(r * 255), round(g * 255), round(b * 255), a)


class Ramp:
    """5-step material ramp: shadow2, shadow1, base, highlight1, highlight2.

    `hue_shift` is in turns (1.0 = 360 degrees) applied most strongly at the
    extremes and not at all at the base. `warm_hue`/`cool_hue` bias which
    direction highlights/shadows rotate (e.g. cloth leans warm-orange
    highlights, metal leans cool-white highlights).
    """

    def __init__(self, base_hex, *, cool_shift=-0.03, warm_shift=0.02,
                 sat_curve=(0.65, 0.85, 1.0, 0.92, 0.55),
                 val_curve=(0.22, 0.42, 1.0, 1.32, 1.65)):
        h, s, v = hex_to_hsv(base_hex)
        self.h, self.s, self.v = h, s, v
        self.cool_shift = cool_shift
        self.warm_shift = warm_shift
        self.sat_curve = sat_curve
        self.val_curve = val_curve
        self._cache = {}

    def step(self, index: int, alpha: int = 255):
        """index: -2, -1, 0, 1, 2 (shadow2, shadow1, base, highlight1, highlight2)."""
        key = (index, alpha)
        if key in self._cache:
            return self._cache[key]
        pos = index + 2  # 0..4 into the curves
        sat = self.s * self.sat_curve[pos]
        val = self.v * self.val_curve[pos]
        if index < 0:
            hue = self.h + self.cool_shift * (abs(index) / 2.0)
        elif index > 0:
            hue = self.h + self.warm_shift * (index / 2.0)
        else:
            hue = self.h
        color = hsv_to_rgba(hue, sat, _clamp(val, 0.0, 1.0), alpha)
        self._cache[key] = color
        return color

    @property
    def shadow2(self): return self.step(-2)
    @property
    def shadow1(self): return self.step(-1)
    @property
    def base(self): return self.step(0)
    @property
    def highlight1(self): return self.step(1)
    @property
    def highlight2(self): return self.step(2)

    def outline(self, index: int = -1):
        """Selective outline color: a darker, slightly desaturated version
        of the fill it borders, never pure black."""
        pos = index + 2
        sat = self.s * self.sat_curve[max(0, min(4, pos))] * 0.72
        val = self.v * self.val_curve[max(0, min(4, pos))] * 0.38
        hue = self.h + self.cool_shift * 1.4
        return hsv_to_rgba(hue, sat, _clamp(val, 0.05, 1.0))


def rim_color(hex_color, boost=1.55, cool=0.015):
    """A thin, bright rim-light tint for the lit edge of a silhouette."""
    h, s, v = hex_to_hsv(hex_color)
    return hsv_to_rgba(h + cool, _clamp(s * 0.55), _clamp(v * boost, 0, 1))
