extends RefCounted
## Warm-soft-fantasy art adapter. Combat clocks and colliders remain
## authoritative; this module maps player/world state to a diffuse+normal
## CanvasTexture pair so Light2D can relight the sprite in real time.

const IDLE_D = [preload("res://assets/art/q/player/idle_00.png"), preload("res://assets/art/q/player/idle_01.png"), preload("res://assets/art/q/player/idle_02.png"), preload("res://assets/art/q/player/idle_03.png")]
const IDLE_N = [preload("res://assets/art/q/player/idle_00_n.png"), preload("res://assets/art/q/player/idle_01_n.png"), preload("res://assets/art/q/player/idle_02_n.png"), preload("res://assets/art/q/player/idle_03_n.png")]
const RUN_D = [preload("res://assets/art/q/player/run_00.png"), preload("res://assets/art/q/player/run_01.png"), preload("res://assets/art/q/player/run_02.png"), preload("res://assets/art/q/player/run_03.png"), preload("res://assets/art/q/player/run_04.png"), preload("res://assets/art/q/player/run_05.png")]
const RUN_N = [preload("res://assets/art/q/player/run_00_n.png"), preload("res://assets/art/q/player/run_01_n.png"), preload("res://assets/art/q/player/run_02_n.png"), preload("res://assets/art/q/player/run_03_n.png"), preload("res://assets/art/q/player/run_04_n.png"), preload("res://assets/art/q/player/run_05_n.png")]
const JUMP_D = [preload("res://assets/art/q/player/jump_00.png")]
const JUMP_N = [preload("res://assets/art/q/player/jump_00_n.png")]
const FALL_D = [preload("res://assets/art/q/player/fall_00.png")]
const FALL_N = [preload("res://assets/art/q/player/fall_00_n.png")]
const LAND_D = [preload("res://assets/art/q/player/land_00.png"), preload("res://assets/art/q/player/land_01.png"), preload("res://assets/art/q/player/land_02.png")]
const LAND_N = [preload("res://assets/art/q/player/land_00_n.png"), preload("res://assets/art/q/player/land_01_n.png"), preload("res://assets/art/q/player/land_02_n.png")]
const CROUCH_D = [preload("res://assets/art/q/player/crouch_00.png")]
const CROUCH_N = [preload("res://assets/art/q/player/crouch_00_n.png")]
const DASH_D = [preload("res://assets/art/q/player/dash_00.png"), preload("res://assets/art/q/player/dash_01.png"), preload("res://assets/art/q/player/dash_02.png")]
const DASH_N = [preload("res://assets/art/q/player/dash_00_n.png"), preload("res://assets/art/q/player/dash_01_n.png"), preload("res://assets/art/q/player/dash_02_n.png")]
const HURT_D = [preload("res://assets/art/q/player/hurt_00.png")]
const HURT_N = [preload("res://assets/art/q/player/hurt_00_n.png")]
const DEATH_D = [preload("res://assets/art/q/player/death_00.png"), preload("res://assets/art/q/player/death_01.png"), preload("res://assets/art/q/player/death_02.png"), preload("res://assets/art/q/player/death_03.png")]
const DEATH_N = [preload("res://assets/art/q/player/death_00_n.png"), preload("res://assets/art/q/player/death_01_n.png"), preload("res://assets/art/q/player/death_02_n.png"), preload("res://assets/art/q/player/death_03_n.png")]
const PULSE_D = [preload("res://assets/art/q/player/pulse_00.png"), preload("res://assets/art/q/player/pulse_01.png"), preload("res://assets/art/q/player/pulse_02.png")]
const PULSE_N = [preload("res://assets/art/q/player/pulse_00_n.png"), preload("res://assets/art/q/player/pulse_01_n.png"), preload("res://assets/art/q/player/pulse_02_n.png")]
const POTION_D = [preload("res://assets/art/q/player/potion_00.png"), preload("res://assets/art/q/player/potion_01.png"), preload("res://assets/art/q/player/potion_02.png"), preload("res://assets/art/q/player/potion_03.png")]
const POTION_N = [preload("res://assets/art/q/player/potion_00_n.png"), preload("res://assets/art/q/player/potion_01_n.png"), preload("res://assets/art/q/player/potion_02_n.png"), preload("res://assets/art/q/player/potion_03_n.png")]
const ATTACK_LIGHT1_D = [preload("res://assets/art/q/player/attack_light1_startup.png"), preload("res://assets/art/q/player/attack_light1_active.png"), preload("res://assets/art/q/player/attack_light1_recovery.png")]
const ATTACK_LIGHT1_N = [preload("res://assets/art/q/player/attack_light1_startup_n.png"), preload("res://assets/art/q/player/attack_light1_active_n.png"), preload("res://assets/art/q/player/attack_light1_recovery_n.png")]
const ATTACK_LIGHT2_D = [preload("res://assets/art/q/player/attack_light2_startup.png"), preload("res://assets/art/q/player/attack_light2_active.png"), preload("res://assets/art/q/player/attack_light2_recovery.png")]
const ATTACK_LIGHT2_N = [preload("res://assets/art/q/player/attack_light2_startup_n.png"), preload("res://assets/art/q/player/attack_light2_active_n.png"), preload("res://assets/art/q/player/attack_light2_recovery_n.png")]
const ATTACK_LIGHT3_D = [preload("res://assets/art/q/player/attack_light3_startup.png"), preload("res://assets/art/q/player/attack_light3_active.png"), preload("res://assets/art/q/player/attack_light3_recovery.png")]
const ATTACK_LIGHT3_N = [preload("res://assets/art/q/player/attack_light3_startup_n.png"), preload("res://assets/art/q/player/attack_light3_active_n.png"), preload("res://assets/art/q/player/attack_light3_recovery_n.png")]
const ATTACK_UP_D = [preload("res://assets/art/q/player/attack_up_startup.png"), preload("res://assets/art/q/player/attack_up_active.png"), preload("res://assets/art/q/player/attack_up_recovery.png")]
const ATTACK_UP_N = [preload("res://assets/art/q/player/attack_up_startup_n.png"), preload("res://assets/art/q/player/attack_up_active_n.png"), preload("res://assets/art/q/player/attack_up_recovery_n.png")]
const ATTACK_DOWN_D = [preload("res://assets/art/q/player/attack_down_startup.png"), preload("res://assets/art/q/player/attack_down_active.png"), preload("res://assets/art/q/player/attack_down_recovery.png")]
const ATTACK_DOWN_N = [preload("res://assets/art/q/player/attack_down_startup_n.png"), preload("res://assets/art/q/player/attack_down_active_n.png"), preload("res://assets/art/q/player/attack_down_recovery_n.png")]
const ATTACK_HEAVY_D = [preload("res://assets/art/q/player/attack_heavy_startup.png"), preload("res://assets/art/q/player/attack_heavy_active.png"), preload("res://assets/art/q/player/attack_heavy_recovery.png")]
const ATTACK_HEAVY_N = [preload("res://assets/art/q/player/attack_heavy_startup_n.png"), preload("res://assets/art/q/player/attack_heavy_active_n.png"), preload("res://assets/art/q/player/attack_heavy_recovery_n.png")]

const ANCHOR = Vector2(24, 50)
const CANVAS = Vector2(48, 56)

const TERRAIN_TOP_D = preload("res://assets/art/q/terrain/top.png")
const TERRAIN_TOP_N = preload("res://assets/art/q/terrain/top_n.png")
const TERRAIN_FILL_D = preload("res://assets/art/q/terrain/fill.png")
const TERRAIN_FILL_N = preload("res://assets/art/q/terrain/fill_n.png")
const TERRAIN_EDGE_D = preload("res://assets/art/q/terrain/edge.png")
const TERRAIN_EDGE_N = preload("res://assets/art/q/terrain/edge_n.png")
const TERRAIN_PLATFORM_D = preload("res://assets/art/q/terrain/platform.png")
const TERRAIN_PLATFORM_N = preload("res://assets/art/q/terrain/platform_n.png")

const LANTERN_D = [preload("res://assets/art/q/props/lantern_00.png"), preload("res://assets/art/q/props/lantern_01.png"), preload("res://assets/art/q/props/lantern_02.png"), preload("res://assets/art/q/props/lantern_03.png")]
const LANTERN_N = [preload("res://assets/art/q/props/lantern_00_n.png"), preload("res://assets/art/q/props/lantern_01_n.png"), preload("res://assets/art/q/props/lantern_02_n.png"), preload("res://assets/art/q/props/lantern_03_n.png")]

const ATTACK_SETS = {
	"light1": [ATTACK_LIGHT1_D, ATTACK_LIGHT1_N], "light2": [ATTACK_LIGHT2_D, ATTACK_LIGHT2_N],
	"light3": [ATTACK_LIGHT3_D, ATTACK_LIGHT3_N], "up": [ATTACK_UP_D, ATTACK_UP_N],
	"down": [ATTACK_DOWN_D, ATTACK_DOWN_N], "heavy": [ATTACK_HEAVY_D, ATTACK_HEAVY_N],
}

## CanvasTexture cache: building a new CanvasTexture every draw call would
## allocate every frame, so each (diffuse, normal) pair is memoized once.
static var _tex_cache: Dictionary = {}

static func paired(diffuse: Texture2D, normal: Texture2D) -> CanvasTexture:
	var key = diffuse.get_rid().get_id()
	if _tex_cache.has(key): return _tex_cache[key]
	var tex = CanvasTexture.new()
	tex.diffuse_texture = diffuse
	tex.normal_texture = normal
	tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_tex_cache[key] = tex
	return tex

## Picks the current (diffuse, normal) frame pair for the player based on
## live combat/motion state. Animation is cosmetic: it reads the existing
## combat clock and physics state, it never drives them.
static func hero_frame_index(p) -> Array:
	# Returns [diffuse_array, normal_array, index]
	if p.dead: return [DEATH_D, DEATH_N, DEATH_D.size() - 1]
	if p.potion_clock >= 0:
		return [POTION_D, POTION_N, int(p.potion_clock * 10.0) % POTION_D.size()]
	if ATTACK_SETS.has(p.action):
		var pair = ATTACK_SETS[p.action]
		var tick = p.attack_clock * 60.0
		var phase = 0 if tick < p.move.startup else (1 if tick < p.move.startup + p.move.active else 2)
		return [pair[0], pair[1], phase]
	if p.action == "pulse":
		return [PULSE_D, PULSE_N, int(p.attack_clock * 60.0 / 6.0) % PULSE_D.size()]
	if p.stun > 0.06:
		return [HURT_D, HURT_N, 0]
	if p.dash_clock > 0:
		var dash_elapsed = 10.0 / 60.0 - p.dash_clock
		var dash_frame = clampi(int(dash_elapsed * 60.0 / 4.0), 0, DASH_D.size() - 1)
		return [DASH_D, DASH_N, dash_frame]
	if p.landing_squash > 0.30:
		return [LAND_D, LAND_N, 0]
	elif p.landing_squash > 0.12:
		return [LAND_D, LAND_N, 1]
	if p.crouched: return [CROUCH_D, CROUCH_N, 0]
	if not p.is_on_floor():
		return [JUMP_D, JUMP_N, 0] if p.velocity.y < 0 else [FALL_D, FALL_N, 0]
	if absf(p.velocity.x) > 15:
		return [RUN_D, RUN_N, int(p.animation_clock * 12.0) % RUN_D.size()]
	return [IDLE_D, IDLE_N, int(p.animation_clock * 6.0) % IDLE_D.size()]

static func draw_hero(p):
	# Mirror by the eased visual_facing, not the instant gameplay facing, so
	# turning around reads as a quick pivot instead of a snap-flip.
	var pick = hero_frame_index(p)
	var diffuse: Texture2D = pick[0][pick[2]]
	var normal: Texture2D = pick[1][pick[2]]
	p.draw_set_transform(Vector2.ZERO, 0, Vector2(p.visual_facing, 1))
	p.draw_texture(paired(diffuse, normal), -ANCHOR)
	p.draw_set_transform(Vector2.ZERO)

static func draw_terrain(node, rect: Rect2, one_way: bool):
	# Top-left pixel stays on the existing collision surface. End tiles crop,
	# never stretch: platform lengths need not be multiples of 16.
	for x in range(int(rect.position.x), int(rect.end.x), 16):
		var width = mini(16, int(rect.end.x) - x)
		if one_way:
			node.draw_texture_rect_region(paired(TERRAIN_PLATFORM_D, TERRAIN_PLATFORM_N), Rect2(x, rect.position.y, width, 16), Rect2(0, 0, width, 16))
		else:
			var is_edge = x == int(rect.position.x)
			var tile = paired(TERRAIN_EDGE_D, TERRAIN_EDGE_N) if is_edge else paired(TERRAIN_TOP_D, TERRAIN_TOP_N)
			node.draw_texture_rect_region(tile, Rect2(x, rect.position.y, width, 16), Rect2(0, 0, width, 16))
			for y in range(int(rect.position.y) + 16, int(rect.end.y), 16):
				var height = mini(16, int(rect.end.y) - y)
				node.draw_texture_rect_region(paired(TERRAIN_FILL_D, TERRAIN_FILL_N), Rect2(x, y, width, height), Rect2(0, 0, width, height))
	node.draw_line(rect.position, Vector2(rect.end.x, rect.position.y), Color("8aa8c4"), 1)

static func lantern_frame(clock: float) -> Texture2D:
	var i = int(clock * 6.0) % LANTERN_D.size()
	return paired(LANTERN_D[i], LANTERN_N[i])
