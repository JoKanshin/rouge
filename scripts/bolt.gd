extends Node2D
const Hitbox = preload("res://scripts/combat/hitbox.gd")
var arena: Node
var direction = -1
var high = true
var damage = 12
var serial = 0
var lifetime = 2.8
var hitbox: Area2D

func _ready():
	add_to_group("bolts")
	hitbox = Hitbox.new()
	add_child(hitbox)
	hitbox.target_mask = 16
	hitbox.begin({"damage": damage, "direction": Vector2(direction, 0), "id": serial}, Vector2(13, 4), Vector2.ZERO)
	hitbox.landed.connect(func(_actor, _payload): queue_free())

func _physics_process(dt):
	lifetime -= dt
	var next = position + Vector2(direction * 215 * dt, 0)
	var query = PhysicsRayQueryParameters2D.create(position, next, 3)
	if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
		arena.feedback.burst(position, Color("ad9871"), 4)
		queue_free()
		return
	position = next
	hitbox.poll()
	if lifetime <= 0 or not arena.world_bounds.has_point(position): queue_free()
	queue_redraw()

func _draw():
	draw_line(Vector2(-direction * 15, 0), Vector2.ZERO, Color("886b51"), 2)
	draw_line(Vector2(-direction * 7, 0), Vector2(direction * 4, 0), Color("f4d999"), 2)
	draw_colored_polygon(PackedVector2Array([Vector2(direction * 6, 0), Vector2(direction, -3), Vector2(direction, 3)]), Color("ffe6b3"))
