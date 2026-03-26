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
const DIRECTIONAL_ACTIONS := [
	"move_up",
	"move_down",
	"move_left",
	"move_right",
	"accelerate",
	"brake",
	"steer_left",
	"steer_right",
]

@export var player_path: NodePath
@export var show_on_desktop_override := false
@export_range(40.0, 120.0, 1.0) var button_radius := 44.0
@export_range(24.0, 160.0, 1.0) var direction_spacing := 84.0
@export_range(12.0, 96.0, 1.0) var edge_padding := 28.0
@export_range(0.0, 64.0, 1.0) var safe_area_padding := 12.0

@onready var player: Node = get_node_or_null(player_path)
@onready var up_button: TouchScreenButton = %UpButton
@onready var down_button: TouchScreenButton = %DownButton
@onready var left_button: TouchScreenButton = %LeftButton
@onready var right_button: TouchScreenButton = %RightButton
@onready var interact_button: TouchScreenButton = %InteractButton
@onready var pause_button: TouchScreenButton = %PauseButton
@onready var up_label: Label = %UpLabel
@onready var down_label: Label = %DownLabel
@onready var left_label: Label = %LeftLabel
@onready var right_label: Label = %RightLabel
@onready var interact_label: Label = %InteractLabel
@onready var pause_label: Label = %PauseLabel

var held_directions := {
	"up": false,
	"down": false,
	"left": false,
	"right": false,
}
var action_states: Dictionary = {}
var normal_texture: Texture2D
var pressed_texture: Texture2D
var action_texture: Texture2D
var action_pressed_texture: Texture2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_button_textures()
	_configure_direction_button(up_button, up_label, "up")
	_configure_direction_button(down_button, down_label, "down")
	_configure_direction_button(left_button, left_label, "left")
	_configure_direction_button(right_button, right_label, "right")
	_configure_action_button(interact_button, interact_label, "interact")
	_configure_action_button(pause_button, pause_label, "pause")
	resized.connect(_layout_buttons)
	visibility_changed.connect(_on_visibility_changed)
	_layout_buttons()
	_update_visibility()

func _process(_delta: float) -> void:
	_update_visibility()
	if not visible:
		_release_all_actions()
		return
	_sync_direction_actions()

func _exit_tree() -> void:
	_release_all_actions()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED:
		_layout_buttons()

func _configure_direction_button(button: TouchScreenButton, label: Label, direction_name: String) -> void:
	button.texture_normal = normal_texture
	button.texture_pressed = pressed_texture
	button.shape = _make_button_shape()
	button.pressed.connect(_on_direction_pressed.bind(direction_name))
	button.released.connect(_on_direction_released.bind(direction_name))
	_configure_label(label)

func _configure_action_button(button: TouchScreenButton, label: Label, action_name: String) -> void:
	button.texture_normal = action_texture
	button.texture_pressed = action_pressed_texture
	button.shape = _make_button_shape(button_radius * 1.1)
	button.pressed.connect(_on_action_pressed.bind(action_name))
	button.released.connect(_on_action_released.bind(action_name))
	_configure_label(label)

func _configure_label(label: Label) -> void:
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08, 0.95))
	label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)

func _layout_buttons() -> void:
	var safe_area := DisplayServer.get_display_safe_area()
	var viewport_rect := get_viewport_rect()
	if safe_area.size == Vector2i.ZERO:
		safe_area = Rect2i(Vector2i.ZERO, Vector2i(viewport_rect.size))
	var left_edge := safe_area.position.x + edge_padding + safe_area_padding
	var right_edge := safe_area.end.x - edge_padding - safe_area_padding
	var top_edge := safe_area.position.y + edge_padding + safe_area_padding
	var bottom_edge := safe_area.end.y - edge_padding - safe_area_padding
	var cluster_origin := Vector2(left_edge + direction_spacing, bottom_edge - direction_spacing)
	var action_origin := Vector2(right_edge - button_radius * 1.2, bottom_edge - button_radius * 0.7)
	var pause_origin := Vector2(right_edge - button_radius * 0.8, top_edge + button_radius * 0.8)

	_place_button(up_button, up_label, cluster_origin + Vector2(0.0, -direction_spacing), button_radius)
	_place_button(down_button, down_label, cluster_origin + Vector2(0.0, direction_spacing), button_radius)
	_place_button(left_button, left_label, cluster_origin + Vector2(-direction_spacing, 0.0), button_radius)
	_place_button(right_button, right_label, cluster_origin + Vector2(direction_spacing, 0.0), button_radius)
	_place_button(interact_button, interact_label, action_origin, button_radius * 1.1)
	_place_button(pause_button, pause_label, pause_origin, button_radius * 0.95)

func _place_button(button: TouchScreenButton, label: Label, center: Vector2, radius: float) -> void:
	button.position = center
	var diameter := radius * 2.0
	label.position = center - Vector2(radius, radius)
	label.size = Vector2(diameter, diameter)

func _update_visibility() -> void:
	var should_show := _should_show_hud()
	if visible == should_show:
		return
	visible = should_show
	if not visible:
		_release_all_actions()

func _should_show_hud() -> bool:
	if show_on_desktop_override:
		return true
	return DisplayServer.is_touchscreen_available() or OS.has_feature("mobile") or OS.get_name() == "iOS" or OS.get_name() == "Android"

func _sync_direction_actions() -> void:
	var active_map := DRIVING_ACTIONS if _is_driving() else ON_FOOT_ACTIONS
	var desired_states: Dictionary = {}
	for action_name in DIRECTIONAL_ACTIONS:
		desired_states[action_name] = false
	for direction_name in DIRECTION_NAMES:
		if held_directions[direction_name]:
			desired_states[active_map[direction_name]] = true
	for action_name in DIRECTIONAL_ACTIONS:
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
	for action_name in DIRECTIONAL_ACTIONS:
		if not action_states.get(action_name, false):
			continue
		Input.action_release(action_name)
		action_states[action_name] = false
	for action_name in ["interact", "pause"]:
		Input.action_release(action_name)

func _on_direction_pressed(direction_name: String) -> void:
	held_directions[direction_name] = true
	_sync_direction_actions()

func _on_direction_released(direction_name: String) -> void:
	held_directions[direction_name] = false
	_sync_direction_actions()

func _on_action_pressed(action_name: String) -> void:
	_emit_action_event(action_name, true)

func _on_action_released(action_name: String) -> void:
	_emit_action_event(action_name, false)

func _emit_action_event(action_name: String, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action_name
	event.pressed = pressed
	Input.parse_input_event(event)

func _on_visibility_changed() -> void:
	if visible:
		return
	_release_all_actions()

func _build_button_textures() -> void:
	normal_texture = _make_button_texture(button_radius, Color(0.96, 0.92, 0.74, 0.68), Color(0.14, 0.14, 0.14, 0.48))
	pressed_texture = _make_button_texture(button_radius, Color(1.0, 0.8, 0.34, 0.9), Color(0.16, 0.12, 0.02, 0.68))
	action_texture = _make_button_texture(button_radius * 1.1, Color(0.82, 0.96, 0.84, 0.72), Color(0.12, 0.16, 0.12, 0.52))
	action_pressed_texture = _make_button_texture(button_radius * 1.1, Color(0.42, 0.86, 0.48, 0.9), Color(0.04, 0.18, 0.06, 0.74))

func _make_button_shape(radius: float = button_radius) -> Shape2D:
	var shape := CircleShape2D.new()
	shape.radius = radius
	return shape

func _make_button_texture(radius: float, fill_color: Color, edge_color: Color) -> Texture2D:
	var diameter := int(ceil(radius * 2.0))
	var image := Image.create(diameter, diameter, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	var center := Vector2(radius, radius)
	for y in range(diameter):
		for x in range(diameter):
			var distance := center.distance_to(Vector2(x + 0.5, y + 0.5))
			if distance > radius:
				continue
			var pixel_color := fill_color
			if distance >= radius - 3.0:
				pixel_color = edge_color
			image.set_pixel(x, y, pixel_color)
	return ImageTexture.create_from_image(image)
