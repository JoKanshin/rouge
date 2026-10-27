extends Area2D
## A damage receiver, independent of solid-body collision.
var actor: Node
var collider: CollisionShape2D

func setup(target: Node, layer: int, size: Vector2, offset: Vector2):
	actor = target
	collision_layer = layer
	collision_mask = 0
	monitoring = false
	monitorable = true
	collider = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = size
	collider.shape = rectangle
	collider.position = offset
	add_child(collider)

func resize(size: Vector2, offset: Vector2):
	collider.shape.size = size
	collider.position = offset

func receive(payload: Dictionary) -> bool:
	if not is_instance_valid(actor) or not actor.has_method("receive_hit"): return false
	return actor.receive_hit(payload)
