extends CharacterBody2D

signal harmed(source: Node2D)

@export_enum("pedestrian", "traffic") var actor_type := "pedestrian"
@export var movement_axis := Vector2.RIGHT
@export_range(16.0, 240.0, 1.0) var patrol_distance := 72.0
@export_range(0.0, 240.0, 1.0) var move_speed := 52.0
@export_range(0.0, 4.0, 0.1) var pause_duration := 0.8
@export var harmed_flash_time := 0.45
@export_range(0.0, 600.0, 1.0) var impact_drag := 320.0
@export_range(0.0, 1.0, 0.05) var impact_recovery_time := 0.4
@export_range(0.0, 1.0, 0.05) var impact_collision_disable_time := 0.25
@export_range(20.0, 200.0, 1.0) var mass_kg := 80.0
@export_range(0.0, 120.0, 1.0) var social_look_radius := 42.0
@export_range(0.1, 10.0, 0.1) var social_turn_speed := 3.0
@export_range(0.0, 1.0, 0.05) var follow_moving_pedestrian_chance := 0.3
@export_range(0.0, 160.0, 1.0) var follow_moving_pedestrian_radius := 36.0
@export_range(16.0, 160.0, 1.0) var follow_moving_pedestrian_distance := 56.0
@export_range(0.0, 1.0, 0.05) var crossing_chance := 0.22
@export_range(8.0, 80.0, 1.0) var obstacle_probe_distance := 18.0
@export_range(0.0, 90.0, 1.0) var obstacle_probe_angle := 42.0
@export_range(0.0, 80.0, 1.0) var separation_radius := 18.0
@export_range(0.0, 2.0, 0.05) var separation_weight := 0.75
@export_range(8.0, 32.0, 1.0) var group_side_spacing := 10.0
@export_range(8.0, 32.0, 1.0) var group_trail_spacing := 12.0
@export_range(0.1, 20.0, 0.1) var steering_turn_speed := 7.5

var anchor_position := Vector2.ZERO
var direction := 1.0
var pause_remaining := 0.0
var harmed_flash_remaining := 0.0
var impact_recovery_remaining := 0.0
var impact_collision_disable_remaining := 0.0
var impact_velocity := Vector2.ZERO
var world_path_points := PackedVector2Array()
var path_target_index := 1
var path_direction := 1
var switch_to_local_roam_after_path := false
var local_roam_axis_after_path := Vector2.ZERO
var default_collision_layer := 0
var default_collision_mask := 0
var reclaim_vehicle: Node2D
var reclaim_delay_remaining := 0.0
var reclaim_attempt_active := false
var incident_vehicle: Node2D
var incident_target: Node2D
var incident_response_active := false
var incident_inspect_position := Vector2.ZERO
var impact_cooldowns: Dictionary = {}
var rng := RandomNumberGenerator.new()
var follow_retarget_cooldown := 0.0
var ambient_network: Array = []
var ambient_node_index := -1
var ambient_target_index := -1
var ambient_previous_index := -1
var ambient_group_id := -1
var ambient_group_slot := 0
var ambient_group_size := 1
var ambient_group_is_leader := true
var ambient_forward_direction := Vector2.RIGHT
var ambient_wait_remaining := 0.0

const RECLAIM_SPEED := 74.0
const RECLAIM_REACHED_DISTANCE := 10.0
const RECLAIM_VEHICLE_STOP_SPEED := 28.0
const INCIDENT_APPROACH_DISTANCE := 18.0
const INCIDENT_TARGET_STOP_SPEED := 18.0
const AMBIENT_REACHED_DISTANCE := 8.0
const AMBIENT_MIN_SPEED := 12.0
const DEFAULT_TILE_WORLD_SIZE := Vector2(1280, 1280)

@onready var body_polygon: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	anchor_position = global_position
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	movement_axis = movement_axis.normalized() if movement_axis != Vector2.ZERO else Vector2.RIGHT
	ambient_forward_direction = movement_axis
	rng.randomize()
	add_to_group("civilian")
	add_to_group("civilian_witness")
	if actor_type == "pedestrian":
		add_to_group("pedestrian_actor")
		add_to_group("civilian_pedestrian")
	else:
		add_to_group("civilian_vehicle")
	rotation = movement_axis.angle()

func _physics_process(delta: float) -> void:
	harmed_flash_remaining = maxf(0.0, harmed_flash_remaining - delta)
	impact_recovery_remaining = maxf(0.0, impact_recovery_remaining - delta)
	impact_collision_disable_remaining = maxf(0.0, impact_collision_disable_remaining - delta)
	reclaim_delay_remaining = maxf(0.0, reclaim_delay_remaining - delta)
	follow_retarget_cooldown = maxf(0.0, follow_retarget_cooldown - delta)
	ambient_wait_remaining = maxf(0.0, ambient_wait_remaining - delta)
	_tick_impact_cooldowns(delta)
	body_polygon.color = _get_body_color()
	_update_impact_collision_state()

	if impact_recovery_remaining > 0.0 and impact_velocity.length() > 1.0:
		velocity = impact_velocity
		impact_velocity = impact_velocity.move_toward(Vector2.ZERO, impact_drag * delta)
		if velocity != Vector2.ZERO:
			rotation = velocity.angle()
		move_and_slide()
		_emit_vehicle_impacts()
		return

	if _update_reclaim_attempt():
		if velocity == Vector2.ZERO:
			_update_social_facing(delta)
		move_and_slide()
		_emit_vehicle_impacts()
		return
	if _update_incident_response():
		if velocity == Vector2.ZERO:
			_update_social_facing(delta)
		move_and_slide()
		_emit_vehicle_impacts()
		return
	if _should_recycle_off_camera():
		queue_free()
		return
	if _update_group_follow():
		move_and_slide()
		return

	if pause_remaining > 0.0 or ambient_wait_remaining > 0.0:
		pause_remaining = maxf(0.0, pause_remaining - delta)
		velocity = Vector2.ZERO
		_try_follow_moving_pedestrian()
		_update_social_facing(delta)
		move_and_slide()
		_emit_vehicle_impacts()
		return

	if world_path_points.size() >= 2:
		_follow_world_path()
	elif _has_ambient_walk():
		_update_ambient_walk()
	else:
		_update_local_wander()

	if velocity == Vector2.ZERO:
		_update_social_facing(delta)
	move_and_slide()
	_emit_vehicle_impacts()

func set_world_path(points: PackedVector2Array) -> void:
	world_path_points = points
	if world_path_points.size() < 2:
		path_target_index = 0
		return

	var start_distance := global_position.distance_to(world_path_points[0])
	var end_distance := global_position.distance_to(world_path_points[world_path_points.size() - 1])
	path_direction = 1 if start_distance <= end_distance else -1
	path_target_index = world_path_points.size() - 1 if path_direction > 0 else 0

func configure_ambient_walk(network: Array, start_index: int, next_index: int = -1, group_id: int = -1, group_slot: int = 0, group_size: int = 1) -> void:
	ambient_network = network
	ambient_node_index = start_index
	ambient_previous_index = -1
	ambient_group_id = group_id
	ambient_group_slot = group_slot
	ambient_group_size = maxi(group_size, 1)
	ambient_group_is_leader = ambient_group_slot == 0
	ambient_target_index = next_index
	if ambient_target_index < 0:
		ambient_target_index = _pick_next_ambient_target(start_index, -1)
	if _is_valid_ambient_node(ambient_target_index):
		ambient_forward_direction = (_get_ambient_node_position(ambient_target_index) - _get_ambient_node_position(start_index)).normalized()
		if ambient_forward_direction == Vector2.ZERO:
			ambient_forward_direction = movement_axis
	world_path_points = PackedVector2Array()
	path_target_index = 0

func set_path_active(is_active: bool) -> void:
	visible = is_active
	set_physics_process(is_active)
	collision_layer = default_collision_layer if is_active else 0
	collision_mask = default_collision_mask if is_active else 0
	if collision_shape != null:
		collision_shape.disabled = not is_active
	if not is_active:
		velocity = Vector2.ZERO

func register_harm(source: Node2D) -> void:
	harmed_flash_remaining = harmed_flash_time
	pause_remaining = maxf(pause_remaining, 0.4)
	ambient_wait_remaining = 0.0
	_apply_impact_response(source)
	harmed.emit(source)

func place_displaced_occupant(spawn_position: Vector2, facing_direction: Vector2, escape_direction: Vector2) -> void:
	global_position = spawn_position
	anchor_position = spawn_position
	rotation = facing_direction.angle() if facing_direction != Vector2.ZERO else rotation
	var escape_vector := escape_direction.normalized() if escape_direction != Vector2.ZERO else Vector2.DOWN
	set_world_path(PackedVector2Array([
		spawn_position,
		spawn_position + escape_vector * 52.0,
	]))
	pause_remaining = 0.2

func place_incident_driver(spawn_position: Vector2, facing_direction: Vector2) -> void:
	global_position = spawn_position
	anchor_position = spawn_position
	rotation = facing_direction.angle() if facing_direction != Vector2.ZERO else rotation
	world_path_points = PackedVector2Array()
	path_target_index = 0
	pause_remaining = 0.0
	velocity = Vector2.ZERO

func place_parking_lot_driver(spawn_position: Vector2, sidewalk_position: Vector2, facing_direction: Vector2, roam_axis: Vector2) -> void:
	global_position = spawn_position
	anchor_position = sidewalk_position
	rotation = facing_direction.angle() if facing_direction != Vector2.ZERO else rotation
	switch_to_local_roam_after_path = true
	local_roam_axis_after_path = roam_axis.normalized() if roam_axis != Vector2.ZERO else movement_axis
	set_world_path(PackedVector2Array([
		spawn_position,
		sidewalk_position,
	]))
	pause_remaining = 0.0
	velocity = Vector2.ZERO

func configure_reclaim_attempt(target_vehicle: Node2D, should_attempt: bool) -> void:
	reclaim_vehicle = target_vehicle
	reclaim_attempt_active = should_attempt
	reclaim_delay_remaining = 0.75

func configure_incident_response(target_vehicle: Node2D, target_actor: Node2D, inspect_position: Vector2 = Vector2.ZERO) -> void:
	incident_vehicle = target_vehicle
	incident_target = target_actor
	incident_inspect_position = inspect_position
	incident_response_active = true
	reclaim_delay_remaining = 0.2

func get_mass_kg() -> float:
	return mass_kg

func get_impact_velocity() -> Vector2:
	return impact_velocity if impact_velocity.length() > 1.0 else velocity

func get_ambient_forward_direction() -> Vector2:
	if velocity.length() > 1.0:
		return velocity.normalized()
	return ambient_forward_direction

func is_harm_settled() -> bool:
	return impact_recovery_remaining <= 0.0 and impact_velocity.length() <= 1.0

func _follow_world_path() -> void:
	var target_position := world_path_points[path_target_index]
	var to_target := target_position - global_position
	if to_target.length() <= 6.0:
		if switch_to_local_roam_after_path and path_target_index == world_path_points.size() - 1:
			world_path_points = PackedVector2Array()
			path_target_index = 0
			path_direction = 1
			switch_to_local_roam_after_path = false
			movement_axis = local_roam_axis_after_path if local_roam_axis_after_path != Vector2.ZERO else movement_axis
			anchor_position = global_position
			velocity = Vector2.ZERO
			return
		if path_target_index == world_path_points.size() - 1:
			path_direction = -1
		elif path_target_index == 0:
			path_direction = 1
		path_target_index = clampi(path_target_index + path_direction, 0, world_path_points.size() - 1)
		target_position = world_path_points[path_target_index]
		to_target = target_position - global_position
	velocity = _compute_steered_velocity(to_target.normalized() if to_target.length() > 0.0 else Vector2.ZERO, -1.0, get_physics_process_delta_time())
	if actor_type == "traffic" and velocity != Vector2.ZERO and _has_pedestrian_ahead(velocity.normalized()):
		velocity = Vector2.ZERO
	_update_rotation_from_velocity()

func _update_local_wander() -> void:
	var target_position := anchor_position + movement_axis * patrol_distance * direction
	var to_target := target_position - global_position
	if to_target.length() <= 6.0:
		direction *= -1.0
		pause_remaining = pause_duration * rng.randf_range(0.7, 1.2)
		velocity = Vector2.ZERO
		return
	velocity = _compute_steered_velocity(to_target.normalized(), -1.0, get_physics_process_delta_time())
	ambient_forward_direction = velocity.normalized() if velocity != Vector2.ZERO else ambient_forward_direction
	_update_rotation_from_velocity()

func _update_ambient_walk() -> void:
	if not _is_valid_ambient_node(ambient_target_index):
		ambient_target_index = _pick_next_ambient_target(ambient_node_index, ambient_previous_index)
	if not _is_valid_ambient_node(ambient_target_index):
		velocity = Vector2.ZERO
		return
	var target_position := _get_ambient_node_position(ambient_target_index)
	var to_target := target_position - global_position
	if to_target.length() <= AMBIENT_REACHED_DISTANCE:
		ambient_previous_index = ambient_node_index
		ambient_node_index = ambient_target_index
		ambient_target_index = _pick_next_ambient_target(ambient_node_index, ambient_previous_index)
		if ambient_group_is_leader and rng.randf() < 0.16:
			ambient_wait_remaining = pause_duration * rng.randf_range(0.6, 1.5)
			velocity = Vector2.ZERO
			return
		if not _is_valid_ambient_node(ambient_target_index):
			velocity = Vector2.ZERO
			return
		target_position = _get_ambient_node_position(ambient_target_index)
		to_target = target_position - global_position
	velocity = _compute_steered_velocity(to_target.normalized() if to_target.length() > 0.0 else Vector2.ZERO, -1.0, get_physics_process_delta_time())
	ambient_forward_direction = velocity.normalized() if velocity.length() > 1.0 else ambient_forward_direction
	_update_rotation_from_velocity()

func _update_group_follow() -> bool:
	if ambient_group_id < 0 or ambient_group_slot <= 0:
		return false
	var leader := _find_ambient_group_leader()
	if leader == null:
		return false
	if leader.has_method("is_group_leader_waiting_for_crosswalk") and leader.is_group_leader_waiting_for_crosswalk():
		velocity = Vector2.ZERO
		ambient_forward_direction = leader.get_ambient_forward_direction() if leader.has_method("get_ambient_forward_direction") else ambient_forward_direction
		return true
	var leader_direction: Vector2 = leader.get_ambient_forward_direction() if leader.has_method("get_ambient_forward_direction") else leader.velocity.normalized()
	if leader_direction == Vector2.ZERO:
		leader_direction = ambient_forward_direction
	var target_position := leader.global_position + _get_group_slot_offset(ambient_group_slot, ambient_group_size, leader_direction)
	var to_target := target_position - global_position
	if to_target.length() <= 4.0:
		velocity = Vector2.ZERO
		ambient_forward_direction = leader_direction
		rotation = leader.rotation
		return true
	velocity = _compute_steered_velocity(to_target.normalized(), -1.0, get_physics_process_delta_time())
	ambient_forward_direction = velocity.normalized() if velocity.length() > 1.0 else leader_direction
	_update_rotation_from_velocity()
	return true

func _has_pedestrian_ahead(direction_vector: Vector2) -> bool:
	for candidate in get_tree().get_nodes_in_group("pedestrian_actor"):
		if candidate == self or not (candidate is Node2D):
			continue
		var pedestrian := candidate as Node2D
		var offset: Vector2 = pedestrian.global_position - global_position
		if offset.length() > 36.0:
			continue
		var forward_distance := direction_vector.dot(offset)
		if forward_distance <= 0.0:
			continue
		var lateral_distance := absf(direction_vector.orthogonal().dot(offset))
		if lateral_distance <= 18.0:
			return true
	return false

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
	if knockback.length() < 40.0:
		return
	impact_velocity = knockback.limit_length(260.0)
	impact_recovery_remaining = impact_recovery_time
	impact_collision_disable_remaining = impact_collision_disable_time

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

func _update_impact_collision_state() -> void:
	var collisions_enabled := impact_collision_disable_remaining <= 0.0
	collision_layer = default_collision_layer if collisions_enabled else 0
	collision_mask = default_collision_mask if collisions_enabled else 0
	if collision_shape != null:
		collision_shape.disabled = not collisions_enabled

func _update_reclaim_attempt() -> bool:
	if not reclaim_attempt_active:
		return false
	if reclaim_delay_remaining > 0.0:
		velocity = Vector2.ZERO
		return true
	if reclaim_vehicle == null or not is_instance_valid(reclaim_vehicle):
		reclaim_attempt_active = false
		return false
	var entry_position: Vector2 = reclaim_vehicle.get_driver_entry_position() if reclaim_vehicle.has_method("get_driver_entry_position") else reclaim_vehicle.global_position
	var to_entry: Vector2 = entry_position - global_position
	if to_entry.length() <= RECLAIM_REACHED_DISTANCE:
		velocity = Vector2.ZERO
		_attempt_vehicle_reclaim()
		return true
	velocity = _compute_steered_velocity(to_entry.normalized(), RECLAIM_SPEED, get_physics_process_delta_time())
	_update_rotation_from_velocity()
	return true

func _attempt_vehicle_reclaim() -> void:
	reclaim_attempt_active = false
	if reclaim_vehicle == null or not is_instance_valid(reclaim_vehicle):
		return
	if not reclaim_vehicle.has_method("has_driver") or not reclaim_vehicle.has_driver():
		return
	if not reclaim_vehicle.has_method("is_player_controlled") or not reclaim_vehicle.is_player_controlled():
		return
	var vehicle_speed := 0.0
	if reclaim_vehicle.has_method("get_impact_velocity"):
		vehicle_speed = reclaim_vehicle.get_impact_velocity().length()
	if vehicle_speed > RECLAIM_VEHICLE_STOP_SPEED:
		return
	var player_actor := get_tree().get_first_node_in_group("player_actor")
	if player_actor == null or not player_actor.is_in_vehicle():
		return
	if player_actor.active_vehicle != reclaim_vehicle:
		return
	if reclaim_vehicle.has_method("resume_civilian_control"):
		reclaim_vehicle.resume_civilian_control()
	else:
		reclaim_vehicle.clear_driver()
	player_actor.exit_vehicle(reclaim_vehicle.get_exit_position())
	queue_free()

func _update_incident_response() -> bool:
	if not incident_response_active:
		return false
	if reclaim_delay_remaining > 0.0:
		velocity = Vector2.ZERO
		return true
	if incident_vehicle == null or not is_instance_valid(incident_vehicle):
		incident_response_active = false
		return false
	var target_position := global_position
	if incident_target != null and is_instance_valid(incident_target):
		var target_velocity := Vector2.ZERO
		if incident_target.has_method("get_impact_velocity"):
			target_velocity = incident_target.get_impact_velocity()
		var toward_vehicle := incident_vehicle.global_position - incident_target.global_position
		var target_moving_to_vehicle := toward_vehicle != Vector2.ZERO and target_velocity.dot(toward_vehicle.normalized()) > INCIDENT_TARGET_STOP_SPEED
		if target_velocity.length() <= INCIDENT_TARGET_STOP_SPEED or target_moving_to_vehicle:
			var offset_direction := (global_position - incident_target.global_position).normalized()
			if offset_direction == Vector2.ZERO:
				offset_direction = Vector2.LEFT
			target_position = incident_target.global_position + offset_direction * INCIDENT_APPROACH_DISTANCE
		else:
			target_position = incident_vehicle.get_driver_entry_position() if incident_vehicle.has_method("get_driver_entry_position") else incident_vehicle.global_position
	else:
		target_position = incident_inspect_position if incident_inspect_position != Vector2.ZERO else incident_vehicle.global_position
	var to_target := target_position - global_position
	if to_target.length() <= RECLAIM_REACHED_DISTANCE:
		velocity = Vector2.ZERO
		return true
	velocity = _compute_steered_velocity(to_target.normalized(), RECLAIM_SPEED, get_physics_process_delta_time())
	_update_rotation_from_velocity()
	return true

func _get_body_color() -> Color:
	if harmed_flash_remaining > 0.0:
		return Color(1, 0.2, 0.2, 1)
	if actor_type == "pedestrian":
		return Color(0.152941, 0.921569, 0.282353, 1)
	return Color(0.105882, 0.760784, 1, 1)

func _try_follow_moving_pedestrian() -> void:
	if actor_type != "pedestrian" or follow_retarget_cooldown > 0.0 or ambient_group_slot > 0:
		return
	var moving_pedestrian := _find_moving_pedestrian_to_follow()
	if moving_pedestrian == null:
		return
	if rng.randf() > follow_moving_pedestrian_chance:
		follow_retarget_cooldown = 1.2
		return
	var leader_velocity: Vector2 = moving_pedestrian.get_impact_velocity() if moving_pedestrian.has_method("get_impact_velocity") else moving_pedestrian.velocity
	if leader_velocity == Vector2.ZERO:
		return
	var follow_direction := leader_velocity.normalized()
	set_world_path(PackedVector2Array([
		global_position,
		global_position + follow_direction * follow_moving_pedestrian_distance,
	]))
	pause_remaining = 0.0
	follow_retarget_cooldown = 1.8

func _find_moving_pedestrian_to_follow() -> Node2D:
	var best_target: Node2D
	var best_distance := follow_moving_pedestrian_radius
	for candidate in get_tree().get_nodes_in_group("civilian_pedestrian"):
		if candidate == self or not (candidate is Node2D):
			continue
		var pedestrian := candidate as Node2D
		if not pedestrian.visible:
			continue
		var candidate_velocity: Vector2 = pedestrian.get_impact_velocity() if pedestrian.has_method("get_impact_velocity") else pedestrian.velocity
		if not (candidate_velocity is Vector2) or candidate_velocity.length() < 12.0:
			continue
		var distance := global_position.distance_to(pedestrian.global_position)
		if distance > best_distance:
			continue
		best_distance = distance
		best_target = pedestrian
	return best_target

func _update_social_facing(delta: float) -> void:
	if actor_type != "pedestrian":
		return
	var nearby_pedestrian := _find_idle_social_target()
	if nearby_pedestrian == null:
		return
	var to_target := nearby_pedestrian.global_position - global_position
	if to_target == Vector2.ZERO:
		return
	rotation = rotate_toward(rotation, to_target.angle(), social_turn_speed * delta)

func _find_idle_social_target() -> Node2D:
	var best_target: Node2D
	var best_distance := social_look_radius
	for candidate in get_tree().get_nodes_in_group("civilian_pedestrian"):
		if candidate == self or not (candidate is Node2D):
			continue
		var pedestrian := candidate as Node2D
		if not pedestrian.visible:
			continue
		if pedestrian.has_method("get_impact_velocity") and pedestrian.get_impact_velocity().length() > 1.0:
			continue
		var distance := global_position.distance_to(pedestrian.global_position)
		if distance > best_distance:
			continue
		best_distance = distance
		best_target = pedestrian
	return best_target

func _has_ambient_walk() -> bool:
	return ambient_network.size() > 0 and ambient_node_index >= 0

func is_group_leader_waiting_for_crosswalk() -> bool:
	if not ambient_group_is_leader:
		return false
	return ambient_wait_remaining > 0.0 and _ambient_node_has_crosswalk(ambient_node_index)

func _pick_next_ambient_target(from_index: int, previous_index: int) -> int:
	if not _is_valid_ambient_node(from_index):
		return -1
	var node: Dictionary = ambient_network[from_index]
	var crosswalk_candidates: PackedInt32Array = node.get("crosswalk_neighbors", PackedInt32Array())
	if crosswalk_candidates.size() > 0 and rng.randf() < crossing_chance:
		var crosswalk_pick := _pick_ambient_neighbor(crosswalk_candidates, previous_index)
		if crosswalk_pick >= 0:
			return crosswalk_pick
	var neighbors: PackedInt32Array = node.get("neighbors", PackedInt32Array())
	return _pick_ambient_neighbor(neighbors, previous_index)

func _pick_ambient_neighbor(candidates: PackedInt32Array, previous_index: int) -> int:
	if candidates.is_empty():
		return -1
	var fallback := -1
	for index in candidates:
		if not _is_valid_ambient_node(index):
			continue
		if fallback < 0:
			fallback = index
		if index != previous_index:
			return index
	return fallback

func _find_ambient_group_leader() -> CharacterBody2D:
	for candidate in get_tree().get_nodes_in_group("civilian_pedestrian"):
		if candidate == self or not (candidate is CharacterBody2D):
			continue
		if candidate.get("ambient_group_id") != ambient_group_id:
			continue
		if candidate.get("ambient_group_slot") != 0:
			continue
		return candidate
	return null

func _get_group_slot_offset(slot: int, group_size: int, forward_direction: Vector2) -> Vector2:
	var forward := forward_direction.normalized() if forward_direction != Vector2.ZERO else Vector2.RIGHT
	var side := forward.orthogonal()
	if group_size <= 1:
		return Vector2.ZERO
	if group_size > 3:
		return -forward * group_trail_spacing * float(slot)
	if group_size == 2:
		return side * (-group_side_spacing if slot == 0 else group_side_spacing)
	if slot == 0:
		return side * -group_side_spacing
	if slot == 1:
		return side * group_side_spacing
	return -forward * group_trail_spacing

func _compute_steered_velocity(desired_direction: Vector2, speed_override: float = -1.0, delta: float = 0.016) -> Vector2:
	if desired_direction == Vector2.ZERO:
		return Vector2.ZERO
	var speed := move_speed if speed_override < 0.0 else speed_override
	var steering_direction := desired_direction.normalized()
	steering_direction += _get_separation_force() * separation_weight
	if steering_direction == Vector2.ZERO:
		steering_direction = desired_direction.normalized()
	steering_direction = steering_direction.normalized()
	if _is_probe_blocked(steering_direction):
		var angle_offset := deg_to_rad(obstacle_probe_angle)
		for sign in [1.0, -1.0, 2.0, -2.0]:
			var candidate_direction := steering_direction.rotated(angle_offset * sign).normalized()
			if not _is_probe_blocked(candidate_direction):
				steering_direction = candidate_direction
				speed = maxf(speed * 0.8, AMBIENT_MIN_SPEED)
				break
	var smoothed_direction := _smooth_steering_direction(steering_direction, delta)
	if smoothed_direction == Vector2.ZERO:
		return Vector2.ZERO
	return smoothed_direction * speed

func _smooth_steering_direction(target_direction: Vector2, delta: float) -> Vector2:
	if target_direction == Vector2.ZERO:
		return Vector2.ZERO
	var current_direction := velocity.normalized() if velocity.length() > 1.0 else ambient_forward_direction
	if current_direction == Vector2.ZERO:
		return target_direction.normalized()
	var current_angle := current_direction.angle()
	var target_angle := target_direction.angle()
	var next_angle := rotate_toward(current_angle, target_angle, steering_turn_speed * delta)
	return Vector2.from_angle(next_angle).normalized()

func _get_separation_force() -> Vector2:
	var separation := Vector2.ZERO
	for group_name in ["pedestrian_actor", "traffic_vehicle"]:
		for candidate in get_tree().get_nodes_in_group(group_name):
			if candidate == self or not (candidate is Node2D):
				continue
			var body := candidate as Node2D
			var offset := global_position - body.global_position
			var distance := offset.length()
			if distance <= 0.0 or distance > separation_radius:
				continue
			separation += offset.normalized() * ((separation_radius - distance) / separation_radius)
	return separation

func _is_probe_blocked(direction_vector: Vector2) -> bool:
	if direction_vector == Vector2.ZERO:
		return false
	return test_move(global_transform, direction_vector.normalized() * obstacle_probe_distance)

func _update_rotation_from_velocity() -> void:
	if velocity != Vector2.ZERO:
		rotation = velocity.angle()

func _is_valid_ambient_node(index: int) -> bool:
	return index >= 0 and index < ambient_network.size()

func _get_ambient_node_position(index: int) -> Vector2:
	if not _is_valid_ambient_node(index):
		return global_position
	return ambient_network[index].get("position", global_position)

func _ambient_node_has_crosswalk(index: int) -> bool:
	if not _is_valid_ambient_node(index):
		return false
	var node: Dictionary = ambient_network[index]
	var crosswalk_neighbors: PackedInt32Array = node.get("crosswalk_neighbors", PackedInt32Array())
	return not crosswalk_neighbors.is_empty()

func _should_recycle_off_camera() -> bool:
	if actor_type != "pedestrian":
		return false
	if reclaim_attempt_active or incident_response_active:
		return false
	if harmed_flash_remaining > 0.0 or impact_recovery_remaining > 0.0:
		return false
	var active_cameras := _get_active_cameras()
	if active_cameras.is_empty():
		return false
	var recycle_margin := _current_tile_world_size() * 2.0
	for camera_node in active_cameras:
		if _is_within_camera_bounds(camera_node, recycle_margin):
			return false
	return true

func _current_tile_world_size() -> Vector2:
	var current_tile := _find_district_tile(global_position)
	if current_tile != null:
		var configured_size = current_tile.get("tile_world_size")
		if configured_size is Vector2:
			return configured_size
	return DEFAULT_TILE_WORLD_SIZE

func _find_district_tile(position: Vector2) -> Node2D:
	var closest_tile: Node2D
	var closest_distance := INF
	for candidate in get_tree().get_nodes_in_group("district_tile"):
		if not (candidate is Node2D):
			continue
		var tile := candidate as Node2D
		var tile_size = tile.get("tile_world_size")
		if not (tile_size is Vector2):
			continue
		var tile_rect := Rect2(tile.global_position - tile_size * 0.5, tile_size)
		if tile_rect.has_point(position):
			return tile
		var distance := tile.global_position.distance_to(position)
		if distance >= closest_distance:
			continue
		closest_distance = distance
		closest_tile = tile
	return closest_tile

func _get_active_cameras() -> Array[Camera2D]:
	var cameras: Array[Camera2D] = []
	for candidate in get_tree().get_nodes_in_group("runtime_camera"):
		if not (candidate is Camera2D):
			continue
		var camera_node := candidate as Camera2D
		if not camera_node.is_inside_tree() or not camera_node.enabled:
			continue
		cameras.append(camera_node)
	return cameras

func _is_within_camera_bounds(camera_node: Camera2D, margin: Vector2) -> bool:
	var viewport_size := camera_node.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return false
	var half_visible := Vector2(
		viewport_size.x / maxf(camera_node.zoom.x, 0.001),
		viewport_size.y / maxf(camera_node.zoom.y, 0.001)
	) * 0.5
	var bounds := Rect2(camera_node.global_position - half_visible - margin, half_visible * 2.0 + margin * 2.0)
	return bounds.has_point(global_position)
