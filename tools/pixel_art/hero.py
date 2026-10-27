"""Chibi hero (巡灯人) frame generator — warm-soft-fantasy pass.

Canvas 48x56, foot anchor (24, 50). Same chibi proportions as before (big
head, short body, strict right-facing side profile) but every shape now
pulls from a hue-shifted Ramp, gets a selective (non-black) outline, and a
thin rim light on its lit edge. A parallel normal map is produced for each
frame so Godot's lantern PointLight2D can re-light the sprite live on top
of the baked ambient shading.

Returns (diffuse_image, normal_image) per frame.
"""
import math
from .canvas import PixelCanvas
from .palette import HERO as C, rim_for

CANVAS = (48, 56)
ANCHOR = (24, 50)


def _base(cv: PixelCanvas, *, head_bob=0.0, lean=0.0, leg_back=0.0, leg_front=0.0,
          arm_back=0.0, arm_front=0.0, crouch=0.0, cape_swing=0.0, squash=0.0,
          eyes_closed=False, torso_lean=0.0):
    ox = 24 + lean
    foot_y = 50
    torso_h = 14 - crouch * 5
    torso_top = foot_y - 6 - torso_h - squash * 2
    hip_x = ox - 2 + torso_lean
    head_cx = ox + 2 + torso_lean * 1.4
    head_cy = torso_top - 8 + head_bob - squash
    head_w = 16 + squash * 2
    head_h = 15 - squash * 1.5

    # Cape trails behind (to the left); rich garnet ramp instead of dull rust.
    cape_top = torso_top + 1
    cv.shaded_polygon([
        (hip_x - 6 + cape_swing * 0.3, cape_top),
        (hip_x - 11 - cape_swing, foot_y - 6),
        (hip_x - 4, foot_y - 4),
        (hip_x, cape_top + 3),
    ], C["cape"], light_from="top")

    # Back leg (shaded darker — far side, away from camera)
    back_leg_x = hip_x - 2 + leg_back
    leg_len = 8 + crouch * 3
    cv.shaded_rect(back_leg_x - 2, foot_y - leg_len, 4, leg_len - 2, C["tunic"], light_from="bottom")
    cv.shaded_rect(back_leg_x - 2, foot_y - 2, 5, 2, C["boots"], light_from="bottom")

    # Back arm
    back_shoulder = (hip_x - 3, torso_top + 2)
    back_hand = (back_shoulder[0] - 1 + arm_back * 0.4, back_shoulder[1] + 8 + abs(arm_back) * 0.3)
    cv.line(back_shoulder[0], back_shoulder[1], back_hand[0], back_hand[1], C["tunic"].shadow1, width=3)
    cv.ellipse(back_hand[0] - 1.5, back_hand[1] - 1.5, 3, 3, C["skin"].shadow1)

    # Torso: the main shaded block, rim-lit on the near/top edge.
    cv.shaded_rect(hip_x - 6, torso_top, 13, torso_h, C["tunic"], light_from="top",
                    rim=rim_for(C["tunic"]))
    cv.rect(hip_x - 1, torso_top + 2, 2, torso_h - 4, C["trim"].highlight1)
    cv.shaded_rect(hip_x - 6, torso_top - 1, 13, 2, C["belt"], light_from="top", outline=False)

    # Front leg (closer to camera, forward of hip, gets the brighter ramp step)
    front_leg_x = hip_x + 2 + leg_front
    cv.shaded_rect(front_leg_x - 1, foot_y - leg_len, 5, leg_len - 2, C["tunic"], light_from="top")
    cv.shaded_rect(front_leg_x - 1, foot_y - 2, 5, 2, C["boots"], light_from="top")

    # Lantern glow at the hip — this is the brightest thing on the body and
    # anchors the "warm light source carried by the hero" identity.
    cv.rect(hip_x - 9, torso_top + torso_h - 6, 4, 6, C["belt"].shadow1)
    cv.ellipse(hip_x - 8.5, torso_top + torso_h - 5.5, 3, 3, C["lantern_glass"].highlight2)
    cv.ellipse(hip_x - 8, torso_top + torso_h - 5, 2, 2, C["lantern_glass"].highlight1)

    # Head: side profile facing right, chibi-big, with a forward snout block.
    hx, hy = round(head_cx - head_w / 2), round(head_cy - head_h / 2)
    cv.shaded_rect(hx, hy, head_w, head_h, C["mask"], light_from="top", rim=rim_for(C["mask"]))
    snout_w = 4
    cv.shaded_rect(hx + head_w - 2, hy + head_h - 7, snout_w, 6, C["mask"], light_from="top", outline=False)
    cv.rect(hx + 1, hy + 2, head_w - 2, 2, C["mask"].shadow1)
    if eyes_closed:
        cv.rect(hx + head_w - 9, hy + 7, 6, 1, C["mask_visor"].shadow1)
    else:
        cv.shaded_rect(hx + head_w - 10, hy + 5, 8, 5, C["mask_visor"], light_from="top", outline=False)
        cv.ellipse(hx + head_w - 7.5, hy + 6, 3, 3, C["eye"].highlight2)
        cv.rect(hx + head_w - 7, hy + 6, 1, 1, (255, 255, 255, 255))
    cv.ellipse(hx + head_w - 0.5, hy + head_h - 6, 2, 2, C["lantern_glass"].highlight1)

    # Front arm over torso, swings forward.
    front_shoulder = (hip_x + 5, torso_top + 2)
    front_hand = (front_shoulder[0] + 2 + arm_front * 0.5, front_shoulder[1] + 7 + arm_front * 0.6)
    cv.line(front_shoulder[0], front_shoulder[1], front_hand[0], front_hand[1], C["tunic"].highlight1, width=3)
    cv.ellipse(front_hand[0] - 1.5, front_hand[1] - 1.5, 3, 3, C["skin"].base)


def _finish(cv):
    return cv.finalize(), cv.finalize_normal()


def idle(frame: int):
    cv = PixelCanvas(*CANVAS)
    bob = [0, -1, 0, 1][frame % 4] * 0.6
    cape = [0, 1, 0.5, -0.5][frame % 4]
    _base(cv, head_bob=bob, cape_swing=cape, arm_back=1, arm_front=1)
    return _finish(cv)


def run(frame: int):
    cv = PixelCanvas(*CANVAS)
    phase = (frame % 6) / 6.0
    swing = math.sin(phase * math.tau)
    leg_back = -swing * 4
    leg_front = swing * 4
    arm_back = swing * 5
    arm_front = -swing * 5
    bob = -abs(math.sin(phase * math.pi)) * 2.2
    _base(cv, head_bob=bob, lean=1.0, torso_lean=1.5, leg_back=leg_back, leg_front=leg_front,
          arm_back=arm_back, arm_front=arm_front, cape_swing=-3 + swing * 2)
    return _finish(cv)


def jump_rise():
    cv = PixelCanvas(*CANVAS)
    _base(cv, head_bob=-1, lean=0.5, torso_lean=1.0, leg_back=4, leg_front=-3,
          arm_back=-5, arm_front=-5, cape_swing=3)
    return _finish(cv)


def fall():
    cv = PixelCanvas(*CANVAS)
    _base(cv, head_bob=1, leg_back=-2, leg_front=2, arm_back=4, arm_front=4, cape_swing=5)
    return _finish(cv)


def land(frame: int):
    cv = PixelCanvas(*CANVAS)
    squash = [1.4, 0.6, 0][min(frame, 2)]
    _base(cv, squash=squash, leg_back=-1, leg_front=1, arm_back=2, arm_front=-2, cape_swing=1)
    return _finish(cv)


def crouch():
    cv = PixelCanvas(*CANVAS)
    _base(cv, crouch=1.0, head_bob=3, arm_back=1, arm_front=1)
    return _finish(cv)


def dash(frame: int):
    cv = PixelCanvas(*CANVAS)
    lean = [3, 6, 4][min(frame, 2)]
    _base(cv, lean=lean, head_bob=0.5, torso_lean=2.0, leg_back=3, leg_front=-4,
          arm_back=-2, arm_front=-6, cape_swing=-6 - lean * 0.4)
    return _finish(cv)


def hurt():
    cv = PixelCanvas(*CANVAS)
    _base(cv, lean=-3, head_bob=-1, torso_lean=-2.0, leg_back=2, leg_front=-2,
          arm_back=-2, arm_front=-4, cape_swing=6, eyes_closed=True)
    return _finish(cv)


def death(frame: int):
    cv = PixelCanvas(*CANVAS)
    tilt = [0, 2, 4, 5][min(frame, 3)]
    _base(cv, lean=tilt * 1.5, head_bob=tilt, crouch=min(tilt / 4.0, 1.0),
          leg_back=tilt, leg_front=-tilt, eyes_closed=True)
    return _finish(cv)


def _attack(cv: PixelCanvas, swing_progress: float, kind: str, pose_lean=0.0):
    lean = pose_lean + swing_progress * 2
    arm_front = -10 + swing_progress * 16
    if kind == "up":
        arm_front = -14
    elif kind == "down":
        arm_front = 4
    _base(cv, lean=lean, torso_lean=2.0, arm_front=arm_front, arm_back=-2,
          leg_back=-1, leg_front=1, cape_swing=-2 - swing_progress * 3)


def attack_pose(kind: str, phase: str):
    cv = PixelCanvas(*CANVAS)
    progress = {"startup": 0.0, "active": 0.55, "recovery": 1.0}[phase]
    _attack(cv, progress, kind, pose_lean=1.0 if kind == "heavy" else 0.0)
    return _finish(cv)


def pulse(frame: int):
    cv = PixelCanvas(*CANVAS)
    bob = [0, -1, 0][frame % 3]
    _base(cv, head_bob=bob, arm_back=-3, arm_front=-3, cape_swing=2)
    return _finish(cv)


def potion(frame: int):
    cv = PixelCanvas(*CANVAS)
    lift = [0, 1, 1, 0][frame % 4]
    _base(cv, head_bob=-lift, arm_front=-12 - lift, arm_back=1)
    cv.ellipse(24 + 7, 50 - 6 - 15 - 12 - lift, 4, 6, C["lantern_glass"].highlight1)
    return _finish(cv)
