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

func _ready() -> void:
	add_to_group("district_tile")
	refresh_tile_profile()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not has_node("Ground"):
		warnings.append("District slice expects a Ground node.")
	return warnings

func refresh_tile_profile() -> void:
	_disable_embedded_layers()
	_update_exit_visibility()
	_update_ground_profile()

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

func _disable_embedded_layers() -> void:
	var buildings = get_node_or_null("Buildings")
	if buildings != null:
		buildings.visible = false
		for child in buildings.get_children():
			if child is CollisionObject2D:
				child.process_mode = Node.PROCESS_MODE_DISABLED
				for nested in child.get_children():
					if nested is CollisionShape2D:
						nested.disabled = true
	var ambient = get_node_or_null("Ambient")
	if ambient != null:
		ambient.visible = false
		for child in ambient.get_children():
			if child.has_method("set_path_active"):
				child.call("set_path_active", false)
