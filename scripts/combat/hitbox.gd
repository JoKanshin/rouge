extends Area2D
## Query a separate attack area during active frames, once per target per attack.
signal landed(target, payload)
var collider: CollisionShape2D
var active = false
var seen: Dictionary = {}
var payload: Dictionary = {}
var target_mask = 8

func _ready():
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false
	collider = CollisionShape2D.new()
	collider.shape = RectangleShape2D.new()
	add_child(collider)

func begin(data: Dictionary, size: Vector2, offset: Vector2):
	payload = data.duplicate()
	collider.shape.size = size
	collider.position = offset
	seen.clear()
	active = true

func end():
	active = false

func poll():
	if not active or not is_inside_tree(): return
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = collider.shape
	query.transform = collider.global_transform
	query.collision_mask = target_mask
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result in get_world_2d().direct_space_state.intersect_shape(query, 32):
		var hurt = result.collider
		if not hurt.has_method("receive"): continue
		var id = hurt.get_instance_id()
		if seen.has(id): continue
		if hurt.receive(payload):
			seen[id] = true
			landed.emit(hurt.actor, payload)

func _draw():
	if active and get_tree().get_first_node_in_group("arena").debug_shapes:
		draw_rect(Rect2(collider.position - collider.shape.size / 2, collider.shape.size), Color(1, 0.7, 0.2, 0.25))
