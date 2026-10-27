extends SceneTree
const Generator = preload("res://scripts/world/world_generator.gd")
var failures = 0
var checks = 0
var game

func _initialize(): call_deferred("run")
func check(ok: bool,label: String):
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: "+label)
	else: print("PASS: "+label)

func frames(n: int):
	for i in range(n): await physics_frame

func run():
	var all_valid = true
	var signatures = {}
	for seed_value in range(1000):
		var w = Generator.generate({"seed":seed_value})
		var errors = Generator.validate(w)
		if not errors.is_empty():
			all_valid = false
			push_error("seed %d: %s"%[seed_value,errors])
			break
		signatures[hash(w.tiles)] = true
	check(all_valid,"1000 seeds: bidirectional routes, loops, safe steps, interaction clearance")
	check(signatures.size() > 990,"Seeds generate different geometry")
	var a = Generator.generate({"seed":42})
	var b = Generator.generate({"seed":42})
	check(a.tiles == b.tiles and a.enemies == b.enemies and a.objects == b.objects,"Same config and seed reproduce geometry, encounters and rewards")
	var c = Generator.generate({"seed":42,"enemy_probability":0.0})
	check(a.tiles == c.tiles and c.enemies.is_empty(),"Encounter settings do not perturb layout RNG")
	for cfg in [{"width_segments":12,"depth_layers":2,"shafts_per_layer":5},{"width_segments":64,"depth_layers":7,"climb_step_pixels":28},{"min_tunnel_height":5,"max_tunnel_height":5}]:
		check(Generator.validate(Generator.generate(cfg)).is_empty(),"Parameter boundary valid: "+str(cfg))
	game = load("res://main.tscn").instantiate()
	game.test_mode = true
	root.add_child(game)
	game.feedback.enabled = false
	game.feedback.sound_enabled = false
	game.set_physics_process(false)
	for enemy in game.living_enemies(): enemy.set_physics_process(false)
	await frames(12)
	check(game.player.is_on_floor(),"Player spawns safely on real continuous-world collision")
	check(game.world_bounds.size.x > 5000 and game.world_bounds.size.y > 1500,"Default world spans multiple screens in both axes")
	var camp = game.world.objects[2]
	game.player.position = camp.pos
	game.player.hp = 40
	game.player.potions = 0
	game.interact()
	check(game.player.hp == 100 and game.player.potions == 1 and game.checkpoint == camp.pos,"Camp heals, refills and sets checkpoint")
	var chest
	for object in game.world.objects:
		if object.kind == "chest": chest = object; break
	game.player.position = chest.pos
	game.interact()
	var after = game.coins
	game.interact()
	check(after > 0 and game.coins == after,"Chest grants coins exactly once")
	game.player.position = camp.pos
	game.interact(true)
	check(game.bank == after and game.coins == 0,"Camp deposits use a separate bank ledger")
	game.coins = 100
	game.player_fell()
	game.respawn()
	check(game.coins == 60 and game.bank == after and not game.player.dead,"Death loses 40 percent once and respawns at camp")
	# Real CharacterBody2D jumps on each alternating shaft step, in several
	# generated shafts. The controller moves using the real input map.
	var p = game.player
	p.testing = false
	var traversed = 0
	var total = 0
	for shaft in game.world.shafts.slice(0,3):
		var ids = shaft.platform_ids
		for i in range(ids.size()-1,0,-1):
			total += 1
			var lower: Rect2 = game.world.platforms[ids[i]]
			var upper: Rect2 = game.world.platforms[ids[i-1]]
			p.position = Vector2(lower.get_center().x,lower.position.y)
			p.velocity = Vector2.ZERO
			p.stun = 0
			p.dash_clock = 0
			p.end_attack()
			await frames(4)
			p.jump_buffer = 0.12
			var landed = false
			for tick in range(65):
				var dx = upper.get_center().x-p.position.x
				Input.action_release("left")
				Input.action_release("right")
				if absf(dx) > 5: Input.action_press("right" if dx > 0 else "left")
				await physics_frame
				if tick > 7 and p.is_on_floor() and absf(p.position.y-upper.position.y) < 3:
					landed = true
					break
			Input.action_release("left")
			Input.action_release("right")
			if landed: traversed += 1
			else: print("JUMP FAILED lower=",lower," upper=",upper," result=",p.position)
	check(traversed == total,"Actual controller shaft jumps: %d / %d"%[traversed,total])
	# Crossing x=640 and y=400 must no longer trigger old arena limits.
	p.position = Generator.surface_position(game.world,2,12)
	p.velocity = Vector2.ZERO
	p.hp = 100
	await frames(20)
	check(not p.dead and p.position.x > 640 and p.position.y > 400,"Large-world coordinates do not trigger legacy arena kill bounds")
	var miner = game.spawn_enemy("miner",Generator.surface_position(game.world,2,14))
	await frames(10)
	check(miner.position.x > 640,"Enemy no longer clamps to first 640 pixels")
	var bolt = game.spawn_bolt(p.position+Vector2(32,-20),1,true,1,1)
	await frames(2)
	check(is_instance_valid(bolt),"Arrows survive beyond old screen bounds")
	var event = InputEventKey.new()
	event.physical_keycode = KEY_TAB
	event.pressed = true
	game._unhandled_key_input(event)
	check(game.map_open and paused,"Map pauses combat")
	event.physical_keycode = KEY_ESCAPE
	game._unhandled_key_input(event)
	check(not game.map_open and not paused,"Esc exits map and resumes")
	event.physical_keycode = KEY_ESCAPE
	game._unhandled_key_input(event)
	check(paused,"Esc pauses normal exploration")
	game._unhandled_key_input(event)
	check(not paused,"Esc resumes normal exploration")
	# Use an isolated test save so real player progress cannot be overwritten.
	game.save_path = "user://world_test_only.json"
	game.test_mode = false
	game.player.position = chest.pos
	game.coins = 77
	game.defeated["test_enemy"] = true
	game.save_run()
	check(FileAccess.file_exists(game.save_path),"Save writes a complete generated-world snapshot")
	game.coins = 999
	game.load_run()
	check(game.coins == 77 and game.bank == after and game.defeated.has("test_enemy"),"Load restores separate balances and defeated enemies")
	var loaded_chest
	for object in game.world.objects:
		if object.id == chest.id: loaded_chest = object; break
	check(loaded_chest.used,"Opened chest remains opened after reload")
	game.interact()
	check(game.coins == 77,"Reloading an opened chest cannot duplicate rewards")
	game.coins = 100
	game.player_fell()
	game.player_fell()
	check(game.coins == 60,"Repeated death callback does not settle twice")
	game.load_run()
	check(game.coins == 60 and game.player.hp == 100,"Reload preserves settled death loss and checkpoint recovery")
	DirAccess.remove_absolute(game.save_path)
	game.test_mode = true
	print("WORLD CHECKS: ",checks-failures," / ",checks," passed")
	quit(1 if failures else 0)
