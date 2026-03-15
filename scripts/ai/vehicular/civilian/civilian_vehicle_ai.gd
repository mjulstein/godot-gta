extends CharacterBody2D

const CivilianVehicleTuning = preload("res://scripts/ai/vehicular/civilian/civilian_vehicle_tuning.gd")

signal harmed(source: Node2D)
signal civilian_hit(target: Node2D)

@export var tuning: CivilianVehicleTuning
@export var is_important := false
@export_range(500.0, 4000.0, 1.0) var mass_kg := 2000.0
@export_range(24.0, 320.0, 1.0) var move_speed := 120.0
@export_range(24.0, 120.0, 1.0) var vehicle_look_ahead := 54.0
@export_range(24.0, 160.0, 1.0) var police_look_ahead := 120.0
@export_range(24.0, 96.0, 1.0) var pedestrian_look_ahead := 44.0
@export_range(24.0, 144.0, 1.0) var obstacle_look_ahead := 84.0
@export_range(8.0, 64.0, 1.0) var vehicle_stop_buffer := 22.0
@export_range(8.0, 64.0, 1.0) var pedestrian_stop_buffer := 22.0
@export_range(8.0, 64.0, 1.0) var dynamic_obstacle_stop_buffer := 22.0
@export_range(16.0, 128.0, 1.0) var police_stop_buffer := 88.0
@export_range(16.0, 96.0, 1.0) var barrier_stop_buffer := 48.0
@export_range(0.2, 8.0, 0.1) var blockage_threshold := 1.25
@export_range(0.2, 8.0, 0.1) var recovery_cooldown := 1.0
@export_range(0.2, 6.0, 0.1) var reroute_focus_time := 2.5
@export var harmed_flash_time := 0.45
@export_range(0.0, 2.0, 0.05) var respawn_pause := 0.35
@export_range(0.0, 4.0, 0.05) var recycle_check_interval := 0.5

var harmed_flash_remaining := 0.0
var pause_remaining := 0.0
var world_path_points := PackedVector2Array()
var path_target_index := 1
var default_collision_layer := 0
var default_collision_mask := 0
var camera_tracking_count := 0
var active_action := "straight"
var heading := "east"
var lane := "right"
var district_tiles: Array[Node2D] = []
var recycle_check_remaining := 0.0
var rng := RandomNumberGenerator.new()
var blockage_time := 0.0
var recovery_cooldown_remaining := 0.0
var reroute_focus_remaining := 0.0
var last_vehicle_ahead_distance := -1.0
var last_police_ahead_distance := -1.0
var last_pedestrian_ahead_distance := -1.0
var last_dynamic_obstacle_ahead_distance := -1.0
var last_barrier_ahead_distance := -1.0
var recent_tiles: Array[Vector2] = []
var current_speed := 0.0
var theft_reported := false
var impact_cooldowns: Dictionary = {}
var occupant_present := true
var driver: Node = null
var longitudinal_speed := 0.0
var last_player_ahead_distance := -1.0
var collision_flash_remaining := 0.0
var abandoned_after_theft := false

const ROAD_HALF_WIDTH := 96.0
const INNER_LANE_OFFSET := 28.0
const OUTER_LANE_OFFSET := 68.0
const TRAFFIC_CAR_LENGTH := 32.0
const CROSSWALK_CLEAR_OFFSET := 120.0
const INTERSECTION_ENTRY_OFFSET := 76.0
const LEFT_TURN_ENTRY_OFFSET := 32.0
const LEFT_TURN_START_OFFSET := 44.0
const SPAWN_ENTRY_OFFSET := 180.0
const ROUTE_SAMPLE_STEP := 24.0
const TURN_ARC_STEPS := 6
const MIN_ROTATION_DISTANCE := 0.5
const RECENT_TILE_MEMORY := 6
const ROUTE_LOOKAHEAD_DEPTH := 3
const RECENT_TILE_PENALTY := 10
const UTURN_PENALTY := 3
const RECYCLE_SPAWN_CLEARANCE := 56.0

@onready var body_polygon: Polygon2D = $Body
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	default_collision_layer = collision_layer
	default_collision_mask = collision_mask
	rng.randomize()
	current_speed = _target_speed_for_action(active_action)
	longitudinal_speed = Vector2.RIGHT.rotated(rotation).dot(velocity)
	add_to_group("civilian")
	add_to_group("civilian_vehicle")
	add_to_group("civilian_witness")
	add_to_group("traffic_vehicle")

func _physics_process(delta: float) -> void:
	harmed_flash_remaining = maxf(0.0, harmed_flash_remaining - delta)
	collision_flash_remaining = maxf(0.0, collision_flash_remaining - delta)
	pause_remaining = maxf(0.0, pause_remaining - delta)
	recycle_check_remaining = maxf(0.0, recycle_check_remaining - delta)
	recovery_cooldown_remaining = maxf(0.0, recovery_cooldown_remaining - delta)
	reroute_focus_remaining = maxf(0.0, reroute_focus_remaining - delta)
	_tick_impact_cooldowns(delta)
	body_polygon.color = _get_body_color()

	if driver != null:
		_drive_player_controlled(delta)
		return

	if abandoned_after_theft:
		current_speed = 0.0
		longitudinal_speed = 0.0
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if recycle_check_remaining == 0.0:
		recycle_check_remaining = recycle_check_interval
		if _should_recycle_off_camera():
			_recycle_to_new_route()
			return

	if pause_remaining > 0.0 or world_path_points.size() < 2:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var previous_position := global_position
	_follow_world_path()
	move_and_slide()
	_update_rotation_from_motion(previous_position)
	if get_slide_collision_count() > 0:
		collision_flash_remaining = harmed_flash_time
		_emit_civilian_impacts()

func initialize_runtime_spawn(initial_heading: String, initial_lane: String, initial_action: String = "straight") -> void:
	heading = initial_heading if not initial_heading.is_empty() else heading
	lane = initial_lane
	active_action = initial_action if not initial_action.is_empty() else active_action
	var spawn_tile: Node2D = null
	var spawn_data := _pick_spawn(initial_heading, initial_lane)
	if spawn_data.is_empty():
		var tile := _find_district_tile(global_position)
		if tile == null:
			return
		spawn_tile = tile
		global_position = _spawn_point(tile, heading, lane)
	else:
		var tile := spawn_data["tile"] as Node2D
		spawn_tile = tile
		heading = spawn_data.get("heading", heading)
		lane = spawn_data.get("lane", lane)
		global_position = _spawn_point(tile, heading, lane)
	rotation = _forward_vector_for_heading(heading).angle()
	velocity = _forward_vector_for_heading(heading) * _spawn_speed()
	current_speed = _spawn_speed()
	pause_remaining = 0.0
	recent_tiles.clear()
	if spawn_tile != null:
		var forced_action := active_action if _available_actions_for(spawn_tile, heading, lane).has(active_action) else ""
		_build_segment_for_tile(spawn_tile, forced_action)

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
	harmed.emit(source)

func can_enter() -> bool:
	return driver == null

func has_civilian_occupant() -> bool:
	return occupant_present

func consume_civilian_occupant() -> void:
	occupant_present = false

func set_driver(value: Node) -> void:
	driver = value
	occupant_present = false
	if value != null and value.is_in_group("player_actor"):
		abandoned_after_theft = true

func clear_driver() -> void:
	driver = null
	longitudinal_speed = 0.0
	current_speed = 0.0
	velocity = Vector2.ZERO

func resume_civilian_control() -> void:
	abandoned_after_theft = false
	driver = null
	pause_remaining = 0.25

func has_recent_collision() -> bool:
	return collision_flash_remaining > 0.0 or harmed_flash_remaining > 0.0

func get_exit_position() -> Vector2:
	return global_position + Vector2.DOWN.rotated(rotation) * 28.0

func get_driver_entry_position() -> Vector2:
	var driver_side := -Vector2.RIGHT.rotated(rotation).orthogonal()
	return global_position + driver_side * 20.0

func mark_theft_reported() -> void:
	theft_reported = true

func was_theft_reported() -> bool:
	return theft_reported

func has_driver() -> bool:
	return driver != null

func is_player_controlled() -> bool:
	return driver != null and driver.is_in_group("player_actor")

func get_impact_velocity() -> Vector2:
	return velocity

func get_mass_kg() -> float:
	return mass_kg

func get_motion_debug_lines() -> PackedStringArray:
	var target_speed := _target_speed_for_action(active_action)
	var blocker := "clear"
	if last_barrier_ahead_distance >= 0.0:
		blocker = "barrier %.0f" % last_barrier_ahead_distance
	elif last_dynamic_obstacle_ahead_distance >= 0.0:
		blocker = "dynamic %.0f" % last_dynamic_obstacle_ahead_distance
	elif last_player_ahead_distance >= 0.0:
		blocker = "player %.0f" % last_player_ahead_distance
	elif last_pedestrian_ahead_distance >= 0.0:
		blocker = "ped %.0f" % last_pedestrian_ahead_distance
	elif last_vehicle_ahead_distance >= 0.0:
		blocker = "car %.0f" % last_vehicle_ahead_distance
	return PackedStringArray([
		"%s lane %s" % [heading, lane],
		"Action %s%s" % [active_action, " reroute" if is_rerouting() else ""],
		"Speed %.1f / %.1f kph" % [current_speed * 0.18, target_speed * 0.18],
		"Blocker: %s" % blocker,
		"Driver: %s" % ("player" if driver != null else "ai"),
	])

func set_camera_tracked(is_tracked: bool) -> void:
	camera_tracking_count += 1 if is_tracked else -1
	camera_tracking_count = maxi(0, camera_tracking_count)

func is_camera_tracked() -> bool:
	return camera_tracking_count > 0

func is_rerouting() -> bool:
	return reroute_focus_remaining > 0.0

func _follow_world_path() -> void:
	_refresh_path_target()
	var target_position := world_path_points[path_target_index]
	var to_target := target_position - global_position

	var direction_vector := to_target.normalized() if to_target.length() > 0.0 else Vector2.ZERO
	current_speed = move_toward(
		current_speed,
		_target_speed_for_action(active_action),
		_acceleration_rate() * get_physics_process_delta_time()
	)
	velocity = direction_vector * current_speed
	var is_blocked := false
	if direction_vector != Vector2.ZERO:
		_displace_pedestrians_ahead(direction_vector)
		is_blocked = _should_stop_for_obstacle(direction_vector)
		if _should_hold_for_intersection_obstacle(direction_vector):
			var hold_point := _current_intersection_hold_point()
			var to_hold := hold_point - global_position
			if to_hold.length() > 8.0:
				current_speed = move_toward(current_speed, _turn_speed(), _brake_rate() * get_physics_process_delta_time())
				velocity = to_hold.normalized() * current_speed
				return
		if _should_immediately_switch_for_barrier():
			velocity = Vector2.ZERO
			if _attempt_barrier_lane_switch():
				blockage_time = 0.0
				recovery_cooldown_remaining = recovery_cooldown
				return
	if is_blocked:
		velocity = Vector2.ZERO
		current_speed = move_toward(current_speed, 0.0, _brake_rate() * get_physics_process_delta_time())
		blockage_time += get_physics_process_delta_time()
		if blockage_time >= blockage_threshold and recovery_cooldown_remaining == 0.0 and _can_attempt_blockage_recovery() and _attempt_blockage_recovery():
			blockage_time = 0.0
			recovery_cooldown_remaining = recovery_cooldown
			return
	else:
		blockage_time = 0.0

func _update_rotation_from_motion(previous_position: Vector2) -> void:
	var displacement := global_position - previous_position
	if displacement.length() < MIN_ROTATION_DISTANCE:
		return
	rotation = displacement.angle()

func _refresh_path_target() -> void:
	var iterations := 0
	while iterations < world_path_points.size():
		var target_position := world_path_points[path_target_index]
		var to_target := target_position - global_position
		if to_target.length() <= 10.0:
			_advance_path_target()
			iterations += 1
			continue
		if _is_target_behind_vehicle(to_target):
			_advance_path_target()
			iterations += 1
			continue
		break

func _advance_path_target() -> void:
	path_target_index += 1
	if path_target_index < world_path_points.size():
		return
	if _build_runtime_segment():
		return
	if is_camera_tracked():
		velocity = Vector2.ZERO
		path_target_index = max(0, world_path_points.size() - 1)
		return
	if _should_recycle_off_camera():
		_recycle_to_new_route()
		return
	velocity = Vector2.ZERO
	path_target_index = max(0, world_path_points.size() - 1)

func _should_recycle_off_camera() -> bool:
	if is_important:
		return false
	var active_cameras := _get_active_cameras()
	if active_cameras.is_empty():
		return false
	var current_tile := _find_district_tile(global_position)
	var tile_size := Vector2(1280, 1280)
	if current_tile != null:
		var configured_size = current_tile.get("tile_world_size")
		if configured_size is Vector2:
			tile_size = configured_size
	var recycle_margin := tile_size
	for camera_node in active_cameras:
		if _is_within_camera_bounds(camera_node, recycle_margin):
			return false
	return true

func _recycle_to_new_route() -> void:
	var next_spawn := _pick_spawn()
	if next_spawn.is_empty():
		return
	var tile := next_spawn["tile"] as Node2D
	heading = next_spawn["heading"]
	lane = next_spawn["lane"]
	global_position = _spawn_point(tile, heading, lane)
	rotation = _forward_vector_for_heading(heading).angle()
	velocity = Vector2.ZERO
	current_speed = 0.0
	pause_remaining = respawn_pause
	recent_tiles.clear()
	_build_runtime_segment()

func _pick_spawn(preferred_heading: String = "", preferred_lane: String = "") -> Dictionary:
	if district_tiles.is_empty():
		district_tiles = _collect_district_tiles(get_tree().root)
	var current_tile := _find_district_tile(global_position)
	var candidates: Array[Dictionary] = []
	for tile in district_tiles:
		if tile == current_tile:
			continue
		if _tile_is_within_any_camera(tile):
			continue
		for spawn_heading in ["east", "west", "north", "south"]:
			if not preferred_heading.is_empty() and spawn_heading != preferred_heading:
				continue
			if not _tile_open(tile, _entry_side_for_heading(spawn_heading)):
				continue
			for spawn_lane in ["left", "right"]:
				if not preferred_lane.is_empty() and spawn_lane != preferred_lane:
					continue
				if _available_actions_for(tile, spawn_heading, spawn_lane).is_empty():
					continue
				if not _recycle_spawn_is_clear(tile, spawn_heading, spawn_lane):
					continue
				candidates.append({
					"tile": tile,
					"heading": spawn_heading,
					"lane": spawn_lane,
				})
	if candidates.is_empty() and (not preferred_heading.is_empty() or not preferred_lane.is_empty()):
		return _pick_spawn()
	if candidates.is_empty():
		return {}
	return candidates[rng.randi_range(0, candidates.size() - 1)]

func _recycle_spawn_is_clear(tile: Node2D, spawn_heading: String, spawn_lane: String) -> bool:
	var candidate_spawn := _spawn_point(tile, spawn_heading, spawn_lane)
	var forward := _forward_vector_for_heading(spawn_heading)
	for candidate in get_tree().get_nodes_in_group("traffic_vehicle"):
		if candidate == self or not (candidate is Node2D):
			continue
		var vehicle := candidate as Node2D
		if not vehicle.visible:
			continue
		var offset := vehicle.global_position - candidate_spawn
		if offset.length() <= RECYCLE_SPAWN_CLEARANCE:
			return false
		var forward_distance := forward.dot(offset)
		if forward_distance < -RECYCLE_SPAWN_CLEARANCE * 0.5 or forward_distance > RECYCLE_SPAWN_CLEARANCE * 2.0:
			continue
		var lateral_distance := absf(forward.orthogonal().dot(offset))
		if lateral_distance > vehicle_stop_buffer * 1.5:
			continue
		return false
	return true

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

func _tile_is_within_any_camera(tile: Node2D) -> bool:
	var active_cameras := _get_active_cameras()
	if active_cameras.is_empty():
		return false
	var tile_size = tile.get("tile_world_size")
	if not (tile_size is Vector2):
		return false
	var margin: Vector2 = tile_size
	for camera_node in active_cameras:
		if _tile_within_camera_bounds(tile, camera_node, margin):
			return true
	return false

func _get_active_cameras() -> Array[Camera2D]:
	var cameras: Array[Camera2D] = []
	for candidate in get_tree().get_nodes_in_group("runtime_camera"):
		if not (candidate is Camera2D):
			continue
		var camera_node := candidate as Camera2D
		if not camera_node.is_inside_tree():
			continue
		if not camera_node.enabled:
			continue
		cameras.append(camera_node)
	return cameras

func _tile_within_camera_bounds(tile: Node2D, camera_node: Camera2D, margin: Vector2) -> bool:
	var viewport_size := camera_node.get_viewport_rect().size
	if viewport_size == Vector2.ZERO:
		return false
	var half_visible := Vector2(
		viewport_size.x / maxf(camera_node.zoom.x, 0.001),
		viewport_size.y / maxf(camera_node.zoom.y, 0.001)
	) * 0.5
	var bounds := Rect2(camera_node.global_position - half_visible - margin, half_visible * 2.0 + margin * 2.0)
	var tile_size: Vector2 = tile.get("tile_world_size")
	var tile_rect := Rect2(tile.global_position - tile_size * 0.5, tile_size)
	return bounds.intersects(tile_rect)

func _is_target_behind_vehicle(to_target: Vector2) -> bool:
	if to_target == Vector2.ZERO:
		return false
	var forward := Vector2.RIGHT.rotated(rotation)
	if forward == Vector2.ZERO:
		return false
	return forward.dot(to_target.normalized()) < -0.2

func has_persistent_blockage() -> bool:
	return blockage_time >= blockage_threshold

func _should_stop_for_obstacle(direction_vector: Vector2) -> bool:
	last_barrier_ahead_distance = _nearest_forward_distance("traffic_barrier", direction_vector, obstacle_look_ahead, 28.0)
	if last_barrier_ahead_distance >= 0.0 and last_barrier_ahead_distance <= barrier_stop_buffer:
		return true
	last_dynamic_obstacle_ahead_distance = _nearest_forward_distance("traffic_dynamic_obstacle", direction_vector, obstacle_look_ahead, 24.0)
	if last_dynamic_obstacle_ahead_distance >= 0.0 and last_dynamic_obstacle_ahead_distance <= dynamic_obstacle_stop_buffer:
		return true
	last_player_ahead_distance = _nearest_on_foot_player_distance(direction_vector)
	if last_player_ahead_distance >= 0.0 and last_player_ahead_distance <= pedestrian_stop_buffer:
		return true
	last_police_ahead_distance = _nearest_forward_distance("police_unit", direction_vector, police_look_ahead, 24.0)
	if last_police_ahead_distance >= 0.0 and last_police_ahead_distance <= police_stop_buffer:
		return true
	last_pedestrian_ahead_distance = _nearest_forward_distance("civilian_pedestrian", direction_vector, pedestrian_look_ahead, 18.0)
	if last_pedestrian_ahead_distance >= 0.0 and last_pedestrian_ahead_distance <= pedestrian_stop_buffer:
		return true
	var vehicle_follow_distance := _vehicle_follow_distance()
	var vehicle_follow_look_ahead := maxf(vehicle_look_ahead, vehicle_follow_distance + TRAFFIC_CAR_LENGTH)
	last_vehicle_ahead_distance = _nearest_forward_distance("traffic_vehicle", direction_vector, vehicle_follow_look_ahead, 20.0)
	if last_vehicle_ahead_distance >= 0.0 and last_vehicle_ahead_distance <= vehicle_follow_distance:
		return true
	return false

func _vehicle_follow_distance() -> float:
	var low_speed_spacing := TRAFFIC_CAR_LENGTH * 0.5
	var high_speed_spacing := TRAFFIC_CAR_LENGTH * 3.0
	var cruise_speed := maxf(_cruise_speed(), 1.0)
	var speed_ratio := clampf(current_speed / cruise_speed, 0.0, 1.0)
	return lerpf(low_speed_spacing, high_speed_spacing, speed_ratio)

func _can_attempt_blockage_recovery() -> bool:
	if last_barrier_ahead_distance >= 0.0 and last_barrier_ahead_distance <= barrier_stop_buffer:
		return true
	if last_police_ahead_distance >= 0.0 and last_police_ahead_distance <= police_stop_buffer:
		return true
	if last_dynamic_obstacle_ahead_distance >= 0.0 and last_dynamic_obstacle_ahead_distance <= dynamic_obstacle_stop_buffer:
		return true
	# Only the lead vehicle in a queue should reroute. Cars blocked by another car
	# should keep their spacing instead of all fanning out through the junction.
	if last_pedestrian_ahead_distance >= 0.0 and last_pedestrian_ahead_distance <= pedestrian_stop_buffer:
		return false
	if last_vehicle_ahead_distance >= 0.0 and last_vehicle_ahead_distance <= vehicle_look_ahead:
		return false
	return true

func _should_immediately_switch_for_barrier() -> bool:
	if last_barrier_ahead_distance < 0.0 or last_barrier_ahead_distance > barrier_stop_buffer:
		return false
	var tile := _find_district_tile(global_position)
	return tile != null and _is_before_intersection_hold_point(tile) and _can_switch_lane(tile)

func _should_hold_for_intersection_obstacle(direction_vector: Vector2) -> bool:
	var non_traffic_distance := _nearest_non_traffic_blocking_distance()
	if non_traffic_distance < 0.0:
		return false
	var tile := _find_district_tile(global_position)
	if tile == null:
		return false
	var hold_point := _world_point(tile, heading, lane, CROSSWALK_CLEAR_OFFSET, false)
	var to_hold := hold_point - global_position
	var hold_forward_distance := direction_vector.dot(to_hold)
	if hold_forward_distance <= 8.0:
		return false
	return hold_forward_distance < non_traffic_distance

func _nearest_non_traffic_blocking_distance() -> float:
	var nearest_distance := -1.0
	for distance in [
		last_barrier_ahead_distance,
		last_police_ahead_distance,
		last_dynamic_obstacle_ahead_distance,
		last_player_ahead_distance,
	]:
		if distance < 0.0:
			continue
		if nearest_distance < 0.0 or distance < nearest_distance:
			nearest_distance = distance
	return nearest_distance

func _current_intersection_hold_point() -> Vector2:
	var tile := _find_district_tile(global_position)
	if tile == null:
		return global_position
	return _world_point(tile, heading, lane, CROSSWALK_CLEAR_OFFSET, false)

func _attempt_barrier_lane_switch() -> bool:
	var tile := _find_district_tile(global_position)
	if tile == null or not _is_before_intersection_hold_point(tile) or not _can_switch_lane(tile):
		return false
	var forced_action := "switch_left" if lane == "right" else "switch_right"
	if not _build_runtime_segment(forced_action):
		return false
	reroute_focus_remaining = reroute_focus_time
	return true

func _nearest_forward_distance(group_name: String, direction_vector: Vector2, max_distance: float, max_lateral_distance: float) -> float:
	var nearest_distance := -1.0
	for candidate in get_tree().get_nodes_in_group(group_name):
		if candidate == self or not (candidate is Node2D):
			continue
		var node := candidate as Node2D
		if not node.visible:
			continue
		var offset: Vector2 = node.global_position - global_position
		if offset.length() > max_distance:
			continue
		var forward_distance := direction_vector.dot(offset)
		if forward_distance <= 0.0:
			continue
		var lateral_distance := absf(direction_vector.orthogonal().dot(offset))
		if lateral_distance > max_lateral_distance:
			continue
		if group_name == "traffic_vehicle":
			var vehicle_forward := Vector2.RIGHT.rotated(node.rotation)
			if direction_vector.dot(vehicle_forward) < 0.35:
				continue
		if nearest_distance < 0.0 or forward_distance < nearest_distance:
			nearest_distance = forward_distance
	return nearest_distance

func _get_body_color() -> Color:
	return Color(1, 0.2, 0.2, 1) if harmed_flash_remaining > 0.0 or collision_flash_remaining > 0.0 else Color(0.105882, 0.760784, 1, 1)

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

func _nearest_on_foot_player_distance(direction_vector: Vector2) -> float:
	for candidate in get_tree().get_nodes_in_group("player_actor"):
		if not (candidate is Node2D):
			continue
		var player_actor := candidate as Node2D
		if not player_actor.visible:
			continue
		var offset: Vector2 = player_actor.global_position - global_position
		if offset.length() > pedestrian_look_ahead:
			continue
		var forward_distance := direction_vector.dot(offset)
		if forward_distance <= 0.0:
			continue
		var lateral_distance := absf(direction_vector.orthogonal().dot(offset))
		if lateral_distance > 18.0:
			continue
		return forward_distance
	return -1.0

func _drive_player_controlled(delta: float) -> void:
	var acceleration := 380.0
	var reverse_acceleration := 280.0
	var brake_power := 440.0
	var max_speed := 320.0
	var reverse_speed := 140.0
	var steering_speed := 2.8
	var friction := 220.0
	var min_steer_speed := 18.0
	var player_vehicle := get_tree().get_first_node_in_group("player_vehicle")
	if player_vehicle != null and player_vehicle.has_method("get"):
		var player_tuning = player_vehicle.get("tuning")
		if player_tuning != null:
			acceleration = player_tuning.acceleration
			reverse_acceleration = player_tuning.reverse_acceleration
			brake_power = player_tuning.brake_power
			max_speed = player_tuning.max_speed
			reverse_speed = player_tuning.reverse_speed
			steering_speed = player_tuning.steering_speed
			friction = player_tuning.friction
			min_steer_speed = player_tuning.min_steer_speed

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
	current_speed = absf(longitudinal_speed)
	_displace_pedestrians_ahead(velocity.normalized() if velocity != Vector2.ZERO else Vector2.ZERO)
	move_and_slide()
	if get_slide_collision_count() > 0:
		collision_flash_remaining = harmed_flash_time
		_emit_civilian_impacts()

func _displace_pedestrians_ahead(direction_vector: Vector2) -> void:
	if current_speed < 18.0 or direction_vector == Vector2.ZERO:
		return
	var look_ahead := 16.0 + current_speed * 0.08
	for candidate in get_tree().get_nodes_in_group("civilian_pedestrian"):
		if not (candidate is Node2D):
			continue
		var pedestrian := candidate as Node2D
		var offset := pedestrian.global_position - global_position
		var forward_distance := direction_vector.dot(offset)
		if forward_distance < 0.0 or forward_distance > look_ahead:
			continue
		var lateral_distance := absf(direction_vector.orthogonal().dot(offset))
		if lateral_distance > 16.0:
			continue
		if _is_impact_on_cooldown(pedestrian):
			continue
		_register_pedestrian_impact(pedestrian)

func _register_pedestrian_impact(collider: Node) -> void:
	impact_cooldowns[collider.get_instance_id()] = 0.75
	if collider.has_method("register_harm"):
		collider.register_harm(self)
	civilian_hit.emit(collider)

func _build_runtime_segment(forced_action: String = "") -> bool:
	var tile := _find_district_tile(global_position)
	if tile == null:
		return false
	return _build_segment_for_tile(tile, forced_action)

func _build_segment_for_tile(tile: Node2D, forced_action: String = "") -> bool:
	if tile == null:
		return false
	_remember_tile(tile)

	var action := forced_action if not forced_action.is_empty() else _choose_action(tile)
	var next_heading := heading
	var next_lane := lane
	match action:
		"left":
			next_heading = _get_left_heading(heading)
			next_lane = "left"
		"right":
			next_heading = _get_right_heading(heading)
			next_lane = "right"
		"uturn":
			next_heading = _get_opposite_heading(heading)
			next_lane = "right"
		"merge_left_uturn":
			next_heading = _get_opposite_heading(heading)
			next_lane = "right"
		"switch_left":
			next_lane = "left"
		"switch_right":
			next_lane = "right"

	var points: Array[Vector2] = [global_position]
	var entry_clear := _world_point(tile, heading, lane, CROSSWALK_CLEAR_OFFSET, false)
	if global_position.distance_to(entry_clear) > 8.0:
		points.append(entry_clear)

	match action:
		"straight":
			points.append(_world_point(tile, heading, lane, _next_tile_offset(tile, heading), true))
		"left", "right":
			var arc_start := _world_point(tile, heading, lane, _turn_entry_offset(action), false)
			var arc_end := _world_point(tile, next_heading, next_lane, INTERSECTION_ENTRY_OFFSET, true)
			var exit_clear := _world_point(tile, next_heading, next_lane, CROSSWALK_CLEAR_OFFSET, true)
			if action == "left":
				var turn_start := _world_point(tile, heading, lane, LEFT_TURN_START_OFFSET, true)
				if points[points.size() - 1].distance_to(turn_start) > 8.0:
					points.append(turn_start)
				arc_start = turn_start
			else:
				if points[points.size() - 1].distance_to(arc_start) > 8.0:
					points.append(arc_start)
				arc_end = exit_clear
			points.append_array(_sample_corner(
				arc_start,
				_turn_pivot(tile, heading, lane, next_heading, next_lane),
				arc_end
			))
			if points[points.size() - 1].distance_to(exit_clear) > 8.0:
				points.append(exit_clear)
			var exit_straight := _world_point(tile, next_heading, next_lane, _next_tile_offset(tile, next_heading), true)
			if points[points.size() - 1].distance_to(exit_straight) > 8.0:
				points.append(exit_straight)
		"uturn":
			var u_entry := _world_point(tile, heading, "left", INTERSECTION_ENTRY_OFFSET, false)
			if points[points.size() - 1].distance_to(u_entry) > 8.0:
				points.append(u_entry)
			points.append_array(_sample_corner(
				u_entry,
				tile.global_position,
				_world_point(tile, next_heading, next_lane, _next_tile_offset(tile, next_heading), true)
			))
		"merge_left_uturn":
			var merge_point := _merge_point(tile, heading, "right", "left")
			if points[points.size() - 1].distance_to(merge_point) > 8.0:
				points.append(merge_point)
			var merge_entry := _world_point(tile, heading, "left", INTERSECTION_ENTRY_OFFSET, false)
			points.append_array(_sample_corner(
				merge_entry,
				tile.global_position,
				_world_point(tile, next_heading, next_lane, _next_tile_offset(tile, next_heading), true)
			))
		"switch_left", "switch_right":
			var switch_entry := _world_point(tile, heading, lane, INTERSECTION_ENTRY_OFFSET, false)
			if points[points.size() - 1].distance_to(switch_entry) > 8.0:
				points.append(switch_entry)
			points.append_array(_sample_corner(
				switch_entry,
				_merge_point(tile, heading, lane, next_lane),
				_world_point(tile, heading, next_lane, _next_tile_offset(tile, heading), true)
			))

	world_path_points = PackedVector2Array(points)
	path_target_index = 1 if world_path_points.size() >= 2 else 0
	active_action = action
	heading = next_heading
	lane = next_lane
	return world_path_points.size() >= 2

func _target_speed_for_action(action: String) -> float:
	match action:
		"left", "right":
			return _turn_speed()
		"uturn", "merge_left_uturn":
			return _u_turn_speed()
		"switch_left", "switch_right":
			return _lane_change_speed()
		_:
			return _cruise_speed()

func _spawn_speed() -> float:
	return _cruise_speed() * 0.55

func _turn_entry_offset(action: String) -> float:
	return LEFT_TURN_ENTRY_OFFSET if action == "left" else INTERSECTION_ENTRY_OFFSET

func _cruise_speed() -> float:
	return tuning.cruise_speed if tuning != null else move_speed

func _turn_speed() -> float:
	return tuning.turn_speed if tuning != null else move_speed

func _u_turn_speed() -> float:
	return tuning.u_turn_speed if tuning != null else move_speed * 0.8

func _lane_change_speed() -> float:
	return tuning.lane_change_speed if tuning != null else move_speed * 0.9

func _acceleration_rate() -> float:
	return tuning.acceleration if tuning != null else 180.0

func _brake_rate() -> float:
	return tuning.brake_power if tuning != null else 260.0

func _attempt_blockage_recovery() -> bool:
	var tile := _find_district_tile(global_position)
	if tile == null:
		return false

	var forced_action := _choose_recovery_action(tile)

	if forced_action.is_empty():
		return false
	if not _build_runtime_segment(forced_action):
		return false
	reroute_focus_remaining = reroute_focus_time
	return true

func _find_district_tile(position: Vector2) -> Node2D:
	if district_tiles.is_empty():
		district_tiles = _collect_district_tiles(get_tree().root)
	for candidate in district_tiles:
		var tile_size = candidate.get("tile_world_size")
		if not (tile_size is Vector2):
			continue
		var half_tile: Vector2 = tile_size * 0.5
		var local_position := position - candidate.global_position
		if absf(local_position.x) <= half_tile.x and absf(local_position.y) <= half_tile.y:
			return candidate
	return null

func _collect_district_tiles(node: Node) -> Array[Node2D]:
	var results: Array[Node2D] = []
	if node is Node2D and node.has_node("Ground") and node.has_method("get") and node.get("tile_world_size") is Vector2:
		results.append(node as Node2D)
	for child in node.get_children():
		results.append_array(_collect_district_tiles(child))
	return results

func _spawn_point(tile: Node2D, direction: String, lane_name: String) -> Vector2:
	return _world_point(tile, direction, lane_name, SPAWN_ENTRY_OFFSET, false)

func _choose_action(tile: Node2D) -> String:
	if _should_prepare_next_tile_lane(tile):
		return "switch_left" if lane == "right" else "switch_right"
	if _is_before_intersection_hold_point(tile):
		var current_actions := _available_actions_for(tile, heading, lane)
		if current_actions.is_empty() and _can_switch_lane(tile):
			var alternate_lane := "left" if lane == "right" else "right"
			var alternate_actions := _available_actions_for(tile, heading, alternate_lane)
			if not alternate_actions.is_empty():
				return "switch_left" if lane == "right" else "switch_right"
	return _pick_preferred_action(tile, heading, lane, _available_actions_for(tile, heading, lane))

func _should_prepare_next_tile_lane(tile: Node2D) -> bool:
	if tile == null or not _is_before_intersection_hold_point(tile) or not _can_switch_lane(tile):
		return false
	if not _tile_open(tile, _get_exit_side_for_heading(heading)):
		return false
	var next_tile := _neighbor_tile(tile, heading)
	if next_tile == null:
		return false
	var current_lane_actions := _available_actions_for(next_tile, heading, lane)
	if not current_lane_actions.is_empty():
		return false
	var alternate_lane := "left" if lane == "right" else "right"
	var alternate_lane_actions := _available_actions_for(next_tile, heading, alternate_lane)
	return not alternate_lane_actions.is_empty()

func _choose_recovery_action(tile: Node2D) -> String:
	var candidates: Array[String] = []
	if _is_before_intersection_hold_point(tile) and _can_switch_lane(tile):
		candidates.append("switch_left" if lane == "right" else "switch_right")
	if lane == "right":
		candidates.append_array(["right", "left", "merge_left_uturn"])
	else:
		candidates.append_array(["left", "right", "uturn"])
	return _pick_preferred_action(tile, heading, lane, candidates)

func _pick_preferred_action(tile: Node2D, entry_heading: String, entry_lane: String, candidates: Array[String]) -> String:
	var valid_actions: Array[String] = []
	for action in candidates:
		if _action_is_valid(tile, entry_heading, entry_lane, action):
			valid_actions.append(action)
	if valid_actions.is_empty():
		return ""
	var best_action := valid_actions[0]
	var best_score := _action_loop_score(tile, entry_heading, entry_lane, best_action, ROUTE_LOOKAHEAD_DEPTH)
	for action in valid_actions:
		var score := _action_loop_score(tile, entry_heading, entry_lane, action, ROUTE_LOOKAHEAD_DEPTH)
		if score < best_score:
			best_score = score
			best_action = action
	return best_action

func _available_actions_for(tile: Node2D, entry_heading: String, entry_lane: String) -> Array[String]:
	var actions: Array[String] = []
	var can_go_straight := _tile_open(tile, _get_exit_side_for_heading(entry_heading))
	var can_turn_left := _tile_open(tile, _get_exit_side_for_heading(_get_left_heading(entry_heading)))
	var can_turn_right := _tile_open(tile, _get_exit_side_for_heading(_get_right_heading(entry_heading)))
	if entry_lane == "left":
		if can_go_straight:
			actions.append("straight")
		if can_turn_left:
			actions.append("left")
		if actions.is_empty() and can_turn_right:
			actions.append("right")
		if actions.is_empty():
			actions.append("uturn")
		return actions
	if can_turn_right:
		actions.append("right")
	return actions

func _action_is_valid(tile: Node2D, entry_heading: String, entry_lane: String, action: String) -> bool:
	match action:
		"straight", "switch_left", "switch_right":
			return _tile_open(tile, _get_exit_side_for_heading(entry_heading))
		"left":
			return _tile_open(tile, _get_exit_side_for_heading(_get_left_heading(entry_heading)))
		"right":
			return _tile_open(tile, _get_exit_side_for_heading(_get_right_heading(entry_heading)))
		"uturn", "merge_left_uturn":
			return true
		_:
			return false

func _action_loop_score(tile: Node2D, entry_heading: String, entry_lane: String, action: String, depth: int) -> int:
	var next_state := _state_after_action(tile, entry_heading, entry_lane, action)
	var target_tile := next_state.get("tile") as Node2D
	var score := 0
	if action == "uturn" or action == "merge_left_uturn":
		score += UTURN_PENALTY
	if target_tile == null:
		return score
	if _tile_is_recent(target_tile.global_position):
		score += RECENT_TILE_PENALTY
	if depth <= 1:
		return score
	var next_heading := String(next_state.get("heading", entry_heading))
	var next_lane := String(next_state.get("lane", entry_lane))
	return score + _best_future_score(target_tile, next_heading, next_lane, depth - 1)

func _best_future_score(tile: Node2D, entry_heading: String, entry_lane: String, depth: int) -> int:
	if tile == null or depth <= 0:
		return 0
	var actions := _available_actions_for(tile, entry_heading, entry_lane)
	if actions.is_empty():
		return 0
	var best_score := INF
	for action in actions:
		if not _action_is_valid(tile, entry_heading, entry_lane, action):
			continue
		best_score = mini(best_score, _action_loop_score(tile, entry_heading, entry_lane, action, depth))
	return 0 if best_score == INF else best_score

func _state_after_action(tile: Node2D, entry_heading: String, entry_lane: String, action: String) -> Dictionary:
	var exit_heading := entry_heading
	var exit_lane := entry_lane
	match action:
		"left":
			exit_heading = _get_left_heading(entry_heading)
			exit_lane = "left"
		"right":
			exit_heading = _get_right_heading(entry_heading)
			exit_lane = "right"
		"uturn", "merge_left_uturn":
			exit_heading = _get_opposite_heading(entry_heading)
			exit_lane = "right"
		"switch_left":
			exit_lane = "left"
		"switch_right":
			exit_lane = "right"
	var target_tile := _neighbor_tile(tile, exit_heading)
	return {
		"tile": target_tile,
		"heading": exit_heading,
		"lane": exit_lane,
	}

func _neighbor_tile(tile: Node2D, direction: String) -> Node2D:
	var tile_size_value = tile.get("tile_world_size")
	if not (tile_size_value is Vector2):
		return null
	var tile_size: Vector2 = tile_size_value
	var offset := Vector2(
		tile_size.x if direction == "east" else -tile_size.x if direction == "west" else 0.0,
		tile_size.y if direction == "south" else -tile_size.y if direction == "north" else 0.0
	)
	return _find_district_tile(tile.global_position + offset)

func _tile_is_recent(tile_position: Vector2) -> bool:
	for recent_tile in recent_tiles:
		if recent_tile.distance_to(tile_position) <= 4.0:
			return true
	return false

func _remember_tile(tile: Node2D) -> void:
	if not recent_tiles.is_empty() and recent_tiles[recent_tiles.size() - 1].distance_to(tile.global_position) <= 4.0:
		return
	recent_tiles.append(tile.global_position)
	while recent_tiles.size() > RECENT_TILE_MEMORY:
		recent_tiles.remove_at(0)

func _can_switch_lane(tile: Node2D) -> bool:
	if tile == null:
		return false
	if not _tile_open(tile, _get_exit_side_for_heading(heading)):
		return false
	var target_lane := "left" if lane == "right" else "right"
	var merge_point := _merge_point(tile, heading, lane, target_lane)
	for candidate in get_tree().get_nodes_in_group("traffic_vehicle"):
		if candidate == self or not (candidate is Node2D):
			continue
		var vehicle := candidate as Node2D
		if not vehicle.visible:
			continue
		if vehicle.global_position.distance_to(merge_point) <= vehicle_stop_buffer * 1.5:
			return false
	return true

func _is_before_intersection_hold_point(tile: Node2D) -> bool:
	if tile == null:
		return false
	var hold_point := _world_point(tile, heading, lane, CROSSWALK_CLEAR_OFFSET, false)
	var to_hold := hold_point - global_position
	var forward := _forward_vector_for_heading(heading)
	return forward.dot(to_hold) > 8.0

func _tile_open(tile: Node2D, side: String) -> bool:
	return bool(tile.get("open_%s" % side))

func _next_tile_offset(tile: Node2D, direction: String) -> float:
	var tile_size: Vector2 = tile.get("tile_world_size")
	var half_extent := (tile_size.x if _is_horizontal(direction) else tile_size.y) * 0.5
	return half_extent + CROSSWALK_CLEAR_OFFSET

func _world_point(tile: Node2D, direction: String, lane_name: String, axis_offset: float, use_exit_side: bool) -> Vector2:
	var signed_axis := axis_offset * _axis_sign(direction, use_exit_side)
	var lane_coordinate := _lane_coordinate(direction, lane_name)
	if _is_horizontal(direction):
		return tile.global_position + Vector2(signed_axis, lane_coordinate)
	return tile.global_position + Vector2(lane_coordinate, signed_axis)

func _turn_pivot(tile: Node2D, entry_heading: String, entry_lane: String, exit_heading: String, exit_lane: String) -> Vector2:
	return tile.global_position + Vector2(
		_lane_coordinate(exit_heading, exit_lane),
		_lane_coordinate(entry_heading, entry_lane)
	)

func _merge_point(tile: Node2D, direction: String, from_lane: String, to_lane: String) -> Vector2:
	var axis_offset := (CROSSWALK_CLEAR_OFFSET + INTERSECTION_ENTRY_OFFSET) * 0.5
	var signed_axis := axis_offset * _axis_sign(direction, false)
	var lane_coordinate := lerpf(_lane_coordinate(direction, from_lane), _lane_coordinate(direction, to_lane), 0.7)
	if _is_horizontal(direction):
		return tile.global_position + Vector2(signed_axis, lane_coordinate)
	return tile.global_position + Vector2(lane_coordinate, signed_axis)

func _sample_corner(start: Vector2, pivot: Vector2, end: Vector2) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var curve_length := start.distance_to(pivot) + pivot.distance_to(end)
	var step_count := maxi(TURN_ARC_STEPS, int(ceil(curve_length / ROUTE_SAMPLE_STEP)))
	for index in range(1, step_count + 1):
		var t := float(index) / float(step_count)
		var a := start.lerp(pivot, t)
		var b := pivot.lerp(end, t)
		points.append(a.lerp(b, t))
	return points

func _lane_coordinate(direction: String, lane_name: String) -> float:
	var left_lane := lane_name == "left"
	match direction:
		"east":
			return INNER_LANE_OFFSET if left_lane else OUTER_LANE_OFFSET
		"west":
			return -INNER_LANE_OFFSET if left_lane else -OUTER_LANE_OFFSET
		"south":
			return -INNER_LANE_OFFSET if left_lane else -OUTER_LANE_OFFSET
		_:
			return INNER_LANE_OFFSET if left_lane else OUTER_LANE_OFFSET

func _axis_sign(direction: String, use_exit_side: bool) -> float:
	match direction:
		"east":
			return 1.0 if use_exit_side else -1.0
		"west":
			return -1.0 if use_exit_side else 1.0
		"south":
			return 1.0 if use_exit_side else -1.0
		_:
			return -1.0 if use_exit_side else 1.0

func _is_horizontal(direction: String) -> bool:
	return direction == "east" or direction == "west"

func _forward_vector_for_heading(direction: String) -> Vector2:
	match direction:
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
		"south":
			return Vector2.DOWN
		_:
			return Vector2.UP

func _get_exit_side_for_heading(direction: String) -> String:
	return direction

func _entry_side_for_heading(direction: String) -> String:
	match direction:
		"east":
			return "west"
		"west":
			return "east"
		"south":
			return "north"
		_:
			return "south"

func _get_left_heading(direction: String) -> String:
	match direction:
		"east":
			return "north"
		"west":
			return "south"
		"south":
			return "east"
		_:
			return "west"

func _get_right_heading(direction: String) -> String:
	match direction:
		"east":
			return "south"
		"west":
			return "north"
		"south":
			return "west"
		_:
			return "east"

func _get_opposite_heading(direction: String) -> String:
	match direction:
		"east":
			return "west"
		"west":
			return "east"
		"south":
			return "north"
		_:
			return "south"
