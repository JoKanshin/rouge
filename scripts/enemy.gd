extends CharacterBody2D
const P0Art = preload("res://scripts/p0_art.gd")

const Hurtbox = preload("res://scripts/combat/hurtbox.gd")
const Hitbox = preload("res://scripts/combat/hitbox.gd")
enum State { PATROL, CHASE, WINDUP, ACTIVE, RECOVER, STUN, BROKEN, DEAD }
const DATA = {
	"dummy": {"name": "练剑木桩", "hp": 999, "stance": 80, "speed": 0.0, "damage": 0, "windup": 0.0, "recover": 0.0},
	"miner": {"name": "镐斧矿工", "hp": 74, "stance": 70, "speed": 38.0, "damage": 15, "windup": 0.45, "recover": 0.65},
	"archer": {"name": "提灯弩手", "hp": 56, "stance": 55, "speed": 34.0, "damage": 12, "windup": 0.65, "recover": 0.85},
	"bat": {"name": "裂翼蝠", "hp": 48, "stance": 50, "speed": 42.0, "damage": 13, "windup": 0.40, "recover": 0.80}
}
var arena: Node
var player: CharacterBody2D
var feedback: Node
var kind = "miner"
var data: Dictionary
var hp = 74
var max_hp = 74
var stance = 0.0
var state = State.PATROL
var state_clock = 0.0
var facing = -1
var visual_facing = -1.0
var locked_facing = -1
var locked_target = Vector2.ZERO
var home = Vector2.ZERO
var hurtbox: Area2D
var hitbox: Area2D
var flash = 0.0
var break_guard = 0.0
var attack_cooldown = 0.7
var animation_clock = 0.0
var shot_count = 0
var high_shot = true
var attack_serial = 0
var attack_open = false
var airborne = false
var debug_label = ""

func _ready():
	add_to_group("enemies")
	data = DATA[kind].duplicate()
	hp = data.hp
	max_hp = hp
	home = position
	airborne = kind == "bat"
	collision_layer = 32
	collision_mask = 1 if airborne else 3
	floor_snap_length = 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING if airborne else CharacterBody2D.MOTION_MODE_GROUNDED
	var solid = CollisionShape2D.new()
	solid.shape = RectangleShape2D.new()
	solid.shape.size = Vector2(18, 20 if airborne else 27)
	solid.position.y = -10 if airborne else -13.5
	add_child(solid)
	hurtbox = Hurtbox.new()
	add_child(hurtbox)
	hurtbox.setup(self, 8, Vector2(20, 20 if airborne else 28), Vector2(0, -10 if airborne else -14))
	hitbox = Hitbox.new()
	add_child(hitbox)
	hitbox.target_mask = 16

func change_state(next: int):
	if state == State.WINDUP or state == State.ACTIVE:
		if next not in [State.WINDUP, State.ACTIVE]: arena.release_attacker(self)
	state = next
	state_clock = 0
	attack_open = false
	hitbox.end()
	if state == State.WINDUP:
		locked_facing = facing
		locked_target = player.position - Vector2(0, 12)
		attack_serial += 1
		high_shot = shot_count % 2 == 0
	if state == State.RECOVER: attack_cooldown = 0.55

func can_see_player() -> bool:
	var from = position - Vector2(0, 17)
	var to = player.position - Vector2(0, 14)
	if from.distance_to(to) > 460: return false
	var query = PhysicsRayQueryParameters2D.create(from, to, 1)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

func _physics_process(dt):
	animation_clock += dt
	state_clock += dt
	flash = maxf(0, flash - dt)
	break_guard = maxf(0, break_guard - dt)
	attack_cooldown = maxf(0, attack_cooldown - dt)
	queue_redraw()
	hitbox.queue_redraw()
	if state == State.DEAD: return
	if kind == "dummy":
		velocity.x = move_toward(velocity.x, 0, dt * 550)
		velocity.y += 1000 * dt
		move_and_slide()
		if state in [State.STUN, State.BROKEN] and state_clock > (0.7 if state == State.BROKEN else 0.12): change_state(State.PATROL)
		if state == State.PATROL: stance = maxf(0, stance - dt * 12)
		return
	if not is_instance_valid(player) or player.dead:
		velocity = Vector2.ZERO
		return
	var distance = position.distance_to(player.position)
	var horizontal = player.position.x - position.x
	if state not in [State.WINDUP, State.ACTIVE, State.STUN, State.BROKEN]:
		if absf(horizontal) > 4: facing = int(signf(horizontal))
	match state:
		State.PATROL:
			velocity.x = 0
			if can_see_player(): change_state(State.CHASE)
		State.CHASE:
			if airborne:
				var desired = Vector2(clampf(player.position.x + facing * -85, arena.world_bounds.position.x+32, arena.world_bounds.end.x-32), minf(player.position.y - 82, home.y))
				velocity = (desired - position).limit_length(data.speed)
				velocity.y += sin(animation_clock * 5) * 8
			elif kind == "archer":
				var away = -facing if absf(horizontal) < 130 else (facing if absf(horizontal) > 265 else 0)
				velocity.x = away * data.speed
			else:
				velocity.x = facing * data.speed if absf(horizontal) > 33 else 0
			var can_attack = distance < (155 if airborne else (390 if kind == "archer" else 65))
			if can_attack and attack_cooldown <= 0 and can_see_player() and arena.claim_attacker(self): change_state(State.WINDUP)
		State.WINDUP:
			velocity = Vector2.ZERO if airborne else Vector2(0, velocity.y)
			if state_clock >= data.windup:
				change_state(State.ACTIVE)
		State.ACTIVE:
			tick_attack(dt)
		State.RECOVER:
			velocity = velocity.move_toward(Vector2.ZERO, dt * 240) if airborne else Vector2(move_toward(velocity.x, 0, dt * 700), velocity.y)
			if state_clock >= data.recover: change_state(State.CHASE)
		State.STUN:
			velocity.x = move_toward(velocity.x, 0, dt * 700)
			if state_clock >= 0.16: change_state(State.CHASE)
		State.BROKEN:
			velocity.x = move_toward(velocity.x, 0, dt * 700)
			if state_clock >= 0.75:
				break_guard = 1.0
				change_state(State.CHASE)
	if not airborne:
		velocity.y = minf(580, velocity.y + dt * 1450)
		# Never walk over a ledge or try to walk through a wall.
		if absf(velocity.x) > 1 and is_on_floor() and state not in [State.STUN, State.BROKEN]:
			var ahead = position + Vector2(signf(velocity.x) * 17, -3)
			var floor_query = PhysicsRayQueryParameters2D.create(ahead, ahead + Vector2(0, 16), 3)
			if get_world_2d().direct_space_state.intersect_ray(floor_query).is_empty(): velocity.x = 0
	else:
		# Flight uses the engine's solid collision, including diving into the floor.
		velocity = velocity.limit_length(300)
	move_and_slide()
	position.x = clampf(position.x, arena.world_bounds.position.x+16, arena.world_bounds.end.x-16)
	if airborne and state == State.ACTIVE and (is_on_wall() or get_slide_collision_count() > 0): change_state(State.RECOVER)
	if state not in [State.STUN, State.BROKEN]: stance = maxf(0, stance - dt * 6)
	# Cosmetic only: gameplay facing/locked_facing flip instantly and still
	# drive hit direction; the drawn sprite eases toward it so enemies don't
	# snap-turn mid-patrol.
	visual_facing = move_toward(visual_facing, float(facing), dt * 10.0)

func tick_attack(_dt):
	if kind == "archer":
		if not attack_open:
			attack_open = true
			shot_count += 1
			arena.spawn_bolt(position + Vector2(locked_facing * 16, -22 if high_shot else -8), locked_facing, high_shot, data.damage, get_instance_id() * 10000 + attack_serial)
			feedback.sound("shot")
		if state_clock > 0.12: change_state(State.RECOVER)
		return
	if not attack_open:
		attack_open = true
		var size = Vector2(44, 30) if kind == "miner" else Vector2(24, 23)
		var offset = Vector2(locked_facing * 27, -14) if kind == "miner" else Vector2(0, -9)
		hitbox.begin({"damage": data.damage, "direction": Vector2(locked_facing, -0.2), "id": get_instance_id() * 10000 + attack_serial}, size, offset)
		if airborne:
			velocity = (locked_target - (position - Vector2(0, 10))).normalized() * 285
		else:
			feedback.burst(position + Vector2(locked_facing * 29, -4), Color("d1ae76"), 8)
			feedback.sound("heavy")
	if not airborne: velocity.x = locked_facing * 18
	hitbox.poll()
	if state_clock > (0.55 if airborne else 0.16): change_state(State.RECOVER)

func receive_hit(payload: Dictionary) -> bool:
	if state == State.DEAD: return false
	var amount = payload.get("damage", 0)
	hp -= amount
	flash = 0.09
	var broken = false
	if break_guard <= 0:
		stance += payload.get("stance", 0)
		if stance >= data.stance:
			stance = 0
			broken = true
			change_state(State.BROKEN)
			break_guard = 1.75
	if not broken and state != State.BROKEN: change_state(State.STUN)
	var direction: Vector2 = payload.get("direction", Vector2.RIGHT)
	velocity = Vector2(signf(direction.x) * (150 if payload.get("kind", "") in ["heavy", "light3", "pulse"] else 75), -45 if not airborne else -15)
	feedback.impact(position - Vector2(0, 15), amount, payload.get("kind", "") in ["heavy", "light3", "pulse"], broken)
	if broken:
		arena.breaks += 1
		feedback.float_text("破势", position - Vector2(8, 37), Color("89d4c4"))
	if kind == "dummy":
		if hp < 700: hp = 999
		return true
	if hp <= 0:
		hp = 0
		change_state(State.DEAD)
		hurtbox.set_deferred("monitorable", false)
		feedback.burst(position - Vector2(0, 12), Color("bfa16d"), 18)
		feedback.float_text("击破", position - Vector2(4, 32), Color("e3c38a"))
		arena.enemy_fell(self)
		queue_free()
	return true

func _draw():
	if state == State.DEAD: return
	var pale = Color("d6d6c7")
	var body = Color("a88b72") if kind == "miner" else Color("89a19e")
	if kind == "bat": body = Color("a69ac2")
	if flash > 0 and feedback.flash_level > 0: body = body.lerp(Color("fff0ce"), feedback.flash_level)
	if kind == "dummy":
		draw_rect(Rect2(-3, -33, 6, 33), Color("69523f"))
		draw_rect(Rect2(-12, -29, 24, 15), Color("a38b62"))
		draw_circle(Vector2(0, -22), 6, Color("615244"))
		draw_circle(Vector2(0, -22), 3, Color("d1b975"))
		draw_rect(Rect2(-14, -3, 28, 3), Color("827767"))
	elif arena.art_enabled and kind in ["miner", "bat"]:
		P0Art.draw_enemy(self)
	elif kind == "bat":
		var flap = sin(animation_clock * 16) * 5
		var wing_span = 9 if state == State.WINDUP else 23
		draw_colored_polygon(PackedVector2Array([Vector2(-5, -15), Vector2(-wing_span, -21 + flap), Vector2(-16, -8), Vector2(-4, -7)]), body)
		draw_colored_polygon(PackedVector2Array([Vector2(5, -15), Vector2(wing_span, -21 + flap), Vector2(16, -8), Vector2(4, -7)]), body)
		draw_rect(Rect2(-7, -19, 14, 16), body)
		draw_rect(Rect2(-6, -23, 4, 5), body)
		draw_rect(Rect2(2, -23, 4, 5), body)
		draw_rect(Rect2(-4, -14, 2, 3), Color("f4d7a3"))
		draw_rect(Rect2(2, -14, 2, 3), Color("f4d7a3"))
	else:
		var draw_face = locked_facing if state in [State.WINDUP, State.ACTIVE] else visual_facing
		draw_set_transform(Vector2.ZERO, 0, Vector2(draw_face, 1))
		var stride = sin(animation_clock * 12) * 2 if absf(velocity.x) > 10 else 0.0
		draw_rect(Rect2(-8, -28, 15, 10), body)
		draw_rect(Rect2(-10, -29, 19, 4), Color("525b5c"))
		draw_rect(Rect2(4, -26, 4, 4), Color("f7d090"))
		draw_rect(Rect2(-9, -18, 17, 13), body)
		draw_rect(Rect2(-8, -8, 17, 3), Color("4c5355"))
		draw_rect(Rect2(-7, -5, 5, 5 + stride), pale)
		draw_rect(Rect2(3, -5, 5, 5 - stride), pale)
		if kind == "miner":
			var angle = -1.35 if state == State.WINDUP else (0.7 if state == State.ACTIVE else -0.25)
			var grip = Vector2(7, -16)
			var tip = grip + Vector2.from_angle(angle) * 24
			draw_line(grip, tip, Color("ba9a70"), 3)
			draw_line(tip + Vector2(-5, -6), tip + Vector2(7, 4), pale, 4)
		else:
			draw_rect(Rect2(5, -23 if high_shot else -10, 20, 5), Color("b7b8a6"))
			draw_rect(Rect2(10, -26 if high_shot else -13, 3, 12), Color("806b52"))
			draw_rect(Rect2(-15, -16, 5, 8), Color("e0b76f"))
		draw_set_transform(Vector2.ZERO)
	if state == State.WINDUP:
		var progress = clampf(state_clock / data.windup, 0, 1)
		var warning = Color("efab79")
		draw_line(Vector2(-11, -38), Vector2(11, -38), Color("4c4240"), 3)
		draw_line(Vector2(-11, -38), Vector2(-11 + 22 * progress, -38), warning, 3)
		draw_line(Vector2(0, -49), Vector2(0, -43), warning, 2)
		draw_rect(Rect2(-1, -41, 2, 2), warning)
		if kind == "miner": draw_arc(Vector2(locked_facing * 17, -1), 30, PI, TAU, 12, Color(0.9, 0.6, 0.4, 0.5), 1)
		if kind == "archer":
			var y = -22.0 if high_shot else -8.0
			for i in range(6, 140, 12): draw_line(Vector2(locked_facing * i, y), Vector2(locked_facing * (i + 6), y), Color(0.91, 0.65, 0.43, 0.55), 1)
		if kind == "bat":
			draw_line(Vector2(0, -10), locked_target - position, Color(0.86, 0.55, 0.5, 0.35), 1)
	if state == State.BROKEN:
		for i in range(3): draw_circle(Vector2(cos(animation_clock * 5 + i * 2.1) * 10, -35), 2, Color("9cdbcb"))
	if kind != "dummy":
		draw_rect(Rect2(-13, -34, 26, 3), Color("292f35"))
		draw_rect(Rect2(-13, -34, 26.0 * hp / max_hp, 3), Color("c59680"))
	if stance > 0:
		draw_rect(Rect2(-13, 4, 26, 2), Color("27353a"))
		draw_rect(Rect2(-13, 4, 26.0 * stance / data.stance, 2), Color("91bcbb"))
	if arena.debug_shapes:
		draw_rect(Rect2(hurtbox.collider.position - hurtbox.collider.shape.size / 2, hurtbox.collider.shape.size), Color(1, 0.3, 0.3, 0.2))
