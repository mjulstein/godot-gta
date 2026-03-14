extends Control

@onready var stats_label: Label = %Stats
var debug_state: Node

func set_debug_state(state: Node) -> void:
	debug_state = state

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		visible = not visible

func _process(_delta: float) -> void:
	if debug_state == null:
		return
	stats_label.text = "\n".join([
		"Mode: %s" % debug_state.player_mode,
		"Hint: %s" % debug_state.interaction_hint,
		"Speed: %.1f kph" % debug_state.speed_kph,
		"Collision: %s" % debug_state.collision_state,
		"Wanted: %d" % debug_state.wanted_level,
		"Police: %d" % debug_state.police_count,
		"Mission: %s" % debug_state.mission_state,
		"",
		"Controls:",
		"WASD move / drive",
		"E enter or exit vehicle",
		"O toggle debug overlay",
	])
