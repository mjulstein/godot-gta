@tool
extends Node2D

const CivilianScene = preload("res://scenes/actors/civilians/civilian_pedestrian.tscn")
const TrafficScene = preload("res://scenes/vehicles/civilian/civilian_vehicle_actor.tscn")

@export_range(0, 9, 1) var activity_density := 0:
	set(value):
		activity_density = value
		_rebuild_if_ready()

@export_range(0, 9, 1) var pedestrian_density := 0:
	set(value):
		pedestrian_density = value
		_rebuild_if_ready()

@export_range(0, 9, 1) var traffic_density := 0:
	set(value):
		traffic_density = value
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
const CURB_RUN_OFFSET := 244.0
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

	var effective_pedestrian_density := pedestrian_density if pedestrian_density > 0 else activity_density
	var effective_traffic_density := traffic_density if traffic_density > 0 else activity_density
	if effective_pedestrian_density <= 0 and effective_traffic_density <= 0:
		return

	var traffic_routes := _build_traffic_routes()
	var pedestrian_spawn_count := 0
	if effective_pedestrian_density >= 8:
		pedestrian_spawn_count = 4
	elif effective_pedestrian_density >= 6:
		pedestrian_spawn_count = 3
	elif effective_pedestrian_density >= 3:
		pedestrian_spawn_count = 2
	elif effective_pedestrian_density >= 1:
		pedestrian_spawn_count = 1
	for spawn_data in _build_pedestrian_spawns(pedestrian_spawn_count):
		_add_pedestrian(spawn_data)
	for route_data in _select_traffic_routes(traffic_routes, effective_traffic_density):
		_add_traffic(route_data)

func _add_pedestrian(spawn_data: Dictionary) -> void:
	if spawn_data.is_empty():
		return
	var actor = CivilianScene.instantiate()
	actor.position = to_local(spawn_data.get("position", global_position))
	add_child(actor)
	if Engine.is_editor_hint():
		return
	if actor.has_method("configure_ambient_walk"):
		actor.call(
			"configure_ambient_walk",
			spawn_data.get("network", []),
			spawn_data.get("start_index", -1),
			spawn_data.get("next_index", -1),
			spawn_data.get("group_id", -1),
			spawn_data.get("group_slot", 0),
			spawn_data.get("group_size", 1)
		)
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

func _build_pedestrian_spawns(spawn_count: int) -> Array[Dictionary]:
	var spawns: Array[Dictionary] = []
	if spawn_count <= 0:
		return spawns
	var network := _build_pedestrian_network()
	if network.is_empty():
		return spawns
	var start_nodes := _build_pedestrian_start_nodes(network)
	if start_nodes.is_empty():
		return spawns
	var seed: int = abs(_traffic_seed()) + 17
	var group_sizes := _build_pedestrian_group_sizes(spawn_count)
	var group_index := 0
	var start_offset: int = seed % start_nodes.size()
	for size in group_sizes:
		var start_index: int = start_nodes[(start_offset + group_index) % start_nodes.size()]
		var next_index := _find_initial_pedestrian_target(network, start_index)
		var forward := (_network_position(network, next_index) - _network_position(network, start_index)).normalized()
		if forward == Vector2.ZERO:
			forward = Vector2.RIGHT
		var group_id: int = seed * 10 + group_index
		for slot in range(size):
			spawns.append({
				"position": _network_position(network, start_index) + _pedestrian_group_offset(slot, size, forward),
				"network": network,
				"start_index": start_index,
				"next_index": next_index,
				"group_id": group_id,
				"group_slot": slot,
				"group_size": size,
			})
		group_index += 1
	return spawns

func _build_pedestrian_network() -> Array:
	var network: Array = []
	var half_width := tile_world_size.x * 0.5
	var half_height := tile_world_size.y * 0.5
	var profile := _get_tile_profile()
	var inset := 56.0

	match profile:
		PROFILE_STRAIGHT_HORIZONTAL:
			network = _build_horizontal_sidewalk_network(half_width, inset)
		PROFILE_STRAIGHT_VERTICAL:
			network = _build_vertical_sidewalk_network(half_height, inset)
		PROFILE_DEAD_END_NORTH, PROFILE_DEAD_END_SOUTH:
			network = _build_vertical_sidewalk_network(half_height, inset)
		PROFILE_DEAD_END_EAST, PROFILE_DEAD_END_WEST:
			network = _build_horizontal_sidewalk_network(half_width, inset)
		_:
			network = _build_intersection_pedestrian_network(half_width, half_height, inset)

	return network

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

func _select_traffic_routes(candidates: Array[Dictionary], density: int) -> Array[Dictionary]:
	var selected: Array[Dictionary] = []
	var spawn_count := 0
	if density >= 8:
		spawn_count = 4
	elif density >= 6:
		spawn_count = 3
	elif density >= 4:
		spawn_count = 2
	elif density >= 2:
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
	var seed_density := pedestrian_density + traffic_density + activity_density
	return int(global_position.x / tile_world_size.x) * 73856093 + int(global_position.y / tile_world_size.y) * 19349663 + seed_density * 83492791

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

func _build_horizontal_sidewalk_network(half_width: float, inset: float) -> Array:
	var network := [
		_node(Vector2(-minf(CURB_RUN_OFFSET, half_width - inset), -SIDEWALK_OFFSET)),
		_node(Vector2(0, -SIDEWALK_OFFSET)),
		_node(Vector2(minf(CURB_RUN_OFFSET, half_width - inset), -SIDEWALK_OFFSET)),
		_node(Vector2(minf(CURB_RUN_OFFSET, half_width - inset), SIDEWALK_OFFSET)),
		_node(Vector2(0, SIDEWALK_OFFSET)),
		_node(Vector2(-minf(CURB_RUN_OFFSET, half_width - inset), SIDEWALK_OFFSET)),
	]
	_connect_nodes(network, 0, 1)
	_connect_nodes(network, 1, 2)
	_connect_nodes(network, 3, 4)
	_connect_nodes(network, 4, 5)
	return _world_network(network)

func _build_vertical_sidewalk_network(half_height: float, inset: float) -> Array:
	var network := [
		_node(Vector2(-SIDEWALK_OFFSET, -minf(CURB_RUN_OFFSET, half_height - inset))),
		_node(Vector2(-SIDEWALK_OFFSET, 0)),
		_node(Vector2(-SIDEWALK_OFFSET, minf(CURB_RUN_OFFSET, half_height - inset))),
		_node(Vector2(SIDEWALK_OFFSET, minf(CURB_RUN_OFFSET, half_height - inset))),
		_node(Vector2(SIDEWALK_OFFSET, 0)),
		_node(Vector2(SIDEWALK_OFFSET, -minf(CURB_RUN_OFFSET, half_height - inset))),
	]
	_connect_nodes(network, 0, 1)
	_connect_nodes(network, 1, 2)
	_connect_nodes(network, 3, 4)
	_connect_nodes(network, 4, 5)
	return _world_network(network)

func _build_intersection_pedestrian_network(half_width: float, half_height: float, inset: float) -> Array:
	var curb_x := minf(CURB_RUN_OFFSET, half_width - inset)
	var curb_y := minf(CURB_RUN_OFFSET, half_height - inset)
	var network := [
		_node(Vector2(-curb_x, -SIDEWALK_OFFSET)),
		_node(Vector2(-SIDEWALK_OFFSET, -SIDEWALK_OFFSET)),
		_node(Vector2(SIDEWALK_OFFSET, -SIDEWALK_OFFSET)),
		_node(Vector2(curb_x, -SIDEWALK_OFFSET)),
		_node(Vector2(curb_x, SIDEWALK_OFFSET)),
		_node(Vector2(SIDEWALK_OFFSET, SIDEWALK_OFFSET)),
		_node(Vector2(-SIDEWALK_OFFSET, SIDEWALK_OFFSET)),
		_node(Vector2(-curb_x, SIDEWALK_OFFSET)),
		_node(Vector2(-SIDEWALK_OFFSET, -curb_y)),
		_node(Vector2(SIDEWALK_OFFSET, -curb_y)),
		_node(Vector2(SIDEWALK_OFFSET, curb_y)),
		_node(Vector2(-SIDEWALK_OFFSET, curb_y)),
	]
	_connect_nodes(network, 0, 1)
	_connect_nodes(network, 1, 2, true)
	_connect_nodes(network, 2, 3)
	_connect_nodes(network, 4, 5)
	_connect_nodes(network, 5, 6, true)
	_connect_nodes(network, 6, 7)
	_connect_nodes(network, 8, 1)
	_connect_nodes(network, 1, 6, true)
	_connect_nodes(network, 6, 11)
	_connect_nodes(network, 9, 2)
	_connect_nodes(network, 2, 5, true)
	_connect_nodes(network, 5, 10)
	return _world_network(network)

func _build_pedestrian_start_nodes(network: Array) -> PackedInt32Array:
	var starts := PackedInt32Array()
	for index in range(network.size()):
		var node: Dictionary = network[index]
		var crosswalk_neighbors: PackedInt32Array = node.get("crosswalk_neighbors", PackedInt32Array())
		if crosswalk_neighbors.is_empty():
			starts.append(index)
	return starts

func _build_pedestrian_group_sizes(spawn_count: int) -> PackedInt32Array:
	match spawn_count:
		1:
			return PackedInt32Array([1])
		2:
			return PackedInt32Array([2])
		3:
			return PackedInt32Array([3])
		_:
			return PackedInt32Array([4])

func _find_initial_pedestrian_target(network: Array, start_index: int) -> int:
	if start_index < 0 or start_index >= network.size():
		return -1
	var neighbors: PackedInt32Array = network[start_index].get("neighbors", PackedInt32Array())
	for neighbor in neighbors:
		if network[start_index].get("crosswalk_neighbors", PackedInt32Array()).has(neighbor):
			continue
		return neighbor
	return neighbors[0] if not neighbors.is_empty() else -1

func _pedestrian_group_offset(slot: int, group_size: int, forward_direction: Vector2) -> Vector2:
	var forward := forward_direction.normalized() if forward_direction != Vector2.ZERO else Vector2.RIGHT
	var side := forward.orthogonal()
	if group_size <= 1:
		return Vector2.ZERO
	if group_size > 3:
		return -forward * 12.0 * float(slot)
	if group_size == 2:
		return side * (-10.0 if slot == 0 else 10.0)
	if slot == 0:
		return side * -10.0
	if slot == 1:
		return side * 10.0
	return -forward * 12.0

func _node(position: Vector2) -> Dictionary:
	return {
		"position": position,
		"neighbors": PackedInt32Array(),
		"crosswalk_neighbors": PackedInt32Array(),
	}

func _connect_nodes(network: Array, from_index: int, to_index: int, is_crosswalk: bool = false) -> void:
	_append_neighbor(network[from_index], to_index, is_crosswalk)
	_append_neighbor(network[to_index], from_index, is_crosswalk)

func _append_neighbor(node: Dictionary, neighbor: int, is_crosswalk: bool) -> void:
	var neighbors: PackedInt32Array = node.get("neighbors", PackedInt32Array())
	if not neighbors.has(neighbor):
		neighbors.append(neighbor)
	node["neighbors"] = neighbors
	if is_crosswalk:
		var crosswalk_neighbors: PackedInt32Array = node.get("crosswalk_neighbors", PackedInt32Array())
		if not crosswalk_neighbors.has(neighbor):
			crosswalk_neighbors.append(neighbor)
		node["crosswalk_neighbors"] = crosswalk_neighbors

func _world_network(local_network: Array) -> Array:
	var world_network: Array = []
	for node in local_network:
		var world_node: Dictionary = node.duplicate(true)
		world_node["position"] = global_position + node.get("position", Vector2.ZERO)
		world_network.append(world_node)
	return world_network

func _network_position(network: Array, index: int) -> Vector2:
	if index < 0 or index >= network.size():
		return global_position
	return network[index].get("position", global_position)

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
