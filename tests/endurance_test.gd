extends SceneTree
var game
var max_particles = 0
var max_bolts = 0
var seen_states: Dictionary = {}
var failure = false

func _initialize(): call_deferred("run_test")

func run_test():
	game = load("res://arena.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.load_lesson(4)
	game.feedback.enabled = false
	game.feedback.sound_enabled = false
	game.player.testing = false
	for i in range(10800):
		var p = game.player
		p.invincible = 10
		var direction = "right" if i % 600 < 300 else "left"
		Input.action_release("left" if direction == "right" else "right")
		Input.action_press(direction)
		if i % 28 == 0: p.request_attack("light")
		if i % 149 == 0: p.requests["heavy"] = 0.12
		if i % 193 == 0: p.requests["dash"] = 0.12
		if i % 277 == 0: p.jump_buffer = 0.12
		if i % 119 == 0 and p.heat >= 60: p.requests["pulse"] = 0.12
		for enemy in game.living_enemies(): seen_states[enemy.kind + ":" + str(enemy.state)] = true
		max_particles = maxi(max_particles, game.feedback.particles.size())
		max_bolts = maxi(max_bolts, get_nodes_in_group("bolts").size())
		if not is_finite(p.position.x) or not is_finite(p.position.y) or p.position.x < 0 or p.position.x > 640 or game.active_attackers.size() > 2:
			failure = true
			break
		await physics_frame
	Input.action_release("left")
	Input.action_release("right")
	print("SIMULATED SECONDS: ", game.elapsed)
	print("WAVES: ", game.wave, " KILLS: ", game.player.kills, " HITS: ", game.player.hits)
	print("PEAK PARTICLES: ", max_particles, " PEAK BOLTS: ", max_bolts)
	print("ENEMY STATES: ", seen_states.keys())
	if game.elapsed < 179 or max_particles > 200 or max_bolts > 8 or game.player.kills < 3: failure = true
	# Real-time recovery must work with overlapping hit-stops, even while paused.
	game.feedback.enabled = true
	game.feedback.freeze(25)
	game.feedback.freeze(50)
	await real_wait(80)
	if Engine.time_scale != 1.0: failure = true
	get_tree_pause_test()
	await real_wait(80)
	if Engine.time_scale != 1.0: failure = true
	var event = InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	await process_frame
	if paused: failure = true
	game.load_lesson(0)
	game.feedback.sound_enabled = false
	game.player.testing = false
	game.feedback.freeze(50)
	event = InputEventKey.new()
	event.physical_keycode = KEY_J
	event.pressed = true
	Input.parse_input_event(event)
	await real_wait(80)
	for i in range(4): await physics_frame
	if game.player.attacks != 1: failure = true
	print("INPUT DURING HIT-STOP: ", game.player.attacks == 1)
	print("ENDURANCE ", "FAILED" if failure else "PASSED")
	paused = false
	game.queue_free()
	await process_frame
	quit(1 if failure else 0)

func real_wait(milliseconds: int):
	var deadline = Time.get_ticks_msec() + milliseconds
	while Time.get_ticks_msec() < deadline: await process_frame

func get_tree_pause_test():
	var event = InputEventKey.new()
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	game.feedback.freeze(35)
