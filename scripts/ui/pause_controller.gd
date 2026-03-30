extends Node

signal pause_toggled(is_paused: bool)

const FullscreenSupport = preload("res://scripts/core/fullscreen_support.gd")

@export var overlay_path: NodePath

@onready var overlay: Control = get_node_or_null(overlay_path)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_overlay()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_fullscreen"):
		_handle_fullscreen_toggle(event)
		return
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	get_tree().paused = not get_tree().paused
	_sync_overlay()
	pause_toggled.emit(get_tree().paused)

func _sync_overlay() -> void:
	if overlay != null:
		overlay.visible = get_tree().paused
		if overlay.has_method("refresh_fullscreen_state"):
			overlay.refresh_fullscreen_state()

func _handle_fullscreen_toggle(event: InputEvent) -> void:
	if not get_tree().paused:
		return
	if not FullscreenSupport.can_toggle_fullscreen():
		return
	get_viewport().set_input_as_handled()
	if overlay != null and overlay.has_method("toggle_fullscreen"):
		overlay.toggle_fullscreen()
