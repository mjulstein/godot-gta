@tool
extends Node2D

@export var open_north := true:
	set(value):
		open_north = value
		refresh_tile_profile()

@export var open_south := true:
	set(value):
		open_south = value
		refresh_tile_profile()

@export var open_east := true:
	set(value):
		open_east = value
		refresh_tile_profile()

@export var open_west := true:
	set(value):
		open_west = value
		refresh_tile_profile()

@export var tile_world_size := Vector2(1280, 1280):
	set(value):
		tile_world_size = value
		refresh_tile_profile()

@export_range(0, 32, 1) var north_span_tiles := 0:
	set(value):
		north_span_tiles = value
		refresh_tile_profile()

@export_range(0, 32, 1) var south_span_tiles := 0:
	set(value):
		south_span_tiles = value
		refresh_tile_profile()

@export_range(0, 32, 1) var east_span_tiles := 0:
	set(value):
		east_span_tiles = value
		refresh_tile_profile()

@export_range(0, 32, 1) var west_span_tiles := 0:
	set(value):
		west_span_tiles = value
		refresh_tile_profile()

const HORIZONTAL_LANE_Y := 58.0
const VERTICAL_LANE_X := 58.0
const NORTH_SIDEWALK_Y := -118.0
const SOUTH_SIDEWALK_Y := 118.0
const WEST_SIDEWALK_X := -118.0
const EAST_SIDEWALK_X := 118.0
const PROFILE_DEFAULT := "default"
const PROFILE_STRAIGHT_HORIZONTAL := "straight_horizontal"
const PROFILE_STRAIGHT_VERTICAL := "straight_vertical"
const PROFILE_DEAD_END_NORTH := "dead_end_north"
const PROFILE_DEAD_END_SOUTH := "dead_end_south"
const PROFILE_DEAD_END_EAST := "dead_end_east"
const PROFILE_DEAD_END_WEST := "dead_end_west"
const SURFACE_BLOCKED := "blocked"
const SURFACE_ROAD := "road"
const SURFACE_SIDEWALK := "sidewalk"
const SURFACE_CROSSWALK := "crosswalk"

var _surface_polygon_cache := {
	SURFACE_ROAD: [],
	SURFACE_SIDEWALK: [],
	SURFACE_CROSSWALK: [],
}

func _ready() -> void:
	add_to_group("district_tile")
	refresh_tile_profile()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not has_node("Ground"):
		warnings.append("District slice expects a Ground node.")
	return warnings

func refresh_tile_profile() -> void:
	_update_exit_visibility()
	_update_ground_profile()
	_rebuild_surface_polygon_cache()

func _update_exit_visibility() -> void:
	if not is_node_ready():
		return

	_set_exit_state("North", open_north)
	_set_exit_state("South", open_south)
	_set_exit_state("East", open_east)
	_set_exit_state("West", open_west)

func _update_ground_profile() -> void:
	if not is_node_ready():
		return

	var profile := _get_tile_profile()
	var is_vertical_straight := profile == PROFILE_STRAIGHT_VERTICAL
	var is_horizontal_straight := profile == PROFILE_STRAIGHT_HORIZONTAL
	var is_dead_end := profile.begins_with("dead_end")

	_set_node_visible("Ground/StraightSidewalkWest", false)
	_set_node_visible("Ground/StraightSidewalkEast", false)
	_set_node_visible("Ground/StraightSidewalkNorth", false)
	_set_node_visible("Ground/StraightSidewalkSouth", false)
	_set_node_visible("Ground/StraightStripeVertical", is_vertical_straight)
	_set_node_visible("Ground/StraightStripeHorizontal", is_horizontal_straight)

	_set_node_visible("Ground/ParkingLotNorth", profile == PROFILE_DEAD_END_NORTH)
	_set_node_visible("Ground/ParkingLotSouth", profile == PROFILE_DEAD_END_SOUTH)
	_set_node_visible("Ground/ParkingLotEast", profile == PROFILE_DEAD_END_EAST)
	_set_node_visible("Ground/ParkingLotWest", profile == PROFILE_DEAD_END_WEST)
	_set_node_visible("Ground/ParkingLotSidewalkNorthLeft", profile == PROFILE_DEAD_END_NORTH)
	_set_node_visible("Ground/ParkingLotSidewalkNorthRight", profile == PROFILE_DEAD_END_NORTH)
	_set_node_visible("Ground/ParkingLotSidewalkNorthBottom", profile == PROFILE_DEAD_END_NORTH)
	_set_node_visible("Ground/ParkingLotSidewalkNorthEntryLeft", profile == PROFILE_DEAD_END_NORTH)
	_set_node_visible("Ground/ParkingLotSidewalkNorthEntryRight", profile == PROFILE_DEAD_END_NORTH)
	_set_node_visible("Ground/ParkingLotSidewalkSouthLeft", profile == PROFILE_DEAD_END_SOUTH)
	_set_node_visible("Ground/ParkingLotSidewalkSouthRight", profile == PROFILE_DEAD_END_SOUTH)
	_set_node_visible("Ground/ParkingLotSidewalkSouthTop", profile == PROFILE_DEAD_END_SOUTH)
	_set_node_visible("Ground/ParkingLotSidewalkSouthEntryLeft", profile == PROFILE_DEAD_END_SOUTH)
	_set_node_visible("Ground/ParkingLotSidewalkSouthEntryRight", profile == PROFILE_DEAD_END_SOUTH)
	_set_node_visible("Ground/ParkingLotSidewalkEastTop", profile == PROFILE_DEAD_END_EAST)
	_set_node_visible("Ground/ParkingLotSidewalkEastBottom", profile == PROFILE_DEAD_END_EAST)
	_set_node_visible("Ground/ParkingLotSidewalkEastLeft", profile == PROFILE_DEAD_END_EAST)
	_set_node_visible("Ground/ParkingLotSidewalkEastEntryTop", profile == PROFILE_DEAD_END_EAST)
	_set_node_visible("Ground/ParkingLotSidewalkEastEntryBottom", profile == PROFILE_DEAD_END_EAST)
	_set_node_visible("Ground/ParkingLotSidewalkWestTop", profile == PROFILE_DEAD_END_WEST)
	_set_node_visible("Ground/ParkingLotSidewalkWestBottom", profile == PROFILE_DEAD_END_WEST)
	_set_node_visible("Ground/ParkingLotSidewalkWestRight", profile == PROFILE_DEAD_END_WEST)
	_set_node_visible("Ground/ParkingLotSidewalkWestEntryTop", profile == PROFILE_DEAD_END_WEST)
	_set_node_visible("Ground/ParkingLotSidewalkWestEntryBottom", profile == PROFILE_DEAD_END_WEST)

	_set_node_visible("Ground/RoadIntersection", profile == PROFILE_DEFAULT or is_vertical_straight or is_horizontal_straight)
	if is_horizontal_straight:
		_set_node_visible("Ground/ClosureNorth", true)
		_set_node_visible("Ground/ClosureSouth", true)
		_set_node_visible("Ground/ClosureEast", false)
		_set_node_visible("Ground/ClosureWest", false)
	if is_vertical_straight:
		_set_node_visible("Ground/ClosureEast", true)
		_set_node_visible("Ground/ClosureWest", true)
		_set_node_visible("Ground/ClosureNorth", false)
		_set_node_visible("Ground/ClosureSouth", false)
	if is_dead_end:
		_set_node_visible("Ground/ClosureNorth", false)
		_set_node_visible("Ground/ClosureSouth", false)
		_set_node_visible("Ground/ClosureEast", false)
		_set_node_visible("Ground/ClosureWest", false)

	var show_crosswalks := not (is_vertical_straight or is_horizontal_straight)
	if is_dead_end:
		show_crosswalks = false
	for crosswalk_path in [
		"Ground/RoadWest/CrosswalkEast",
		"Ground/RoadEast/CrosswalkWest",
		"Ground/RoadNorth/CrosswalkSouth",
		"Ground/RoadSouth/CrosswalkNorth",
	]:
		_set_node_visible(crosswalk_path, show_crosswalks)

func _set_exit_state(direction: String, is_open: bool) -> void:
	var road := get_node_or_null("Ground/Road%s" % direction)
	var cap := get_node_or_null("Ground/Closure%s" % direction)
	if road != null:
		road.visible = is_open
	if cap != null:
		cap.visible = not is_open
	for sidewalk_path in _get_sidewalk_paths(direction):
		var sidewalk := get_node_or_null(sidewalk_path)
		if sidewalk != null:
			sidewalk.visible = is_open

func _get_sidewalk_paths(direction: String) -> PackedStringArray:
	match direction:
		"North":
			return PackedStringArray([
				"Ground/SidewalkWestNorth",
				"Ground/SidewalkEastNorth",
			])
		"South":
			return PackedStringArray([
				"Ground/SidewalkWestSouth",
				"Ground/SidewalkEastSouth",
			])
		"East":
			return PackedStringArray([
				"Ground/SidewalkNorthEast",
				"Ground/SidewalkSouthEast",
			])
		"West":
			return PackedStringArray([
				"Ground/SidewalkNorthWest",
				"Ground/SidewalkSouthWest",
			])
		_:
			return PackedStringArray()

func _set_node_visible(node_path: String, is_visible: bool) -> void:
	var node = get_node_or_null(node_path)
	if node != null:
		node.visible = is_visible

func get_tile_profile_name() -> String:
	return _get_tile_profile()

func get_surface_type_at_world_position(world_position: Vector2) -> String:
	if _point_in_cached_polygons(world_position, SURFACE_CROSSWALK):
		return SURFACE_CROSSWALK
	if _point_in_cached_polygons(world_position, SURFACE_SIDEWALK):
		return SURFACE_SIDEWALK
	if _point_in_cached_polygons(world_position, SURFACE_ROAD):
		return SURFACE_ROAD
	return SURFACE_BLOCKED

func is_walkable_world_position(world_position: Vector2) -> bool:
	var surface_type := get_surface_type_at_world_position(world_position)
	return surface_type == SURFACE_SIDEWALK or surface_type == SURFACE_CROSSWALK

func is_sidewalk_world_position(world_position: Vector2) -> bool:
	return get_surface_type_at_world_position(world_position) == SURFACE_SIDEWALK

func get_dead_end_parking_data(entry_heading: String) -> Dictionary:
	var profile := _get_tile_profile()
	match profile:
		PROFILE_DEAD_END_NORTH:
			return {
				"spot": global_position + Vector2(-36, -236),
				"sidewalk": global_position + Vector2(-118, -118),
				"roam_axis": Vector2.RIGHT,
				"facing": Vector2.UP,
			}
		PROFILE_DEAD_END_SOUTH:
			return {
				"spot": global_position + Vector2(36, 236),
				"sidewalk": global_position + Vector2(118, 118),
				"roam_axis": Vector2.LEFT,
				"facing": Vector2.DOWN,
			}
		PROFILE_DEAD_END_EAST:
			return {
				"spot": global_position + Vector2(236, 36),
				"sidewalk": global_position + Vector2(118, -118),
				"roam_axis": Vector2.DOWN,
				"facing": Vector2.RIGHT,
			}
		PROFILE_DEAD_END_WEST:
			return {
				"spot": global_position + Vector2(-236, -36),
				"sidewalk": global_position + Vector2(-118, 118),
				"roam_axis": Vector2.UP,
				"facing": Vector2.LEFT,
			}
		_:
			return {}

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
	return PROFILE_DEFAULT

func _rebuild_surface_polygon_cache() -> void:
	_surface_polygon_cache = {
		SURFACE_ROAD: [],
		SURFACE_SIDEWALK: [],
		SURFACE_CROSSWALK: [],
	}
	var ground := get_node_or_null("Ground")
	if ground == null:
		return
	_collect_surface_polygons(ground)

func _collect_surface_polygons(node: Node) -> void:
	for child in node.get_children():
		if child is Polygon2D:
			var polygon := child as Polygon2D
			if polygon.visible:
				var surface_type := _surface_type_for_polygon_name(polygon.name)
				if not surface_type.is_empty():
					_surface_polygon_cache[surface_type].append({
						"inverse_transform": polygon.global_transform.affine_inverse(),
						"polygon": polygon.polygon,
					})
		_collect_surface_polygons(child)

func _point_in_cached_polygons(world_position: Vector2, surface_type: String) -> bool:
	var polygons: Array = _surface_polygon_cache.get(surface_type, [])
	for polygon_data in polygons:
		var inverse_transform: Transform2D = polygon_data["inverse_transform"]
		var local_point := inverse_transform * world_position
		var polygon: PackedVector2Array = polygon_data["polygon"]
		if Geometry2D.is_point_in_polygon(local_point, polygon):
			return true
	return false

func _surface_type_for_polygon_name(node_name: String) -> String:
	if node_name.contains("Crosswalk"):
		return SURFACE_CROSSWALK
	if node_name.contains("Sidewalk"):
		return SURFACE_SIDEWALK
	if node_name.begins_with("Road") or node_name.begins_with("ParkingLot"):
		return SURFACE_ROAD
	return ""
