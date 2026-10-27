"""Warm-soft-fantasy palette for Ash Below, v2.

Every material is a hue-shifted Ramp (see ramp.py) instead of a flat color:
cool/desaturated in shadow, base hue at mid, warm/bright at highlight. This
is the single biggest lever for "painterly" vs "flat chibi sticker" pixel
art. Scripts pull `.base`, `.highlight1`, `.shadow1`, `.outline()` etc. from
these ramps rather than inventing new hex values per sprite.
"""
from .ramp import Ramp, rim_color

# -- Hero: pale ash skin, deep teal-indigo tunic, rich garnet cape, molten
# amber lantern. Richer and more saturated than the first pass so it reads
# as "fantasy adventurer" rather than "grey chibi mannequin". --
HERO = {
    "skin": Ramp((237, 201, 170), warm_shift=0.015, cool_shift=-0.02),
    "mask": Ramp((214, 222, 219), cool_shift=-0.018, warm_shift=0.01,
                 sat_curve=(0.5, 0.7, 0.85, 0.7, 0.4)),
    "mask_visor": Ramp((36, 46, 58), cool_shift=-0.02, warm_shift=0.0,
                       val_curve=(0.08, 0.3, 0.55, 0.85, 1.4)),
    "tunic": Ramp((42, 99, 107), warm_shift=0.03, cool_shift=-0.035,
                  sat_curve=(0.8, 0.95, 1.0, 0.75, 0.42)),
    "trim": Ramp((223, 173, 86), warm_shift=0.02, cool_shift=-0.02),
    "cape": Ramp((150, 48, 58), warm_shift=0.025, cool_shift=-0.03,
                 sat_curve=(0.75, 0.95, 1.0, 0.8, 0.5)),
    "belt": Ramp((101, 75, 54), warm_shift=0.02, cool_shift=-0.02),
    "boots": Ramp((54, 42, 46), warm_shift=0.0, cool_shift=-0.02),
    "lantern_glass": Ramp((255, 191, 97), warm_shift=0.03, cool_shift=-0.01,
                          val_curve=(0.3, 0.55, 1.0, 1.5, 1.95)),
    "eye": Ramp((255, 221, 140), warm_shift=0.02,
               val_curve=(0.3, 0.6, 1.0, 1.6, 2.0)),
    "hair": Ramp((70, 54, 64), warm_shift=0.01, cool_shift=-0.02),
}

MINER = {
    "skin": Ramp((224, 182, 148), warm_shift=0.015, cool_shift=-0.02),
    "coat": Ramp((150, 103, 62), warm_shift=0.03, cool_shift=-0.03,
                sat_curve=(0.8, 0.95, 1.0, 0.75, 0.45)),
    "helmet": Ramp((108, 84, 58), warm_shift=0.02, cool_shift=-0.03),
    "helmet_lamp": Ramp((255, 201, 110), warm_shift=0.03,
                        val_curve=(0.35, 0.6, 1.0, 1.55, 1.9)),
    "pick_head": Ramp((176, 182, 186), cool_shift=-0.02, warm_shift=0.01),
    "pick_handle": Ramp((120, 85, 55), warm_shift=0.02, cool_shift=-0.03),
    "boots": Ramp((58, 46, 40), cool_shift=-0.02),
    "warn": Ramp((233, 128, 72), warm_shift=0.04, cool_shift=-0.02),
}

ARCHER = {
    "skin": Ramp((222, 190, 169), warm_shift=0.015, cool_shift=-0.02),
    "robe": Ramp((63, 110, 104), warm_shift=0.025, cool_shift=-0.035,
                sat_curve=(0.78, 0.95, 1.0, 0.75, 0.4)),
    "hood": Ramp((46, 61, 66), cool_shift=-0.03, warm_shift=0.01),
    "trim": Ramp((223, 173, 86), warm_shift=0.02, cool_shift=-0.02),
    "bow": Ramp((176, 178, 164), cool_shift=-0.02, warm_shift=0.01),
    "lantern": Ramp((233, 158, 76), warm_shift=0.03,
                   val_curve=(0.3, 0.55, 1.0, 1.5, 1.9)),
    "boots": Ramp((54, 47, 44), cool_shift=-0.02),
}

BAT = {
    "body": Ramp((122, 91, 148), warm_shift=0.015, cool_shift=-0.04,
                sat_curve=(0.75, 0.9, 1.0, 0.8, 0.5)),
    "wing": Ramp((93, 69, 128), cool_shift=-0.045, warm_shift=0.01),
    "fang": Ramp((244, 221, 176), warm_shift=0.02),
    "eye": Ramp((255, 196, 120), warm_shift=0.03, val_curve=(0.4, 0.7, 1.0, 1.6, 2.0)),
}

# -- Terrain: deep indigo-blue stone in shadow, warm ore seams for pop --
TERRAIN = {
    "stone": Ramp((47, 58, 84), warm_shift=0.012, cool_shift=-0.05,
                 sat_curve=(0.7, 0.85, 1.0, 0.7, 0.4),
                 val_curve=(0.16, 0.38, 0.62, 0.95, 1.3)),
    "rim": Ramp((138, 168, 196), cool_shift=-0.03, warm_shift=0.015),
    "ore": Ramp((233, 178, 86), warm_shift=0.035, cool_shift=-0.02,
               val_curve=(0.3, 0.55, 1.0, 1.55, 2.0)),
    "crystal": Ramp((120, 198, 214), cool_shift=-0.03, warm_shift=0.02,
                    val_curve=(0.3, 0.55, 1.0, 1.55, 2.0)),
    "wood": Ramp((115, 83, 56), warm_shift=0.02, cool_shift=-0.03),
}

LANTERN_PROP = {
    "frame": Ramp((88, 71, 55), warm_shift=0.02, cool_shift=-0.02),
    "glass": Ramp((255, 184, 92), warm_shift=0.03, cool_shift=-0.01,
                 val_curve=(0.3, 0.55, 1.0, 1.5, 2.0)),
}

# Scene-level ambient tint applied via CanvasModulate: cool indigo base so
# warm lantern light has something to contrast against.
AMBIENT_TINT = (0.42, 0.47, 0.64, 1.0)
LANTERN_LIGHT_COLOR = (255, 179, 97, 255)

TRANSPARENT = (0, 0, 0, 0)


def rim_for(ramp: Ramp):
    import colorsys
    r, g, b = colorsys.hsv_to_rgb(ramp.h, 0.5, 1.0)
    return rim_color((round(r * 255), round(g * 255), round(b * 255)))
