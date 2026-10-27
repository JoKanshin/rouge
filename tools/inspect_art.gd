extends SceneTree
func _initialize():
	for name in ["hero_strip_v01", "miner_strip_v01", "bat_strip_v02", "terrain_strip_v01", "lantern_v01"]:
		var img = Image.load_from_file("res://art_source/candidates/" + name + ".png")
		var counts = [0, 0, 0]
		for y in range(img.get_height()):
			for x in range(img.get_width()):
				var a = img.get_pixel(x, y).a
				counts[0 if a == 0 else (2 if a > 0.95 else 1)] += 1
		print(name, " size=", img.get_size(), " used=", img.get_used_rect(), " alpha[zero,partial,opaque]=", counts)
	quit()
