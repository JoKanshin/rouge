extends SceneTree

func _initialize():
	call_deferred("run_checks")

func check(condition: bool, description: String):
	if not condition:
		push_error("FAIL: " + description)
		quit(1)
		return
	print("PASS: " + description)

func run_checks():
	var game = load("res://legacy.tscn").instantiate()
	root.add_child(game)
	game.set_physics_process(false)
	check(game.town and game.hp == 100, "Town initial state")
	game.player.x = 344
	game.interact()
	check(game.coins == 5 and game.damage == 30, "Smith purchase")
	game.coins = 100
	game.hp = 30
	game.player.x = 188
	game.interact()
	check(game.hp == 100 and game.coins == 85, "Town healing")
	game.player.x = 550
	game.interact()
	check(not game.town and game.room == 1 and game.enemies.size() == 4, "Dungeon entry")
	check(390.0 * 390.0 / (2 * 820) > 326 - game.platforms[1].position.y, "First platform is reachable")
	game.player = game.chests[0].pos
	game.interact()
	check(game.choosing and game.choices.size() == 3, "Chest offers three relics")
	game.apply_boon(0)
	check(game.damage == 39 and not game.choosing, "Relic applies")
	game.enemies.clear()
	game.enemies.append({"pos": Vector2(210, 305), "hp": 20, "max": 20, "flying": false, "flash": 0.0, "phase": 0.0, "attack": 1.0, "wind": 0.0, "dir": -1.0})
	game.player = Vector2(185, 300)
	game.attack_time = 0.2
	game.facing = 1
	game._physics_process(0.016)
	check(game.enemies.is_empty() and game.kills == 1, "Sword kills and awards loot")
	game.player.x = 590
	game.interact()
	check(game.room == 2, "Cleared exit advances floor")
	game.player.x = 35
	game.interact()
	check(game.town, "Return to town")
	game.enter_room()
	game.hp = 1
	game.invincible = 0
	game.hurt(15, Vector2.ZERO)
	check(game.town and game.hp == 100 and game.permanent_damage == 6, "Death returns safely and retains upgrade")
	for i in range(120): game._physics_process(1.0 / 60)
	await process_frame
	await process_frame
	print("ALL CHECKS COMPLETE")
	quit()
