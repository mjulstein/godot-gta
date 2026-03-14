extends Camera2D

@export var follow_speed := 7.5
var target: Node2D

func _ready() -> void:
	limit_enabled = true

func set_target(node: Node2D) -> void:
	target = node
	if target != null:
		global_position = target.global_position

func set_world_bounds(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.position.x + bounds.size.x)
	limit_bottom = int(bounds.position.y + bounds.size.y)

func _process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(target.global_position, min(1.0, delta * follow_speed))
