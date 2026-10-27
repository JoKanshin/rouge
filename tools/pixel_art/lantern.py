"""Hanging mine lantern prop, 32x32 canvas, matches existing anchor (16,28).
This sprite is the brightest asset in the game — its flame core is the only
thing authored above the ambient palette, so Godot's glow pass has a clean
authored "hot spot" to bloom instead of blooming every warm color."""
from .canvas import PixelCanvas
from .palette import LANTERN_PROP as C

CANVAS = (32, 32)


def _finish(cv):
    return cv.finalize(), cv.finalize_normal()


def lantern(frame: int = 0):
    cv = PixelCanvas(*CANVAS)
    flicker = [0, 1, 0, -1][frame % 4]
    cv.shaded_rect(14, 2, 4, 3, C["frame"], light_from="top")
    cv.shaded_rect(10, 5, 12, 14, C["frame"], light_from="top")
    cv.rect(12, 7, 8, 10, C["glass"].shadow1)
    cv.polygon([(16, 9 + flicker * 0.3), (19, 15), (16, 18), (13, 15)], C["glass"].highlight1)
    cv.ellipse(14.5, 10.5, 3, 4, C["glass"].highlight2)
    cv.shaded_rect(10, 19, 12, 2, C["frame"], light_from="top", outline=False)
    return _finish(cv)
