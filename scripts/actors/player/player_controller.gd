extends CharacterBody2D

const ActorState = preload("res://scripts/core/actor_state.gd")

@export var tuning: Resource
var active_vehicle: Node = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_sensor: Area2D = $InteractionSensor

func _physics_process(_delta: float) -> void:
	if active_vehicle != null:
		velocity = Vector2.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_speed: float = 220.0 if tuning == null else tuning.move_speed
	velocity = input_vector * target_speed
	if input_vector != Vector2.ZERO:
		rotation = input_vector.angle()
	move_and_slide()

func is_in_vehicle() -> bool:
	return active_vehicle != null

func enter_vehicle(vehicle: Node2D) -> void:
	active_vehicle = vehicle
	visible = false
	collision_shape.disabled = true
	interaction_sensor.monitoring = false

func exit_vehicle(exit_position: Vector2) -> void:
	global_position = exit_position
	active_vehicle = null
	visible = true
	collision_shape.disabled = false
	interaction_sensor.monitoring = true

func get_state_name() -> String:
	return ActorState.DRIVING if is_in_vehicle() else ActorState.ON_FOOT
