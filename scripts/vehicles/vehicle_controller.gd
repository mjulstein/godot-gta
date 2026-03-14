extends CharacterBody2D

signal civilian_hit(target: Node2D)

@export var tuning: Resource
@export var collision_flash_time := 0.12

var driver: Node = null
var collision_flash_remaining := 0.0
var theft_reported := false
var impact_cooldowns: Dictionary = {}

@onready var body_polygon: Polygon2D = $Body

func _physics_process(delta: float) -> void:
	collision_flash_remaining = maxf(0.0, collision_flash_remaining - delta)
	_tick_impact_cooldowns(delta)
	body_polygon.color = Color(1, 0.45, 0.35, 1) if collision_flash_remaining > 0.0 else Color(0.94902, 0.701961, 0.160784, 1)

	var acceleration: float = 380.0 if tuning == null else tuning.acceleration
	var brake_power: float = 440.0 if tuning == null else tuning.brake_power
	var max_speed: float = 320.0 if tuning == null else tuning.max_speed
	var steering_speed: float = 2.8 if tuning == null else tuning.steering_speed
	var friction: float = 220.0 if tuning == null else tuning.friction

	if driver == null:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	var forward := Vector2.RIGHT.rotated(rotation)
	var drive_input := Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
	var steer_input := Input.get_action_strength("steer_right") - Input.get_action_strength("steer_left")

	rotation += steer_input * steering_speed * delta
	velocity += forward * drive_input * acceleration * delta
	velocity = velocity.limit_length(max_speed)

	if absf(drive_input) < 0.01:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	elif drive_input < 0.0:
		velocity = velocity.move_toward(Vector2.ZERO, brake_power * delta)

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

func has_recent_collision() -> bool:
	return collision_flash_remaining > 0.0

func mark_theft_reported() -> void:
	theft_reported = true

func was_theft_reported() -> bool:
	return theft_reported

func _emit_civilian_impacts() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider == null or not collider.is_in_group("civilian"):
			continue
		if _is_impact_on_cooldown(collider):
			continue
		impact_cooldowns[collider.get_instance_id()] = 0.75
		if collider.has_method("register_harm"):
			collider.register_harm(self)
		civilian_hit.emit(collider)

func _tick_impact_cooldowns(delta: float) -> void:
	for collider_id in impact_cooldowns.keys():
		var remaining: float = impact_cooldowns[collider_id] - delta
		if remaining <= 0.0:
			impact_cooldowns.erase(collider_id)
		else:
			impact_cooldowns[collider_id] = remaining

func _is_impact_on_cooldown(collider: Node) -> bool:
	return impact_cooldowns.has(collider.get_instance_id())
