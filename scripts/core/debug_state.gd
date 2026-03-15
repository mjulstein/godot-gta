extends Node

var player_mode := "On Foot"
var interaction_hint := "Press E near the car"
var wanted_level := 0
var police_count := 0
var mission_state := "Free Roam"
var speed_kph := 0.0
var collision_state := "Clear"
var active_vehicle_label := "Parked Vehicle"
var takeover_state := "Walk to the yellow car"
var impact_state := "None"
var motion_debug_lines := PackedStringArray()

func set_player_mode(value: String) -> void:
	player_mode = value

func set_interaction_hint(value: String) -> void:
	interaction_hint = value

func set_speed(value: float) -> void:
	speed_kph = value

func set_collision_state(value: String) -> void:
	collision_state = value

func set_active_vehicle_label(value: String) -> void:
	active_vehicle_label = value

func set_takeover_state(value: String) -> void:
	takeover_state = value

func set_impact_state(value: String) -> void:
	impact_state = value

func set_motion_debug_lines(value: PackedStringArray) -> void:
	motion_debug_lines = value

func set_wanted_level(value: int) -> void:
	wanted_level = value

func set_police_count(value: int) -> void:
	police_count = value
