extends Node2D

const ActorState = preload("res://scripts/core/actor_state.gd")

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

var traffic_camera_target: Node2D

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
	player.civilian_assaulted.connect(_on_player_civilian_assaulted)
	vehicle.civilian_hit.connect(_on_vehicle_civilian_hit)
	crime_system.crime_reported.connect(wanted_system.handle_crime)
	wanted_system.configure(player, world, debug_state)

	debug_overlay.set_debug_state(debug_state)
	interaction_prompt.set_debug_state(debug_state)
	camera.set_world_bounds(_compute_world_bounds())
	camera.set_target(player)
	if pause_controller.has_signal("pause_toggled"):
		pause_controller.pause_toggled.connect(_on_pause_toggled)

func _process(_delta: float) -> void:
	var active_actor: Node2D = _get_active_camera_target()
	if camera.get_target() != active_actor:
		camera.set_target(active_actor)

	debug_state.set_player_mode("Driving" if player.get_state_name() == ActorState.DRIVING else "On Foot")
	debug_state.set_interaction_hint(interaction_system.get_interaction_hint())
	debug_state.set_speed(vehicle.velocity.length() * 0.18 if player.is_in_vehicle() else player.velocity.length() * 0.18)
	var collision_active: bool = vehicle.has_recent_collision() if player.is_in_vehicle() else player.has_recent_collision()
	debug_state.set_collision_state("Impact" if collision_active else "Clear")

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("debug_camera"):
		return
	get_viewport().set_input_as_handled()
	_toggle_traffic_camera()

func _on_enter_requested(target_vehicle: Node2D) -> void:
	if not target_vehicle.can_enter():
		return
	target_vehicle.set_driver(player)
	player.enter_vehicle(target_vehicle)
	if target_vehicle.has_method("was_theft_reported") and not target_vehicle.was_theft_reported():
		if crime_system.report_vehicle_theft(player, target_vehicle):
			target_vehicle.mark_theft_reported()

func _on_exit_requested(target_vehicle: Node2D) -> void:
	target_vehicle.clear_driver()
	player.exit_vehicle(target_vehicle.get_exit_position())

func _on_player_civilian_assaulted(target: Node2D) -> void:
	crime_system.report_pedestrian_assault(player, target)

func _on_vehicle_civilian_hit(target: Node2D) -> void:
	if not player.is_in_vehicle():
		return
	crime_system.report_harmful_collision(vehicle, target)

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
	return vehicle if player.is_in_vehicle() else player

func _toggle_traffic_camera() -> void:
	_set_traffic_camera_target(_find_debug_traffic_vehicle(traffic_camera_target))

func _set_traffic_camera_target(target_vehicle: Node2D) -> void:
	if traffic_camera_target == target_vehicle:
		return
	if is_instance_valid(traffic_camera_target) and traffic_camera_target.has_method("set_camera_tracked"):
		traffic_camera_target.call("set_camera_tracked", false)
	traffic_camera_target = target_vehicle
	if is_instance_valid(traffic_camera_target) and traffic_camera_target.has_method("set_camera_tracked"):
		traffic_camera_target.call("set_camera_tracked", true)

func _find_debug_traffic_vehicle(excluded_vehicle: Node2D = null) -> Node2D:
	var rerouting_vehicle := _find_nearby_traffic_vehicle(excluded_vehicle, true)
	if rerouting_vehicle != null:
		return rerouting_vehicle
	return _find_nearby_traffic_vehicle(excluded_vehicle, false)

func _find_nearby_traffic_vehicle(excluded_vehicle: Node2D = null, require_rerouting: bool = false) -> Node2D:
	var search_origin := camera.global_position
	var best_vehicle: Node2D
	var best_distance := INF
	for candidate in get_tree().get_nodes_in_group("traffic_vehicle"):
		if not (candidate is Node2D):
			continue
		var traffic_vehicle := candidate as Node2D
		if traffic_vehicle == excluded_vehicle:
			continue
		if not traffic_vehicle.visible:
			continue
		if require_rerouting:
			if not traffic_vehicle.has_method("is_rerouting"):
				continue
			if not traffic_vehicle.call("is_rerouting"):
				continue
		var distance := search_origin.distance_squared_to(traffic_vehicle.global_position)
		if distance < best_distance:
			best_distance = distance
			best_vehicle = traffic_vehicle
	if best_vehicle == null and require_rerouting and is_instance_valid(excluded_vehicle):
		if excluded_vehicle.has_method("is_rerouting") and excluded_vehicle.call("is_rerouting"):
			return excluded_vehicle
	if best_vehicle == null and is_instance_valid(excluded_vehicle):
		return excluded_vehicle
	return best_vehicle

func _on_pause_toggled(is_paused: bool) -> void:
	if is_paused:
		return
	_set_traffic_camera_target(null)
