extends Node2D

const ActorState = preload("res://scripts/core/actor_state.gd")
const CivilianPedestrianScene = preload("res://scenes/actors/civilians/civilian_pedestrian.tscn")

@onready var debug_state: Node = $DebugState
@onready var world: Node2D = $World
@onready var player = $Player
@onready var vehicle = $CivilianVehicle
@onready var crime_system: Node = $CrimeSystem
@onready var wanted_system: Node2D = $WantedSystem
@onready var camera: Camera2D = $FollowCamera
@onready var debug_overlay: Control = $Ui/DebugOverlay
@onready var interaction_prompt = $Ui/InteractionPrompt
@onready var interaction_system: Node = $VehicleInteractionSystem
@onready var pause_controller: Node = $Ui/PauseController
@onready var palette_overlay: Control = $Ui/PaletteOverlay

var traffic_camera_target: Node2D
var active_vehicle_source_label := "Parked Vehicle"
var possessed_traffic_vehicle: Node2D
var impact_vibration_enabled := false

const IMPACT_VIBRATION_MIN_SPEED_LOSS := 70.0
const IMPACT_VIBRATION_MAX_SPEED_LOSS := 320.0
const IMPACT_VIBRATION_MAX_DURATION_MS := 250

func _ready() -> void:
	var player_spawn := _find_spawn_marker("player_spawn")
	var vehicle_spawn := _find_spawn_marker("vehicle_spawn")
	if player_spawn != null:
		player.global_position = player_spawn.global_position
	if vehicle_spawn != null:
		vehicle.global_position = vehicle_spawn.global_position

	interaction_system.configure(player, player.get_node("InteractionSensor"))
	interaction_system.enter_requested.connect(_on_enter_requested)
	interaction_system.exit_requested.connect(_on_exit_requested)
	player.vehicle_entry_completed.connect(_on_enter_requested)
	player.civilian_assaulted.connect(_on_player_civilian_assaulted)
	_connect_vehicle_signals(player)
	_connect_vehicle_signals(vehicle)
	for traffic_vehicle in get_tree().get_nodes_in_group("traffic_vehicle"):
		_connect_vehicle_signals(traffic_vehicle)
	crime_system.crime_reported.connect(wanted_system.handle_crime)
	wanted_system.configure(player, world, debug_state)
	get_tree().node_added.connect(_on_tree_node_added)

	debug_overlay.set_debug_state(debug_state)
	interaction_prompt.set_debug_state(debug_state)
	camera.set_world_bounds(_compute_world_bounds())
	camera.set_target(player)
	if pause_controller.has_signal("pause_toggled"):
		pause_controller.pause_toggled.connect(_on_pause_toggled)
	if palette_overlay != null:
		if palette_overlay.has_signal("impact_vibration_toggled"):
			palette_overlay.impact_vibration_toggled.connect(_on_impact_vibration_toggled)
		if palette_overlay.has_method("is_impact_vibration_enabled"):
			impact_vibration_enabled = palette_overlay.is_impact_vibration_enabled()

func _process(_delta: float) -> void:
	var active_actor: Node2D = _get_active_camera_target()
	if camera.get_target() != active_actor:
		camera.set_target(active_actor)

	var active_vehicle := _get_active_player_vehicle()
	debug_state.set_player_mode("Driving" if player.get_state_name() == ActorState.DRIVING else "On Foot")
	debug_state.set_interaction_hint(_get_interaction_hint())
	debug_state.set_active_vehicle_label(_get_active_vehicle_label(active_vehicle))
	debug_state.set_takeover_state(_get_takeover_state())
	debug_state.set_speed(active_vehicle.velocity.length() * 0.18 if active_vehicle != null else player.velocity.length() * 0.18)
	var collision_active: bool = active_vehicle.has_recent_collision() if active_vehicle != null else player.has_recent_collision()
	debug_state.set_collision_state("Impact" if collision_active else "Clear")
	debug_state.set_motion_debug_lines(_get_motion_debug_lines())
	debug_state.set_tracked_vehicle_metrics(_get_tracked_vehicle_metrics())
	debug_state.set_pedestrian_state_counts(_count_group_states("civilian_pedestrian", "get_state_name"))
	debug_state.set_traffic_state_counts(_count_group_states("traffic_vehicle", "get_traffic_state_name"))
	if debug_state.impact_state != "None" and (active_vehicle == null or not collision_active):
		debug_state.set_impact_state("None")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and _can_toggle_traffic_possession():
		get_viewport().set_input_as_handled()
		_toggle_traffic_possession()
		return
	if not event.is_action_pressed("debug_camera"):
		return
	get_viewport().set_input_as_handled()
	_toggle_traffic_camera()

func _on_enter_requested(target_vehicle: Node2D) -> void:
	if not target_vehicle.can_enter():
		debug_state.set_takeover_state(target_vehicle.get_entry_block_reason() if target_vehicle.has_method("get_entry_block_reason") else "Entry blocked")
		return
	var vehicle_to_drive := _prepare_vehicle_takeover(target_vehicle)
	vehicle_to_drive.set_driver(player)
	player.enter_vehicle(vehicle_to_drive)
	if target_vehicle.has_method("was_theft_reported") and not target_vehicle.was_theft_reported():
		if crime_system.report_vehicle_theft(player, vehicle_to_drive):
			target_vehicle.mark_theft_reported()
			if vehicle_to_drive != target_vehicle and vehicle_to_drive.has_method("mark_theft_reported"):
				vehicle_to_drive.mark_theft_reported()

func _on_exit_requested(target_vehicle: Node2D) -> void:
	if target_vehicle == null:
		return
	if target_vehicle.has_method("can_exit") and not target_vehicle.can_exit():
		debug_state.set_takeover_state(target_vehicle.get_exit_block_reason() if target_vehicle.has_method("get_exit_block_reason") else "Exit blocked")
		return
	target_vehicle.clear_driver()
	player.exit_vehicle(target_vehicle.get_exit_position())

func _on_player_civilian_assaulted(target: Node2D) -> void:
	crime_system.report_pedestrian_assault(player, target)

func _on_vehicle_civilian_hit(source: Node2D, target: Node2D) -> void:
	if player.is_in_vehicle() and source == _get_active_player_vehicle():
		var source_speed: float = source.get_impact_velocity().length() if source.has_method("get_impact_velocity") else 0.0
		debug_state.set_impact_state("Pedestrian hit at %.1f kph" % (source_speed * 0.18))
		crime_system.report_harmful_collision(source, target)
		return

func _find_spawn_marker(marker_kind: String) -> Marker2D:
	return _find_spawn_marker_in_node(world, marker_kind)

func _find_spawn_marker_in_node(node: Node, marker_kind: String) -> Marker2D:
	for child in node.get_children():
		if child is Marker2D and child.has_method("get") and child.get("marker_kind") == marker_kind:
			return child
		var nested := _find_spawn_marker_in_node(child, marker_kind)
		if nested != null:
			return nested
	return null

func _compute_world_bounds() -> Rect2:
	var tile_size := Vector2(1280, 1280)
	if world != null and world.has_method("get"):
		var configured_size = world.get("tile_size")
		if configured_size is Vector2:
			tile_size = configured_size
	var children := world.get_children()
	if children.is_empty():
		return Rect2(-tile_size * 0.5, tile_size)
	var min_corner := Vector2(INF, INF)
	var max_corner := Vector2(-INF, -INF)
	var half_tile := tile_size * 0.5
	for child in children:
		if not (child is Node2D):
			continue
		var node := child as Node2D
		min_corner.x = minf(min_corner.x, node.global_position.x - half_tile.x)
		min_corner.y = minf(min_corner.y, node.global_position.y - half_tile.y)
		max_corner.x = maxf(max_corner.x, node.global_position.x + half_tile.x)
		max_corner.y = maxf(max_corner.y, node.global_position.y + half_tile.y)
	return Rect2(min_corner, max_corner - min_corner)

func _get_active_camera_target() -> Node2D:
	if is_instance_valid(traffic_camera_target):
		return traffic_camera_target
	var active_vehicle := _get_active_player_vehicle()
	return active_vehicle if active_vehicle != null else player

func _toggle_traffic_camera() -> void:
	_set_traffic_camera_target(_find_debug_traffic_vehicle(traffic_camera_target))

func _set_traffic_camera_target(target_vehicle: Node2D) -> void:
	if traffic_camera_target == target_vehicle:
		return
	if is_instance_valid(traffic_camera_target) and traffic_camera_target == possessed_traffic_vehicle and target_vehicle != possessed_traffic_vehicle:
		_release_traffic_possession()
	if is_instance_valid(traffic_camera_target) and traffic_camera_target.has_method("set_camera_tracked"):
		traffic_camera_target.call("set_camera_tracked", false)
	traffic_camera_target = target_vehicle
	if is_instance_valid(traffic_camera_target) and traffic_camera_target.has_method("set_camera_tracked"):
		traffic_camera_target.call("set_camera_tracked", true)

func _find_debug_traffic_vehicle(excluded_vehicle: Node2D = null) -> Node2D:
	var candidates: Array[Node2D] = []
	for candidate in get_tree().get_nodes_in_group("traffic_vehicle"):
		if not (candidate is Node2D):
			continue
		var traffic_vehicle := candidate as Node2D
		if not traffic_vehicle.visible:
			continue
		if traffic_vehicle.has_method("is_debug_trackable") and not traffic_vehicle.is_debug_trackable():
			continue
		if traffic_vehicle.has_method("is_manned") and not traffic_vehicle.is_manned():
			continue
		candidates.append(traffic_vehicle)
	if candidates.is_empty():
		return null
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.get_instance_id() < b.get_instance_id()
	)
	if excluded_vehicle == null or not is_instance_valid(excluded_vehicle):
		return candidates[0]
	var excluded_index := candidates.find(excluded_vehicle)
	if excluded_index == -1:
		return candidates[0]
	return candidates[(excluded_index + 1) % candidates.size()]

func _on_pause_toggled(is_paused: bool) -> void:
	if is_paused:
		return
	_set_traffic_camera_target(null)

func _on_tree_node_added(node: Node) -> void:
	if node == null:
		return
	if node.has_signal("civilian_hit"):
		_connect_vehicle_signals(node)

func _connect_vehicle_signals(node: Node) -> void:
	if node == null:
		return
	if node.has_signal("civilian_hit"):
		var hit_callable := Callable(self, "_on_connected_vehicle_civilian_hit").bind(node)
		if not node.is_connected("civilian_hit", hit_callable):
			node.connect("civilian_hit", hit_callable)
	if node.has_signal("collision_feedback_requested"):
		var feedback_callable := Callable(self, "_on_connected_collision_feedback_requested").bind(node)
		if not node.is_connected("collision_feedback_requested", feedback_callable):
			node.connect("collision_feedback_requested", feedback_callable)
	if node.has_signal("incident_driver_requested"):
		var incident_callable := Callable(self, "_on_connected_vehicle_incident_driver_requested").bind(node)
		if not node.is_connected("incident_driver_requested", incident_callable):
			node.connect("incident_driver_requested", incident_callable)

func _on_connected_vehicle_civilian_hit(target: Node2D, source: Node2D) -> void:
	_on_vehicle_civilian_hit(source, target)

func _on_connected_vehicle_incident_driver_requested(target: Node, inspect_position: Vector2, source: Node) -> void:
	var source_vehicle: Node2D = source as Node2D
	var target_actor: Node2D = target as Node2D
	_maybe_spawn_incident_driver(source_vehicle, target_actor, inspect_position)

func _on_connected_collision_feedback_requested(speed_loss: float, source: Node) -> void:
	if not impact_vibration_enabled:
		return
	if source == player:
		_trigger_impact_vibration(speed_loss)
		return
	var active_vehicle := _get_active_player_vehicle()
	if active_vehicle != null and source == active_vehicle:
		_trigger_impact_vibration(speed_loss)

func _on_impact_vibration_toggled(enabled: bool) -> void:
	impact_vibration_enabled = enabled

func _trigger_impact_vibration(speed_loss: float) -> void:
	if speed_loss < IMPACT_VIBRATION_MIN_SPEED_LOSS:
		return
	var duration_ratio := inverse_lerp(IMPACT_VIBRATION_MIN_SPEED_LOSS, IMPACT_VIBRATION_MAX_SPEED_LOSS, speed_loss)
	var duration_ms := int(round(clampf(duration_ratio, 0.0, 1.0) * IMPACT_VIBRATION_MAX_DURATION_MS))
	if duration_ms <= 0:
		return
	Input.vibrate_handheld(duration_ms, 1.0)

func _prepare_vehicle_takeover(target_vehicle: Node2D) -> Node2D:
	if target_vehicle == vehicle:
		active_vehicle_source_label = "Parked Vehicle"
		return vehicle
	var displaced_position: Vector2 = target_vehicle.get_exit_position() if target_vehicle.has_method("get_exit_position") else target_vehicle.global_position
	var forward := Vector2.RIGHT.rotated(target_vehicle.rotation)
	var side := Vector2.DOWN.rotated(target_vehicle.rotation)
	if target_vehicle.has_method("has_civilian_occupant") and target_vehicle.has_civilian_occupant():
		_spawn_displaced_occupant(displaced_position, forward, side, target_vehicle)
		target_vehicle.consume_civilian_occupant()
	active_vehicle_source_label = "Civilian Traffic"
	return target_vehicle

func _spawn_displaced_occupant(spawn_position: Vector2, facing_direction: Vector2, escape_direction: Vector2, target_vehicle: Node2D) -> void:
	var occupant := CivilianPedestrianScene.instantiate()
	world.add_child(occupant)
	if occupant.has_method("place_displaced_occupant"):
		occupant.place_displaced_occupant(spawn_position, facing_direction, escape_direction)
	else:
		occupant.global_position = spawn_position
	if occupant.has_method("configure_reclaim_attempt"):
		occupant.configure_reclaim_attempt(target_vehicle, randf() < 0.5)

func _maybe_spawn_incident_driver(source_vehicle: Node2D, target_actor: Node2D, inspect_position: Vector2 = Vector2.ZERO) -> void:
	if source_vehicle == null or not is_instance_valid(source_vehicle):
		return
	if not source_vehicle.has_method("release_driver_for_incident") or not source_vehicle.release_driver_for_incident():
		return
	var spawn_position: Vector2 = source_vehicle.get_driver_entry_position() if source_vehicle.has_method("get_driver_entry_position") else source_vehicle.get_exit_position()
	var side_offset := spawn_position - source_vehicle.global_position
	if side_offset != Vector2.ZERO:
		spawn_position += side_offset.normalized() * 14.0
	var facing_direction := Vector2.RIGHT.rotated(source_vehicle.rotation)
	var driver_actor := CivilianPedestrianScene.instantiate()
	world.add_child(driver_actor)
	if driver_actor.has_method("place_incident_driver"):
		driver_actor.place_incident_driver(spawn_position, facing_direction)
	elif driver_actor.has_method("place_displaced_occupant"):
		driver_actor.place_displaced_occupant(spawn_position, facing_direction, Vector2.ZERO)
	else:
		driver_actor.global_position = spawn_position
	if driver_actor.has_method("configure_incident_response"):
		driver_actor.configure_incident_response(source_vehicle, target_actor, inspect_position)


func _get_active_player_vehicle() -> Node2D:
	if not player.is_in_vehicle():
		return null
	return player.active_vehicle as Node2D

func is_camera_possession_active() -> bool:
	return is_instance_valid(possessed_traffic_vehicle) and possessed_traffic_vehicle == traffic_camera_target

func _get_interaction_hint() -> String:
	if _can_toggle_traffic_possession():
		return "Press E to return driver" if possessed_traffic_vehicle == traffic_camera_target else "Press E to possess driver"
	return interaction_system.get_interaction_hint()

func _can_toggle_traffic_possession() -> bool:
	if player.is_in_vehicle():
		return false
	if not is_instance_valid(traffic_camera_target):
		return false
	if not traffic_camera_target.has_method("set_possessed_by_player"):
		return false
	if traffic_camera_target.has_method("is_debug_trackable") and not traffic_camera_target.is_debug_trackable() and possessed_traffic_vehicle != traffic_camera_target:
		return false
	return true

func _toggle_traffic_possession() -> void:
	if possessed_traffic_vehicle == traffic_camera_target:
		_release_traffic_possession()
		return
	_release_traffic_possession()
	possessed_traffic_vehicle = traffic_camera_target
	if is_instance_valid(possessed_traffic_vehicle) and possessed_traffic_vehicle.has_method("set_possessed_by_player"):
		possessed_traffic_vehicle.set_possessed_by_player(true)

func _release_traffic_possession() -> void:
	if not is_instance_valid(possessed_traffic_vehicle):
		possessed_traffic_vehicle = null
		return
	if possessed_traffic_vehicle.has_method("set_possessed_by_player"):
		possessed_traffic_vehicle.set_possessed_by_player(false)
	possessed_traffic_vehicle = null

func _get_active_vehicle_label(active_vehicle: Node2D) -> String:
	if active_vehicle == null:
		return "None"
	return active_vehicle_source_label

func _get_takeover_state() -> String:
	if player.is_in_vehicle():
		return "Driving %s" % active_vehicle_source_label.to_lower()
	var candidate: Node2D = interaction_system.get_nearest_vehicle()
	if candidate == null:
		return "No vehicle nearby"
	if candidate == vehicle:
		return "Parked car ready"
	return "Civilian takeover ready"

func _get_motion_debug_lines() -> PackedStringArray:
	if is_instance_valid(traffic_camera_target) and traffic_camera_target.has_method("get_motion_debug_lines"):
		var traffic_lines = traffic_camera_target.call("get_motion_debug_lines")
		if traffic_lines is PackedStringArray:
			var lines: PackedStringArray = traffic_lines
			lines.insert(0, "Inspecting traffic car")
			return lines
	if player.is_in_vehicle():
		var active_vehicle := _get_active_player_vehicle()
		if active_vehicle != null and active_vehicle.has_method("get_motion_debug_lines"):
			var vehicle_lines = active_vehicle.call("get_motion_debug_lines")
			if vehicle_lines is PackedStringArray:
				var lines: PackedStringArray = vehicle_lines
				lines.insert(0, "Inspecting player car")
				return lines
	return player.get_motion_debug_lines()

func _get_tracked_vehicle_metrics() -> Dictionary:
	if is_instance_valid(traffic_camera_target) and traffic_camera_target.has_method("get_debug_metrics"):
		var metrics = traffic_camera_target.call("get_debug_metrics")
		return metrics if metrics is Dictionary else {}
	var active_vehicle := _get_active_player_vehicle()
	if active_vehicle != null and active_vehicle.has_method("get_debug_metrics"):
		var metrics = active_vehicle.call("get_debug_metrics")
		return metrics if metrics is Dictionary else {}
	return {}

func _count_group_states(group_name: String, method_name: String) -> Dictionary:
	var counts := {}
	for candidate in get_tree().get_nodes_in_group(group_name):
		if candidate == null or not is_instance_valid(candidate):
			continue
		if not candidate.has_method(method_name):
			continue
		var state_name = str(candidate.call(method_name))
		counts[state_name] = int(counts.get(state_name, 0)) + 1
	return counts
