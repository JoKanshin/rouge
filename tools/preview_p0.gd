extends SceneTree
var game
func _initialize(): call_deferred("capture")
func snapshot(name: String):
	game.queue_redraw()
	game.player.queue_redraw()
	for e in game.living_enemies(): e.queue_redraw()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var img = root.get_texture().get_image()
	img.save_png("res://docs/art_reviews/" + name + ".png")
	return img
func capture():
	game = load("res://arena.tscn").instantiate()
	root.add_child(game)
	game.load_lesson(4)
	game.feedback.sound_enabled = false
	game.feedback.enabled = false
	await physics_frame
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.message_clock = 0
	for e in game.living_enemies(): e.set_physics_process(false)
	var one = await snapshot("p0_scene_1x")
	var two = one.duplicate()
	two.resize(1280,800,Image.INTERPOLATE_NEAREST)
	two.save_png("res://docs/art_reviews/p0_scene_2x.png")
	game.player.position = Vector2(312,324)
	for e in game.living_enemies():
		if e.kind == "miner":
			e.position = Vector2(366,324)
			e.change_state(e.State.WINDUP)
			e.state_clock = 0.3
		if e.kind == "bat":
			e.change_state(e.State.WINDUP)
			e.state_clock = 0.2
	await snapshot("p0_windup")
	game.player.action = "light1"
	game.player.attack_face = 1
	game.player.move = load("res://scripts/combat/sword_moves.gd").get_move("light1")
	for frame in range(18):
		game.player.attack_clock = frame / 60.0
		await snapshot("slash_%02d" % frame)
	game.player.action = ""
	game.player.crouched = true
	await snapshot("p0_crouch")
	game.player.crouched = false
	game.art_enabled = false
	await snapshot("graybox_comparison")
	# Review board is composed from exact runtime PNGs, not AI presentation art.
	var sheet = Image.create(512,160,false,Image.FORMAT_RGBA8)
	sheet.fill(Color("111922"))
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/p0_manifest.json"))
	for i in range(manifest.assets.size()):
		var img = load(manifest.assets[i].path).get_image()
		var cell = Vector2i(8+(i%7)*72,8+(i/7)*76)
		sheet.blend_rect(img,Rect2i(Vector2i.ZERO,img.get_size()),cell)
	sheet.resize(1536,480,Image.INTERPOLATE_NEAREST)
	sheet.save_png("res://docs/art_reviews/p0_asset_board_3x.png")
	print("P0 screenshots and 18-frame visual timing replay captured")
	quit()
