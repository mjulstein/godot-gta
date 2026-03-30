class_name FullscreenSupport
extends RefCounted

static func can_toggle_fullscreen() -> bool:
	if OS.has_feature("mobile"):
		return false
	return true

static func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

static func toggle_fullscreen() -> bool:
	if not can_toggle_fullscreen():
		return false
	var target_mode := DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen() else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(target_mode)
	return true

static func get_button_label() -> String:
	var state_label := "On" if is_fullscreen() else "Off"
	return "Fullscreen: %s (F)" % state_label
