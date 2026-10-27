"""Warm-soft-fantasy mine terrain tiles. 16x16 logical pixels, top-left
anchor, matching the existing TileSet convention (top/fill/edge/platform).

Deep indigo stone in shadow with warm ore/crystal seams for pop, instead of
flat grey blocks. Each tile also produces a matching normal map so the
lantern PointLight2D can pick out the ore veins and platform grain.
"""
from .canvas import PixelCanvas
from .palette import TERRAIN as C

SIZE = 16


def _finish(cv):
    return cv.finalize(), cv.finalize_normal()


def top():
    cv = PixelCanvas(SIZE, SIZE)
    cv.shaded_rect(0, 0, SIZE, SIZE, C["stone"], light_from="top", rim=None)
    cv.rect(0, 0, SIZE, 1, C["rim"].highlight1)
    cv.ellipse(2, 4, 4, 3, C["stone"].shadow1)
    cv.ellipse(9, 6, 5, 4, C["stone"].shadow1)
    cv.rect(3, 10, 3, 2, C["ore"].shadow1)
    cv.ellipse(10.5, 10.5, 3, 3, C["crystal"].highlight2)
    cv.ellipse(11, 11, 1.4, 1.4, (255, 255, 255, 255))
    return _finish(cv)


def fill():
    cv = PixelCanvas(SIZE, SIZE)
    cv.shaded_rect(0, 0, SIZE, SIZE, C["stone"], light_from="top", outline=False)
    cv.ellipse(1, 2, 5, 4, C["stone"].base)
    cv.ellipse(8, 7, 6, 5, C["stone"].shadow1)
    cv.rect(2, 11, 4, 3, C["ore"].shadow1)
    return _finish(cv)


def edge():
    cv = PixelCanvas(SIZE, SIZE)
    cv.shaded_rect(0, 0, SIZE, SIZE, C["stone"], light_from="top")
    cv.rect(0, 0, SIZE, 1, C["rim"].highlight1)
    cv.rect(0, 0, 3, SIZE, C["stone"].shadow2)
    cv.ellipse(5, 5, 4, 4, C["crystal"].highlight1)
    return _finish(cv)


def platform():
    cv = PixelCanvas(SIZE, SIZE)
    cv.shaded_rect(0, 2, SIZE, 5, C["wood"], light_from="top")
    cv.rect(0, 2, SIZE, 1, C["ore"].highlight1)
    for x in (2, 8, 13):
        cv.rect(x, 7, 1, 5, C["wood"].shadow1)
    return _finish(cv)
