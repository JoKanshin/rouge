extends "res://scripts/arena_game.gd"
const Generator = preload("res://scripts/world/world_generator.gd")
const WorldHUD = preload("res://scripts/world/world_hud.gd")
const SAVE_PATH = "user://continuous_mine_v1.json"
var save_path = SAVE_PATH
var world: Dictionary
var explored: Dictionary = {}
var defeated: Dictionary = {}
var coins = 0
var bank = 0
var checkpoint = Vector2.ZERO
var map_open = false
var settings_open = false
var completed = false
var interaction = ""
var settings_panel: PanelContainer
var controls: Dictionary = {}
var active_enemies = 0
var background_colors = [Color("111e28"),Color("18232a"),Color("19252a"),Color("242029"),Color("262225")]

func _ready():
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("arena")
	font = SystemFont.new()
	font.font_names = PackedStringArray(["Microsoft YaHei","sans-serif"])
	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7
	add_child(camera)
	feedback = Feedback.new()
	feedback.z_index = 20
	feedback.camera = camera
	add_child(feedback)
	var canvas = CanvasLayer.new()
	add_child(canvas)
	hud = WorldHUD.new()
	hud.arena = self
	canvas.add_child(hud)
	make_settings(canvas)
	start_world(Generator.defaults())

func start_world(settings: Dictionary,snapshot: Dictionary = {}):
	get_tree().paused = false
	settings_open = false
	settings_panel.hide()
	map_open = false
	help_visible = false
	feedback.reset()
	world = Generator.generate(settings)
	var errors = Generator.validate(world)
	if not errors.is_empty():
		push_error("World rejected: "+str(errors))
		# Bounded deterministic fallback, never loop indefinitely.
		world = Generator.generate({"seed":27102026,"floor_variation_tiles":0})
	world_bounds = world.bounds
	if is_instance_valid(actors):
		remove_child(actors)
		actors.queue_free()
	if is_instance_valid(geometry):
		remove_child(geometry)
		geometry.queue_free()
	geometry = Node2D.new()
	add_child(geometry)
	actors = Node2D.new()
	actors.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(actors)
	active_attackers.clear()
	explored.clear()
	defeated.clear()
	coins = 0
	completed = false
	dead = false
	elapsed = 0
	breaks = 0
	checkpoint = world.spawn
	build_collision()
	player = Player.new()
	player.arena = self
	player.feedback = feedback
	player.position = world.spawn
	actors.add_child(player)
	player.testing = test_mode
	if not snapshot.is_empty():
		coins = snapshot.get("coins",0)
		bank = snapshot.get("bank",0)
		checkpoint = unpack_pos(snapshot.get("checkpoint",[world.spawn.x,world.spawn.y]))
		player.position = unpack_pos(snapshot.get("player",[checkpoint.x,checkpoint.y]))
		player.hp = clampi(int(snapshot.get("hp",100)),1,100)
		player.heat = clampi(int(snapshot.get("heat",0)),0,100)
		player.potions = clampi(int(snapshot.get("potions",1)),0,3)
		for key in snapshot.get("defeated",[]): defeated[key] = true
		for key in snapshot.get("explored",[]): explored[int(key)] = true
		for object in world.objects:
			object.used = object.id in snapshot.get("used",[])
	for entry in world.enemies:
		if defeated.has(entry.id): continue
		var enemy = spawn_enemy(entry.kind,entry.pos)
		enemy.set_meta("world_id",entry.id)
		enemy.set_physics_process(false)
		# Distant actors are dormant and culled; their state stays in this world.
		enemy.visible = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(world_bounds.size.x)
	camera.limit_bottom = int(world_bounds.size.y)
	camera.position = player.position-Vector2(0,48)
	camera.reset_smoothing()
	update_exploration()
	notify("旧矿道已生成 · E 点亮篝火 / 开箱 · Tab 地图 · F7 参数")

func build_collision():
	# Merge equal horizontal rock spans across consecutive rows. Geometry is
	# generated once; visibility culling affects drawing only, never collisions.
	var spans = {}
	for y in range(world.height):
		var next = {}
		var x = 0
		while x < world.width:
			if not Generator.solid(world,x,y):
				x += 1
				continue
			var begin = x
			while x < world.width and Generator.solid(world,x,y): x += 1
			var key = "%d:%d"%[begin,x-begin]
			if spans.has(key):
				var r: Rect2 = spans[key]
				r.size.y += 16
				next[key] = r
				spans.erase(key)
			else: next[key] = Rect2(begin*16,y*16,(x-begin)*16,16)
		for r in spans.values(): create_platform(r,false)
		spans = next
	for r in spans.values(): create_platform(r,false)
	for r in world.platforms: create_platform(r,true)

func enemy_fell(enemy):
	release_attacker(enemy)
	defeated[enemy.get_meta("world_id",str(enemy.get_instance_id()))] = true
	coins += 8
	feedback.float_text("+8 金币",enemy.position-Vector2(8,30),Color("dfbf85"))

func player_fell():
	if dead: return
	dead = true
	var lost = int(ceil(coins*0.4))
	coins -= lost
	notify("倒下损失 %d 金币 · E 从最近篝火重来"%lost)
	# Save the settled state immediately. Reload cannot undo the death loss.
	save_run(true)

func respawn():
	dead = false
	player.dead = false
	player.hp = 100
	player.potions = 1
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	player.invincible = 2
	player.stun = 0
	player.end_attack()
	player.modulate.a = 1
	feedback.reset()
	camera.reset_smoothing()
	notify("在篝火旁醒来 · 已开启的宝箱和击败的敌人保留")

func current_layer() -> int:
	return clampi(int((player.position.y-32)/320),0,world.config.depth_layers-1)

func current_segment() -> int:
	return clampi(int((player.position.x-32)/128),0,world.config.width_segments-1)

func update_exploration():
	var layer = current_layer()
	var segment = current_segment()
	for offset in range(-1,2):
		if segment+offset >= 0 and segment+offset < world.config.width_segments:
			explored[layer*world.config.width_segments+segment+offset] = true

func _physics_process(dt):
	if get_tree().paused or world.is_empty(): return
	ticks += dt
	message_clock = maxf(0,message_clock-dt)
	if not dead: elapsed += dt
	camera.position = player.position + Vector2(player.facing*45,-42)
	update_exploration()
	interaction = ""
	for object in world.objects:
		if object.pos.distance_to(player.position) < 46:
			interaction = object_prompt(object)
	active_enemies = 0
	for enemy in living_enemies():
		var active = enemy.position.distance_to(player.position) < world.config.activation_radius
		if not active:
			if enemy.state in [enemy.State.WINDUP,enemy.State.ACTIVE]: enemy.change_state(enemy.State.PATROL)
			enemy.velocity = Vector2.ZERO
		else: active_enemies += 1
		enemy.set_physics_process(active and not dead)
		enemy.visible = active
	queue_redraw()

func object_prompt(object: Dictionary) -> String:
	match object.kind:
		"camp": return "E 休整补药并保存  ·  T 将金币存入仓库"
		"chest": return "空宝箱" if object.used else "E 开启物资箱"
		"exit": return "E 启动深井升降机，带回本次收益"
		"entry": return "旧矿道入口 · 朝右探索，寻找下降纵井"
	return ""

func interact(deposit: bool = false):
	if dead:
		respawn()
		return
	for object in world.objects:
		if object.pos.distance_to(player.position) > 46: continue
		if object.kind == "camp":
			checkpoint = object.pos
			player.hp = 100
			player.potions = 1
			object.used = true
			if deposit:
				bank += coins
				coins = 0
			save_run()
			feedback.sound("heal")
			notify("篝火已点亮 · 生命与药瓶补满 · 已保存" if not deposit else "金币已存入仓库 · 已保存")
		elif object.kind == "chest" and not object.used and not deposit:
			object.used = true
			coins += object.coins
			feedback.sound("pickup")
			feedback.burst(object.pos-Vector2(0,12),Color("dfbf85"),12)
			notify("回收物资 +%d 金币"%object.coins)
			save_run()
		elif object.kind == "exit" and not completed and not deposit:
			completed = true
			bank += coins
			coins = 0
			save_run()
			notify("深井升降机已启动 · 收益存入仓库！F7 可生成下一片矿区")
		return

func save_run(after_death: bool = false):
	if test_mode: return
	var used = []
	for object in world.objects:
		if object.used: used.append(object.id)
	var pos = checkpoint if after_death else player.position
	var snapshot = {"save_version":1,"generator_version":Generator.VERSION,"config":world.config,"tile_snapshot":Marshalls.raw_to_base64(world.tiles),"coins":coins,"bank":bank,"checkpoint":[checkpoint.x,checkpoint.y],"player":[pos.x,pos.y],"hp":100 if after_death else player.hp,"potions":1 if after_death else player.potions,"heat":0 if after_death else player.heat,"used":used,"defeated":defeated.keys(),"explored":explored.keys(),"completed":completed}
	var file = FileAccess.open(save_path+".tmp",FileAccess.WRITE)
	if file == null:
		notify("保存失败：无法写入用户目录")
		return
	file.store_string(JSON.stringify(snapshot))
	file.close()
	var renamed = DirAccess.rename_absolute(save_path+".tmp",save_path)
	if renamed != OK: notify("保存失败：无法替换存档文件")

func load_run():
	if not FileAccess.file_exists(save_path):
		notify("暂无存档 · E 篝火或 F5 保存")
		return
	var snapshot = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if not snapshot is Dictionary or snapshot.get("generator_version",-1) != Generator.VERSION:
		notify("存档版本不兼容，已保留原文件")
		return
	var candidate = Generator.generate(snapshot.config)
	if Marshalls.raw_to_base64(candidate.tiles) != snapshot.get("tile_snapshot",""):
		notify("存档地形与当前生成器不符，已保留原文件")
		return
	start_world(snapshot.config,snapshot)
	completed = snapshot.get("completed",false)
	notify("已恢复同一矿区 · 宝箱、敌人和探索记录已恢复")

func unpack_pos(value: Array) -> Vector2: return Vector2(value[0],value[1])

func _unhandled_key_input(event):
	if not event.pressed or event.echo: return
	var key = event.physical_keycode
	if key == KEY_ESCAPE:
		var was_overlay = settings_open or map_open or help_visible
		if settings_open:
			settings_open = false
			settings_panel.hide()
		elif map_open: map_open = false
		elif help_visible: help_visible = false
		else: get_tree().paused = not get_tree().paused
		if was_overlay: get_tree().paused = false
		return
	if key == KEY_F7:
		settings_open = not settings_open
		settings_panel.visible = settings_open
		get_tree().paused = settings_open
		if settings_open: sync_controls()
		return
	if settings_open: return
	if key == KEY_TAB:
		map_open = not map_open
		get_tree().paused = map_open
	elif key == KEY_F1:
		help_visible = not help_visible
		get_tree().paused = help_visible
	elif key == KEY_F2: debug_shapes = not debug_shapes
	elif key == KEY_F3: feedback.shake_level = 1.0-feedback.shake_level
	elif key == KEY_F4: feedback.flash_level = 1.0-feedback.flash_level
	elif key == KEY_F6: art_enabled = not art_enabled
	elif key == KEY_M: feedback.sound_enabled = not feedback.sound_enabled
	elif key == KEY_F9:
		get_tree().paused = false
		feedback.reset()
		get_tree().change_scene_to_file("res://arena.tscn")
	elif not get_tree().paused:
		if key in [KEY_E,KEY_T]: interact(key == KEY_T)
		elif key == KEY_F5:
			save_run(dead)
			notify("已保存 · F8 恢复")
		elif key == KEY_F8: call_deferred("load_run")

func make_settings(canvas: CanvasLayer):
	settings_panel = PanelContainer.new()
	settings_panel.position = Vector2(100,50)
	settings_panel.size = Vector2(440,300)
	var style = StyleBoxFlat.new()
	style.bg_color = Color("18262f")
	style.border_color = Color("806b52")
	style.set_border_width_all(1)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	settings_panel.add_theme_stylebox_override("panel",style)
	canvas.add_child(settings_panel)
	var stack = VBoxContainer.new()
	settings_panel.add_child(stack)
	var title = Label.new()
	title.text = "连续矿区生成参数"
	stack.add_child(title)
	for entry in [["seed","种子",1,999999999],["width_segments","横向长度（每段128像素）",12,64],["depth_layers","深度层数（每层320像素）",2,7],["shafts_per_layer","相邻层纵井数",2,5],["treasure_count","宝箱数量",1,24],["enemy_probability","每段敌人概率",0,0.7]]:
		var row = HBoxContainer.new()
		stack.add_child(row)
		var label = Label.new()
		label.text = entry[1]
		label.custom_minimum_size.x = 270
		row.add_child(label)
		var spin = SpinBox.new()
		spin.min_value = entry[2]
		spin.max_value = entry[3]
		spin.step = 0.01 if entry[0] == "enemy_probability" else 1
		spin.custom_minimum_size.x = 140
		row.add_child(spin)
		controls[entry[0]] = spin
	var buttons = HBoxContainer.new()
	stack.add_child(buttons)
	var same = Button.new()
	same.text = "按参数重新生成"
	same.pressed.connect(func(): apply_settings(false))
	buttons.add_child(same)
	var fresh = Button.new()
	fresh.text = "换种子生成"
	fresh.pressed.connect(func(): apply_settings(true))
	buttons.add_child(fresh)
	var note = Label.new()
	note.text = "重新生成会结束当前探索；先按 F5 可保存。Esc 返回。"
	note.add_theme_font_size_override("font_size",12)
	stack.add_child(note)
	settings_panel.hide()

func sync_controls():
	for key in controls: controls[key].value = world.config[key]

func apply_settings(new_seed: bool):
	var settings = world.config.duplicate()
	for key in controls: settings[key] = controls[key].value
	if new_seed: settings.seed = (Time.get_unix_time_from_system() as int)%999999999
	call_deferred("start_world",settings)

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(player): save_run(dead)

func _draw():
	if world.is_empty(): return
	var view = Rect2(camera.get_screen_center_position()-Vector2(352,232),Vector2(704,464))
	var layer = clampi(int(view.get_center().y/320),0,background_colors.size()-1)
	draw_rect(view,background_colors[layer])
	# Continuous world-space landmarks, not screen-sized room backgrounds.
	for x in range(int(view.position.x/128)*128,int(view.end.x)+128,128):
		draw_rect(Rect2(x,view.position.y,12,view.size.y),Color("152129"))
		for y in range(int(view.position.y/96)*96,int(view.end.y),96):
			draw_line(Vector2(x,y),Vector2(x+110,y),Color("253139"),1)
	var min_x = maxi(0,int(view.position.x/16))
	var max_x = mini(world.width-1,int(view.end.x/16))
	var min_y = maxi(0,int(view.position.y/16))
	var max_y = mini(world.height-1,int(view.end.y/16))
	for y in range(min_y,max_y+1):
		for x in range(min_x,max_x+1):
			if not Generator.solid(world,x,y): continue
			var pos = Vector2(x*16,y*16)
			var top = not Generator.solid(world,x,y-1)
			draw_texture(QArt.paired(QArt.TERRAIN_TOP_D,QArt.TERRAIN_TOP_N) if top else QArt.paired(QArt.TERRAIN_FILL_D,QArt.TERRAIN_FILL_N),pos)
			if not Generator.solid(world,x-1,y): draw_line(pos,pos+Vector2(0,16),Color("596b6c"),1)
			if not Generator.solid(world,x+1,y): draw_line(pos+Vector2(15,0),pos+Vector2(15,16),Color("596b6c"),1)
	for rect in world.platforms:
		if not view.intersects(rect.grow(16)): continue
		QArt.draw_terrain(self,rect,true)
	for object in world.objects:
		if not view.has_point(object.pos): continue
		draw_object(object)

func draw_object(object: Dictionary):
	var p: Vector2 = object.pos
	match object.kind:
		"camp":
			draw_circle(p-Vector2(0,14),26,Color(0.8,0.58,0.25,0.07))
			draw_line(p+Vector2(-13,-2),p+Vector2(12,-8),Color("806b52"),4)
			draw_line(p+Vector2(-12,-8),p+Vector2(13,-2),Color("806b52"),4)
			draw_colored_polygon(PackedVector2Array([p+Vector2(-7,-7),p+Vector2(0,-27-sin(ticks*5)*3),p+Vector2(8,-7)]),Color("dfbf85"))
			draw_string(font,p+Vector2(-24,-38),"篝火",0,-1,11,Color("dfbf85"))
		"chest":
			draw_rect(Rect2(p+Vector2(-11,-15),Vector2(22,15)),Color("806b52"))
			draw_rect(Rect2(p+Vector2(-11,-15),Vector2(22,4)),Color("c49c63"))
			draw_rect(Rect2(p+Vector2(-2,-11),Vector2(4,6)),Color("dfbf85"))
			if object.used: draw_rect(Rect2(p+Vector2(-9,-12),Vector2(18,5)),Color("17232d"))
		"entry", "exit":
			draw_rect(Rect2(p+Vector2(-24,-66),Vector2(48,66)),Color("3c4a4c"),false,3)
			for offset in [-17,-6,5,16]: draw_line(p+Vector2(offset,-64),p+Vector2(offset,-1),Color("806b52"),2)
			draw_string(font,p+Vector2(-34,-77),"矿道入口" if object.kind == "entry" else "深井升降机",0,-1,11,Color("dfbf85"))
