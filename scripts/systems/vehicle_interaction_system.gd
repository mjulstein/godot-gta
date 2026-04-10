extends Node

signal enter_requested(vehicle: Node2D)
signal exit_requested(vehicle: Node2D)

var player: Node2D
var interaction_sensor: Area2D

func configure(player_actor: Node2D, sensor: Area2D) -> void:
	player = player_actor
	interaction_sensor = sensor

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or player == null:
		return

	if player.is_in_vehicle():
		var active_vehicle: Node2D = player.active_vehicle
		if active_vehicle != null and active_vehicle.has_method("can_exit") and not active_vehicle.can_exit():
			return
		exit_requested.emit(active_vehicle)
		return

	var candidate := get_nearest_vehicle()
	if candidate != null:
		if player.has_method("begin_vehicle_entry"):
			player.begin_vehicle_entry(candidate)
		else:
			enter_requested.emit(candidate)

func get_interaction_hint() -> String:
	if player == null:
		return ""
	if player.is_in_vehicle():
		var active_vehicle: Node2D = player.active_vehicle
		if active_vehicle != null and active_vehicle.has_method("can_exit") and not active_vehicle.can_exit():
			if active_vehicle.has_method("get_exit_block_reason"):
				return active_vehicle.get_exit_block_reason()
			return "Exit blocked"
		return "Press E to exit vehicle"
	if player.has_method("is_entering_vehicle") and player.is_entering_vehicle():
		return "Moving to driver seat"
	var enterable_candidate := get_nearest_vehicle()
	if enterable_candidate != null:
		return "Press E to enter vehicle"
	var blocked_candidate := _get_nearest_vehicle(true)
	if blocked_candidate != null and blocked_candidate.has_method("get_entry_block_reason"):
		return blocked_candidate.get_entry_block_reason()
	return "Walk to the yellow car"

func get_nearest_vehicle() -> Node2D:
	return _get_nearest_vehicle(false)

func _get_nearest_vehicle(include_blocked: bool) -> Node2D:
	if interaction_sensor == null:
		return null
	return interaction_sensor.get_closest_candidate(player.global_position, include_blocked)
