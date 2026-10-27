extends SceneTree
var game
func _initialize(): call_deferred("capture")
func shot(name: String):
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/world_reviews/"+name+".png")
func capture():
	DirAccess.make_dir_recursive_absolute("res://docs/world_reviews")
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.feedback.enabled = false
	game.feedback.sound_enabled = false
	await create_timer(0.3).timeout
	await shot("world_entry")
	var shaft = game.world.shafts[0]
	game.player.position = Vector2(shaft.x+64,shaft.top)
	game.player.velocity = Vector2.ZERO
	game.camera.position_smoothing_enabled = false
	await create_timer(0.1).timeout
	await shot("world_shaft")
	game.player.position = Vector2(shaft.x+64,shaft.top+160)
	game.player.velocity = Vector2.ZERO
	await create_timer(0.1).timeout
	await shot("world_depth")
	# Fully revealed map is a developer overview, not the initial player map.
	for i in range(game.world.route_nodes.size()): game.explored[i] = true
	game.map_open = true
	paused = true
	await shot("world_map_debug_revealed")
	game.map_open = false
	game.settings_open = true
	game.settings_panel.show()
	game.sync_controls()
	await shot("world_settings")
	paused = false
	quit()
