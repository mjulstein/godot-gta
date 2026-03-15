extends CharacterBody2D

const ActorState = preload("res://scripts/core/actor_state.gd")

signal civilian_assaulted(target: Node2D)
signal vehicle_entry_completed(vehicle: Node2D)

@export var tuning: Resource
@export var collision_flash_time := 0.12
@export_range(20.0, 200.0, 1.0) var mass_kg := 80.0
var active_vehicle: Node = null
var collision_flash_remaining := 0.0
var impact_cooldowns: Dictionary = {}
var pending_entry_vehicle: Node2D
var pending_entry_position := Vector2.ZERO
var entry_collision_exception_vehicle: PhysicsBody2D

const VEHICLE_ENTRY_REACHED_DISTANCE := 10.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_sensor: Area2D = $InteractionSensor
@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	add_to_group("traffic_obstacle")
	add_to_group("traffic_dynamic_obstacle")
	add_to_group("player_actor")

func _physics_process(delta: float) -> void:
	collision_flash_remaining = maxf(0.0, collision_flash_remaining - delta)
	_tick_impact_cooldowns(delta)
	body_polygon.color = Color(1, 0.2, 0.2, 1) if collision_flash_remaining > 0.0 else Color(0.976471, 0.956863, 0.278431, 1)

	if active_vehicle != null:
		velocity = Vector2.ZERO
		return
	if _update_vehicle_entry_approach(delta):
		move_and_slide()
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target_speed: float = 220.0 if tuning == null else tuning.move_speed
	var target_velocity := input_vector * target_speed
	var acceleration_rate: float = 1320.0 if tuning == null else tuning.acceleration
	var deceleration_rate: float = 1460.0 if tuning == null else tuning.deceleration
	var carry_factor: float = 0.08 if tuning == null else tuning.direction_carry
	if input_vector != Vector2.ZERO:
		var carry_velocity := velocity * carry_factor
		var blended_target := target_velocity + carry_velocity
		if blended_target.length() > target_speed:
			blended_target = blended_target.normalized() * target_speed
		velocity = velocity.move_toward(blended_target, acceleration_rate * delta)
		rotation = blended_target.angle()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration_rate * delta)
	move_and_slide()
	if get_slide_collision_count() > 0:
		collision_flash_remaining = collision_flash_time
		_emit_civilian_impacts()

func is_in_vehicle() -> bool:
	return active_vehicle != null

func enter_vehicle(vehicle: Node2D) -> void:
	_clear_entry_collision_exception()
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
	_clear_entry_collision_exception()

func get_state_name() -> String:
	return ActorState.DRIVING if is_in_vehicle() else ActorState.ON_FOOT

func has_recent_collision() -> bool:
	return collision_flash_remaining > 0.0

func get_impact_velocity() -> Vector2:
	return velocity

func get_motion_debug_lines() -> PackedStringArray:
	return PackedStringArray([
		"On Foot %.1f kph" % (velocity.length() * 0.18),
		"Input model: %s" % ("entry assist" if pending_entry_vehicle != null else "direct"),
	])

func get_mass_kg() -> float:
	return mass_kg

func begin_vehicle_entry(vehicle: Node2D) -> void:
	if vehicle == null:
		return
	_set_entry_collision_exception(vehicle)
	pending_entry_vehicle = vehicle
	pending_entry_position = vehicle.get_driver_entry_position() if vehicle.has_method("get_driver_entry_position") else vehicle.global_position

func cancel_vehicle_entry() -> void:
	pending_entry_vehicle = null
	pending_entry_position = Vector2.ZERO
	_clear_entry_collision_exception()

func is_entering_vehicle() -> bool:
	return pending_entry_vehicle != null

func _emit_civilian_impacts() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider == null or not collider.is_in_group("civilian_pedestrian"):
			continue
		if _is_impact_on_cooldown(collider):
			continue
		impact_cooldowns[collider.get_instance_id()] = 0.6
		if collider.has_method("register_harm"):
			collider.register_harm(self)
		civilian_assaulted.emit(collider)

func _tick_impact_cooldowns(delta: float) -> void:
	for collider_id in impact_cooldowns.keys():
		var remaining: float = impact_cooldowns[collider_id] - delta
		if remaining <= 0.0:
			impact_cooldowns.erase(collider_id)
		else:
			impact_cooldowns[collider_id] = remaining

func _is_impact_on_cooldown(collider: Node) -> bool:
	return impact_cooldowns.has(collider.get_instance_id())

func _update_vehicle_entry_approach(delta: float) -> bool:
	if pending_entry_vehicle == null or not is_instance_valid(pending_entry_vehicle):
		cancel_vehicle_entry()
		return false
	if pending_entry_vehicle.has_method("can_enter") and not pending_entry_vehicle.can_enter():
		cancel_vehicle_entry()
		return false
	pending_entry_position = pending_entry_vehicle.get_driver_entry_position() if pending_entry_vehicle.has_method("get_driver_entry_position") else pending_entry_vehicle.global_position
	var to_entry := pending_entry_position - global_position
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector != Vector2.ZERO and to_entry != Vector2.ZERO:
		var input_alignment := input_vector.normalized().dot(to_entry.normalized())
		if input_alignment < 0.5:
			cancel_vehicle_entry()
			return false
	if to_entry.length() <= VEHICLE_ENTRY_REACHED_DISTANCE:
		velocity = Vector2.ZERO
		var vehicle := pending_entry_vehicle
		cancel_vehicle_entry()
		vehicle_entry_completed.emit(vehicle)
		return false
	var target_speed: float = 220.0 if tuning == null else tuning.move_speed
	var acceleration_rate: float = 1320.0 if tuning == null else tuning.acceleration
	velocity = velocity.move_toward(to_entry.normalized() * target_speed, acceleration_rate * delta)
	if velocity != Vector2.ZERO:
		rotation = velocity.angle()
	return true

func _set_entry_collision_exception(vehicle: Node2D) -> void:
	_clear_entry_collision_exception()
	if vehicle is PhysicsBody2D:
		entry_collision_exception_vehicle = vehicle as PhysicsBody2D
		add_collision_exception_with(entry_collision_exception_vehicle)

func _clear_entry_collision_exception() -> void:
	if entry_collision_exception_vehicle == null:
		return
	remove_collision_exception_with(entry_collision_exception_vehicle)
	entry_collision_exception_vehicle = null
