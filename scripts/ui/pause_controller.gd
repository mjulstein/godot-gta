extends Node

signal pause_toggled(is_paused: bool)

const FullscreenSupport = preload("res://scripts/core/fullscreen_support.gd")

@export var overlay_path: NodePath

@onready var overlay: Control = get_node_or_null(overlay_path)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	FullscreenSupport.poll_state()
	_sync_overlay()

func _process(_delta: float) -> void:
	_sync_fullscreen_state()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_handle_fullscreen_toggle(event)
		return
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	_set_paused(not get_tree().paused)

func _sync_overlay() -> void:
	if overlay != null:
		overlay.visible = get_tree().paused
		if overlay.has_method("refresh_fullscreen_state"):
			overlay.refresh_fullscreen_state()

func _set_paused(is_paused: bool) -> void:
	if get_tree().paused == is_paused:
		_sync_overlay()
		return
	get_tree().paused = is_paused
	_sync_overlay()
	pause_toggled.emit(get_tree().paused)

func _sync_fullscreen_state() -> void:
	var fullscreen_state := FullscreenSupport.poll_state()
	if bool(fullscreen_state.get("changed", false)):
		if FullscreenSupport.is_web_runtime() and bool(fullscreen_state.get("was_fullscreen", false)) and not bool(fullscreen_state.get("is_fullscreen", false)) and not get_tree().paused:
			_set_paused(true)
			return
		_sync_overlay()
		return
	if get_tree().paused and overlay != null and overlay.has_method("refresh_fullscreen_state"):
		overlay.refresh_fullscreen_state()

func _handle_fullscreen_toggle(event: InputEvent) -> void:
	if not get_tree().paused:
		return
	if not FullscreenSupport.can_toggle_fullscreen():
		return
	get_viewport().set_input_as_handled()
	if overlay != null and overlay.has_method("toggle_fullscreen"):
		overlay.toggle_fullscreen("paused_f_shortcut")
