@tool
extends Node2D

const CivilianScene = preload("res://scenes/actors/civilians/civilian_pedestrian.tscn")
const TrafficScene = preload("res://scenes/vehicles/civilian/civilian_vehicle_actor.tscn")

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

const SIDEWALK_OFFSET := 118.0
const CROSSWALK_OFFSET := 140.0
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
		_add_traffic(route_data)

func _add_pedestrian(path: PackedVector2Array) -> void:
	if path.size() < 2:
		return
	var actor = CivilianScene.instantiate()
	actor.position = to_local(path[0])
	add_child(actor)
	if Engine.is_editor_hint():
		return
	if actor.has_method("set_world_path"):
		actor.call("set_world_path", path)
	if actor.has_method("set_path_active"):
		actor.call("set_path_active", true)

func _add_traffic(route_data: Dictionary) -> void:
	var actor = TrafficScene.instantiate()
	add_child(actor)
	if Engine.is_editor_hint():
		return
	if actor.has_method("initialize_runtime_spawn"):
		actor.call(
			"initialize_runtime_spawn",
			route_data.get("heading", ""),
			route_data.get("lane", "right"),
			route_data.get("action", "straight")
		)
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

func _open_side_count() -> int:
	return int(open_north) + int(open_south) + int(open_east) + int(open_west)

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
