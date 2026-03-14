extends CharacterBody2D

const ActorState = preload("res://scripts/core/actor_state.gd")

@export var tuning: Resource
@export var collision_flash_time := 0.12
var active_vehicle: Node = null
var collision_flash_remaining := 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_sensor: Area2D = $InteractionSensor
@onready var body_polygon: Polygon2D = $Body

func _physics_process(delta: float) -> void:
	collision_flash_remaining = maxf(0.0, collision_flash_remaining - delta)
	body_polygon.color = Color(1, 0.45, 0.35, 1) if collision_flash_remaining > 0.0 else Color(0.941176, 0.705882, 0.184314, 1)

	if active_vehicle != null:
		velocity = Vector2.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_speed: float = 220.0 if tuning == null else tuning.move_speed
	velocity = input_vector * target_speed
	if input_vector != Vector2.ZERO:
		rotation = input_vector.angle()
	move_and_slide()
	if get_slide_collision_count() > 0:
		collision_flash_remaining = collision_flash_time

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

func has_recent_collision() -> bool:
	return collision_flash_remaining > 0.0
