extends Camera2D

@export var follow_speed := 7.5
var target: Node2D

func set_target(node: Node2D) -> void:
	target = node
	if target != null:
		global_position = target.global_position

func _process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(target.global_position, min(1.0, delta * follow_speed))
