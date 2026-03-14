extends Node

signal enter_requested(vehicle: Node2D)
signal exit_requested(vehicle: Node2D)

@export var enter_radius := 48.0

var player: Node2D
var vehicles: Array[Node2D] = []

func configure(player_actor: Node2D, vehicle_nodes: Array) -> void:
	player = player_actor
	vehicles.clear()
	for vehicle in vehicle_nodes:
		if vehicle is Node2D:
			vehicles.append(vehicle)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or player == null:
		return

	if player.is_in_vehicle():
		exit_requested.emit(player.active_vehicle)
		return

	var candidate := get_nearest_vehicle()
	if candidate != null:
		enter_requested.emit(candidate)

func get_interaction_hint() -> String:
	if player == null:
		return ""
	if player.is_in_vehicle():
		return "Press E to exit vehicle"
	if get_nearest_vehicle() != null:
		return "Press E to enter vehicle"
	return "Walk to the yellow car"

func get_nearest_vehicle() -> Node2D:
	var closest: Node2D = null
	var closest_distance := enter_radius
	for vehicle in vehicles:
		if vehicle == null or not vehicle.can_enter():
			continue
		var distance := player.global_position.distance_to(vehicle.global_position)
		if distance <= closest_distance:
			closest = vehicle
			closest_distance = distance
	return closest
