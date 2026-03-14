@tool
extends Node2D

const TILE_EMPTY := "0"
const TILE_DISTRICT := "D"

@export_multiline var tile_rows := "DDDDDD00\nDD0DDD00\nD000DDDD\n0000DD00":
	set(value):
		tile_rows = value
		_rebuild_if_ready()

@export_multiline var building_rows := "66666600\n66066600\n60066666\n00006600":
	set(value):
		building_rows = value
		_rebuild_if_ready()

@export_multiline var activity_rows := "33333300\n33033300\n30033333\n00003300":
	set(value):
		activity_rows = value
		_rebuild_if_ready()

@export var district_tile_scene: PackedScene:
	set(value):
		district_tile_scene = value
		_rebuild_if_ready()

@export var empty_ground_tile_scene: PackedScene:
	set(value):
		empty_ground_tile_scene = value
		_rebuild_if_ready()

@export var building_overlay_scene: PackedScene:
	set(value):
		building_overlay_scene = value
		_rebuild_if_ready()

@export var activity_overlay_scene: PackedScene:
	set(value):
		activity_overlay_scene = value
		_rebuild_if_ready()

@export var tile_size := Vector2(1280, 1280):
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
	var building_map := _parse_density_rows(building_rows)
	var activity_map := _parse_density_rows(activity_rows)
	var district_tiles: Array[Node2D] = []
	var district_layers: Array[Node] = []
	for row_index in range(rows.size()):
		var row: String = rows[row_index]
		for column_index in range(row.length()):
			var tile_code := row[column_index]
			var tile_scene := _get_tile_scene(tile_code)
			if tile_scene == null:
				continue

			var tile := tile_scene.instantiate()
			tile.position = Vector2(column_index * tile_size.x, row_index * tile_size.y)
			add_child(tile)
			tile.name = "Tile_%d_%d_%s" % [column_index, row_index, tile_code]

			if tile_code == TILE_DISTRICT and tile.has_method("set"):
				_apply_district_properties(tile, rows, row_index, column_index)
				district_tiles.append(tile)
				var building_density := _density_at(building_map, row_index, column_index)
				var activity_density := _density_at(activity_map, row_index, column_index)
				var overlays := _build_overlays(rows, row_index, column_index, building_density, activity_density)
				district_layers.append_array(overlays)

	for tile in district_tiles:
		if tile.has_method("refresh_tile_profile"):
			tile.refresh_tile_profile()
	for layer in district_layers:
		if layer.has_method("refresh_overlay"):
			layer.refresh_overlay()

func _parse_rows() -> PackedStringArray:
	var rows := PackedStringArray()
	for raw_line in tile_rows.split("\n"):
		var line := raw_line.strip_edges()
		if not line.is_empty():
			rows.append(line)
	return rows

func _parse_density_rows(source: String) -> PackedStringArray:
	var rows := PackedStringArray()
	for raw_line in source.split("\n"):
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

func _count_tiles(rows: PackedStringArray, row_index: int, column_index: int, row_step: int, column_step: int) -> int:
	var count := 0
	var next_row := row_index + row_step
	var next_column := column_index + column_step
	while _tile_at(rows, next_row, next_column) == TILE_DISTRICT:
		count += 1
		next_row += row_step
		next_column += column_step
	return count

func _density_at(rows: PackedStringArray, row_index: int, column_index: int) -> int:
	var code := _tile_at(rows, row_index, column_index)
	if code.is_empty():
		return 0
	if code == TILE_DISTRICT:
		return 9
	return clampi(int(code.to_int()), 0, 9)

func _apply_district_properties(tile: Node, rows: PackedStringArray, row_index: int, column_index: int) -> void:
	tile.set("open_north", _tile_at(rows, row_index - 1, column_index) == TILE_DISTRICT)
	tile.set("open_south", _tile_at(rows, row_index + 1, column_index) == TILE_DISTRICT)
	tile.set("open_west", _tile_at(rows, row_index, column_index - 1) == TILE_DISTRICT)
	tile.set("open_east", _tile_at(rows, row_index, column_index + 1) == TILE_DISTRICT)
	tile.set("tile_world_size", tile_size)
	tile.set("north_span_tiles", _count_tiles(rows, row_index, column_index, -1, 0))
	tile.set("south_span_tiles", _count_tiles(rows, row_index, column_index, 1, 0))
	tile.set("west_span_tiles", _count_tiles(rows, row_index, column_index, 0, -1))
	tile.set("east_span_tiles", _count_tiles(rows, row_index, column_index, 0, 1))

func _build_overlays(rows: PackedStringArray, row_index: int, column_index: int, building_density: int, activity_density: int) -> Array[Node]:
	var overlays: Array[Node] = []
	if building_overlay_scene != null and building_density > 0:
		var building_overlay := building_overlay_scene.instantiate()
		building_overlay.position = Vector2(column_index * tile_size.x, row_index * tile_size.y)
		building_overlay.name = "Tile_%d_%d_Buildings" % [column_index, row_index]
		add_child(building_overlay)
		_apply_district_properties(building_overlay, rows, row_index, column_index)
		building_overlay.set("building_density", building_density)
		overlays.append(building_overlay)
	if activity_overlay_scene != null and activity_density > 0:
		var activity_overlay := activity_overlay_scene.instantiate()
		activity_overlay.position = Vector2(column_index * tile_size.x, row_index * tile_size.y)
		activity_overlay.name = "Tile_%d_%d_Activity" % [column_index, row_index]
		add_child(activity_overlay)
		_apply_district_properties(activity_overlay, rows, row_index, column_index)
		activity_overlay.set("activity_density", activity_density)
		overlays.append(activity_overlay)
	return overlays
