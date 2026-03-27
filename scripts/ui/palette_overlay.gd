extends Control

signal impact_vibration_toggled(enabled: bool)

@export var debug_overlay_path: NodePath
@export var mobile_controls_hud_path: NodePath

@onready var debug_overlay: Control = get_node_or_null(debug_overlay_path)
@onready var mobile_controls_hud: Control = get_node_or_null(mobile_controls_hud_path)
@onready var toggle_debug_button: Button = %ToggleDebugButton
@onready var hud_opacity_button: Button = %HudOpacityButton
@onready var impact_vibration_button: Button = %ImpactVibrationButton
@onready var restart_button: Button = %RestartButton

var impact_vibration_enabled := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	toggle_debug_button.pressed.connect(_on_toggle_debug_pressed)
	hud_opacity_button.pressed.connect(_on_hud_opacity_pressed)
	impact_vibration_button.pressed.connect(_on_impact_vibration_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	_refresh_button_text()

func _on_toggle_debug_pressed() -> void:
	if debug_overlay != null and debug_overlay.has_method("toggle_overlay"):
		debug_overlay.toggle_overlay()
	_refresh_button_text()

func _on_hud_opacity_pressed() -> void:
	if mobile_controls_hud != null and mobile_controls_hud.has_method("cycle_hud_opacity"):
		mobile_controls_hud.cycle_hud_opacity()
	_refresh_button_text()

func _on_impact_vibration_pressed() -> void:
	set_impact_vibration_enabled(not impact_vibration_enabled)

func set_impact_vibration_enabled(enabled: bool) -> void:
	if impact_vibration_enabled == enabled:
		_refresh_button_text()
		return
	impact_vibration_enabled = enabled
	_refresh_button_text()
	impact_vibration_toggled.emit(impact_vibration_enabled)

func is_impact_vibration_enabled() -> bool:
	return impact_vibration_enabled

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _refresh_button_text() -> void:
	var debug_active := false
	if debug_overlay != null and debug_overlay.has_method("is_overlay_active"):
		debug_active = debug_overlay.is_overlay_active()
	toggle_debug_button.text = "Debug: On" if debug_active else "Debug: Off"

	var opacity_label := "HUD Opacity"
	if mobile_controls_hud != null and mobile_controls_hud.has_method("get_hud_opacity_label"):
		opacity_label = mobile_controls_hud.get_hud_opacity_label()
	hud_opacity_button.text = opacity_label
	impact_vibration_button.text = "Impact Vibration: On" if impact_vibration_enabled else "Impact Vibration: Off"
