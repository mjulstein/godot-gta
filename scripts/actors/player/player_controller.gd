extends CharacterBody2D

@export var move_speed := 220.0
var active_vehicle: Node = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _physics_process(_delta: float) -> void:
	if active_vehicle != null:
		velocity = Vector2.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	if input_vector != Vector2.ZERO:
		rotation = input_vector.angle()
	move_and_slide()

func is_in_vehicle() -> bool:
	return active_vehicle != null

func enter_vehicle(vehicle: Node2D) -> void:
	active_vehicle = vehicle
	visible = false
	collision_shape.disabled = true

func exit_vehicle(exit_position: Vector2) -> void:
	global_position = exit_position
	active_vehicle = null
	visible = true
	collision_shape.disabled = false
