extends Node

var player_mode := "On Foot"
var interaction_hint := "Press E near the car"
var wanted_level := 0
var mission_state := "Free Roam"
var speed_kph := 0.0

func set_player_mode(value: String) -> void:
	player_mode = value

func set_interaction_hint(value: String) -> void:
	interaction_hint = value

func set_speed(value: float) -> void:
	speed_kph = value
