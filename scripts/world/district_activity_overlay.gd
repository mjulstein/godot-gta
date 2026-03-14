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

const HORIZONTAL_LANE_Y := 58.0
const VERTICAL_LANE_X := 58.0
const NORTH_SIDEWALK_Y := -118.0
const SOUTH_SIDEWALK_Y := 118.0
const WEST_SIDEWALK_X := -118.0
const EAST_SIDEWALK_X := 118.0

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

	var horizontal_open := open_east or open_west
	var vertical_open := open_north or open_south

	if activity_density >= 2:
		if horizontal_open:
			_add_pedestrian(Vector2(-42, NORTH_SIDEWALK_Y), _build_horizontal_path(NORTH_SIDEWALK_Y))
		elif vertical_open:
			_add_pedestrian(Vector2(WEST_SIDEWALK_X, -42), _build_vertical_path(WEST_SIDEWALK_X))

	if activity_density >= 5:
		if vertical_open:
			_add_pedestrian(Vector2(EAST_SIDEWALK_X, 24), _build_vertical_path(EAST_SIDEWALK_X))
		elif horizontal_open:
			_add_pedestrian(Vector2(24, SOUTH_SIDEWALK_Y), _build_horizontal_path(SOUTH_SIDEWALK_Y))

	if activity_density >= 3:
		if horizontal_open:
			_add_traffic(Vector2(0, HORIZONTAL_LANE_Y), _build_horizontal_path(HORIZONTAL_LANE_Y))
		elif vertical_open:
			_add_traffic(Vector2(VERTICAL_LANE_X, 0), _build_vertical_path(VERTICAL_LANE_X))

func _add_pedestrian(local_position: Vector2, path: PackedVector2Array) -> void:
	var actor = CivilianScene.instantiate()
	actor.position = local_position
	add_child(actor)
	if actor.has_method("set_world_path"):
		actor.call("set_world_path", path)
	if actor.has_method("set_path_active"):
		actor.call("set_path_active", path.size() >= 2)

func _add_traffic(local_position: Vector2, path: PackedVector2Array) -> void:
	var actor = TrafficScene.instantiate()
	actor.position = local_position
	add_child(actor)
	if actor.has_method("set_world_path"):
		actor.call("set_world_path", path)
	if actor.has_method("set_path_active"):
		actor.call("set_path_active", path.size() >= 2)

func _build_horizontal_path(y_offset: float) -> PackedVector2Array:
	var half_width := tile_world_size.x * 0.5
	return PackedVector2Array([
		global_position + Vector2(-half_width - west_span_tiles * tile_world_size.x, y_offset),
		global_position + Vector2(half_width + east_span_tiles * tile_world_size.x, y_offset),
	])

func _build_vertical_path(x_offset: float) -> PackedVector2Array:
	var half_height := tile_world_size.y * 0.5
	return PackedVector2Array([
		global_position + Vector2(x_offset, -half_height - north_span_tiles * tile_world_size.y),
		global_position + Vector2(x_offset, half_height + south_span_tiles * tile_world_size.y),
	])
