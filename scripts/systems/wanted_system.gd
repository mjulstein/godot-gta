extends Node2D

@export var tuning: WantedTuning
@export var police_scene: PackedScene

var player: Node2D
var district: Node2D
var debug_state: Node
var wanted_level := 0
var decay_progress := 0.0
var spawn_markers: Array[Marker2D] = []

func configure(target_player: Node2D, world_district: Node2D, state: Node) -> void:
	player = target_player
	district = world_district
	debug_state = state
	spawn_markers.clear()
	_collect_police_spawn_markers(district)

func handle_crime(event: Dictionary) -> void:
	var value: int = event.get("wanted_value", 0)
	wanted_level = mini(tuning.max_wanted_level, wanted_level + value)
	decay_progress = 0.0
	_sync_police_presence()

func _process(delta: float) -> void:
	if player == null or tuning == null:
		return

	if _has_active_pressure():
		decay_progress = 0.0
	else:
		decay_progress += delta
		if wanted_level > 0 and decay_progress >= tuning.decay_delay_seconds:
			wanted_level -= 1
			decay_progress = 0.0

	_sync_police_presence()
	_cleanup_idle_police()
	if debug_state != null:
		debug_state.set_wanted_level(wanted_level)
		debug_state.set_police_count(get_police_count())

func get_police_count() -> int:
	return get_tree().get_nodes_in_group("police_unit").size()

func _sync_police_presence() -> void:
	if police_scene == null or player == null:
		return

	var desired_units := mini(wanted_level, tuning.max_police_units)
	while get_police_count() < desired_units:
		_spawn_police_unit()

	if wanted_level == 0:
		for unit in get_tree().get_nodes_in_group("police_unit"):
			unit.queue_free()

func _spawn_police_unit() -> void:
	if spawn_markers.is_empty():
		return

	var best_marker := spawn_markers[0]
	var best_distance := -1.0
	for marker in spawn_markers:
		var distance_to_player := marker.global_position.distance_to(player.global_position)
		if distance_to_player > best_distance:
			best_distance = distance_to_player
			best_marker = marker

	var police_unit := police_scene.instantiate()
	add_child(police_unit)
	police_unit.global_position = best_marker.global_position
	police_unit.configure(player)

func _has_active_pressure() -> bool:
	for unit in get_tree().get_nodes_in_group("police_unit"):
		if unit.is_applying_pressure():
			return true
	return false

func _cleanup_idle_police() -> void:
	if wanted_level > 0:
		return
	for unit in get_tree().get_nodes_in_group("police_unit"):
		if unit.can_despawn():
			unit.queue_free()

func _collect_police_spawn_markers(node: Node) -> void:
	for child in node.get_children():
		if child is Marker2D and child.has_method("get") and child.get("marker_kind") == "police_spawn":
			spawn_markers.append(child)
		_collect_police_spawn_markers(child)
