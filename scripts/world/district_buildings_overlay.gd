@tool
extends Node2D

@export_range(0, 9, 1) var building_density := 0:
	set(value):
		building_density = value
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
const SIDEWALK_WIDTH := 44.0
const PROFILE_STRAIGHT_HORIZONTAL := "straight_horizontal"
const PROFILE_STRAIGHT_VERTICAL := "straight_vertical"
const PROFILE_DEAD_END_NORTH := "dead_end_north"
const PROFILE_DEAD_END_SOUTH := "dead_end_south"
const PROFILE_DEAD_END_EAST := "dead_end_east"
const PROFILE_DEAD_END_WEST := "dead_end_west"
const BUILDING_COLOR_A := Color(0.372549, 0.356863, 0.333333, 1)
const BUILDING_COLOR_B := Color(0.337255, 0.392157, 0.333333, 1)

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

	if building_density <= 0:
		return

	var profile := _get_tile_profile()
	var half_width := tile_world_size.x * 0.5
	var half_height := tile_world_size.y * 0.5
	var margin := 56.0
	var density_t := float(building_density) / 9.0

	match profile:
		PROFILE_DEAD_END_NORTH:
			_add_dead_end_north_buildings(half_width, half_height, margin, density_t)
		PROFILE_DEAD_END_SOUTH:
			_add_dead_end_south_buildings(half_width, half_height, margin, density_t)
		PROFILE_DEAD_END_EAST:
			_add_dead_end_east_buildings(half_width, half_height, margin, density_t)
		PROFILE_DEAD_END_WEST:
			_add_dead_end_west_buildings(half_width, half_height, margin, density_t)
		PROFILE_STRAIGHT_VERTICAL:
			var block_width := lerpf(160.0, half_width - ROAD_HALF_WIDTH - SIDEWALK_WIDTH - margin, density_t)
			_add_block(
				Vector2(-half_width + margin, -half_height + margin),
				Vector2(block_width, tile_world_size.y - margin * 2.0),
				BUILDING_COLOR_A
			)
			_add_block(
				Vector2(ROAD_HALF_WIDTH + SIDEWALK_WIDTH + margin, -half_height + margin),
				Vector2(block_width, tile_world_size.y - margin * 2.0),
				BUILDING_COLOR_B
			)
		PROFILE_STRAIGHT_HORIZONTAL:
			var block_height := lerpf(160.0, half_height - ROAD_HALF_WIDTH - SIDEWALK_WIDTH - margin, density_t)
			_add_block(
				Vector2(-half_width + margin, -half_height + margin),
				Vector2(tile_world_size.x - margin * 2.0, block_height),
				BUILDING_COLOR_A
			)
			_add_block(
				Vector2(-half_width + margin, ROAD_HALF_WIDTH + SIDEWALK_WIDTH + margin),
				Vector2(tile_world_size.x - margin * 2.0, block_height),
				BUILDING_COLOR_B
			)
		_:
			var x_extent := half_width - ROAD_HALF_WIDTH - SIDEWALK_WIDTH - margin
			var y_extent := half_height - ROAD_HALF_WIDTH - SIDEWALK_WIDTH - margin
			var block_size := Vector2(
				lerpf(140.0, x_extent, density_t),
				lerpf(120.0, y_extent, density_t)
			)
			_add_block(
				Vector2(-half_width + margin, -half_height + margin),
				block_size,
				BUILDING_COLOR_A
			)
			_add_block(
				Vector2(ROAD_HALF_WIDTH + SIDEWALK_WIDTH + margin, -half_height + margin),
				block_size,
				BUILDING_COLOR_B
			)
			_add_block(
				Vector2(-half_width + margin, ROAD_HALF_WIDTH + SIDEWALK_WIDTH + margin),
				block_size,
				BUILDING_COLOR_B
			)
			_add_block(
				Vector2(ROAD_HALF_WIDTH + SIDEWALK_WIDTH + margin, ROAD_HALF_WIDTH + SIDEWALK_WIDTH + margin),
				block_size,
				BUILDING_COLOR_A
			)

func _add_dead_end_north_buildings(half_width: float, half_height: float, margin: float, density_t: float) -> void:
	var side_width := lerpf(120.0, half_width - 224.0 - margin, density_t)
	var side_height := lerpf(180.0, 360.0, density_t)
	var top_height := lerpf(120.0, half_height - 264.0 - margin, density_t)
	_add_block(Vector2(-half_width + margin, -half_height + margin), Vector2(side_width, side_height), BUILDING_COLOR_A)
	_add_block(Vector2(half_width - margin - side_width, -half_height + margin), Vector2(side_width, side_height), BUILDING_COLOR_B)
	_add_block(Vector2(-half_width + margin, 264.0), Vector2(tile_world_size.x - margin * 2.0, top_height), BUILDING_COLOR_A)

func _add_dead_end_south_buildings(half_width: float, half_height: float, margin: float, density_t: float) -> void:
	var side_width := lerpf(120.0, half_width - 224.0 - margin, density_t)
	var side_height := lerpf(180.0, 360.0, density_t)
	var bottom_height := lerpf(120.0, half_height - 264.0 - margin, density_t)
	_add_block(Vector2(-half_width + margin, half_height - margin - side_height), Vector2(side_width, side_height), BUILDING_COLOR_A)
	_add_block(Vector2(half_width - margin - side_width, half_height - margin - side_height), Vector2(side_width, side_height), BUILDING_COLOR_B)
	_add_block(Vector2(-half_width + margin, -half_height + margin), Vector2(tile_world_size.x - margin * 2.0, bottom_height), BUILDING_COLOR_A)

func _add_dead_end_east_buildings(half_width: float, half_height: float, margin: float, density_t: float) -> void:
	var side_height := lerpf(120.0, half_height - 224.0 - margin, density_t)
	var side_width := lerpf(180.0, 360.0, density_t)
	var left_width := lerpf(120.0, half_width - 264.0 - margin, density_t)
	_add_block(Vector2(-half_width + margin, -half_height + margin), Vector2(side_width, side_height), BUILDING_COLOR_A)
	_add_block(Vector2(-half_width + margin, half_height - margin - side_height), Vector2(side_width, side_height), BUILDING_COLOR_B)
	_add_block(Vector2(264.0, -half_height + margin), Vector2(left_width, tile_world_size.y - margin * 2.0), BUILDING_COLOR_A)

func _add_dead_end_west_buildings(half_width: float, half_height: float, margin: float, density_t: float) -> void:
	var side_height := lerpf(120.0, half_height - 224.0 - margin, density_t)
	var side_width := lerpf(180.0, 360.0, density_t)
	var right_width := lerpf(120.0, half_width - 264.0 - margin, density_t)
	_add_block(Vector2(half_width - margin - side_width, -half_height + margin), Vector2(side_width, side_height), BUILDING_COLOR_A)
	_add_block(Vector2(half_width - margin - side_width, half_height - margin - side_height), Vector2(side_width, side_height), BUILDING_COLOR_B)
	_add_block(Vector2(-half_width + margin, -half_height + margin), Vector2(right_width, tile_world_size.y - margin * 2.0), BUILDING_COLOR_A)

func _add_block(top_left: Vector2, size: Vector2, color: Color) -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return

	var body := StaticBody2D.new()
	body.position = top_left + size * 0.5
	add_child(body)

	var collision_shape := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision_shape.shape = shape
	body.add_child(collision_shape)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5),
	])
	visual.color = color
	body.add_child(visual)

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
