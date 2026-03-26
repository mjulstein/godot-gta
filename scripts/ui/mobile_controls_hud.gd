extends Control

const ON_FOOT_ACTIONS := {
	"up": "move_up",
	"down": "move_down",
	"left": "move_left",
	"right": "move_right",
}
const DRIVING_ACTIONS := {
	"up": "accelerate",
	"down": "brake",
	"left": "steer_left",
	"right": "steer_right",
}
const DIRECTION_NAMES := ["up", "down", "left", "right"]
const DIRECTION_GLYPHS := {
	"up": "U",
	"down": "D",
	"left": "L",
	"right": "R",
}
const OPACITY_LEVELS := [1.0, 0.8, 0.55, 0.3]

@export var player_path: NodePath
@export var debug_overlay_path: NodePath
@export var show_on_desktop_override := false
@export_range(48.0, 120.0, 1.0) var button_size := 76.0
@export_range(8.0, 48.0, 1.0) var button_gap := 14.0
@export_range(12.0, 96.0, 1.0) var edge_padding := 20.0
@export_range(0.0, 64.0, 1.0) var safe_area_padding := 12.0

@onready var player: Node = get_node_or_null(player_path)
@onready var debug_overlay: Control = get_node_or_null(debug_overlay_path)

var held_directions := {
	"up": false,
	"down": false,
	"left": false,
	"right": false,
}
var action_states: Dictionary = {}
var desktop_visibility_toggled := false
var desktop_toggle_key_was_down := false
var opacity_level_index := 0

var direction_buttons: Dictionary = {}
var interact_button: Button
var pause_button: Button
var debug_button: Button
var opacity_button: Button
var joystick_backdrop: Panel

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_buttons()
	_hide_legacy_nodes()
	resized.connect(_layout_hud)
	visibility_changed.connect(_on_visibility_changed)
	_apply_opacity_level()
	_layout_hud()
	_update_visibility()

func _process(_delta: float) -> void:
	var toggle_key_down := Input.is_action_pressed("toggle_mobile_controls") or Input.is_physical_key_pressed(KEY_M)
	if toggle_key_down and not desktop_toggle_key_was_down:
		desktop_visibility_toggled = not desktop_visibility_toggled
		_update_visibility()
	desktop_toggle_key_was_down = toggle_key_down
	_update_visibility()
	if not visible:
		_release_all_actions()
		return
	_update_direction_labels()
	_update_auxiliary_visibility()
	_sync_direction_actions()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout_hud()

func _exit_tree() -> void:
	_release_all_actions()

func _create_buttons() -> void:
	if joystick_backdrop != null:
		return
	joystick_backdrop = Panel.new()
	joystick_backdrop.name = "JoystickBackdrop"
	joystick_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_backdrop.self_modulate = Color(1.0, 0.93, 0.72, 0.22)
	add_child(joystick_backdrop)

	for direction_name in DIRECTION_NAMES:
		var button := _make_button(direction_name.to_upper(), Color(0.96, 0.9, 0.72, 0.94), Color(0.12, 0.1, 0.04, 0.95))
		button.button_down.connect(_on_direction_button_down.bind(direction_name))
		button.button_up.connect(_on_direction_button_up.bind(direction_name))
		direction_buttons[direction_name] = button

	interact_button = _make_button("ACT", Color(0.36, 0.9, 0.48, 0.96), Color(0.04, 0.18, 0.06, 0.95))
	interact_button.button_down.connect(_emit_action_event.bind("interact", true))
	interact_button.button_up.connect(_emit_action_event.bind("interact", false))

	pause_button = _make_button("PAUSE", Color(0.98, 0.96, 0.56, 0.96), Color(0.18, 0.18, 0.04, 0.95))
	pause_button.button_down.connect(_emit_action_event.bind("pause", true))
	pause_button.button_up.connect(_emit_action_event.bind("pause", false))

	debug_button = _make_button("DBG", Color(1.0, 0.82, 0.42, 0.96), Color(0.18, 0.12, 0.02, 0.95))
	debug_button.pressed.connect(_toggle_debug_overlay)

	opacity_button = _make_button("OP", Color(0.74, 0.9, 1.0, 0.96), Color(0.08, 0.14, 0.2, 0.95))
	opacity_button.pressed.connect(_cycle_opacity)

func _make_button(text: String, fill_color: Color, text_color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.custom_minimum_size = Vector2(button_size, button_size)
	button.flat = false
	button.clip_text = true
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_focus_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_hover_pressed_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)
	button.add_theme_stylebox_override("normal", _make_stylebox(fill_color))
	button.add_theme_stylebox_override("hover", _make_stylebox(fill_color.lightened(0.08)))
	button.add_theme_stylebox_override("pressed", _make_stylebox(fill_color.darkened(0.12)))
	button.add_theme_stylebox_override("focus", _make_stylebox(fill_color))
	add_child(button)
	return button

func _make_stylebox(fill_color: Color) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
	stylebox.corner_radius_top_left = int(button_size * 0.38)
	stylebox.corner_radius_top_right = int(button_size * 0.38)
	stylebox.corner_radius_bottom_right = int(button_size * 0.38)
	stylebox.corner_radius_bottom_left = int(button_size * 0.38)
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color(0.08, 0.08, 0.08, 0.78)
	return stylebox

func _hide_legacy_nodes() -> void:
	for child in get_children():
		if child is TouchScreenButton or (child is Label and child not in direction_buttons.values()):
			child.visible = false

func _layout_hud() -> void:
	if joystick_backdrop == null:
		return
	var safe_area := DisplayServer.get_display_safe_area()
	var viewport_rect := get_viewport_rect()
	if safe_area.size == Vector2i.ZERO:
		safe_area = Rect2i(Vector2i.ZERO, Vector2i(viewport_rect.size))
	var left_edge := safe_area.position.x + edge_padding + safe_area_padding
	var right_edge := safe_area.end.x - edge_padding - safe_area_padding
	var top_edge := safe_area.position.y + edge_padding + safe_area_padding
	var bottom_edge := safe_area.end.y - edge_padding - safe_area_padding

	var cluster_size := button_size * 3.0 + button_gap * 2.0
	var cluster_origin := Vector2(left_edge, bottom_edge - cluster_size)
	joystick_backdrop.position = cluster_origin - Vector2(button_gap, button_gap)
	joystick_backdrop.size = Vector2(cluster_size + button_gap * 2.0, cluster_size + button_gap * 2.0)

	_place_button(direction_buttons["up"], cluster_origin + Vector2(button_size + button_gap, 0.0))
	_place_button(direction_buttons["left"], cluster_origin + Vector2(0.0, button_size + button_gap))
	_place_button(direction_buttons["right"], cluster_origin + Vector2((button_size + button_gap) * 2.0, button_size + button_gap))
	_place_button(direction_buttons["down"], cluster_origin + Vector2(button_size + button_gap, (button_size + button_gap) * 2.0))

	_place_button(interact_button, Vector2(right_edge - button_size * 1.35, bottom_edge - button_size * 1.35))
	_place_button(debug_button, Vector2(right_edge - button_size, top_edge))
	_place_button(opacity_button, Vector2(right_edge - button_size * 2.15 - button_gap, top_edge))
	_place_button(pause_button, Vector2(right_edge - button_size, top_edge + button_size + button_gap))

func _place_button(button: Button, position: Vector2) -> void:
	button.position = position
	button.size = Vector2(button_size, button_size)

func _update_visibility() -> void:
	var should_show := _should_show_hud()
	if visible == should_show:
		if visible:
			_update_auxiliary_visibility()
		return
	visible = should_show
	if not visible:
		_release_all_actions()
	else:
		_update_auxiliary_visibility()

func _should_show_hud() -> bool:
	if show_on_desktop_override or desktop_visibility_toggled:
		return true
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"

func _update_auxiliary_visibility() -> void:
	var desktop_test_mode := desktop_visibility_toggled and _is_desktop_mouse_mode()
	var debug_visible := desktop_test_mode or get_tree().paused or _is_debug_overlay_active()
	var opacity_visible := desktop_test_mode or get_tree().paused
	debug_button.visible = debug_visible
	opacity_button.visible = opacity_visible
	pause_button.visible = true
	interact_button.visible = true
	joystick_backdrop.visible = true
	for button in direction_buttons.values():
		button.visible = true

func _update_direction_labels() -> void:
	for direction_name in DIRECTION_NAMES:
		var button: Button = direction_buttons[direction_name]
		button.text = DIRECTION_GLYPHS[direction_name]

func _on_direction_button_down(direction_name: String) -> void:
	held_directions[direction_name] = true
	_sync_direction_actions()

func _on_direction_button_up(direction_name: String) -> void:
	held_directions[direction_name] = false
	_sync_direction_actions()

func _toggle_debug_overlay() -> void:
	if debug_overlay != null and debug_overlay.has_method("toggle_overlay"):
		debug_overlay.toggle_overlay()
	else:
		_emit_action_event("debug_overlay", true)
		_emit_action_event("debug_overlay", false)
	_update_auxiliary_visibility()

func _cycle_opacity() -> void:
	opacity_level_index = (opacity_level_index + 1) % OPACITY_LEVELS.size()
	_apply_opacity_level()

func _apply_opacity_level() -> void:
	modulate.a = OPACITY_LEVELS[opacity_level_index]

func _sync_direction_actions() -> void:
	var active_map := DRIVING_ACTIONS if _is_driving() else ON_FOOT_ACTIONS
	var desired_states: Dictionary = {}
	for action_name in ON_FOOT_ACTIONS.values():
		desired_states[action_name] = false
	for action_name in DRIVING_ACTIONS.values():
		desired_states[action_name] = false
	for direction_name in DIRECTION_NAMES:
		if held_directions[direction_name]:
			desired_states[active_map[direction_name]] = true
	for action_name in desired_states.keys():
		var should_press: bool = desired_states[action_name]
		var is_pressed: bool = action_states.get(action_name, false)
		if should_press == is_pressed:
			continue
		if should_press:
			Input.action_press(action_name)
		else:
			Input.action_release(action_name)
		action_states[action_name] = should_press

func _is_driving() -> bool:
	return player != null and player.has_method("is_in_vehicle") and player.is_in_vehicle()

func _release_all_actions() -> void:
	for direction_name in DIRECTION_NAMES:
		held_directions[direction_name] = false
	for action_name in ON_FOOT_ACTIONS.values():
		Input.action_release(action_name)
		action_states[action_name] = false
	for action_name in DRIVING_ACTIONS.values():
		Input.action_release(action_name)
		action_states[action_name] = false
	Input.action_release("interact")
	Input.action_release("pause")

func _emit_action_event(action_name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = pressed
	Input.parse_input_event(event)

func _on_visibility_changed() -> void:
	if not visible:
		_release_all_actions()

func _is_debug_overlay_active() -> bool:
	if debug_overlay == null:
		return false
	if debug_overlay.has_method("is_overlay_active"):
		return debug_overlay.is_overlay_active()
	return debug_overlay.visible

func _is_desktop_mouse_mode() -> bool:
	return not (DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android")
