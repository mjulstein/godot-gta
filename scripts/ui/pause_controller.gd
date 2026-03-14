extends Node

@export var overlay_path: NodePath

@onready var overlay: Control = get_node_or_null(overlay_path)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_overlay()

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	get_viewport().set_input_as_handled()
	get_tree().paused = not get_tree().paused
	_sync_overlay()

func _sync_overlay() -> void:
	if overlay != null:
		overlay.visible = get_tree().paused
