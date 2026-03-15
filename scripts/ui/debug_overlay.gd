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
	var lines := PackedStringArray([
		"Mode: %s" % debug_state.player_mode,
		"Vehicle: %s" % debug_state.active_vehicle_label,
		"Hint: %s" % debug_state.interaction_hint,
		"Takeover: %s" % debug_state.takeover_state,
		"Speed: %.1f kph" % debug_state.speed_kph,
		"Collision: %s" % debug_state.collision_state,
		"Impact: %s" % debug_state.impact_state,
		"Traffic: %d active" % get_tree().get_nodes_in_group("traffic_vehicle").size(),
	])
	if debug_state.motion_debug_lines.size() > 0:
		lines.append("")
		lines.append_array(debug_state.motion_debug_lines)
	lines.append_array(PackedStringArray([
		"",
		"Controls:",
		"WASD move / drive",
		"E enter or exit vehicle",
		"O toggle debug overlay",
		"P pause + palette key",
	]))
	stats_label.text = "\n".join(lines)
