extends RefCounted
## Seamless side-view mine. Pure data first; independent layout/encounter RNGs.
const TILE = 16
const VERSION = 1

static func defaults() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("res://config/world_defaults.json"))

static func generate(settings: Dictionary) -> Dictionary:
	var c = defaults()
	c.merge(settings,true)
	c.width_segments = clampi(int(c.width_segments),12,64)
	c.depth_layers = clampi(int(c.depth_layers),2,7)
	c.segment_tiles = 8 # Safe horizontal rhythm is part of generator version 1.
	c.layer_tiles = 20
	c.min_tunnel_height = clampi(int(c.min_tunnel_height),5,12)
	c.max_tunnel_height = clampi(int(c.max_tunnel_height),c.min_tunnel_height,14)
	c.floor_variation_tiles = clampi(int(c.floor_variation_tiles),0,2)
	c.shafts_per_layer = clampi(int(c.shafts_per_layer),2,5)
	c.shaft_width_tiles = 8
	c.climb_step_pixels = clampi(int(c.climb_step_pixels),28,40)
	c.enemy_probability = clampf(float(c.enemy_probability),0,0.7)
	c.treasure_count = clampi(int(c.treasure_count),1,24)
	c.camp_spacing_layers = clampi(int(c.camp_spacing_layers),1,2)
	c.activation_radius = clampi(int(c.activation_radius),500,1000)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(c.seed)
	var encounter_rng = RandomNumberGenerator.new()
	encounter_rng.seed = int(c.seed) ^ 0x5eeda11
	var width = c.width_segments*8+4
	var height = c.depth_layers*20+4
	var tiles = PackedByteArray()
	tiles.resize(width*height)
	tiles.fill(1)
	var world = {"version": VERSION, "config": c, "width": width, "height": height, "tiles": tiles, "floors": [], "shafts": [], "platforms": [], "enemies": [], "objects": [], "bounds": Rect2(0,0,width*TILE,height*TILE), "route_nodes": [], "route_edges": []}
	# Alternating long galleries form a readable horizontal skeleton. Their floor
	# profiles, ceiling heights, shafts and encounters all change with the seed.
	for layer in range(c.depth_layers):
		var row = []
		var previous = 0
		for segment in range(c.width_segments):
			var variation = clampi(previous+rng.randi_range(-1,1),-c.floor_variation_tiles,c.floor_variation_tiles)
			if segment < 2: variation = 0
			elif segment >= c.width_segments-2: variation = int(move_toward(previous,0,1))
			previous = variation
			var floor_y = 2+layer*20+15+variation
			row.append(floor_y)
			var ceiling = floor_y-rng.randi_range(c.min_tunnel_height,c.max_tunnel_height)
			carve(world,Rect2i(2+segment*8,ceiling,8,floor_y-ceiling))
			# Every gallery segment has a navigation surface. Neighboring surfaces
			# differ by <=16px; ramps use a generous 128px-wide landing.
			world.route_nodes.append(Vector2((2+segment*8+4)*TILE,floor_y*TILE))
			if segment > 0: link(world,layer*c.width_segments+segment-1,layer*c.width_segments+segment)
		world.floors.append(row)
	# Wide open shafts connect adjacent depth bands with climbable ledges.
	# Two or more per band guarantees real loops, with different horizontal routes.
	for layer in range(c.depth_layers-1):
		var chosen = []
		for index in range(c.shafts_per_layer):
			var zone = float(c.width_segments-6)/c.shafts_per_layer
			var segment = clampi(3+int(index*zone)+rng.randi_range(0,maxi(0,int(zone)-2)),3,c.width_segments-4)
			if segment in chosen: continue
			chosen.append(segment)
			var left = (2+segment*8)*TILE
			var upper = world.floors[layer][segment]*TILE
			var lower = world.floors[layer+1][segment]*TILE
			carve(world,Rect2i(left/TILE,upper/TILE-5,8,(lower-upper)/TILE+5))
			var shaft = {"x": left, "top": upper, "bottom": lower, "layer": layer, "segment": segment, "platform_ids": []}
			# Full-width landings let the player cross or deliberately drop down.
			world.platforms.append(Rect2(left,upper,128,6))
			shaft.platform_ids.append(world.platforms.size()-1)
			var y = upper+c.climb_step_pixels
			var flip = false
			while y < lower:
				world.platforms.append(Rect2(left+(48 if flip else 0),y,80,6))
				shaft.platform_ids.append(world.platforms.size()-1)
				flip = not flip
				y += c.climb_step_pixels
			world.platforms.append(Rect2(left,lower,128,6))
			shaft.platform_ids.append(world.platforms.size()-1)
			world.shafts.append(shaft)
			link(world,layer*c.width_segments+segment,(layer+1)*c.width_segments+segment)
	world.spawn = Vector2(112,world.floors[0][0]*TILE)
	world.exit = Vector2((2+(c.width_segments-1)*8+4)*TILE,world.floors[-1][-1]*TILE)
	world.objects.append({"id":"entry","kind":"entry","pos":world.spawn,"used":false})
	world.objects.append({"id":"exit","kind":"exit","pos":world.exit,"used":false})
	for layer in range(0,c.depth_layers,c.camp_spacing_layers):
		var segment = 1 if layer == 0 else (c.width_segments/2 if layer%2 else c.width_segments-3)
		var pos = surface_position(world,layer,segment)
		world.objects.append({"id":"camp_%d"%layer,"kind":"camp","pos":pos,"used":false})
	for i in range(c.treasure_count):
		var layer = i%c.depth_layers
		var segment = encounter_rng.randi_range(3,c.width_segments-3)
		var pos = surface_position(world,layer,segment)
		world.objects.append({"id":"chest_%d"%i,"kind":"chest","pos":pos,"used":false,"coins":encounter_rng.randi_range(25,55)})
	for layer in range(c.depth_layers):
		for segment in range(3,c.width_segments-1):
			if layer == 0 and segment < 5: continue
			if encounter_rng.randf() > c.enemy_probability: continue
			var pos = surface_position(world,layer,segment)
			var safe = false
			for object in world.objects:
				if object.kind in ["camp","entry","exit"] and pos.distance_to(object.pos) < 210: safe = true
			if safe: continue
			var kind = ["miner","archer","bat"][encounter_rng.randi_range(0,2)]
			if kind == "bat": pos.y -= 64
			world.enemies.append({"id":"enemy_%d_%d"%[layer,segment],"kind":kind,"pos":pos})
	return world

static func surface_position(world: Dictionary,layer: int,segment: int) -> Vector2:
	return Vector2((2+segment*8+4)*TILE,world.floors[layer][segment]*TILE)

static func carve(world: Dictionary,rect: Rect2i):
	for y in range(maxi(2,rect.position.y),mini(world.height-2,rect.end.y)):
		for x in range(maxi(2,rect.position.x),mini(world.width-2,rect.end.x)):
			world.tiles[y*world.width+x] = 0

static func link(world: Dictionary,a: int,b: int):
	world.route_edges.append([a,b])
	world.route_edges.append([b,a])

static func solid(world: Dictionary,x: int,y: int) -> bool:
	if x < 0 or y < 0 or x >= world.width or y >= world.height: return true
	return world.tiles[y*world.width+x] == 1

static func validate(world: Dictionary) -> Array:
	var errors = []
	var c = world.config
	var visited = {0:true}
	var queue = [0]
	var adjacency = {}
	for edge in world.route_edges:
		if not adjacency.has(edge[0]): adjacency[edge[0]] = []
		adjacency[edge[0]].append(edge[1])
	var at = 0
	while at < queue.size():
		var index = queue[at]
		at += 1
		for next in adjacency.get(index,[]):
			if not visited.has(next):
				visited[next] = true
				queue.append(next)
	if visited.size() != world.route_nodes.size(): errors.append("disconnected route graph")
	if world.shafts.size() < 2*(c.depth_layers-1): errors.append("missing loop shafts")
	for row in world.floors:
		for i in range(1,row.size()):
			if abs(row[i]-row[i-1]) > 1: errors.append("unsafe gallery step")
	for shaft in world.shafts:
		var platforms = shaft.platform_ids
		for i in range(1,platforms.size()):
			var a: Rect2 = world.platforms[platforms[i-1]]
			var b: Rect2 = world.platforms[platforms[i]]
			if b.position.y-a.position.y > 44: errors.append("unsafe shaft jump")
	for object in world.objects:
		var feet: Vector2 = object.pos
		if solid(world,int(feet.x)/TILE,int(feet.y-14)/TILE): errors.append("object inside rock")
	return errors
