extends CharacterBody2D

const ActorState = preload("res://scripts/core/actor_state.gd")

signal civilian_assaulted(target: Node2D)
signal vehicle_entry_completed(vehicle: Node2D)
signal harmed(source: Node2D)
signal collision_feedback_requested(speed_loss: float)

@export var tuning: Resource
@export var collision_flash_time := 0.12
@export_range(20.0, 200.0, 1.0) var mass_kg := 80.0
@export_range(0.1, 3.0, 0.05) var knockout_hold_time := 0.85
var active_vehicle: Node = null
var collision_flash_remaining := 0.0
var impact_cooldowns: Dictionary = {}
var pending_entry_vehicle: Node2D
var pending_entry_position := Vector2.ZERO
var entry_collision_exception_vehicle: PhysicsBody2D
var default_collision_layer := 0
var default_collision_mask := 0
var impact_recovery_remaining := 0.0
var impact_collision_disable_remaining := 0.0
var impact_velocity := Vector2.ZERO
var knocked_out := false
var pending_harm_source: Node2D
var knockout_hold_remaining := 0.0
var knockout_input_released := false

const VEHICLE_ENTRY_REACHED_DISTANCE := 10.0
const KNOCKOUT_IMPACT_THRESHOLD := 12.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_sensor: Area2D = $InteractionSensor
@onready var body_polygon: Polygon2D = $Body

func _ready() -> void:
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	add_to_group("traffic_obstacle")
	add_to_group("traffic_dynamic_obstacle")
	add_to_group("pedestrian_actor")
	add_to_group("player_actor")

func _physics_process(delta: float) -> void:
	collision_flash_remaining = maxf(0.0, collision_flash_remaining - delta)
	impact_recovery_remaining = maxf(0.0, impact_recovery_remaining - delta)
	impact_collision_disable_remaining = maxf(0.0, impact_collision_disable_remaining - delta)
	knockout_hold_remaining = maxf(0.0, knockout_hold_remaining - delta)
	_tick_impact_cooldowns(delta)
	body_polygon.color = Color(1, 0.2, 0.2, 1) if collision_flash_remaining > 0.0 else Color(0.976471, 0.956863, 0.278431, 1)
	_update_impact_collision_state()

	if active_vehicle != null:
		velocity = Vector2.ZERO
		return
	if impact_recovery_remaining > 0.0 and impact_velocity.length() > 1.0:
		velocity = impact_velocity
		impact_velocity = impact_velocity.move_toward(Vector2.ZERO, 320.0 * delta)
		if velocity != Vector2.ZERO:
			rotation = velocity.angle()
		move_and_slide()
		_emit_vehicle_impacts()
		return
	if knocked_out:
		velocity = Vector2.ZERO
		if knockout_hold_remaining > 0.0:
			return
		var recovery_input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if recovery_input == Vector2.ZERO:
			knockout_input_released = true
			return
		if not knockout_input_released:
			return
		knocked_out = false
		knockout_hold_remaining = 0.0
		knockout_input_released = false
		pending_harm_source = null
	if _update_vehicle_entry_approach(delta):
		var entry_speed_before_move := velocity.length()
		move_and_slide()
		_emit_vehicle_impacts()
		if get_slide_collision_count() > 0:
			collision_flash_remaining = collision_flash_time
			collision_feedback_requested.emit(maxf(entry_speed_before_move - velocity.length(), 0.0))
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
	var speed_before_move := velocity.length()
	move_and_slide()
	_emit_vehicle_impacts()
	if get_slide_collision_count() > 0:
		collision_flash_remaining = collision_flash_time
		collision_feedback_requested.emit(maxf(speed_before_move - velocity.length(), 0.0))
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
		"Input model: %s" % ("knocked out" if knocked_out else "entry assist" if pending_entry_vehicle != null else "direct"),
	])

func get_mass_kg() -> float:
	return mass_kg

func is_knocked_out() -> bool:
	return knocked_out

func is_harm_settled() -> bool:
	return knocked_out and knockout_hold_remaining <= 0.0 and impact_recovery_remaining <= 0.0 and velocity.length() <= 1.0

func get_pending_harm_source() -> Node2D:
	return pending_harm_source

func register_harm(source: Node2D) -> void:
	collision_flash_remaining = collision_flash_time
	_apply_impact_response(source)
	harmed.emit(source)

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
		if collider == null or not collider.is_in_group("pedestrian_actor"):
			continue
		if _is_impact_on_cooldown(collider):
			continue
		impact_cooldowns[collider.get_instance_id()] = 0.6
		if collider.has_method("register_harm"):
			collider.register_harm(self)
		civilian_assaulted.emit(collider)

func _emit_vehicle_impacts() -> void:
	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider == null or not collider.is_in_group("traffic_vehicle"):
			continue
		if _is_impact_on_cooldown(collider):
			continue
		impact_cooldowns[collider.get_instance_id()] = 0.6
		register_harm(collider)
		if collider.has_method("begin_incident_stop"):
			collider.begin_incident_stop(self)

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

func _apply_impact_response(source: Node2D) -> void:
	if source == null or not source.has_method("get_impact_velocity"):
		return
	var source_velocity = source.call("get_impact_velocity")
	if not (source_velocity is Vector2):
		return
	var source_mass := 2000.0
	if source.has_method("get_mass_kg"):
		source_mass = source.get_mass_kg()
	var knockback: Vector2 = source_velocity * (source_mass / maxf(source_mass + mass_kg, 1.0))
	if knockback.length() < KNOCKOUT_IMPACT_THRESHOLD:
		return
	cancel_vehicle_entry()
	impact_velocity = knockback.limit_length(260.0)
	impact_recovery_remaining = 0.4
	impact_collision_disable_remaining = 0.25
	knocked_out = true
	knockout_hold_remaining = knockout_hold_time
	knockout_input_released = false
	pending_harm_source = source

func _update_impact_collision_state() -> void:
	var collisions_enabled := impact_collision_disable_remaining <= 0.0
	collision_layer = default_collision_layer if collisions_enabled else 0
	collision_mask = default_collision_mask if collisions_enabled else 0
	if collision_shape != null:
		collision_shape.disabled = not collisions_enabled
