extends SceneTree
var game
var failures = 0
var checks = 0

func _initialize(): call_deferred("run_checks")

func check(value: bool, description: String):
	checks += 1
	if not value:
		failures += 1
		push_error("FAIL: " + description)
	else: print("PASS: " + description)

func frames(count: int):
	for i in range(count): await physics_frame

func fresh(index: int = 0):
	Input.action_release("down")
	Input.action_release("jump")
	Input.action_release("left")
	Input.action_release("right")
	game.load_lesson(index)
	game.feedback.enabled = false
	game.feedback.sound_enabled = false
	for enemy in game.living_enemies(): enemy.set_physics_process(false)
	await frames(5)

func run_checks():
	game = load("res://arena.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	await fresh()
	check(game.player.is_on_floor(), "Native CharacterBody2D stands on solid floor")
	var p = game.player
	var target = game.living_enemies()[0]
	p.position = Vector2(330, 324)
	await frames(2)
	p.start_attack("light")
	await frames(22)
	check(target.hp == 981 and p.hits == 1, "An active sword segment damages each target exactly once")
	check(p.heat == 8, "First melee contact generates heat once")
	await frames(30)
	check(p.attacks == 1 and target.hp == 981, "No automatic attacks without a new press")
	await fresh()
	p = game.player
	p.start_attack("light")
	await frames(16)
	p.request_attack("light")
	await frames(5)
	check(p.action == "light2", "Buffered second input links into second slash")
	await frames(13)
	p.request_attack("light")
	await frames(6)
	check(p.action == "light3", "Third deliberate input links the finisher")
	await fresh()
	p = game.player
	p.start_attack("heavy")
	check(not p.start_dash(), "Heavy startup cannot be cancelled into dash")
	await frames(39)
	check(p.start_dash(), "Late heavy recovery can be dash-cancelled")
	check(p.action == "" and not p.hitbox.active, "Cancel closes old attack hitbox")
	await fresh()
	p = game.player
	target = game.living_enemies()[0]
	p.position.x = 330
	p.start_attack("heavy")
	await frames(48)
	p.start_attack("heavy")
	await frames(24)
	check(game.breaks == 1 and target.state == target.State.BROKEN, "Heavy hits accumulate stance and cause a break")
	target.receive_hit({"damage": 1, "stance": 999, "kind": "heavy", "direction": Vector2.RIGHT})
	check(game.breaks == 1, "Break protection prevents immediate repeat stun-lock")
	await fresh()
	p = game.player
	p.heat = 59
	check(not p.start_attack("pulse"), "Pulse rejects insufficient heat")
	p.heat = 60
	check(p.start_attack("pulse") and p.heat == 0, "Pulse consumes sixty heat")
	await frames(35)
	check(p.heat == 0, "Pulse does not refund its own heat")
	await fresh()
	p = game.player
	p.start_dash()
	check(not p.dash_invulnerable(), "Dash startup is vulnerable")
	p.dash_clock = 0.09
	check(p.dash_invulnerable(), "Middle dash frames grant invulnerability")
	check(not p.receive_hit({"damage": 12, "id": 900, "direction": Vector2.RIGHT}) and p.hp == 100, "Middle dash evades damage")
	check(p.dodges == 1, "An avoided attack is counted once")
	p.receive_hit({"damage": 12, "id": 900, "direction": Vector2.RIGHT})
	check(p.dodges == 1, "Repeated contact from the same attack does not duplicate dodge rewards")
	p.dash_clock = 0.01
	check(not p.dash_invulnerable(), "Dash ending is vulnerable")
	check(p.receive_hit({"damage": 12, "id": 901, "direction": Vector2.RIGHT}) and p.hp == 88, "Damage is applied outside the invulnerability window")
	check(not p.receive_hit({"damage": 12, "id": 902, "direction": Vector2.RIGHT}), "Post-hit protection prevents repeated damage")
	await fresh()
	p = game.player
	p.testing = false
	Input.action_press("jump")
	p.jump_buffer = 0.12
	var min_y = p.position.y
	for i in range(42):
		await frames(1)
		min_y = minf(min_y, p.position.y)
	var full_height = 324 - min_y
	check(full_height >= 58 and full_height <= 66, "Full jump reaches calibrated four-tile height: %.1f px" % full_height)
	await fresh()
	p = game.player
	p.testing = false
	p.jump_buffer = 0.12
	await frames(5)
	var release = InputEventAction.new()
	release.action = "jump"
	release.pressed = false
	p._unhandled_input(release)
	min_y = p.position.y
	for i in range(35):
		await frames(1)
		min_y = minf(min_y, p.position.y)
	check(324 - min_y < full_height * 0.7, "Releasing jump produces a shorter hop")
	await fresh()
	p = game.player
	p.testing = false
	p.position = Vector2(128, 324)
	await frames(3)
	Input.action_press("right")
	p.jump_buffer = 0.12
	await frames(29)
	Input.action_release("right")
	await frames(3)
	check(p.is_on_floor() and absf(p.position.y - 278) < 1, "First elevated platform is reachable by actual run and jump")
	p.position.x = 249
	p.velocity = Vector2.ZERO
	await frames(2)
	Input.action_press("right")
	p.jump_buffer = 0.12
	await frames(29)
	Input.action_release("right")
	await frames(3)
	check(p.is_on_floor() and absf(p.position.y - 234) < 1, "Second platform is reachable without an upgrade")
	await fresh()
	p = game.player
	p.position = Vector2(205, 278)
	p.velocity = Vector2.ZERO
	await frames(6)
	check(p.is_on_floor(), "Player can stand on one-way platform")
	check(p.try_drop(), "Down-jump targets the current one-way platform")
	await frames(38)
	check(absf(p.position.y - 324) < 1 and p.get_collision_exceptions().is_empty(), "Drop-through lands on solid floor and restores collision")
	await fresh()
	p = game.player
	p.position = Vector2(628, 324)
	p.facing = 1
	p.start_dash()
	await frames(15)
	check(p.position.x < 634, "Fast dash respects native wall collision")
	await fresh()
	p = game.player
	p.position.x = 300
	p.testing = false
	Input.action_press("down")
	await frames(5)
	check(p.crouched and p.hurtbox.collider.shape.size.y == 14, "Crouch changes the real damage-receiving shape")
	game.spawn_bolt(Vector2(350, 302), -1, true, 12, 910)
	await frames(24)
	check(p.hp == 100, "High archer bolt passes over crouched player")
	game.spawn_bolt(Vector2(350, 316), -1, false, 12, 911)
	await frames(24)
	check(p.hp == 88, "Low archer bolt still hits a crouched player")
	await fresh()
	p = game.player
	p.position = Vector2(361, 275)
	p.velocity = Vector2(0, 10)
	p.start_attack("down")
	await frames(12)
	check(p.bounces == 1 and p.velocity.y < 0, "Downslash contact triggers an actual upward bounce")
	await fresh()
	p = game.player
	p.hp = 40
	check(p.start_potion(), "One bottle starts a vulnerable healing action")
	await frames(42)
	check(p.hp == 75 and p.potions == 0, "Healing completes once and consumes one bottle")
	await fresh()
	p = game.player
	p.hp = 40
	p.start_potion()
	await frames(10)
	p.receive_hit({"damage": 10, "id": 915, "direction": Vector2.RIGHT})
	await frames(45)
	check(p.hp == 30 and p.potions == 0, "Damage interrupts healing without granting health")
	await fresh(4)
	var enemies = game.living_enemies()
	check(game.claim_attacker(enemies[0]) and game.claim_attacker(enemies[1]) and not game.claim_attacker(enemies[2]), "Encounter budget limits simultaneous attackers to two")
	game.release_attacker(enemies[0])
	check(game.claim_attacker(enemies[2]), "Attack slot is released for another enemy")
	var miner = enemies[0]
	miner.facing = -1
	miner.change_state(miner.State.WINDUP)
	var locked = miner.locked_facing
	p = game.player
	p.position.x = 600
	check(miner.locked_facing == locked, "Windup locks its attack direction")
	await fresh()
	p = game.player
	p.invincible = 0
	p.receive_hit({"damage": 200, "id": 999, "direction": Vector2.LEFT})
	check(p.dead and game.dead and p.hp == 0, "Lethal damage ends the practice safely")
	await fresh(1)
	check(not game.dead and game.player.hp == 100, "Switching practice resets safely with fresh actor instances")
	game.player.testing = false
	var native_event = InputEventKey.new()
	native_event.physical_keycode = KEY_J
	native_event.pressed = true
	Input.parse_input_event(native_event)
	await frames(2)
	check(game.player.action == "light1", "Physical J input routes through the real input map to sword action")
	native_event = InputEventKey.new()
	native_event.physical_keycode = KEY_J
	native_event.pressed = false
	Input.parse_input_event(native_event)
	print("COMBAT CHECKS: %d passed / %d total" % [checks - failures, checks])
	game.queue_free()
	await frames(2)
	quit(1 if failures > 0 else 0)
