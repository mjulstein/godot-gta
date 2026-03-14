extends Node2D

const ActorState = preload("res://scripts/core/actor_state.gd")

@onready var debug_state: Node = $DebugState
@onready var district: Node2D = $District
@onready var player = $Player
@onready var vehicle = $CivilianVehicle
@onready var crime_system: Node = $CrimeSystem
@onready var wanted_system: Node2D = $WantedSystem
@onready var camera: Camera2D = $FollowCamera
@onready var debug_overlay: Control = $Ui/DebugOverlay
@onready var interaction_prompt = $Ui/InteractionPrompt
@onready var interaction_system: Node = $VehicleInteractionSystem

func _ready() -> void:
	player.global_position = district.get_node("PlayerSpawn").global_position
	vehicle.global_position = district.get_node("VehicleSpawn").global_position

	interaction_system.configure(player, player.get_node("InteractionSensor"))
	interaction_system.enter_requested.connect(_on_enter_requested)
	interaction_system.exit_requested.connect(_on_exit_requested)
	player.civilian_assaulted.connect(_on_player_civilian_assaulted)
	vehicle.civilian_hit.connect(_on_vehicle_civilian_hit)
	crime_system.crime_reported.connect(wanted_system.handle_crime)
	wanted_system.configure(player, district, debug_state)

	debug_overlay.set_debug_state(debug_state)
	interaction_prompt.set_debug_state(debug_state)
	camera.set_world_bounds(Rect2(Vector2(-624, -344), Vector2(1248, 688)))
	camera.set_target(player)

func _process(_delta: float) -> void:
	var active_actor: Node2D = vehicle if player.is_in_vehicle() else player
	camera.set_target(active_actor)

	debug_state.set_player_mode("Driving" if player.get_state_name() == ActorState.DRIVING else "On Foot")
	debug_state.set_interaction_hint(interaction_system.get_interaction_hint())
	debug_state.set_speed(vehicle.velocity.length() * 0.18 if player.is_in_vehicle() else player.velocity.length() * 0.18)
	var collision_active: bool = vehicle.has_recent_collision() if player.is_in_vehicle() else player.has_recent_collision()
	debug_state.set_collision_state("Impact" if collision_active else "Clear")

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
