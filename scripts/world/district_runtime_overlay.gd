@tool
extends Node2D

const SpawnMarkerScene = preload("res://scenes/world/props/spawn_marker.tscn")

func _ready() -> void:
	_rebuild()

func refresh_overlay() -> void:
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	_add_spawn("PlayerSpawn", Vector2(-260, -24), "player_spawn")
	_add_spawn("VehicleSpawn", Vector2(-120, 36), "vehicle_spawn")
	_add_spawn("PoliceSpawnNorth", Vector2(0, -248), "police_spawn")
	_add_spawn("PoliceSpawnSouth", Vector2(0, 248), "police_spawn")

func _add_spawn(node_name: String, position_value: Vector2, kind: String) -> void:
	var marker := SpawnMarkerScene.instantiate()
	marker.name = node_name
	marker.position = position_value
	marker.set("marker_kind", kind)
	add_child(marker)
