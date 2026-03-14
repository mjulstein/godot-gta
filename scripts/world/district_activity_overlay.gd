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

const ROAD_HALF_WIDTH := 96.0
const LANE_OFFSET := 58.0
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
	if activity_density >= 3 and traffic_routes.size() > 0:
		_add_traffic(traffic_routes[0])
	if activity_density >= 7 and traffic_routes.size() > 1:
		_add_traffic(traffic_routes[1])

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

func _build_traffic_routes() -> Array[PackedVector2Array]:
	var routes: Array[PackedVector2Array] = []
	var half_width := tile_world_size.x * 0.5
	var half_height := tile_world_size.y * 0.5
	var profile := _get_tile_profile()

	match profile:
		PROFILE_STRAIGHT_HORIZONTAL:
			routes.append(_to_world_path([Vector2(-half_width, LANE_OFFSET), Vector2(half_width, LANE_OFFSET)]))
			routes.append(_to_world_path([Vector2(half_width, -LANE_OFFSET), Vector2(-half_width, -LANE_OFFSET)]))
		PROFILE_STRAIGHT_VERTICAL:
			routes.append(_to_world_path([Vector2(LANE_OFFSET, -half_height), Vector2(LANE_OFFSET, half_height)]))
			routes.append(_to_world_path([Vector2(-LANE_OFFSET, half_height), Vector2(-LANE_OFFSET, -half_height)]))
		PROFILE_DEAD_END_NORTH:
			routes.append(_to_world_path([Vector2(LANE_OFFSET, -half_height), Vector2(LANE_OFFSET, 0)]))
		PROFILE_DEAD_END_SOUTH:
			routes.append(_to_world_path([Vector2(-LANE_OFFSET, half_height), Vector2(-LANE_OFFSET, 0)]))
		PROFILE_DEAD_END_EAST:
			routes.append(_to_world_path([Vector2(half_width, -LANE_OFFSET), Vector2(0, -LANE_OFFSET)]))
		PROFILE_DEAD_END_WEST:
			routes.append(_to_world_path([Vector2(-half_width, LANE_OFFSET), Vector2(0, LANE_OFFSET)]))
		_:
			if open_north and open_east and not open_south and not open_west:
				routes.append(_to_world_path([Vector2(LANE_OFFSET, -half_height), Vector2(LANE_OFFSET, -LANE_OFFSET), Vector2(half_width, -LANE_OFFSET)]))
			elif open_north and open_west and not open_south and not open_east:
				routes.append(_to_world_path([Vector2(-LANE_OFFSET, -half_height), Vector2(-LANE_OFFSET, LANE_OFFSET), Vector2(-half_width, LANE_OFFSET)]))
			elif open_south and open_east and not open_north and not open_west:
				routes.append(_to_world_path([Vector2(-LANE_OFFSET, half_height), Vector2(-LANE_OFFSET, -LANE_OFFSET), Vector2(half_width, -LANE_OFFSET)]))
			elif open_south and open_west and not open_north and not open_east:
				routes.append(_to_world_path([Vector2(LANE_OFFSET, half_height), Vector2(LANE_OFFSET, LANE_OFFSET), Vector2(-half_width, LANE_OFFSET)]))
			else:
				if open_east or open_west:
					routes.append(_to_world_path([Vector2(-half_width, LANE_OFFSET), Vector2(half_width, LANE_OFFSET)]))
				if open_north or open_south:
					routes.append(_to_world_path([Vector2(-LANE_OFFSET, half_height), Vector2(-LANE_OFFSET, -half_height)]))

	return routes

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
