extends CharacterBody2D

@export var acceleration := 380.0
@export var brake_power := 440.0
@export var max_speed := 320.0
@export var steering_speed := 2.8
@export var friction := 220.0

var driver: Node = null

func _physics_process(delta: float) -> void:
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

func can_enter() -> bool:
	return driver == null

func set_driver(value: Node) -> void:
	driver = value

func clear_driver() -> void:
	driver = null

func get_exit_position() -> Vector2:
	return global_position + Vector2.DOWN.rotated(rotation) * 28.0
