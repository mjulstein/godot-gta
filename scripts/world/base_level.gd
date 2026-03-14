@tool
extends Node2D

const TILE_EMPTY := "0"
const TILE_DISTRICT := "D"

@export_multiline var tile_rows := "DDDDDD00\nDD0DDD00\nD000DDDD\n0000DD00":
	set(value):
		tile_rows = value
		_rebuild_if_ready()

@export var district_tile_scene: PackedScene:
	set(value):
		district_tile_scene = value
		_rebuild_if_ready()

@export var empty_ground_tile_scene: PackedScene:
	set(value):
		empty_ground_tile_scene = value
		_rebuild_if_ready()

@export var tile_size := Vector2(1280, 720):
	set(value):
		tile_size = value
		_rebuild_if_ready()

func _ready() -> void:
	_rebuild_tiles()

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if district_tile_scene == null:
		warnings.append("Base level expects a district_tile_scene.")
	if empty_ground_tile_scene == null:
		warnings.append("Base level expects an empty_ground_tile_scene.")
	return warnings

func _rebuild_if_ready() -> void:
	if is_node_ready():
		_rebuild_tiles()

func _rebuild_tiles() -> void:
	for child in get_children():
		child.queue_free()

	var rows := _parse_rows()
	for row_index in range(rows.size()):
		var row: String = rows[row_index]
		for column_index in range(row.length()):
			var tile_code := row[column_index]
			var tile_scene := _get_tile_scene(tile_code)
			if tile_scene == null:
				continue

			var tile := tile_scene.instantiate()
			add_child(tile)
			tile.position = Vector2(column_index * tile_size.x, row_index * tile_size.y)
			tile.name = "Tile_%d_%d_%s" % [column_index, row_index, tile_code]

			if tile_code == TILE_DISTRICT and tile.has_method("set"):
				tile.set("open_north", _tile_at(rows, row_index - 1, column_index) == TILE_DISTRICT)
				tile.set("open_south", _tile_at(rows, row_index + 1, column_index) == TILE_DISTRICT)
				tile.set("open_west", _tile_at(rows, row_index, column_index - 1) == TILE_DISTRICT)
				tile.set("open_east", _tile_at(rows, row_index, column_index + 1) == TILE_DISTRICT)

func _parse_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	for raw_line in tile_rows.split("\n"):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			rows.append(line)
	return rows

func _get_tile_scene(tile_code: String) -> PackedScene:
	match tile_code:
		TILE_DISTRICT:
			return district_tile_scene
		TILE_EMPTY:
			return empty_ground_tile_scene
		_:
			return null

func _tile_at(rows: PackedStringArray, row_index: int, column_index: int) -> String:
	if row_index < 0 or row_index >= rows.size():
		return ""
	var row: String = rows[row_index]
	if column_index < 0 or column_index >= row.length():
		return ""
	return row[column_index]
