extends Control

@onready var panel: Control = $Panel
@onready var stats_label: Label = %Stats
@onready var camera_button: Button = %CameraButton
var debug_state: Node
var overlay_active := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	camera_button.pressed.connect(_on_takeover_button_pressed)
	_sync_overlay_state()

func set_debug_state(state: Node) -> void:
	debug_state = state

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_overlay"):
		toggle_overlay()

func toggle_overlay() -> void:
	set_overlay_active(not overlay_active)

func set_overlay_active(value: bool) -> void:
	if overlay_active == value:
		return
	overlay_active = value
	_sync_overlay_state()

func is_overlay_active() -> bool:
	return overlay_active

func _sync_overlay_state() -> void:
	if is_instance_valid(panel):
		panel.visible = overlay_active
	if is_instance_valid(camera_button):
		camera_button.visible = true

func _on_takeover_button_pressed() -> void:
	_emit_action("debug_camera")

func _emit_action(action_name: String) -> void:
	var pressed_event := InputEventAction.new()
	pressed_event.action = action_name
	pressed_event.pressed = true
	Input.parse_input_event(pressed_event)
	var released_event := InputEventAction.new()
	released_event.action = action_name
	released_event.pressed = false
	Input.parse_input_event(released_event)

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
