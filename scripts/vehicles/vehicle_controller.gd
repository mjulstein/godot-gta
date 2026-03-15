extends CharacterBody2D

signal civilian_hit(target: Node2D)

@export var tuning: Resource
@export var collision_flash_time := 0.12
@export_range(500.0, 4000.0, 1.0) var mass_kg := 2000.0

var driver: Node = null
var collision_flash_remaining := 0.0
var theft_reported := false
var impact_cooldowns: Dictionary = {}
var longitudinal_speed := 0.0

@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	add_to_group("traffic_obstacle")
	add_to_group("traffic_dynamic_obstacle")
	longitudinal_speed = Vector2.RIGHT.rotated(rotation).dot(velocity)

func _physics_process(delta: float) -> void:
	collision_flash_remaining = maxf(0.0, collision_flash_remaining - delta)
	_tick_impact_cooldowns(delta)
	body_polygon.color = Color(1, 0.2, 0.2, 1) if collision_flash_remaining > 0.0 else Color(1, 0.54902, 0.14902, 1)

	var acceleration: float = 380.0 if tuning == null else tuning.acceleration
	var reverse_acceleration: float = 280.0 if tuning == null else tuning.reverse_acceleration
	var brake_power: float = 440.0 if tuning == null else tuning.brake_power
	var max_speed: float = 320.0 if tuning == null else tuning.max_speed
	var reverse_speed: float = 140.0 if tuning == null else tuning.reverse_speed
	var steering_speed: float = 2.8 if tuning == null else tuning.steering_speed
	var friction: float = 220.0 if tuning == null else tuning.friction
	var min_steer_speed: float = 18.0 if tuning == null else tuning.min_steer_speed

	if driver == null:
		longitudinal_speed = move_toward(longitudinal_speed, 0.0, friction * delta)
		velocity = Vector2.RIGHT.rotated(rotation) * longitudinal_speed
		move_and_slide()
		return

	var forward_input := Input.get_action_strength("accelerate")
	var reverse_input := Input.get_action_strength("brake")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var forward := Vector2.RIGHT.rotated(rotation)
	longitudinal_speed = forward.dot(velocity)

	if forward_input > 0.0:
		if longitudinal_speed < 0.0:
			longitudinal_speed = move_toward(longitudinal_speed, 0.0, brake_power * forward_input * delta)
		else:
			longitudinal_speed = move_toward(longitudinal_speed, max_speed * forward_input, acceleration * delta)
	elif reverse_input > 0.0:
		if longitudinal_speed > 0.0:
			longitudinal_speed = move_toward(longitudinal_speed, 0.0, brake_power * reverse_input * delta)
		else:
			longitudinal_speed = move_toward(longitudinal_speed, -reverse_speed * reverse_input, reverse_acceleration * delta)
	else:
		longitudinal_speed = move_toward(longitudinal_speed, 0.0, friction * delta)

	var steering_speed_scale := clampf(absf(longitudinal_speed) / maxf(max_speed, 1.0), 0.0, 1.0)
	if absf(longitudinal_speed) >= min_steer_speed:
		var steering_direction := 1.0 if longitudinal_speed >= 0.0 else -1.0
		rotation += steer_input * steering_speed * steering_direction * maxf(0.35, steering_speed_scale) * delta

	velocity = Vector2.RIGHT.rotated(rotation) * longitudinal_speed
	_displace_pedestrians_ahead()

	move_and_slide()
	if get_slide_collision_count() > 0:
		collision_flash_remaining = collision_flash_time
		_emit_civilian_impacts()

func can_enter() -> bool:
	return driver == null

func set_driver(value: Node) -> void:
	driver = value

func clear_driver() -> void:
	driver = null

func get_exit_position() -> Vector2:
	return global_position + Vector2.DOWN.rotated(rotation) * 28.0

func get_driver_entry_position() -> Vector2:
	var driver_side := -Vector2.RIGHT.rotated(rotation).orthogonal()
	return global_position + driver_side * 22.0

func has_recent_collision() -> bool:
	return collision_flash_remaining > 0.0

func has_driver() -> bool:
	return driver != null

func is_player_controlled() -> bool:
	return driver != null and driver.is_in_group("player_actor")

func get_impact_velocity() -> Vector2:
	return velocity

func get_mass_kg() -> float:
	return mass_kg

func get_motion_debug_lines() -> PackedStringArray:
	var forward_input := Input.get_action_strength("accelerate")
	var reverse_input := Input.get_action_strength("brake")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")
	var max_speed: float = 320.0 if tuning == null else tuning.max_speed
	var reverse_speed: float = 140.0 if tuning == null else tuning.reverse_speed
	var drive_state := "reverse" if longitudinal_speed < -0.5 else "forward" if longitudinal_speed > 0.5 else "idle"
	return PackedStringArray([
		"Throttle %.1f / reverse %.1f / steer %.1f" % [forward_input, reverse_input, steer_input],
		"State %s" % drive_state,
		"Speed %.1f / %.1f kph" % [longitudinal_speed * 0.18, maxf(max_speed, reverse_speed) * 0.18],
		"Driver: %s" % ("player" if driver != null else "none"),
	])

func mark_theft_reported() -> void:
	theft_reported = true

func was_theft_reported() -> bool:
	return theft_reported

func _emit_civilian_impacts() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider == null or not collider.is_in_group("civilian_pedestrian"):
			continue
		if _is_impact_on_cooldown(collider):
			continue
		_register_pedestrian_impact(collider)

func _tick_impact_cooldowns(delta: float) -> void:
	for collider_id in impact_cooldowns.keys():
		var remaining: float = impact_cooldowns[collider_id] - delta
		if remaining <= 0.0:
			impact_cooldowns.erase(collider_id)
		else:
			impact_cooldowns[collider_id] = remaining

func _is_impact_on_cooldown(collider: Node) -> bool:
	return impact_cooldowns.has(collider.get_instance_id())

func _displace_pedestrians_ahead() -> void:
	if absf(longitudinal_speed) < 18.0:
		return
	var forward := Vector2.RIGHT.rotated(rotation) * signf(longitudinal_speed)
	var look_ahead := 18.0 + absf(longitudinal_speed) * 0.08
	var half_width := 16.0
	for candidate in get_tree().get_nodes_in_group("civilian_pedestrian"):
		if not (candidate is Node2D):
			continue
		var pedestrian := candidate as Node2D
		var offset := pedestrian.global_position - global_position
		var forward_distance := forward.dot(offset)
		if forward_distance < 0.0 or forward_distance > look_ahead:
			continue
		var lateral_distance := absf(forward.orthogonal().dot(offset))
		if lateral_distance > half_width:
			continue
		if _is_impact_on_cooldown(pedestrian):
			continue
		_register_pedestrian_impact(pedestrian)

func _register_pedestrian_impact(collider: Node) -> void:
	impact_cooldowns[collider.get_instance_id()] = 0.75
	if collider.has_method("register_harm"):
		collider.register_harm(self)
	civilian_hit.emit(collider)
