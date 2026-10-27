extends Node2D

const FLOOR_Y = 326.0
const GOLD = Color("eac375")
const INK = Color("111b2b")
const PALE = Color("dddaca")
var font: SystemFont
var rng = RandomNumberGenerator.new()
var player = Vector2(82, 300)
var velocity = Vector2.ZERO
var facing = 1
var grounded = false
var crouched = false
var hp = 100
var max_hp = 100
var coins = 35
var damage = 24
var permanent_damage = 0
var speed = 132.0
var attack_time = 0.0
var attack_cooldown = 0.0
var dash_time = 0.0
var dash_cooldown = 0.0
var invincible = 0.0
var town = true
var room = 0
var run_number = 0
var platforms: Array[Rect2] = []
var enemies: Array[Dictionary] = []
var chests: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var drops: Array[Dictionary] = []
var time = 0.0
var message = "欢迎来到灰烬镇。向右走，按 E 进入地牢。"
var message_time = 6.0
var choosing = false
var choices: Array[int] = []
var paused = false
var kills = 0
var run_gold = 0
var jump_buffer = 0.0
var coyote = 0.0
var attack_hit: Array[int] = []

func _ready():
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei", "Noto Sans CJK SC", "sans-serif"])
	rng.randomize()
	setup_town()

func down(keys: Array) -> bool:
	for key in keys:
		if Input.is_physical_key_pressed(key): return true
	return false

func _unhandled_key_input(event):
	if not event is InputEventKey or not event.pressed or event.echo: return
	var key = event.physical_keycode
	if key == KEY_ESCAPE:
		paused = not paused
		return
	if paused: return
	if choosing:
		if key in [KEY_1, KEY_2, KEY_3]: apply_boon(choices[key - KEY_1])
		return
	if key in [KEY_SPACE, KEY_W, KEY_UP]: jump_buffer = 0.14
	if key in [KEY_J, KEY_Z] and attack_cooldown <= 0:
		attack_time = 0.21
		attack_cooldown = 0.34
		attack_hit.clear()
		for enemy in enemies: enemy.hit = false
	if key in [KEY_K, KEY_SHIFT] and dash_cooldown <= 0:
		dash_time = 0.17
		dash_cooldown = 0.8
		invincible = maxf(invincible, 0.23)
	if key == KEY_E: interact()

func tell(value: String):
	message = value
	message_time = 4.5

func setup_town():
	town = true
	room = 0
	player = Vector2(85, FLOOR_Y - 26)
	velocity = Vector2.ZERO
	platforms = [Rect2(0, FLOOR_Y, 640, 74)]
	enemies.clear()
	chests.clear()
	drops.clear()
	choosing = false

func enter_room():
	town = false
	room += 1
	player = Vector2(45, FLOOR_Y - 26)
	velocity = Vector2.ZERO
	platforms = [Rect2(0, FLOOR_Y, 640, 74)]
	var height_a = rng.randi_range(245, 267)
	platforms.append(Rect2(140, height_a, 105, 12))
	platforms.append(Rect2(302, 204, 94, 12))
	platforms.append(Rect2(445, 258, 106, 12))
	enemies.clear()
	drops.clear()
	chests = [{"pos": Vector2(345, 187), "opened": false}, {"pos": Vector2(492, 241), "opened": false}]
	for i in range(mini(3 + room, 8)):
		var flying = i % 3 == 2
		enemies.append({"pos": Vector2(230 + i * 43, 290 if not flying else 172), "hp": 42 + room * 9, "max": 42 + room * 9, "flying": flying, "flash": 0.0, "phase": rng.randf() * 6.28, "attack": rng.randf(), "wind": 0.0, "dir": -1.0})
	tell("地下 %d 层 · 清除敌人后，右侧封印门开启。" % room)

func interact():
	if town:
		if absf(player.x - 188) < 48:
			if hp >= max_hp: tell("生命已满，留点金币再出发。")
			elif coins >= 15:
				coins -= 15
				hp = max_hp
				tell("热汤下肚，生命恢复。")
			else: tell("补充生命需要 15 金币。")
		elif absf(player.x - 344) < 48:
			var price = 30 + permanent_damage * 5
			if coins >= price:
				coins -= price
				permanent_damage += 6
				damage += 6
				tell("铁匠强化：永久攻击 +6。")
			else: tell("强化需要 %d 金币。" % price)
		elif player.x > 520:
			run_number += 1
			run_gold = 0
			kills = 0
			damage = 24 + permanent_damage
			speed = 132.0
			max_hp = 100
			hp = mini(hp, max_hp)
			enter_room()
	else:
		for chest in chests:
			if not chest.opened and player.distance_to(chest.pos) < 43:
				chest.opened = true
				add_gold(rng.randi_range(12, 23), chest.pos)
				choices = [0, 1, 2, 3, 4]
				choices.shuffle()
				choices.resize(3)
				choosing = true
				return
		if player.x > 560:
			if not enemies.is_empty(): tell("封印尚未解除：还有 %d 个敌人。" % enemies.size())
			else: enter_room()
		elif player.x < 77:
			setup_town()
			tell("带回 %d 金币 · 击败 %d 个敌人。可以补给后再次出发。" % [run_gold, kills])

func apply_boon(index: int):
	match index:
		0: damage += 9
		1:
			max_hp += 20
			hp = mini(max_hp, hp + 35)
		2: speed += 22.0
		3: hp = mini(max_hp, hp + 55)
		4: add_gold(30, player)
	choosing = false
	tell("获得强化：" + boon_name(index))

func boon_name(index: int) -> String:
	return ["磨砺刀锋", "余烬之心", "轻盈步伐", "生命泉水", "贪婪馈赠"][index]

func burst(pos: Vector2, color: Color, count: int):
	for i in range(count): particles.append({"pos": pos, "vel": Vector2(rng.randf_range(-80, 80), rng.randf_range(-110, 20)), "life": rng.randf_range(0.2, 0.6), "color": color})

func add_gold(amount: int, pos: Vector2):
	coins += amount
	if not town: run_gold += amount
	burst(pos, GOLD, 14)

func hurt(amount: int, source: Vector2):
	if invincible > 0: return
	hp -= amount
	invincible = 0.95
	velocity = Vector2(signf(player.x - source.x) * 170, -130)
	burst(player + Vector2(8, 12), Color("f07570"), 12)
	if hp <= 0:
		var lost = int(ceil(coins * 0.4))
		coins -= lost
		max_hp = 100
		hp = 100
		damage = 24 + permanent_damage
		speed = 132
		setup_town()
		tell("倒在了地牢里。遗失 %d 金币，其余金币与铁匠强化保留。" % lost)

func _physics_process(dt):
	if paused or choosing:
		queue_redraw()
		return
	time += dt
	message_time -= dt
	attack_time = maxf(0, attack_time - dt)
	attack_cooldown = maxf(0, attack_cooldown - dt)
	dash_time = maxf(0, dash_time - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)
	invincible = maxf(0, invincible - dt)
	jump_buffer -= dt
	coyote = 0.1 if grounded else coyote - dt
	var axis = float(down([KEY_D, KEY_RIGHT])) - float(down([KEY_A, KEY_LEFT]))
	crouched = down([KEY_S, KEY_DOWN]) and grounded
	if axis != 0: facing = int(axis)
	if jump_buffer > 0 and coyote > 0:
		velocity.y = -390
		grounded = false
		coyote = 0
		jump_buffer = 0
		burst(player + Vector2(8, 26), Color("74818b"), 5)
	velocity.x = move_toward(velocity.x, axis * speed * (0.4 if crouched else 1.0), 1000 * dt)
	velocity.y += 820 * dt
	if dash_time > 0:
		velocity = Vector2(facing * 370, 0)
		burst(player + Vector2(8, 15), Color("4b9099"), 1)
	player.x = clampf(player.x + velocity.x * dt, 8, 614)
	var old_bottom = player.y + 26
	player.y += velocity.y * dt
	grounded = false
	for platform in platforms:
		if velocity.y >= 0 and old_bottom <= platform.position.y + 1 and player.y + 26 >= platform.position.y and player.x + 15 > platform.position.x and player.x < platform.end.x:
			player.y = platform.position.y - 26
			velocity.y = 0
			grounded = true
	var body = Rect2(player + Vector2(0, 12 if crouched else 0), Vector2(16, 14 if crouched else 26))
	var blade = Rect2(player + Vector2(10 if facing > 0 else -39, 9 if crouched else -4), Vector2(45, 30))
	for i in range(enemies.size() - 1, -1, -1):
		var enemy = enemies[i]
		enemy.flash = maxf(0, enemy.flash - dt)
		var direction = signf(player.x - enemy.pos.x)
		if enemy.flying:
			enemy.pos += (player + Vector2(5, 4) - enemy.pos).normalized() * (29 + room * 2) * dt
			enemy.pos.y += sin(time * 5 + enemy.phase) * 15 * dt
		else:
			enemy.attack -= dt
			if enemy.wind > 0:
				enemy.wind -= dt
				if enemy.wind <= 0: enemy.attack = -0.26
			elif enemy.attack < 0 and enemy.attack > -0.29:
				enemy.pos.x += enemy.dir * 205 * dt
			else:
				if enemy.attack <= -0.29: enemy.attack = 1.6
				enemy.pos.x += direction * (27 + room * 3) * dt
				if absf(player.x - enemy.pos.x) < 95 and enemy.attack < 0.4:
					enemy.wind = 0.5
					enemy.dir = direction
			enemy.pos.x = clampf(enemy.pos.x, 95, 580)
			enemy.pos.y = FLOOR_Y - 21
		var enemy_box = Rect2(enemy.pos, Vector2(20, 21))
		if attack_time > 0 and not enemy.get("hit", false) and blade.intersects(enemy_box):
			enemy.hit = true
			enemy.hp -= damage
			enemy.flash = 0.14
			enemy.pos.x += facing * 19
			burst(enemy.pos + Vector2(10, 10), GOLD, 6)
		if enemy.hp <= 0:
			kills += 1
			drops.append({"pos": enemy.pos + Vector2(8, 8), "value": rng.randi_range(4, 9)})
			enemies.remove_at(i)
			# Indices below the removed index remain stable for this descending pass.
		elif body.intersects(enemy_box):
			hurt(10 + room * 2, enemy.pos)
			if town: break
	for i in range(drops.size() - 1, -1, -1):
		var drop = drops[i]
		if drop.pos.distance_to(player + Vector2(8, 13)) < 75: drop.pos = drop.pos.move_toward(player + Vector2(8, 13), dt * 240)
		if drop.pos.distance_to(player + Vector2(8, 13)) < 18:
			add_gold(drop.value, drop.pos)
			drops.remove_at(i)
	for i in range(particles.size() - 1, -1, -1):
		particles[i].life -= dt
		particles[i].pos += particles[i].vel * dt
		particles[i].vel.y += dt * 230
		if particles[i].life <= 0: particles.remove_at(i)
	queue_redraw()

func box(x: float, y: float, w: float, h: float, color: Color):
	draw_rect(Rect2(floorf(x), floorf(y), w, h), color)

func label_at(value: String, x: float, y: float, size: int = 12, color: Color = PALE):
	draw_string(font, Vector2(x, y), value, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw():
	box(0, 0, 640, 400, Color("111927") if town else Color("10131e"))
	if town: draw_town()
	else: draw_dungeon()
	for platform in platforms:
		draw_rect(platform, Color("29343c"))
		box(platform.position.x, platform.position.y, platform.size.x, 3, Color("7d8c75") if town else Color("60717a"))
		for x in range(int(platform.position.x), int(platform.end.x), 24):
			box(x + 2, platform.position.y + 6, 20, 3, Color("39444b"))
	for chest in chests:
		var p: Vector2 = chest.pos
		box(p.x - 2, p.y + 3, 26, 14, Color("734b38"))
		box(p.x - 2, p.y + (0 if not chest.opened else -7), 26, 5, GOLD)
		box(p.x + 9, p.y + 5, 4, 7, GOLD)
		if not chest.opened and player.distance_to(p) < 43: label_at("E 开箱", p.x - 8, p.y - 12, 10, GOLD)
	for drop in drops: box(drop.pos.x, drop.pos.y + sin(time * 6) * 2, 5, 7, GOLD)
	for enemy in enemies: draw_enemy(enemy)
	if invincible <= 0 or int(time * 18) % 2 == 0: draw_player()
	for particle in particles: box(particle.pos.x, particle.pos.y, 3, 3, particle.color)
	draw_hud()
	if message_time > 0:
		box(42, 66, 556, 25, Color(0.04, 0.07, 0.11, 0.92))
		label_at(message, 54, 83, 11, GOLD)
	if choosing: draw_choices()
	if paused:
		box(0, 0, 640, 400, Color(0.02, 0.03, 0.05, 0.85))
		label_at("已暂停", 275, 185, 25, GOLD)
		label_at("ESC 继续探险", 276, 216, 13)

func draw_town():
	box(0, 96, 640, 135, Color("172535"))
	for i in range(11):
		var x = i * 67 - 20
		box(x, 174 - (i % 3) * 19, 49, 150, Color("22323d"))
		box(x + 12, 160 - (i % 3) * 19, 26, 14, Color("22323d"))
	box(482, 101, 25, 25, Color("d3c8a0"))
	for i in range(24): box((i * 89 + 14) % 640, 100 + (i * 47) % 65, 1, 1, Color("7f9298"))
	draw_house(126, "旅人食堂", Color("72664e"))
	draw_house(285, "灰烬铁铺", Color("626975"))
	label_at("热汤 / 15 G", 151, 279, 10, GOLD)
	label_at("攻击 +6 / %d G" % (30 + permanent_damage * 5), 300, 279, 10, GOLD)
	for x in [93, 441]:
		box(x, 252, 4, 74, Color("4e5453"))
		box(x - 4, 245, 12, 14, GOLD)
		box(x - 1, 249, 6, 6, Color("fff2bd"))
	draw_portal(554, true)
	label_at("地牢入口", 542, 242, 12, GOLD)
	if absf(player.x - 188) < 48: label_at("E 补充生命", 151, 231, 11, GOLD)
	elif absf(player.x - 344) < 48: label_at("E 锻造强化", 304, 231, 11, GOLD)
	elif player.x > 520: label_at("E 开始探险", 538, 224, 11, GOLD)

func draw_house(x: int, title: String, color: Color):
	box(x, 219, 120, 107, color)
	box(x - 8, 211, 136, 11, Color("333a45"))
	box(x + 5, 199, 110, 12, Color("333a45"))
	box(x + 14, 184, 89, 15, Color("333a45"))
	box(x + 45, 284, 28, 42, INK)
	box(x + 12, 287, 20, 21, GOLD)
	box(x + 87, 287, 20, 21, GOLD)
	box(x + 14, 240, 93, 25, INK)
	label_at(title, x + 24, 257, 13)

func draw_dungeon():
	for row_index in range(6):
		for column in range(14):
			box(column * 49 + (row_index % 2) * 23, 95 + row_index * 39, 46, 36, Color("19212b") if (column + row_index) % 3 else Color("1d2731"))
	for x in [98, 267, 421, 564]:
		box(x, 99, 14, 227, Color("29323c"))
		box(x - 5, 100, 24, 10, Color("35404b"))
		box(x + 3, 164, 7, 17, Color("6b5142"))
		box(x + 2, 155 + sin(time * 13 + x) * 2, 8, 13, GOLD)
		box(x + 4, 153, 4, 8, Color("ffe1a3"))
	draw_portal(22, true)
	label_at("E 回城", 17, 256, 10, GOLD)
	draw_portal(581, enemies.is_empty())
	label_at("E 深入" if enemies.is_empty() else "封印", 577, 256, 10, GOLD)
	label_at("跳上平台 · 寻找遗物", 274, 139, 10, Color("637680"))

func draw_portal(x: int, opened: bool):
	box(x - 4, 270, 35, 56, Color("3e4a54"))
	box(x, 265, 27, 61, Color("3e4a54"))
	box(x + 3, 275, 21, 51, Color("284c55") if opened else Color("573b49"))
	for i in range(4): box(x + 5 + i * 5, 279, 2, 47, Color("6caaa7") if opened else Color("966170"))

func draw_player():
	var p = player.floor()
	var crouch_offset = 11 if crouched else 0
	var stride = sin(time * 17) * 3 if grounded and absf(velocity.x) > 10 else 0.0
	box(p.x - 3 - facing * 3, p.y + 7 + crouch_offset, 10, 16 - crouch_offset, Color("bb6559"))
	box(p.x + 3, p.y + crouch_offset, 11, 10, Color("c9d5cc"))
	box(p.x + (9 if facing > 0 else 1), p.y + 4 + crouch_offset, 7, 3, INK)
	box(p.x + 2, p.y + 10 + crouch_offset, 12, 11 - crouch_offset / 2, Color("6d9ba2"))
	box(p.x + 1, p.y + 21, 6, 5 + stride, Color("ced2ba"))
	box(p.x + 10, p.y + 21, 6, 5 - stride, Color("ced2ba"))
	box(p.x + (15 if facing > 0 else -2), p.y + 13 + crouch_offset / 2, 3, 15 - crouch_offset / 2, Color("e4debf"))
	if attack_time > 0:
		var center = p + Vector2(9, 15 + crouch_offset / 2)
		var start = -1.25 if facing > 0 else PI - 1.25
		draw_arc(center, 35, start, start + 2.5, 12, Color("f9e9bd"), 5)
		draw_arc(center, 28, start + 0.3, start + 2.2, 10, Color("c4a777"), 2)

func draw_enemy(enemy: Dictionary):
	var p: Vector2 = enemy.pos.floor()
	var color = Color("c97982") if not enemy.flying else Color("9b87bb")
	if enemy.flash > 0: color = Color("fff2d1")
	if enemy.wind > 0: color = Color("f0b46e")
	if enemy.flying:
		var wing = sin(time * 15 + enemy.phase) * 5
		box(p.x - 8, p.y + 4 + wing, 10, 5, color)
		box(p.x + 18, p.y + 4 + wing, 10, 5, color)
		box(p.x, p.y + 3, 20, 13, color)
	else:
		box(p.x + 3, p.y, 14, 8, color)
		box(p.x, p.y + 8, 20, 11, color)
		box(p.x + 2, p.y + 18, 5, 3, color)
		box(p.x + 14, p.y + 18, 5, 3, color)
	box(p.x + 4, p.y + 6, 4, 3, INK)
	box(p.x + 13, p.y + 6, 4, 3, INK)
	if enemy.hp < enemy.max:
		box(p.x, p.y - 7, 20, 3, INK)
		box(p.x, p.y - 7, 20.0 * enemy.hp / enemy.max, 3, Color("c7797c"))
	if enemy.wind > 0: label_at("!", p.x + 7, p.y - 9, 15, GOLD)

func draw_hud():
	box(0, 0, 640, 58, Color("0c131e"))
	box(0, 57, 640, 1, Color("38434a"))
	label_at("灰烬之下", 19, 24, 18, GOLD)
	label_at("ASH BELOW / 可玩原型", 20, 44, 9, Color("829197"))
	label_at("生命", 188, 21, 10)
	box(220, 12, 126, 11, Color("302732"))
	box(220, 12, 126.0 * hp / max_hp, 11, Color("bb7272"))
	label_at("%d / %d" % [hp, max_hp], 254, 21, 9)
	label_at("攻击 %d  ·  冲刺 %s" % [damage, "就绪" if dash_cooldown <= 0 else "冷却"], 188, 43, 10, Color("94b7b6"))
	label_at("%03d G" % coins, 393, 26, 20, GOLD)
	label_at("可带回城镇消费", 393, 44, 9, Color("829197"))
	label_at("灰烬镇" if town else "地下 %02d 层" % room, 529, 24, 14)
	label_at("安全区域" if town else "剩余敌人 %d" % enemies.size(), 529, 43, 10, Color("829197"))
	box(0, 351, 640, 49, Color("0c131e"))
	label_at("A D / ← → 移动    空格 跳跃    S / ↓ 下蹲    J 劈砍    K / Shift 冲刺", 20, 372, 11)
	label_at("E 交互    ESC 暂停", 20, 391, 10, GOLD)
	label_at("随机房间 · 宝箱三选一 · 死亡损失 40% 金币", 323, 391, 10, Color("829197"))

func draw_choices():
	box(0, 0, 640, 400, Color(0.02, 0.03, 0.05, 0.9))
	label_at("遗物的回响", 240, 112, 25, GOLD)
	label_at("选择一项强化，继续这一次探险", 220, 141, 12)
	var descriptions = ["本次探险攻击 +9", "生命上限 +20，恢复 35", "本次探险移动速度 +22", "立即恢复 55 点生命", "立即获得 30 金币"]
	for i in range(3):
		var x = 38 + i * 193
		box(x, 174, 178, 123, Color("1c2a38"))
		box(x, 174, 178, 3, GOLD)
		label_at("0%d" % (i + 1), x + 16, 205, 20, Color("87b3b5"))
		label_at(boon_name(choices[i]), x + 16, 237, 18, GOLD)
		label_at(descriptions[choices[i]], x + 16, 265, 10)
	label_at("按 1 / 2 / 3 选择", 263, 330, 12)

