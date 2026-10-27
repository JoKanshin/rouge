extends RefCounted
## Frame timings at 60 Hz. Damage, stance damage, hit shape and cancel windows.
static func get_move(move_name: String) -> Dictionary:
	var table = {
		"light1": [5, 4, 9, 18, 14, Vector2(43, 29), Vector2(25, -17), 13],
		"light2": [5, 4, 9, 18, 15, Vector2(46, 30), Vector2(27, -17), 13],
		"light3": [7, 5, 18, 26, 28, Vector2(51, 32), Vector2(28, -18), 21],
		"up": [4, 6, 12, 20, 20, Vector2(31, 41), Vector2(0, -38), 16],
		"down": [5, 9, 13, 22, 25, Vector2(27, 36), Vector2(0, 5), 21],
		"heavy": [16, 6, 22, 32, 55, Vector2(53, 35), Vector2(29, -17), 37],
		"pulse": [9, 6, 18, 20, 50, Vector2(144, 90), Vector2(0, -19), 28]
	}
	var a = table[move_name]
	return {"name": move_name, "startup": a[0], "active": a[1], "recovery": a[2], "damage": a[3], "stance": a[4], "size": a[5], "offset": a[6], "cancel": a[7], "total": a[0] + a[1] + a[2]}
