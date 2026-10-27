"""Build warm-soft-fantasy art and export PNGs into assets/art/.

Run: python tools/pixel_art/build.py
Writes diffuse + normal PNG pairs and a manifest to assets/art/q_manifest.json
describing every exported frame, its animation, canvas size, foot anchor and
normal-map path, so the Godot-side art adapter can build CanvasTexture
resources (diffuse + normal) for real-time PointLight2D relighting.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from tools.pixel_art import hero, terrain, lantern

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, "assets", "art", "q")


def ensure(path):
    os.makedirs(path, exist_ok=True)


def save_pair(pair, rel_path):
    diffuse, normal = pair
    full = os.path.join(OUT, rel_path)
    ensure(os.path.dirname(full))
    diffuse.save(full)
    normal_rel = rel_path.rsplit(".", 1)[0] + "_n.png"
    normal_full = os.path.join(OUT, normal_rel)
    normal.save(normal_full)
    return (
        "res://assets/art/q/" + rel_path.replace(os.sep, "/"),
        "res://assets/art/q/" + normal_rel.replace(os.sep, "/"),
    )


def main():
    manifest = {
        "version": 2,
        "generator": "tools/pixel_art/build.py (Pillow ramps + baked normals, no SVG intermediate)",
        "player": {}, "terrain": {}, "props": {},
    }

    anchor = list(hero.ANCHOR)
    canvas = list(hero.CANVAS)

    def anim_entry(pairs, loop=True, fps=10):
        diffuse = [p[0] for p in pairs]
        normal = [p[1] for p in pairs]
        return {"frames": diffuse, "normals": normal, "loop": loop, "fps": fps,
                "canvas": canvas, "anchor": anchor}

    idle_pairs = [save_pair(hero.idle(i), f"player/idle_{i:02d}.png") for i in range(4)]
    manifest["player"]["idle"] = anim_entry(idle_pairs, fps=6)

    run_pairs = [save_pair(hero.run(i), f"player/run_{i:02d}.png") for i in range(6)]
    manifest["player"]["run"] = anim_entry(run_pairs, fps=12)

    manifest["player"]["jump"] = anim_entry([save_pair(hero.jump_rise(), "player/jump_00.png")], loop=False, fps=1)
    manifest["player"]["fall"] = anim_entry([save_pair(hero.fall(), "player/fall_00.png")], loop=False, fps=1)

    land_pairs = [save_pair(hero.land(i), f"player/land_{i:02d}.png") for i in range(3)]
    manifest["player"]["land"] = anim_entry(land_pairs, loop=False, fps=14)

    manifest["player"]["crouch"] = anim_entry([save_pair(hero.crouch(), "player/crouch_00.png")], loop=False, fps=1)

    dash_pairs = [save_pair(hero.dash(i), f"player/dash_{i:02d}.png") for i in range(3)]
    manifest["player"]["dash"] = anim_entry(dash_pairs, loop=False, fps=16)

    manifest["player"]["hurt"] = anim_entry([save_pair(hero.hurt(), "player/hurt_00.png")], loop=False, fps=1)

    death_pairs = [save_pair(hero.death(i), f"player/death_{i:02d}.png") for i in range(4)]
    manifest["player"]["death"] = anim_entry(death_pairs, loop=False, fps=8)

    pulse_pairs = [save_pair(hero.pulse(i), f"player/pulse_{i:02d}.png") for i in range(3)]
    manifest["player"]["pulse"] = anim_entry(pulse_pairs, loop=False, fps=10)

    potion_pairs = [save_pair(hero.potion(i), f"player/potion_{i:02d}.png") for i in range(4)]
    manifest["player"]["potion"] = anim_entry(potion_pairs, loop=False, fps=8)

    for kind in ["light1", "light2", "light3", "up", "down", "heavy"]:
        pairs = []
        for phase in ["startup", "active", "recovery"]:
            pair = hero.attack_pose(kind, phase)
            pairs.append(save_pair(pair, f"player/attack_{kind}_{phase}.png"))
        manifest["player"][f"attack_{kind}"] = anim_entry(pairs, loop=False, fps=1)
        manifest["player"][f"attack_{kind}"]["phase_frames"] = {
            "startup": pairs[0][0], "active": pairs[1][0], "recovery": pairs[2][0]
        }
        manifest["player"][f"attack_{kind}"]["phase_normals"] = {
            "startup": pairs[0][1], "active": pairs[1][1], "recovery": pairs[2][1]
        }

    terrain_pairs = {
        "top": save_pair(terrain.top(), "terrain/top.png"),
        "fill": save_pair(terrain.fill(), "terrain/fill.png"),
        "edge": save_pair(terrain.edge(), "terrain/edge.png"),
        "platform": save_pair(terrain.platform(), "terrain/platform.png"),
    }
    manifest["terrain"] = {
        "size": [16, 16],
        "paths": {k: v[0] for k, v in terrain_pairs.items()},
        "normals": {k: v[1] for k, v in terrain_pairs.items()},
    }

    lantern_pairs = [save_pair(lantern.lantern(i), f"props/lantern_{i:02d}.png") for i in range(4)]
    manifest["props"]["lantern"] = anim_entry(lantern_pairs, fps=6)

    manifest_path = os.path.join(ROOT, "assets", "art", "q_manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    total_frames = sum(len(v["frames"]) for v in manifest["player"].values()) + 4 + len(lantern_pairs)
    print(f"Exported {total_frames} diffuse+normal pairs to {OUT}")
    print(f"Manifest: {manifest_path}")


if __name__ == "__main__":
    main()
