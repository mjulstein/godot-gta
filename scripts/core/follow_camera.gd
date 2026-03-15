extends Camera2D

@export var follow_speed := 7.5
@export var base_zoom := Vector2(1.1, 1.1)
@export var max_zoom_out := Vector2(0.82, 0.82)
@export_range(1.0, 1200.0, 1.0) var zoom_out_speed := 320.0
@export_range(0.1, 20.0, 0.1) var zoom_lerp_speed := 5.0
@export_range(0.0, 20.0, 0.1) var look_ahead_lerp_speed := 4.0
@export_range(0.0, 2.0, 0.05) var zoom_in_delay := 0.35
@export_range(0.1, 20.0, 0.1) var speed_decay_rate := 240.0
@export_range(0.0, 2.0, 0.05) var exit_transition_duration := 0.5
var target: Node2D
var look_ahead := Vector2.ZERO
var world_bounds := Rect2(Vector2(-624, -344), Vector2(1248, 688))
var displayed_speed := 0.0
var zoom_hold_remaining := 0.0
var exit_transition_remaining := 0.0
var exit_transition_speed := 0.0
var exit_transition_direction := Vector2.ZERO

func _ready() -> void:
	add_to_group("runtime_camera")
	limit_enabled = false
	zoom = base_zoom

func set_target(node: Node2D) -> void:
	if target == node:
		return
	if _is_vehicle_node(target) and not _is_vehicle_node(node):
		exit_transition_remaining = exit_transition_duration
		exit_transition_speed = displayed_speed
		exit_transition_direction = _get_direction_for_node(target)
	target = node
	if target != null:
		global_position = _clamp_camera_position(target.global_position)

func get_target() -> Node2D:
	return target

func set_world_bounds(bounds: Rect2) -> void:
	world_bounds = bounds

func _process(delta: float) -> void:
	if target == null:
		return
	_update_speed_state(delta)
	look_ahead = look_ahead.lerp(_get_target_look_ahead(), min(1.0, delta * look_ahead_lerp_speed))
	zoom = zoom.lerp(_get_target_zoom(), min(1.0, delta * zoom_lerp_speed))
	var desired_position := _clamp_camera_position(target.global_position + look_ahead)
	global_position = global_position.lerp(desired_position, min(1.0, delta * follow_speed))

func _get_target_zoom() -> Vector2:
	if not _is_vehicle_target() and exit_transition_remaining <= 0.0:
		return base_zoom
	var speed := displayed_speed
	var weight := clampf(speed / zoom_out_speed, 0.0, 1.0)
	return base_zoom.lerp(max_zoom_out, weight)

func _get_target_speed() -> float:
	if target != null:
		var value = target.get("velocity")
		if value is Vector2:
			return value.length()
	return 0.0

func _get_target_look_ahead() -> Vector2:
	if not _is_vehicle_target() and exit_transition_remaining <= 0.0:
		return Vector2.ZERO
	var speed := displayed_speed
	if speed <= 0.01:
		return Vector2.ZERO
	var direction := _get_target_direction()
	var weight := clampf(speed / zoom_out_speed, 0.0, 1.0)
	return direction * _get_back_third_offset_distance(direction) * weight

func _get_target_direction() -> Vector2:
	if exit_transition_remaining > 0.0 and exit_transition_direction != Vector2.ZERO and not _is_vehicle_target():
		return exit_transition_direction
	if target == null:
		return Vector2.ZERO
	return _get_direction_for_node(target)

func _is_vehicle_target() -> bool:
	return _is_vehicle_node(target)

func _get_back_third_offset_distance(direction: Vector2) -> float:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return 0.0
	var visible_size := Vector2(
		viewport_size.x / maxf(zoom.x, 0.001),
		viewport_size.y / maxf(zoom.y, 0.001)
	)
	var half_span_in_direction := absf(direction.x) * visible_size.x * 0.5 + absf(direction.y) * visible_size.y * 0.5
	return half_span_in_direction / 3.0

func _clamp_camera_position(desired_position: Vector2) -> Vector2:
	var viewport_size := get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return desired_position

	var half_visible_size := Vector2(
		viewport_size.x / maxf(zoom.x, 0.001),
		viewport_size.y / maxf(zoom.y, 0.001)
	) * 0.5

	if world_bounds.size.x <= half_visible_size.x * 2.0:
		desired_position.x = world_bounds.get_center().x
	else:
		desired_position.x = clampf(
			desired_position.x,
			world_bounds.position.x + half_visible_size.x,
			world_bounds.position.x + world_bounds.size.x - half_visible_size.x
		)

	if world_bounds.size.y <= half_visible_size.y * 2.0:
		desired_position.y = world_bounds.get_center().y
	else:
		desired_position.y = clampf(
			desired_position.y,
			world_bounds.position.y + half_visible_size.y,
			world_bounds.position.y + world_bounds.size.y - half_visible_size.y
		)

	return desired_position

func _update_speed_state(delta: float) -> void:
	var raw_speed := _get_target_speed()
	if exit_transition_remaining > 0.0:
		exit_transition_remaining = maxf(0.0, exit_transition_remaining - delta)
		raw_speed = maxf(raw_speed, exit_transition_speed * (exit_transition_remaining / maxf(exit_transition_duration, 0.001)))

	if raw_speed >= displayed_speed:
		displayed_speed = raw_speed
		zoom_hold_remaining = zoom_in_delay
		return

	if zoom_hold_remaining > 0.0:
		zoom_hold_remaining = maxf(0.0, zoom_hold_remaining - delta)
		return

	displayed_speed = move_toward(displayed_speed, raw_speed, speed_decay_rate * delta)

func _is_vehicle_node(node: Node) -> bool:
	return node != null and node.has_method("can_enter")

func _get_direction_for_node(node: Node2D) -> Vector2:
	if node == null:
		return Vector2.ZERO
	var value = node.get("velocity")
	if value is Vector2 and value.length() > 0.01:
		return value.normalized()
	return Vector2.RIGHT.rotated(node.global_rotation)
