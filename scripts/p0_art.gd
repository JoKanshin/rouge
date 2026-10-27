extends RefCounted
## Visual-only P0 samples. Combat clocks and colliders remain authoritative.
const HERO = [preload("res://assets/art/player/hero_idle_v01.png"), preload("res://assets/art/player/hero_anticipate_v01.png"), preload("res://assets/art/player/hero_contact_v01.png"), preload("res://assets/art/player/hero_recover_v01.png")]
const MINER = [preload("res://assets/art/enemies/miner/idle_v01.png"), preload("res://assets/art/enemies/miner/windup_v01.png")]
const BAT = [preload("res://assets/art/enemies/bat/spread_v01.png"), preload("res://assets/art/enemies/bat/fold_v01.png")]
const TOP = preload("res://assets/art/terrain/mine/top_v01.png")
const FILL = preload("res://assets/art/terrain/mine/fill_v01.png")
const EDGE = preload("res://assets/art/terrain/mine/edge_v01.png")
const PLATFORM = preload("res://assets/art/terrain/mine/platform_v01.png")
const LANTERN = preload("res://assets/art/props/lantern_v01.png")

static func hero_frame(p) -> int:
	if p.action not in ["light1", "light2", "light3", "heavy"]: return 0
	var frame = p.attack_clock * 60
	if frame < p.move.startup: return 1
	if frame < p.move.startup + p.move.active: return 2
	return 3

static func draw_hero(p):
	var compressed = 0.5 if p.crouched else 1.0
	p.draw_set_transform(Vector2.ZERO, 0, Vector2(p.facing, compressed))
	p.draw_texture(HERO[hero_frame(p)], Vector2(-16,-44))
	p.draw_set_transform(Vector2.ZERO, 0, Vector2(p.facing,1))

static func draw_enemy(e):
	var frame = 1 if e.state == e.State.WINDUP else 0
	var tint = Color(1.6,1.6,1.6) if e.flash > 0 and e.feedback.flash_level > 0 else Color.WHITE
	if e.kind == "miner":
		var face = e.locked_facing if e.state in [e.State.WINDUP,e.State.ACTIVE] else e.visual_facing
		e.draw_set_transform(Vector2.ZERO,0,Vector2(face,1))
		e.draw_texture(MINER[frame],Vector2(-24,-56),tint)
	else:
		e.draw_texture(BAT[frame],Vector2(-32,-36),tint)
	e.draw_set_transform(Vector2.ZERO)

static func draw_terrain(node, rect: Rect2, one_way: bool):
	# Top-left pixel stays on the existing collision surface. End tiles crop,
	# never stretch: platform lengths need not be multiples of 16.
	for x in range(int(rect.position.x),int(rect.end.x),16):
		var width = mini(16,int(rect.end.x)-x)
		if one_way:
			node.draw_texture_rect_region(PLATFORM,Rect2(x,rect.position.y,width,16),Rect2(0,0,width,16))
		else:
			var tile = EDGE if x == int(rect.position.x) else TOP
			node.draw_texture_rect_region(tile,Rect2(x,rect.position.y,width,16),Rect2(0,0,width,16))
			for y in range(int(rect.position.y)+16,int(rect.end.y),16):
				var height = mini(16,int(rect.end.y)-y)
				node.draw_texture_rect_region(FILL,Rect2(x,y,width,height),Rect2(0,0,width,height),Color(0.65,0.65,0.65))
	# An unbroken readable 1px rim aligns exactly with the collision plane.
	node.draw_line(rect.position,Vector2(rect.end.x,rect.position.y),Color("72817b"),1)
