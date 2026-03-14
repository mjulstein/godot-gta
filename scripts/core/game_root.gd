extends Node2D

const ActorState = preload("res://scripts/core/actor_state.gd")

@onready var debug_state: Node = $DebugState
@onready var district: Node2D = $District
@onready var player = $Player
@onready var vehicle = $CivilianVehicle
@onready var camera: Camera2D = $FollowCamera
@onready var debug_overlay: Control = $Ui/DebugOverlay
@onready var interaction_system: Node = $VehicleInteractionSystem

func _ready() -> void:
	player.global_position = district.get_node("PlayerSpawn").global_position
	vehicle.global_position = district.get_node("VehicleSpawn").global_position

	interaction_system.configure(player, player.get_node("InteractionSensor"))
	interaction_system.enter_requested.connect(_on_enter_requested)
	interaction_system.exit_requested.connect(_on_exit_requested)

	debug_overlay.set_debug_state(debug_state)
	camera.set_target(player)

func _process(_delta: float) -> void:
	var active_actor: Node2D = vehicle if player.is_in_vehicle() else player
	camera.set_target(active_actor)

	debug_state.set_player_mode("Driving" if player.get_state_name() == ActorState.DRIVING else "On Foot")
	debug_state.set_interaction_hint(interaction_system.get_interaction_hint())
	debug_state.set_speed(vehicle.velocity.length() * 0.18 if player.is_in_vehicle() else player.velocity.length() * 0.18)
	debug_state.set_collision_state("Impact" if vehicle.get_slide_collision_count() > 0 else "Clear")

func _on_enter_requested(target_vehicle: Node2D) -> void:
	if not target_vehicle.can_enter():
		return
	target_vehicle.set_driver(player)
	player.enter_vehicle(target_vehicle)

func _on_exit_requested(target_vehicle: Node2D) -> void:
	target_vehicle.clear_driver()
	player.exit_vehicle(target_vehicle.get_exit_position())
