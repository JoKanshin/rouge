extends CharacterBody2D
const QArt = preload("res://scripts/q_art.gd")

const Hurtbox = preload("res://scripts/combat/hurtbox.gd")
const Hitbox = preload("res://scripts/combat/hitbox.gd")
const Moves = preload("res://scripts/combat/sword_moves.gd")
const RUN_SPEED = 180.0
const RISE_GRAVITY = 1422.2222
const JUMP_SPEED = -426.6667
var arena: Node
var feedback: Node
var solid: CollisionShape2D
var hurtbox: Area2D
var hitbox: Area2D
var hp = 100
var heat = 0
var potions = 1
var facing = 1
var visual_facing = 1.0
var crouched = false
var dead = false
var action = ""
var move: Dictionary = {}
var attack_clock = 0.0
var attack_serial = 0
var attack_open = false
var attack_connected = false
var attack_face = 1
var combo = 0
var combo_grace = 0.0
var jump_buffer = 0.0
var coyote = 0.0
var requests: Dictionary = {}
var dash_clock = 0.0
var dash_cooldown = 0.0
var dash_dodged: Dictionary = {}
var invincible = 0.0
var stun = 0.0
var potion_clock = -1.0
var drop_clock = 0.0
var dropped_platform: PhysicsBody2D
var animation_clock = 0.0
var landing_squash = 0.0
var attacks = 0
var hits = 0
var kills = 0
var dodges = 0
var damage_taken = 0
var bounces = 0
var last_action = "准备就绪"
var testing = false

func _ready():
	add_to_group("player")
	collision_layer = 4
	collision_mask = 3
	floor_snap_length = 4
	solid = CollisionShape2D.new()
	solid.shape = RectangleShape2D.new()
	solid.shape.size = Vector2(13, 28)
	solid.position.y = -14
	add_child(solid)
	hurtbox = Hurtbox.new()
	add_child(hurtbox)
	hurtbox.setup(self, 16, Vector2(13, 27), Vector2(0, -14))
	hitbox = Hitbox.new()
	add_child(hitbox)
	hitbox.target_mask = 8
	hitbox.landed.connect(_on_hit)

func _unhandled_input(event):
	if dead or testing or get_tree().paused: return
	if event.is_action_pressed("jump"):
		if Input.is_action_pressed("down") and is_on_floor() and try_drop(): return
		jump_buffer = 0.12
	if event.is_action_released("jump") and velocity.y < 0: velocity.y *= 0.45
	if event.is_action_pressed("light"): request_attack("light")
	if event.is_action_pressed("heavy"): requests["heavy"] = 0.12
	if event.is_action_pressed("pulse"): requests["pulse"] = 0.12
	if event.is_action_pressed("dash"): requests["dash"] = 0.12
	if event.is_action_pressed("potion"): start_potion()

func request_attack(kind: String):
	requests[kind] = 0.10

func try_drop() -> bool:
	for i in range(get_slide_collision_count()):
		var body = get_slide_collision(i).get_collider()
		if body is PhysicsBody2D and body.get_meta("one_way", false):
			dropped_platform = body
			add_collision_exception_with(body)
			drop_clock = 0.25
			position.y += 2
			velocity.y = 65
			coyote = 0
			jump_buffer = 0
			last_action = "穿下平台"
			return true
	return false

func can_dash() -> bool:
	return not dead and stun <= 0 and dash_clock <= 0 and dash_cooldown <= 0 and potion_clock < 0 and (action == "" or attack_clock * 60 >= move.cancel)

func start_dash() -> bool:
	if not can_dash(): return false
	end_attack()
	dash_clock = 10.0 / 60.0
	dash_cooldown = 0.60
	dash_dodged.clear()
	last_action = "冲刺 · 中段无敌"
	feedback.sound("dash")
	return true

func dash_invulnerable() -> bool:
	var elapsed = 10.0 / 60 - dash_clock
	return dash_clock > 0 and elapsed >= 2.0 / 60 and elapsed < 8.0 / 60

func start_attack(kind: String) -> bool:
	if dead or stun > 0 or dash_clock > 0 or potion_clock >= 0 or action != "": return false
	var chosen = kind
	if kind == "light":
		if Input.is_action_pressed("up"): chosen = "up"
		elif Input.is_action_pressed("down") and not is_on_floor(): chosen = "down"
		else:
			combo = combo % 3 + 1 if combo_grace > 0 else 1
			chosen = "light%d" % combo
	if chosen == "pulse":
		if heat < 60:
			arena.notify("热量不足：近战命中积攒热量，60 点释放灯焰。")
			return false
		heat -= 60
	move = Moves.get_move(chosen)
	action = chosen
	attack_clock = 0
	attack_face = facing
	attack_open = false
	attack_connected = false
	attack_serial += 1
	attacks += 1
	if not chosen.begins_with("light"): combo = 0
	var names = {"light1": "轻击 Ⅰ", "light2": "轻击 Ⅱ", "light3": "终结斩 Ⅲ", "up": "上挑", "down": "下劈", "heavy": "重击 · 破势", "pulse": "灯焰脉冲"}
	last_action = names[chosen]
	return true

func end_attack():
	if action.begins_with("light"): combo_grace = 0.32
	action = ""
	attack_open = false
	hitbox.end()

func start_potion() -> bool:
	if dead or potions <= 0 or hp >= 100 or action != "" or dash_clock > 0 or stun > 0 or potion_clock >= 0: return false
	potions -= 1
	potion_clock = 0
	last_action = "饮药中 · 受击会打断"
	return true

func _physics_process(dt):
	animation_clock += dt
	queue_redraw()
	hitbox.queue_redraw()
	if dead: return
	invincible = maxf(0, invincible - dt)
	stun = maxf(0, stun - dt)
	landing_squash = maxf(0, landing_squash - dt * 2.2)
	dash_cooldown = maxf(0, dash_cooldown - dt)
	combo_grace = maxf(0, combo_grace - dt)
	jump_buffer = maxf(0, jump_buffer - dt)
	if drop_clock > 0:
		drop_clock -= dt
		if drop_clock <= 0 and is_instance_valid(dropped_platform):
			remove_collision_exception_with(dropped_platform)
			dropped_platform = null
	coyote = 0.10 if is_on_floor() else maxf(0, coyote - dt)
	var axis = 0.0 if testing else Input.get_axis("left", "right")
	var wants_crouch = false if testing else Input.is_action_pressed("down")
	crouched = wants_crouch and is_on_floor() and action == "" and dash_clock <= 0
	if not crouched and solid.shape.size.y < 28 and test_move(global_transform.translated(Vector2(0, -12)), Vector2(0, -1)):
		crouched = true
	solid.shape.size = Vector2(13, 15 if crouched else 28)
	solid.position.y = -7.5 if crouched else -14.0
	hurtbox.resize(Vector2(13, 14 if crouched else 27), Vector2(0, -7.5 if crouched else -14.0))
	if axis != 0 and action == "" and dash_clock <= 0 and stun <= 0: facing = int(signf(axis))
	if requests.has("dash") and start_dash(): requests.erase("dash")
	if stun <= 0 and dash_clock <= 0:
		if requests.has("heavy") and start_attack("heavy"): requests.erase("heavy")
		elif requests.has("pulse") and start_attack("pulse"): requests.erase("pulse")
		elif requests.has("light") and start_attack("light"): requests.erase("light")
	for key in requests.keys():
		requests[key] -= dt
		if requests[key] <= 0: requests.erase(key)
	if jump_buffer > 0 and coyote > 0 and stun <= 0 and dash_clock <= 0 and potion_clock < 0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0
		coyote = 0
		feedback.burst(position, Color("758e96"), 4)
	if potion_clock >= 0:
		potion_clock += dt
		if potion_clock >= 0.65:
			hp = mini(100, hp + 35)
			potion_clock = -1
			feedback.sound("heal")
			feedback.burst(position - Vector2(0, 17), Color("9dceac"), 15)
			last_action = "生命 +35"
	if dash_clock > 0:
		dash_clock = maxf(0, dash_clock - dt)
		velocity = Vector2(facing * 395, 0)
		feedback.traces.append({"p": position, "life": 0.18})
	else:
		var speed_scale = 0.38 if crouched else (0.48 if action == "heavy" else 1.0)
		if potion_clock >= 0: speed_scale = 0.15
		if stun <= 0: velocity.x = move_toward(velocity.x, axis * RUN_SPEED * speed_scale, dt * (2250 if is_on_floor() else 1600))
		else: velocity.x = move_toward(velocity.x, 0, dt * 550)
		var gravity = RISE_GRAVITY * (1.6 if velocity.y > 0 else 1.0)
		velocity.y = minf(velocity.y + gravity * dt, 580)
	var was_grounded = is_on_floor()
	move_and_slide()
	if not was_grounded and is_on_floor():
		landing_squash = 0.45
		feedback.burst(position, Color("75828c"), 5)
	if action != "": tick_attack(dt)
	if position.y > arena.world_bounds.end.y + 32: receive_hit({"damage": 100, "direction": Vector2.UP, "id": -2, "unavoidable": true})
	# Cosmetic turn-around smoothing: gameplay facing flips instantly (attack
	# direction, collisions, input all read `facing`), but the drawn sprite
	# eases toward it so a quick reversal doesn't look like a jump-cut.
	visual_facing = move_toward(visual_facing, float(facing), dt * 14.0)

func tick_attack(dt):
	attack_clock += dt
	var frame = attack_clock * 60
	if frame >= move.startup and frame < move.startup + move.active:
		if not attack_open:
			attack_open = true
			var offset: Vector2 = move.offset
			offset.x *= attack_face
			if crouched: offset.y += 10
			hitbox.begin({"damage": move.damage, "stance": move.stance, "direction": Vector2(attack_face, -0.18), "source": self, "kind": action, "id": attack_serial}, move.size, offset)
			feedback.sound("heavy" if action == "pulse" else "swing")
			if action == "down": velocity.y = maxf(velocity.y, 180)
		hitbox.poll()
	else: hitbox.end()
	if frame >= move.total: end_attack()

func _on_hit(target, payload):
	hits += 1
	if not attack_connected:
		if payload.kind != "pulse": heat = mini(100, heat + 8)
		attack_connected = true
	if payload.kind == "down":
		velocity.y = -335
		bounces += 1
		last_action = "下劈反弹"
		end_attack()
	if is_instance_valid(target) and target.get("hp") != null and target.hp <= 0:
		kills += 1
		heat = mini(100, heat + 12)

func receive_hit(payload: Dictionary) -> bool:
	if dead: return false
	if not payload.get("unavoidable", false):
		if dash_invulnerable():
			var source_id = payload.get("id", 0)
			if not dash_dodged.has(source_id):
				dash_dodged[source_id] = true
				dodges += 1
				feedback.float_text("闪避", position - Vector2(10, 36), Color("91d1ce"))
			return false
		if invincible > 0: return false
	hp = maxi(0, hp - payload.damage)
	damage_taken += payload.damage
	invincible = 0.65
	stun = 0.12
	potion_clock = -1
	dash_clock = 0
	end_attack()
	combo_grace = 0
	combo = 0
	requests.clear()
	var direction: Vector2 = payload.get("direction", Vector2.RIGHT)
	velocity = Vector2(signf(direction.x) * 155, -100)
	feedback.burst(position - Vector2(0, 15), Color("dc8c7d"), 13)
	feedback.trauma = minf(1, feedback.trauma + 0.4)
	feedback.freeze(50)
	feedback.sound("hurt")
	last_action = "受到攻击"
	if hp <= 0:
		dead = true
		arena.player_fell()
	return true

func _draw():
	var blink = invincible > 0 and int(animation_clock * 26) % 2 == 0
	modulate.a = 0.35 if blink else 1.0
	QArt.draw_hero(self)
	if action != "": draw_sword()
	if arena.debug_shapes:
		draw_rect(Rect2(solid.position - solid.shape.size / 2, solid.shape.size), Color(0.2, 0.9, 0.7, 0.3))

func sword_hand() -> Vector2:
	# Mirrors the hand position hero.py computes for the mid-swing attack
	# pose, so the sword hilt in this vector overlay matches where the
	# sprite's drawn hand is instead of floating at a generic offset.
	var arm_front = -10.0 + 0.55 * 16.0
	if action == "up": arm_front = -14.0
	elif action == "down": arm_front = 4.0
	var shoulder = Vector2(3.0, -18.0)
	var hand = Vector2(shoulder.x + 2 + arm_front * 0.5, shoulder.y + 7 + arm_front * 0.6)
	return Vector2(hand.x * attack_face, hand.y)

func draw_sword():
	var frame = attack_clock * 60
	var active_progress = clampf((frame - move.startup) / move.active, 0, 1)
	var center = sword_hand()
	if action == "pulse":
		if frame >= move.startup:
			var radius = 18 + clampf((frame - move.startup) / 18, 0, 1) * 62
			draw_arc(Vector2(0, -18), radius, 0, TAU, 36, Color(0.54, 0.87, 0.80, 1 - clampf((frame - move.startup) / 24, 0, 1)), 3)
		else: draw_circle(Vector2(0, -18), 8, Color("9ed0bd"))
		return
	var direction = 0.0 if attack_face > 0 else PI
	if action == "up": direction = -PI / 2
	if action == "down": direction = PI / 2
	var angle = direction - 1.3 + active_progress * 2.6
	if action == "light2": angle = direction + 1.3 - active_progress * 2.6
	var length = 40.0 if action != "heavy" else 48.0
	var tip = center + Vector2.from_angle(angle) * length
	var hilt = center - Vector2.from_angle(angle) * 6
	if frame < move.startup:
		tip = center + Vector2.from_angle(direction - 1.4) * 27
		draw_line(center, tip, Color("c8cbaf"), 2)
		if action == "heavy": draw_circle(center, 3 + sin(animation_clock * 36), Color("d7b170"))
	elif frame < move.startup + move.active + 3:
		draw_arc(center, length - 3, direction - 1.22, direction + 1.22, 12, Color("e6cb8a"), 4 if action == "heavy" else 2)
		draw_arc(center, length + 1, direction - 1.1, direction + 1.1, 10, Color("fff0c9"), 2)
		draw_line(hilt, tip, Color("fff7db"), 3)
		draw_line(center - Vector2.from_angle(angle + PI / 2) * 5, center + Vector2.from_angle(angle + PI / 2) * 5, Color("b8905f"), 2)
