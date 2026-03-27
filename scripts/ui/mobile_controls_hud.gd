extends Control

const ON_FOOT_ACTIONS := {
	"up": "move_up",
	"down": "move_down",
	"left": "move_left",
	"right": "move_right",
}
const DRIVING_ACTIONS := {
	"left": "steer_left",
	"right": "steer_right",
}
const OPACITY_LEVELS := [1.0, 0.8, 0.55, 0.3, 0.0]

@export var player_path: NodePath
@export var game_root_path: NodePath
@export_range(60.0, 180.0, 1.0) var joystick_size := 176.0
@export_range(0.05, 0.5, 0.01) var joystick_deadzone := 0.18
@export_range(0.0, 96.0, 1.0) var hud_margin := 20.0

@onready var player: Node = get_node_or_null(player_path)
@onready var game_root: Node = get_node_or_null(game_root_path)
@onready var top_right_buttons: HBoxContainer = %TopRightButtons
@onready var interact_button: Button = %ActButton
@onready var pause_button: Button = %PauseButton
@onready var joystick_panel: PanelContainer = %JoystickPanel
@onready var joystick_text: Label = %JoystickText
@onready var driving_buttons: VBoxContainer = %DrivingButtons
@onready var accelerate_button: Button = %GasButton
@onready var brake_button: Button = %BrakeButton

var action_strengths: Dictionary = {}
var desktop_toggle_key_was_down := false
var joystick_touch_id := -1
var joystick_mouse_active := false
var joystick_center := Vector2.ZERO
var joystick_value := Vector2.ZERO
var opacity_level_index := 0
var last_visible_opacity_index := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_configure_controls()
	resized.connect(_layout_hud)
	visibility_changed.connect(_on_visibility_changed)
	_apply_opacity_level()
	_layout_hud()
	_update_visibility()

func _process(_delta: float) -> void:
	var toggle_key_down := Input.is_action_pressed("toggle_mobile_controls") or Input.is_physical_key_pressed(KEY_M)
	if toggle_key_down and not desktop_toggle_key_was_down:
		toggle_hud_opacity()
	desktop_toggle_key_was_down = toggle_key_down
	_update_visibility()
	_update_auxiliary_visibility()
	_sync_direction_actions()

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_handle_screen_touch(event)
		return
	if event is InputEventScreenDrag:
		_handle_screen_drag(event)
		return
	if event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout_hud()

func _exit_tree() -> void:
	_release_all_actions()

func _configure_controls() -> void:
	_style_button(interact_button, Color(0.36, 0.9, 0.48, 0.96), Color(0.04, 0.18, 0.06, 0.95))
	_style_button(pause_button, Color(0.98, 0.96, 0.56, 0.96), Color(0.18, 0.18, 0.04, 0.95))
	_style_button(accelerate_button, Color(1.0, 0.66, 0.2, 0.96), Color(0.18, 0.1, 0.02, 0.95))
	_style_button(brake_button, Color(0.86, 0.38, 0.28, 0.96), Color(0.2, 0.04, 0.02, 0.95))

	interact_button.button_down.connect(_emit_action_event.bind("interact", true))
	interact_button.button_up.connect(_emit_action_event.bind("interact", false))
	pause_button.button_down.connect(_emit_action_event.bind("pause", true))
	pause_button.button_up.connect(_emit_action_event.bind("pause", false))
	accelerate_button.button_down.connect(_emit_action_event.bind("accelerate", true))
	accelerate_button.button_up.connect(_emit_action_event.bind("accelerate", false))
	brake_button.button_down.connect(_emit_action_event.bind("brake", true))
	brake_button.button_up.connect(_emit_action_event.bind("brake", false))

func _style_button(button: Button, fill_color: Color, text_color: Color) -> void:
	button.process_mode = Node.PROCESS_MODE_ALWAYS
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_filter = Control.MOUSE_FILTER_STOP
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

func _make_stylebox(fill_color: Color) -> StyleBoxFlat:
	var stylebox := StyleBoxFlat.new()
	stylebox.bg_color = fill_color
	stylebox.corner_radius_top_left = 18
	stylebox.corner_radius_top_right = 18
	stylebox.corner_radius_bottom_right = 18
	stylebox.corner_radius_bottom_left = 18
	stylebox.border_width_left = 3
	stylebox.border_width_top = 3
	stylebox.border_width_right = 3
	stylebox.border_width_bottom = 3
	stylebox.border_color = Color(0.08, 0.08, 0.08, 0.78)
	return stylebox

func _layout_hud() -> void:
	var viewport_rect := get_viewport_rect()
	var top_left := Vector2.ONE * hud_margin
	var bottom_right := viewport_rect.size - Vector2.ONE * hud_margin

	top_right_buttons.position = Vector2(bottom_right.x - top_right_buttons.size.x, top_left.y)
	joystick_panel.position = Vector2(top_left.x, bottom_right.y - joystick_size)
	joystick_panel.size = Vector2(joystick_size, joystick_size)
	driving_buttons.position = Vector2(bottom_right.x - driving_buttons.size.x, bottom_right.y - driving_buttons.size.y)
	joystick_center = joystick_panel.position + joystick_panel.size * 0.5

func _update_visibility() -> void:
	visible = true
	_update_auxiliary_visibility()

func _update_auxiliary_visibility() -> void:
	top_right_buttons.visible = true
	joystick_panel.visible = true
	var driving := _is_driving()
	driving_buttons.visible = driving
	joystick_text.text = "STEER" if driving else "MOVE"

func _handle_screen_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		if joystick_touch_id == -1 and joystick_panel.get_global_rect().has_point(event.position):
			joystick_touch_id = event.index
			_update_joystick_value(event.position)
		return
	if event.index == joystick_touch_id:
		_reset_joystick()

func _handle_screen_drag(event: InputEventScreenDrag) -> void:
	if event.index != joystick_touch_id:
		return
	_update_joystick_value(event.position)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index != MOUSE_BUTTON_LEFT:
		return
	if event.pressed:
		if joystick_panel.get_global_rect().has_point(event.position):
			joystick_mouse_active = true
			_update_joystick_value(event.position)
		return
	if joystick_mouse_active:
		_reset_joystick()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if not joystick_mouse_active:
		return
	_update_joystick_value(event.position)

func _update_joystick_value(screen_position: Vector2) -> void:
	var radius := joystick_panel.size.x * 0.5
	var offset := screen_position - joystick_center
	joystick_value = offset.limit_length(radius) / maxf(radius, 1.0)

func _sync_direction_actions() -> void:
	var desired_strengths := {}
	for action_name in ON_FOOT_ACTIONS.values():
		desired_strengths[action_name] = 0.0
	for action_name in DRIVING_ACTIONS.values():
		desired_strengths[action_name] = 0.0

	var filtered_vector := _get_filtered_joystick_value()
	if _is_driving():
		desired_strengths[DRIVING_ACTIONS["left"]] = maxf(-filtered_vector.x, 0.0)
		desired_strengths[DRIVING_ACTIONS["right"]] = maxf(filtered_vector.x, 0.0)
	else:
		desired_strengths[ON_FOOT_ACTIONS["up"]] = maxf(-filtered_vector.y, 0.0)
		desired_strengths[ON_FOOT_ACTIONS["down"]] = maxf(filtered_vector.y, 0.0)
		desired_strengths[ON_FOOT_ACTIONS["left"]] = maxf(-filtered_vector.x, 0.0)
		desired_strengths[ON_FOOT_ACTIONS["right"]] = maxf(filtered_vector.x, 0.0)

	for action_name in desired_strengths.keys():
		var desired_strength: float = desired_strengths[action_name]
		var current_strength: float = action_strengths.get(action_name, 0.0)
		if is_equal_approx(desired_strength, current_strength):
			continue
		if desired_strength <= 0.0:
			Input.action_release(action_name)
		else:
			Input.action_press(action_name, desired_strength)
		action_strengths[action_name] = desired_strength

func _get_filtered_joystick_value() -> Vector2:
	var magnitude := joystick_value.length()
	if magnitude <= joystick_deadzone:
		return Vector2.ZERO
	var normalized_magnitude := inverse_lerp(joystick_deadzone, 1.0, magnitude)
	return joystick_value.normalized() * normalized_magnitude

func _is_driving() -> bool:
	var player_driving: bool = player != null and player.has_method("is_in_vehicle") and player.is_in_vehicle()
	var camera_possession_driving: bool = game_root != null and game_root.has_method("is_camera_possession_active") and game_root.is_camera_possession_active()
	return player_driving or camera_possession_driving

func _release_all_actions() -> void:
	_reset_joystick()
	for action_name in ON_FOOT_ACTIONS.values():
		Input.action_release(action_name)
		action_strengths[action_name] = 0.0
	for action_name in DRIVING_ACTIONS.values():
		Input.action_release(action_name)
		action_strengths[action_name] = 0.0
	Input.action_release("accelerate")
	Input.action_release("brake")
	Input.action_release("interact")
	Input.action_release("pause")

func _reset_joystick() -> void:
	joystick_touch_id = -1
	joystick_mouse_active = false
	joystick_value = Vector2.ZERO

func cycle_hud_opacity() -> void:
	opacity_level_index = (opacity_level_index + 1) % OPACITY_LEVELS.size()
	if OPACITY_LEVELS[opacity_level_index] > 0.0:
		last_visible_opacity_index = opacity_level_index
	_apply_opacity_level()

func get_hud_opacity_label() -> String:
	return "HUD Opacity: %d%%" % int(round(OPACITY_LEVELS[opacity_level_index] * 100.0))

func toggle_hud_opacity() -> void:
	if OPACITY_LEVELS[opacity_level_index] <= 0.0:
		opacity_level_index = last_visible_opacity_index
	else:
		last_visible_opacity_index = opacity_level_index
		opacity_level_index = OPACITY_LEVELS.size() - 1
	_apply_opacity_level()

func _apply_opacity_level() -> void:
	modulate.a = OPACITY_LEVELS[opacity_level_index]

func _emit_action_event(action_name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = pressed
	Input.parse_input_event(event)

func _on_visibility_changed() -> void:
	if not visible:
		_release_all_actions()
