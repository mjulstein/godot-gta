extends Control

@onready var prompt_label: Label = %Prompt
var debug_state: Node

func set_debug_state(state: Node) -> void:
	debug_state = state

func _process(_delta: float) -> void:
	if debug_state == null:
		return
	var hint: String = debug_state.interaction_hint
	visible = not hint.is_empty()
	prompt_label.text = hint
