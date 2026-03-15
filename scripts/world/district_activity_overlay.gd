@tool
extends Node2D

const CivilianScene = preload("res://scenes/actors/civilians/civilian_pedestrian.tscn")
const TrafficScene = preload("res://scenes/vehicles/civilian/traffic_vehicle.tscn")

@export_range(0, 9, 1) var activity_density := 0:
	set(value):
		activity_density = value
		_rebuild_if_ready()

@export var open_north := true:
	set(value):
		open_north = value
		_rebuild_if_ready()

@export var open_south := true:
	set(value):
		open_south = value
		_rebuild_if_ready()

@export var open_east := true:
	set(value):
		open_east = value
		_rebuild_if_ready()

@export var open_west := true:
	set(value):
		open_west = value
		_rebuild_if_ready()

@export var tile_world_size := Vector2(1280, 1280):
	set(value):
		tile_world_size = value
		_rebuild_if_ready()

@export_range(0, 32, 1) var north_span_tiles := 0:
	set(value):
		north_span_tiles = value
		_rebuild_if_ready()

@export_range(0, 32, 1) var south_span_tiles := 0:
	set(value):
		south_span_tiles = value
		_rebuild_if_ready()

@export_range(0, 32, 1) var east_span_tiles := 0:
	set(value):
		east_span_tiles = value
		_rebuild_if_ready()

@export_range(0, 32, 1) var west_span_tiles := 0:
	set(value):
		west_span_tiles = value
		_rebuild_if_ready()

const ROAD_HALF_WIDTH := 96.0
const SIDEWALK_OFFSET := 118.0
const CROSSWALK_OFFSET := 140.0
const INNER_LANE_OFFSET := 28.0
const OUTER_LANE_OFFSET := 68.0
const SPAWN_MARGIN := 192.0
const CROSSWALK_CLEAR_OFFSET := 120.0
const INTERSECTION_ENTRY_OFFSET := 76.0
const U_TURN_SWEEP_OFFSET := 24.0
const ROUTE_SAMPLE_STEP := 24.0
const TURN_ARC_STEPS := 6
const ROUTE_EDGE_INSET := 24.0
const PROFILE_STRAIGHT_HORIZONTAL := "straight_horizontal"
const PROFILE_STRAIGHT_VERTICAL := "straight_vertical"
const PROFILE_DEAD_END_NORTH := "dead_end_north"
const PROFILE_DEAD_END_SOUTH := "dead_end_south"
const PROFILE_DEAD_END_EAST := "dead_end_east"
const PROFILE_DEAD_END_WEST := "dead_end_west"

func _ready() -> void:
	_rebuild()

func refresh_overlay() -> void:
	_rebuild()

func _rebuild_if_ready() -> void:
	if is_node_ready():
		_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	if activity_density <= 0:
		return

	var pedestrian_routes := _build_pedestrian_routes()
	var traffic_routes := _build_traffic_routes()

	if activity_density >= 2 and pedestrian_routes.size() > 0:
		_add_pedestrian(pedestrian_routes[0])
	if activity_density >= 5 and pedestrian_routes.size() > 1:
		_add_pedestrian(pedestrian_routes[1])
	for route_data in _select_traffic_routes(traffic_routes):
		_add_traffic(route_data["path"])

func _add_pedestrian(path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	var actor = CivilianScene.instantiate()
	actor.position = to_local(path[0])
	add_child(actor)
	if actor.has_method("set_world_path"):
		actor.call("set_world_path", path)
	if actor.has_method("set_path_active"):
		actor.call("set_path_active", true)

func _add_traffic(path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	var actor = TrafficScene.instantiate()
	actor.position = to_local(path[0])
	add_child(actor)
	if actor.has_method("set_world_path"):
		actor.call("set_world_path", path)
	if actor.has_method("set_path_active"):
		actor.call("set_path_active", true)

func _build_pedestrian_routes() -> Array[PackedVector2Array]:
	var routes: Array[PackedVector2Array] = []
	var half_width := tile_world_size.x * 0.5
	var half_height := tile_world_size.y * 0.5
	var profile := _get_tile_profile()

	match profile:
		PROFILE_STRAIGHT_HORIZONTAL:
			routes.append(_to_world_path([Vector2(-half_width, -SIDEWALK_OFFSET), Vector2(half_width, -SIDEWALK_OFFSET)]))
			routes.append(_to_world_path([Vector2(half_width, SIDEWALK_OFFSET), Vector2(-half_width, SIDEWALK_OFFSET)]))
		PROFILE_STRAIGHT_VERTICAL:
			routes.append(_to_world_path([Vector2(-SIDEWALK_OFFSET, -half_height), Vector2(-SIDEWALK_OFFSET, half_height)]))
			routes.append(_to_world_path([Vector2(SIDEWALK_OFFSET, half_height), Vector2(SIDEWALK_OFFSET, -half_height)]))
		PROFILE_DEAD_END_NORTH, PROFILE_DEAD_END_SOUTH, PROFILE_DEAD_END_EAST, PROFILE_DEAD_END_WEST:
			routes.append(_to_world_path([Vector2(-SIDEWALK_OFFSET, -half_height), Vector2(-SIDEWALK_OFFSET, half_height)]))
			routes.append(_to_world_path([Vector2(SIDEWALK_OFFSET, half_height), Vector2(SIDEWALK_OFFSET, -half_height)]))
		_:
			if open_north and open_east and not open_south and not open_west:
				routes.append(_to_world_path([Vector2(SIDEWALK_OFFSET, -half_height), Vector2(SIDEWALK_OFFSET, -SIDEWALK_OFFSET), Vector2(half_width, -SIDEWALK_OFFSET)]))
			elif open_north and open_west and not open_south and not open_east:
				routes.append(_to_world_path([Vector2(-SIDEWALK_OFFSET, -half_height), Vector2(-SIDEWALK_OFFSET, -SIDEWALK_OFFSET), Vector2(-half_width, -SIDEWALK_OFFSET)]))
			elif open_south and open_east and not open_north and not open_west:
				routes.append(_to_world_path([Vector2(SIDEWALK_OFFSET, half_height), Vector2(SIDEWALK_OFFSET, SIDEWALK_OFFSET), Vector2(half_width, SIDEWALK_OFFSET)]))
			elif open_south and open_west and not open_north and not open_east:
				routes.append(_to_world_path([Vector2(-SIDEWALK_OFFSET, half_height), Vector2(-SIDEWALK_OFFSET, SIDEWALK_OFFSET), Vector2(-half_width, SIDEWALK_OFFSET)]))
			else:
				routes.append(_to_world_path([Vector2(-CROSSWALK_OFFSET, 0), Vector2(CROSSWALK_OFFSET, 0)]))
				routes.append(_to_world_path([Vector2(0, -CROSSWALK_OFFSET), Vector2(0, CROSSWALK_OFFSET)]))

	return routes

func _build_traffic_routes() -> Array[Dictionary]:
	var routes: Array[Dictionary] = []
	if _open_side_count() <= 1:
		return routes

	for heading in ["east", "west", "north", "south"]:
		if not _can_enter_heading(heading):
			continue
		for lane in ["left", "right"]:
			for action in _allowed_actions(heading, lane):
				routes.append({
					"heading": heading,
					"lane": lane,
					"action": action,
					"path": _build_route(heading, lane, action),
				})
	return routes

func _select_traffic_routes(candidates: Array[Dictionary]) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	var spawn_count := 0
	if activity_density >= 7:
		spawn_count = 2
	elif activity_density >= 3:
		spawn_count = 1
	if spawn_count == 0 or candidates.is_empty():
		return selected

	var turning_candidates: Array[Dictionary] = []
	var straight_candidates: Array[Dictionary] = []
	for candidate in candidates:
		if candidate["action"] == "straight":
			straight_candidates.append(candidate)
		else:
			turning_candidates.append(candidate)

	var preferred_heading := _preferred_heading()
	var preferred_turn := _pick_candidate(turning_candidates, preferred_heading, PackedStringArray())
	if preferred_turn.is_empty():
		preferred_turn = _pick_candidate(turning_candidates, "", PackedStringArray())
	if not preferred_turn.is_empty():
		selected.append(preferred_turn)

	if selected.size() < spawn_count:
		var blocked_ids := _selected_ids(selected)

		var second_choice := _pick_candidate(straight_candidates, preferred_heading, blocked_ids)
		if second_choice.is_empty():
			second_choice = _pick_candidate(turning_candidates, "", blocked_ids)
		if second_choice.is_empty():
			second_choice = _pick_candidate(straight_candidates, "", blocked_ids)
		if not second_choice.is_empty():
			selected.append(second_choice)

	while selected.size() < min(spawn_count, candidates.size()):
		var fallback := _pick_candidate(candidates, "", _selected_ids(selected))
		if fallback.is_empty():
			break
		selected.append(fallback)
	return selected

func _build_route(heading: String, lane: String, action: String) -> PackedVector2Array:
	match action:
		"straight":
			return _build_straight_route(heading, lane)
		"left":
			return _build_turn_route(heading, lane, _get_left_heading(heading), "left")
		"right":
			return _build_turn_route(heading, lane, _get_right_heading(heading), "right")
		"uturn":
			return _build_u_turn_route(heading)
		"merge_left_uturn":
			return _build_merge_left_u_turn_route(heading)
		_:
			return PackedVector2Array()

func _build_straight_route(heading: String, lane: String) -> PackedVector2Array:
	return _sample_route([
		_get_spawn_point(heading, lane),
		_get_crosswalk_clear_point(heading, lane),
		_get_crosswalk_clear_point(heading, lane, true),
		_get_despawn_point(heading, lane),
	])

func _build_turn_route(heading: String, lane: String, exit_heading: String, exit_lane: String) -> PackedVector2Array:
	var points: Array[Vector2] = [
		_get_spawn_point(heading, lane),
		_get_crosswalk_clear_point(heading, lane),
		_get_intersection_entry_point(heading, lane, false),
	]
	points.append_array(_build_turn_arc_points(heading, lane, exit_heading, exit_lane))
	points.append_array([
		_get_crosswalk_clear_point(exit_heading, exit_lane, true),
		_get_despawn_point(exit_heading, exit_lane),
	])
	return _sample_route(points)

func _build_u_turn_route(heading: String) -> PackedVector2Array:
	var exit_heading := _get_opposite_heading(heading)
	var exit_lane := "right"
	var points: Array[Vector2] = [
		_get_spawn_point(heading, "left"),
		_get_crosswalk_clear_point(heading, "left"),
		_get_intersection_entry_point(heading, "left", false),
	]
	points.append_array(_build_u_turn_arc_points(heading, exit_heading, exit_lane))
	points.append_array([
		_get_crosswalk_clear_point(exit_heading, exit_lane, true),
		_get_despawn_point(exit_heading, exit_lane),
	])
	return _sample_route(points)

func _build_merge_left_u_turn_route(heading: String) -> PackedVector2Array:
	var left_merge_point := _get_merge_point(heading, "right", "left")
	var points: Array[Vector2] = [
		_get_spawn_point(heading, "right"),
		_get_crosswalk_clear_point(heading, "right"),
		left_merge_point,
		_get_intersection_entry_point(heading, "left", false),
	]
	var exit_heading := _get_opposite_heading(heading)
	var exit_lane := "right"
	points.append_array(_build_u_turn_arc_points(heading, exit_heading, exit_lane))
	points.append_array([
		_get_crosswalk_clear_point(exit_heading, exit_lane, true),
		_get_despawn_point(exit_heading, exit_lane),
	])
	return _sample_route(points)

func _can_enter_heading(heading: String) -> bool:
	return _is_side_open(_get_entry_side_for_heading(heading))

func _allowed_actions(heading: String, lane: String) -> PackedStringArray:
	var actions := PackedStringArray()
	var can_go_straight := _is_side_open(_get_exit_side_for_heading(heading))
	var can_turn_left := _is_side_open(_get_exit_side_for_heading(_get_left_heading(heading)))
	var can_turn_right := _is_side_open(_get_exit_side_for_heading(_get_right_heading(heading)))

	if lane == "left":
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
	if can_go_straight:
		actions.append("straight")
	if can_turn_left and actions.is_empty():
		actions.append("left")
	if actions.is_empty():
		actions.append("merge_left_uturn")
	return actions

func _get_spawn_point(heading: String, lane: String) -> Vector2:
	return _point_for_heading(heading, lane, _entry_travel_extent_for_heading(heading))

func _get_despawn_point(heading: String, lane: String) -> Vector2:
	return _point_for_heading(heading, lane, _exit_travel_extent_for_heading(heading), true)

func _get_crosswalk_clear_point(heading: String, lane: String, use_exit_side := false) -> Vector2:
	return _point_for_heading(heading, lane, CROSSWALK_CLEAR_OFFSET, use_exit_side)

func _get_intersection_entry_point(heading: String, lane: String, use_exit_side: bool) -> Vector2:
	return _point_for_heading(heading, lane, INTERSECTION_ENTRY_OFFSET, use_exit_side)

func _get_merge_point(heading: String, from_lane: String, to_lane: String) -> Vector2:
	var merge_axis := (CROSSWALK_CLEAR_OFFSET + INTERSECTION_ENTRY_OFFSET) * 0.5
	var signed_axis := merge_axis * _axis_sign_for_heading(heading, false)
	var from_coordinate := _lane_coordinate_for_heading(heading, from_lane)
	var to_coordinate := _lane_coordinate_for_heading(heading, to_lane)
	var lane_coordinate := lerpf(from_coordinate, to_coordinate, 0.7)
	if _is_horizontal_heading(heading):
		return Vector2(signed_axis, lane_coordinate)
	return Vector2(lane_coordinate, signed_axis)

func _build_turn_arc_points(entry_heading: String, entry_lane: String, exit_heading: String, exit_lane: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var entry_point := _get_intersection_entry_point(entry_heading, entry_lane, false)
	var exit_point := _get_intersection_entry_point(exit_heading, exit_lane, true)
	var pivot := Vector2(
		_lane_coordinate_for_heading(exit_heading, exit_lane),
		_lane_coordinate_for_heading(entry_heading, entry_lane)
	)
	points.append_array(_sample_corner(entry_point, pivot, exit_point))
	return points

func _build_u_turn_arc_points(entry_heading: String, exit_heading: String, exit_lane: String) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var entry_point := _get_intersection_entry_point(entry_heading, "left", false)
	var exit_point := _get_intersection_entry_point(exit_heading, exit_lane, true)
	var midpoint := (_entry_direction(entry_heading) + _entry_direction(exit_heading)).normalized()
	var apex := midpoint * U_TURN_SWEEP_OFFSET
	points.append_array(_sample_corner(entry_point, apex, exit_point))
	return points

func _point_for_heading(heading: String, lane: String, axis_offset: float, use_exit_side := false) -> Vector2:
	var signed_axis := axis_offset * _axis_sign_for_heading(heading, use_exit_side)
	var lane_coordinate := _lane_coordinate_for_heading(heading, lane)
	if _is_horizontal_heading(heading):
		return Vector2(signed_axis, lane_coordinate)
	return Vector2(lane_coordinate, signed_axis)

func _entry_travel_extent_for_heading(heading: String) -> float:
	var span_tiles := _span_tiles_for_heading(heading, false)
	var tile_extent := tile_world_size.x if _is_horizontal_heading(heading) else tile_world_size.y
	return maxf(ROAD_HALF_WIDTH, ROAD_HALF_WIDTH + span_tiles * tile_extent - ROUTE_EDGE_INSET)

func _exit_travel_extent_for_heading(heading: String) -> float:
	var span_tiles := mini(1, _span_tiles_for_heading(heading, true))
	var tile_extent := tile_world_size.x if _is_horizontal_heading(heading) else tile_world_size.y
	return ROAD_HALF_WIDTH + span_tiles * tile_extent - ROUTE_EDGE_INSET

func _span_tiles_for_heading(heading: String, use_exit_side: bool) -> int:
	match heading:
		"east":
			return east_span_tiles if use_exit_side else west_span_tiles
		"west":
			return west_span_tiles if use_exit_side else east_span_tiles
		"south":
			return south_span_tiles if use_exit_side else north_span_tiles
		_:
			return north_span_tiles if use_exit_side else south_span_tiles

func _axis_sign_for_heading(heading: String, use_exit_side: bool) -> float:
	match heading:
		"east":
			return 1.0 if use_exit_side else -1.0
		"west":
			return -1.0 if use_exit_side else 1.0
		"south":
			return 1.0 if use_exit_side else -1.0
		_:
			return -1.0 if use_exit_side else 1.0

func _lane_coordinate_for_heading(heading: String, lane: String) -> float:
	return _lane_offset_for_heading(heading, lane)

func _is_horizontal_heading(heading: String) -> bool:
	return heading == "east" or heading == "west"

func _open_side_count() -> int:
	return int(open_north) + int(open_south) + int(open_east) + int(open_west)

func _lane_offset_for_heading(heading: String, lane: String) -> float:
	var left_lane := lane == "left"
	match heading:
		"east":
			return -INNER_LANE_OFFSET if left_lane else -OUTER_LANE_OFFSET
		"west":
			return INNER_LANE_OFFSET if left_lane else OUTER_LANE_OFFSET
		"south":
			return INNER_LANE_OFFSET if left_lane else OUTER_LANE_OFFSET
		_:
			return -INNER_LANE_OFFSET if left_lane else -OUTER_LANE_OFFSET

func _get_entry_side_for_heading(heading: String) -> String:
	match heading:
		"east":
			return "west"
		"west":
			return "east"
		"south":
			return "north"
		_:
			return "south"

func _get_exit_side_for_heading(heading: String) -> String:
	match heading:
		"east":
			return "east"
		"west":
			return "west"
		"south":
			return "south"
		_:
			return "north"

func _get_left_heading(heading: String) -> String:
	match heading:
		"east":
			return "north"
		"west":
			return "south"
		"south":
			return "east"
		_:
			return "west"

func _get_right_heading(heading: String) -> String:
	match heading:
		"east":
			return "south"
		"west":
			return "north"
		"south":
			return "west"
		_:
			return "east"

func _get_opposite_heading(heading: String) -> String:
	match heading:
		"east":
			return "west"
		"west":
			return "east"
		"south":
			return "north"
		_:
			return "south"

func _is_side_open(side: String) -> bool:
	match side:
		"north":
			return open_north
		"south":
			return open_south
		"east":
			return open_east
		"west":
			return open_west
		_:
			return false

func _traffic_seed() -> int:
	return int(global_position.x / tile_world_size.x) * 73856093 + int(global_position.y / tile_world_size.y) * 19349663 + activity_density * 83492791

func _preferred_heading() -> String:
	var open_headings := PackedStringArray()
	for heading in ["south", "east", "north", "west"]:
		if _can_enter_heading(heading):
			open_headings.append(heading)
	if open_headings.is_empty():
		return ""
	return open_headings[abs(_traffic_seed()) % open_headings.size()]

func _pick_candidate(pool: Array[Dictionary], preferred_heading: String, blocked: PackedStringArray) -> Dictionary:
	if pool.is_empty():
		return {}
	var start_index: int = abs(_traffic_seed()) % pool.size()
	for offset in range(pool.size()):
		var candidate: Dictionary = pool[(start_index + offset) % pool.size()]
		var candidate_id := _route_id(candidate)
		if blocked.has(candidate_id):
			continue
		if not preferred_heading.is_empty() and candidate["heading"] != preferred_heading:
			continue
		return candidate
	if preferred_heading.is_empty():
		return {}
	return _pick_candidate(pool, "", blocked)

func _selected_ids(selected: Array[Dictionary]) -> PackedStringArray:
	var ids := PackedStringArray()
	for candidate in selected:
		ids.append(_route_id(candidate))
	return ids

func _route_id(candidate: Dictionary) -> String:
	return "%s:%s:%s" % [candidate["heading"], candidate["lane"], candidate["action"]]

func _sample_route(local_points: Array[Vector2]) -> PackedVector2Array:
	var sampled := PackedVector2Array()
	if local_points.is_empty():
		return sampled

	sampled.append(global_position + local_points[0])
	for index in range(1, local_points.size()):
		var segment := _sample_line(local_points[index - 1], local_points[index], ROUTE_SAMPLE_STEP)
		for point in segment:
			sampled.append(global_position + point)
	return sampled

func _sample_line(start: Vector2, end: Vector2, step: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	var delta := end - start
	var distance := delta.length()
	if distance <= 0.001:
		return points
	var count := maxi(1, int(ceil(distance / step)))
	for index in range(1, count + 1):
		var t := float(index) / float(count)
		points.append(start.lerp(end, t))
	return points

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

func _entry_direction(heading: String) -> Vector2:
	match heading:
		"east":
			return Vector2.RIGHT
		"west":
			return Vector2.LEFT
		"south":
			return Vector2.DOWN
		_:
			return Vector2.UP

func _to_world_path(local_points: Array[Vector2]) -> PackedVector2Array:
	var path := PackedVector2Array()
	for point in local_points:
		path.append(global_position + point)
	return path

func _get_tile_profile() -> String:
	var open_count := int(open_north) + int(open_south) + int(open_east) + int(open_west)
	if open_count == 1:
		if open_north:
			return PROFILE_DEAD_END_NORTH
		if open_south:
			return PROFILE_DEAD_END_SOUTH
		if open_east:
			return PROFILE_DEAD_END_EAST
		return PROFILE_DEAD_END_WEST
	if open_north and open_south and not open_east and not open_west:
		return PROFILE_STRAIGHT_VERTICAL
	if open_east and open_west and not open_north and not open_south:
		return PROFILE_STRAIGHT_HORIZONTAL
	return "default"
