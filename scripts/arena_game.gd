extends Node2D
const P0Art = preload("res://scripts/p0_art.gd")
const QArt = preload("res://scripts/q_art.gd")
const Player = preload("res://scripts/player.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Bolt = preload("res://scripts/bolt.gd")
const Feedback = preload("res://scripts/feedback.gd")
const HUD = preload("res://scripts/arena_hud.gd")
const LESSONS = ["练剑木桩", "镐斧矿工", "提灯弩手", "裂翼蝠", "混合遭遇"]
const HINTS = ["J 连击 · ↑ J 上挑 · 空中 ↓ J 下劈反弹 · L 重击积累破势", "举镐时离开正面，等下砸结束反击；冲刺可穿过攻击", "高位弹下蹲，低位弹跳过；亮灯期间可以接近打断", "收翼后锁定俯冲方向；横移避开，再用上挑或下劈反击", "利用平台分开敌人；优先处理远程，同时最多两名敌人出招"]
var player: CharacterBody2D
var feedback: Node2D
var actors: Node2D
var geometry: Node2D
var camera: Camera2D
var hud: Node2D
var lesson = 0
var wave = 1
var breaks = 0
var elapsed = 0.0
var dead = false
var respawn_clock = -1.0
var active_attackers: Dictionary = {}
var message = ""
var message_clock = 0.0
var debug_shapes = false
var help_visible = false
var platforms: Array[Rect2] = []
var ticks = 0.0
var test_mode = false
var art_enabled = true
var world_bounds = Rect2(0,0,640,400)
var font: Font

func _enter_tree():
	var actions = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE], "light": [KEY_J, KEY_Z], "heavy": [KEY_L], "dash": [KEY_K, KEY_SHIFT], "pulse": [KEY_Q], "potion": [KEY_R]}
	for action in actions:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in actions[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event): InputMap.action_add_event(action, event)

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arena")
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "sans-serif"])
	setup_ambient()
	geometry = Node2D.new()
	add_child(geometry)
	platforms = [Rect2(0, 324, 640, 76), Rect2(152, 278, 111, 9), Rect2(303, 234, 104, 9), Rect2(447, 278, 102, 9)]
	for i in range(platforms.size()): create_platform(platforms[i], i > 0)
	create_platform(Rect2(-16, 0, 16, 400), false)
	create_platform(Rect2(640, 0, 16, 400), false)
	for chain_x in [120, 286, 439, 576]: spawn_lantern_light(Vector2(chain_x, 200))
	camera = Camera2D.new()
	camera.position = Vector2(320, 200)
	add_child(camera)
	feedback = Feedback.new()
	feedback.z_index = 20
	feedback.camera = camera
	add_child(feedback)
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = HUD.new()
	hud.arena = self
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	canvas.add_child(hud)
	load_lesson(0)

var lantern_lights: Array = []
var _light_cookie: Texture2D

func setup_ambient():
	# Cool indigo base tint so the warm lantern PointLight2D has contrast to
	# push against, matching the project's existing "cool stone / warm
	# lantern" art direction, now driven by a real CanvasModulate instead of
	# only a baked background color.
	var modulate_node = CanvasModulate.new()
	modulate_node.color = Color(0.46, 0.5, 0.66)
	add_child(modulate_node)

func build_light_cookie() -> Texture2D:
	if _light_cookie: return _light_cookie
	# A few concentric bands instead of a smooth radial gradient, so the
	# lantern glow reads as pixel-art falloff rather than a soft 3D-game glow.
	var img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var steps = [1.0, 1.0, 0.78, 0.78, 0.5, 0.5, 0.26, 0.26, 0.0]
	for y in range(64):
		for x in range(64):
			var d = Vector2(x - 31.5, y - 31.5).length() / 31.5
			var idx = clampi(int(d * (steps.size() - 1)), 0, steps.size() - 1)
			var a = steps[idx]
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_light_cookie = ImageTexture.create_from_image(img)
	return _light_cookie

func spawn_lantern_light(pos: Vector2):
	var light = PointLight2D.new()
	light.position = pos
	light.color = Color("ffb361")
	light.energy = 1.6
	light.texture_scale = 4.4
	light.texture = build_light_cookie()
	light.blend_mode = Light2D.BLEND_MODE_ADD
	add_child(light)
	lantern_lights.append({"node": light, "seed": randf() * 100.0, "base": 1.1})

func create_platform(rect: Rect2, one_way: bool):
	var body = StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 2 if one_way else 1
	body.collision_mask = 0
	body.set_meta("one_way", one_way)
	var shape = CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	shape.shape.size = rect.size
	shape.one_way_collision = one_way
	shape.one_way_collision_margin = 3
	body.add_child(shape)
	geometry.add_child(body)
	return body

func load_lesson(index: int):
	get_tree().paused = false
	help_visible = false
	feedback.reset()
	if is_instance_valid(actors):
		remove_child(actors)
		actors.queue_free()
	actors = Node2D.new()
	actors.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actors)
	active_attackers.clear()
	lesson = clampi(index, 0, 4)
	wave = 1
	breaks = 0
	elapsed = 0
	dead = false
	respawn_clock = -1
	player = Player.new()
	player.arena = self
	player.feedback = feedback
	player.position = Vector2(92, 324)
	actors.add_child(player)
	player.testing = test_mode
	spawn_wave()
	notify("试验场 %02d / %s · F1 查看动作说明" % [lesson + 1, LESSONS[lesson]])

func spawn_enemy(kind: String, pos: Vector2):
	var enemy = Enemy.new()
	enemy.kind = kind
	enemy.arena = self
	enemy.player = player
	enemy.feedback = feedback
	enemy.position = pos
	actors.add_child(enemy)
	return enemy

func spawn_wave():
	if lesson == 0: spawn_enemy("dummy", Vector2(361, 324))
	elif lesson == 1: spawn_enemy("miner", Vector2(408, 324))
	elif lesson == 2: spawn_enemy("archer", Vector2(513, 324))
	elif lesson == 3: spawn_enemy("bat", Vector2(391, 217))
	else:
		spawn_enemy("miner", Vector2(350, 324))
		spawn_enemy("archer", Vector2(550, 324))
		spawn_enemy("bat", Vector2(450, 199))
		if wave % 3 == 0: spawn_enemy("miner", Vector2(440, 278))

func claim_attacker(enemy: Node) -> bool:
	for id in active_attackers.keys():
		if not is_instance_valid(active_attackers[id]): active_attackers.erase(id)
	var id = enemy.get_instance_id()
	if active_attackers.has(id): return true
	if active_attackers.size() >= 2: return false
	active_attackers[id] = enemy
	return true

func release_attacker(enemy: Node):
	active_attackers.erase(enemy.get_instance_id())

func spawn_bolt(pos: Vector2, direction: int, high: bool, damage: int, serial: int):
	var bolt = Bolt.new()
	bolt.arena = self
	bolt.position = pos
	bolt.direction = direction
	bolt.high = high
	bolt.damage = damage
	bolt.serial = serial
	actors.add_child(bolt)
	return bolt

func enemy_fell(enemy):
	release_attacker(enemy)
	# Wait until the queued dead actor is gone before counting remaining enemies.
	call_deferred("check_wave")

func living_enemies() -> Array:
	var result = []
	if not is_instance_valid(actors): return result
	for child in actors.get_children():
		if child.is_in_group("enemies") and child.hp > 0 and not child.is_queued_for_deletion(): result.append(child)
	return result

func check_wave():
	if lesson > 0 and living_enemies().is_empty() and not dead and respawn_clock < 0:
		respawn_clock = 2.2
		player.hp = mini(100, player.hp + 20)
		player.potions = 1
		for child in get_tree().get_nodes_in_group("bolts"): child.queue_free()
		feedback.sound("pickup")
		notify("遭遇完成 · 恢复 20 生命与 1 瓶药，下一波即将开始。")

func player_fell():
	dead = true
	respawn_clock = -1
	notify("练习结束 · 按 E 重试，或按 1–5 切换项目。")

func notify(value: String):
	message = value
	message_clock = 4

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.physical_keycode
	if key in [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5]:
		call_deferred("load_lesson", key - KEY_1)
		return
	if key == KEY_ESCAPE:
		if help_visible: help_visible = false
		get_tree().paused = not get_tree().paused
	if key == KEY_F1:
		help_visible = not help_visible
		get_tree().paused = help_visible
	if key == KEY_E and (dead or lesson == 0): call_deferred("load_lesson", lesson)
	if key == KEY_F2:
		debug_shapes = not debug_shapes
		notify("判定框 %s" % ("开启" if debug_shapes else "关闭"))
	if key == KEY_F3:
		feedback.shake_level = 0.0 if feedback.shake_level > 0 else 1.0
		notify("画面震动 %s" % ("开启" if feedback.shake_level > 0 else "关闭"))
	if key == KEY_F4:
		feedback.flash_level = 0.0 if feedback.flash_level > 0 else 1.0
		notify("受击闪光 %s" % ("开启" if feedback.flash_level > 0 else "关闭"))
	if key == KEY_F6:
		art_enabled = not art_enabled
		notify("敌人像素素材 %s · F6 对比灰盒（玩家与地形已固定为新版像素）" % ("开启" if art_enabled else "关闭"))
	if key == KEY_M:
		feedback.sound_enabled = not feedback.sound_enabled
		notify("音效 %s" % ("开启" if feedback.sound_enabled else "关闭"))
	if key == KEY_F9:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://legacy.tscn")
	if key == KEY_F10:
		get_tree().paused = false
		feedback.reset()
		get_tree().change_scene_to_file("res://main.tscn")

func _physics_process(dt):
	if get_tree().paused: return
	ticks += dt
	message_clock = maxf(0, message_clock - dt)
	if not dead: elapsed += dt
	if respawn_clock > 0:
		respawn_clock -= dt
		if respawn_clock <= 0:
			respawn_clock = -1
			wave += 1
			spawn_wave()
	update_lantern_flicker(dt)
	queue_redraw()

func update_lantern_flicker(dt):
	# A smoothed-noise flicker reads as a live flame; pure randf() per frame
	# is too jittery. Each lantern gets its own time offset so they don't
	# flicker in lockstep.
	for entry in lantern_lights:
		var light: PointLight2D = entry.node
		if not is_instance_valid(light): continue
		var t = ticks * 7.0 + entry.seed
		var wobble = sin(t) * 0.5 + sin(t * 2.7 + 1.3) * 0.3 + sin(t * 5.1) * 0.2
		light.energy = entry.base + wobble * 0.14

func _draw():
	draw_rect(Rect2(0, 0, 640, 400), Color("111922"))
	# Distant arches and masonry stay subdued behind the readable playfield.
	for i in range(6):
		var x = i * 122 - 25
		draw_rect(Rect2(x, 93, 82, 231), Color("17232d"))
		draw_rect(Rect2(x + 13, 107, 56, 217), Color("101b25"))
		draw_rect(Rect2(x - 3, 90, 88, 8), Color("25313a"))
	for row in range(5):
		for col in range(12):
			var x = col * 59 + (row % 2) * 29
			draw_line(Vector2(x, 119 + row * 43), Vector2(x + 52, 119 + row * 43), Color("202c34"), 1)
	for chain_x in [120, 286, 439, 576]:
		for y in range(92, 143, 5): draw_rect(Rect2(chain_x, y, 2, 3), Color("4b5354"))
		draw_texture(QArt.lantern_frame(ticks),Vector2(chain_x-16,133))
	for rect in platforms:
		QArt.draw_terrain(self,rect,rect.size.y < 16)
	# Wood braces and floor chips use a deterministic pattern, never gameplay RNG.
	for x in [170, 244, 321, 389, 462, 531]:
		var top = 286 if x < 280 or x > 420 else 242
		draw_line(Vector2(x, top), Vector2(x + 11, top + 15), Color("3e4949"), 3)
	for i in range(38): draw_rect(Rect2((i * 83 + 7) % 640, 334 + (i * 11) % 16, 3, 1), Color("3c4849"))
	if lesson == 0:
		draw_string(font, Vector2(25, 252), "巡灯人的练剑室", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("a1aaa2"))
		draw_string(font, Vector2(25, 272), "先试剑，再下矿。", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("6f8587"))
	if message_clock > 0 and not dead:
		draw_rect(Rect2(18, 170, 604, 22), Color(0.055, 0.085, 0.11, 0.94))
		draw_string(font, Vector2(28, 185), message, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("d9bc83"))
