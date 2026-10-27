extends SceneTree
## Reproducible production export: inspected source regions, hard alpha,
## nearest-neighbor sampling, project palette, explicit anchor and canvas.
const PALETTE = ["0d151d", "111922", "17232d", "29383e", "3c4a4c", "72817b", "83aaa9", "d5dacf", "fff0c9", "dfbf85", "c49c63", "806b52", "c98668", "b77c73", "efab79", "a69ac2", "8bd2c5", "f0776c"]
var manifest = {"version": 1, "date": "2026-10-26", "generator": "built-in image_gen", "assets": []}

func _initialize():
	# Regions are individually inspected; do not assume equal AI sprite cells.
	for i in range(4):
		export_frame("hero_strip_v01", Rect2i(i * 496, 200, 496 if i < 3 else 495, 500), Vector2i(32,48), Vector2i(16,44), Vector2i(0,28), "player/hero_" + ["idle", "anticipate", "contact", "recover"][i], 0.0)
	export_frame("miner_strip_v01", Rect2i(180,340,720,525), Vector2i(64,64), Vector2i(24,56), Vector2i(0,0), "enemies/miner/idle", 0.057, 0.34)
	export_frame("miner_strip_v01", Rect2i(1020,90,620,775), Vector2i(64,64), Vector2i(24,56), Vector2i(0,0), "enemies/miner/windup", 0.057, 0.56)
	export_frame("bat_strip_v02", Rect2i(80,210,1180,355), Vector2i(64,48), Vector2i(32,36), Vector2i(46,22), "enemies/bat/spread", 0.0)
	export_frame("bat_strip_v02", Rect2i(1430,200,455,365), Vector2i(64,48), Vector2i(32,36), Vector2i(16,22), "enemies/bat/fold", 0.0)
	for i in range(4):
		export_frame("terrain_strip_v01", Rect2i(i*543,240,543,410), Vector2i(16,16), Vector2i(8,16), Vector2i(16,16), "terrain/mine/" + ["top", "fill", "edge", "platform"][i], 0.0)
	export_frame("lantern_v01", Rect2i(300,320,410,830), Vector2i(32,32), Vector2i(16,28), Vector2i(12,24), "props/lantern", 0.0)
	var file = FileAccess.open("res://assets/art/p0_manifest.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(manifest, "\t"))
	print("P0 exported: ", manifest.assets.size(), " PNG assets")
	quit()

func export_frame(source: String, region: Rect2i, canvas: Vector2i, anchor: Vector2i, fit: Vector2i, target: String, ratio: float, pivot_fraction: float = 0.5):
	var image = Image.load_from_file("res://art_source/candidates/" + source + ".png").get_region(region)
	image.convert(Image.FORMAT_RGBA8)
	# Generated soft alpha is excluded from opaque pixel silhouettes.
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var c = image.get_pixel(x,y)
			image.set_pixel(x,y, Color(c.r,c.g,c.b,1) if c.a >= 0.98 else Color.TRANSPARENT)
	var used = image.get_used_rect()
	image = image.get_region(used)
	var size: Vector2i
	if ratio > 0: size = Vector2i(round(image.get_width()*ratio), round(image.get_height()*ratio))
	elif fit.x == 0: size = Vector2i(round(float(image.get_width()) / image.get_height() * fit.y), fit.y)
	else: size = fit
	image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	for y in range(size.y):
		for x in range(size.x):
			var c = image.get_pixel(x,y)
			if c.a == 0: continue
			var best = Color(PALETTE[0])
			var distance = INF
			for code in PALETTE:
				var p = Color(code)
				var d = pow(c.r-p.r,2) + pow(c.g-p.g,2) + pow(c.b-p.b,2)
				if d < distance:
					distance = d
					best = p
			image.set_pixel(x,y,best)
	var result = Image.create(canvas.x,canvas.y,false,Image.FORMAT_RGBA8)
	var offset = anchor - Vector2i(round(size.x * pivot_fraction), size.y)
	assert(offset.x >= 0 and offset.y >= 0 and offset.x+size.x <= canvas.x and offset.y+size.y <= canvas.y, target + " overflows")
	result.blit_rect(image, Rect2i(Vector2i.ZERO,size), offset)
	var path = "res://assets/art/" + target + "_v01.png"
	assert(result.save_png(path) == OK)
	manifest.assets.append({"asset_id": target, "path": path, "canvas": [canvas.x,canvas.y], "anchor": [anchor.x,anchor.y], "source": source, "source_region": [region.position.x,region.position.y,region.size.x,region.size.y], "trimmed_region": [used.position.x,used.position.y,used.size.x,used.size.y], "body_size": [size.x,size.y], "facing": "right" if not target.begins_with("enemies/bat") else "front", "status": "P0 runtime sample", "processing": "alpha >= 0.98; nearest resize; project palette; explicit anchor"})
	print(target, " -> ", size, " at ", offset)
