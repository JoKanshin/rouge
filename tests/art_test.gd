extends SceneTree
var failures = 0
var checks = 0
func check(ok: bool, label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func _initialize(): call_deferred("run")
func run():
	var manifest = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/p0_manifest.json"))
	check(manifest.assets.size() == 13, "13 runtime assets")
	for item in manifest.assets:
		var img = load(item.path).get_image()
		check(img.get_size() == Vector2i(item.canvas[0],item.canvas[1]), item.asset_id + " canvas")
		check(img.get_used_rect().has_area(), item.asset_id + " nonempty")
		var opaque = true
		var colors = {}
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var color = img.get_pixel(x,y)
				if color.a != 0 and color.a != 1: opaque = false
				if color.a > 0: colors[color.to_html(false)] = true
		check(opaque, item.asset_id + " hard alpha")
		check(colors.size() <= 18, item.asset_id + " palette limit")
		check(FileAccess.file_exists("res://art_source/candidates/" + item.source + ".png"), item.asset_id + " source retained")
	var game = load("res://arena.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	var p = game.player
	p.set_physics_process(false)
	var art = load("res://scripts/p0_art.gd")
	p.action = "light1"
	p.move = load("res://scripts/combat/sword_moves.gd").get_move("light1")
	for entry in [[0.0,1],[5.0/60,2],[9.0/60,3]]:
		p.attack_clock = entry[0]
		check(art.hero_frame(p) == entry[1], "Visual phase follows combat clock")
	var before = [p.solid.shape.size,p.hurtbox.collider.shape.size,p.collision_mask,p.position]
	var event = InputEventKey.new()
	event.physical_keycode = KEY_F6
	event.pressed = true
	game._unhandled_key_input(event)
	check(not game.art_enabled, "F6 shows graybox")
	check(before == [p.solid.shape.size,p.hurtbox.collider.shape.size,p.collision_mask,p.position], "Visual toggle does not change physics")
	game._unhandled_key_input(event)
	check(game.art_enabled, "F6 restores P0")
	print("ART CHECKS: ",checks-failures," / ",checks," passed")
	quit(1 if failures else 0)
