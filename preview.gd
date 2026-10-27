extends SceneTree

func _initialize():
	call_deferred("capture")

func capture():
	var game = load("res://arena.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-combat-lab.png")
	game.load_lesson(4)
	for i in range(45): await physics_frame
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://preview-combat-mixed.png")
	quit()
