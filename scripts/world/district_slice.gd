@tool
extends Node2D

@export var open_north := true:
	set(value):
		open_north = value
		_update_exit_visibility()

@export var open_south := true:
	set(value):
		open_south = value
		_update_exit_visibility()

@export var open_east := true:
	set(value):
		open_east = value
		_update_exit_visibility()

@export var open_west := true:
	set(value):
		open_west = value
		_update_exit_visibility()

func _ready() -> void:
	_update_exit_visibility()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if not has_node("Ground"):
		warnings.append("District slice expects a Ground node.")
	return warnings

func _update_exit_visibility() -> void:
	if not is_node_ready():
		return

	_set_exit_state("North", open_north)
	_set_exit_state("South", open_south)
	_set_exit_state("East", open_east)
	_set_exit_state("West", open_west)

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
