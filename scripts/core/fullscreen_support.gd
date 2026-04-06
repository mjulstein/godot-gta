class_name FullscreenSupport
extends RefCounted

static var _cached_is_fullscreen := false
static var _cached_capability := {
	"browser_target": "native_desktop",
	"supports_windowed_and_fullscreen": true,
	"supports_browser_fullscreen_api": false,
	"supports_external_fullscreen_exit_signal": false,
}
static var _last_toggle_source := "unknown"
static var _last_toggle_result := "unchanged"

static func is_web_runtime() -> bool:
	return OS.has_feature("web")

static func get_runtime_capability() -> Dictionary:
	if is_web_runtime():
		_ensure_web_bridge()
		var supports_browser_fullscreen_api := _eval_bool("""
!!(
	document.documentElement
	&& typeof document.documentElement.requestFullscreen === "function"
	&& typeof document.exitFullscreen === "function"
)
""")
		var fullscreen_only_display_mode := _eval_bool("""
!!(window.matchMedia && window.matchMedia("(display-mode: fullscreen)").matches && !document.fullscreenElement)
""")
		_cached_capability = {
			"browser_target": "desktop_chrome",
			"supports_windowed_and_fullscreen": supports_browser_fullscreen_api and not fullscreen_only_display_mode,
			"supports_browser_fullscreen_api": supports_browser_fullscreen_api,
			"supports_external_fullscreen_exit_signal": _eval_bool("'onfullscreenchange' in document"),
		}
		return _cached_capability

	var supports_windowed_and_fullscreen := not OS.has_feature("mobile")
	_cached_capability = {
		"browser_target": "native_desktop",
		"supports_windowed_and_fullscreen": supports_windowed_and_fullscreen,
		"supports_browser_fullscreen_api": false,
		"supports_external_fullscreen_exit_signal": false,
	}
	return _cached_capability

static func can_toggle_fullscreen() -> bool:
	return bool(get_runtime_capability().get("supports_windowed_and_fullscreen", false))

static func is_fullscreen() -> bool:
	_cached_is_fullscreen = _read_fullscreen_state()
	return _cached_is_fullscreen

static func poll_state() -> Dictionary:
	var was_fullscreen := _cached_is_fullscreen
	var is_now_fullscreen := _read_fullscreen_state()
	var denied := _consume_denied_state()
	var changed := is_now_fullscreen != was_fullscreen
	_cached_is_fullscreen = is_now_fullscreen
	if denied:
		_last_toggle_result = "denied"
	elif changed:
		_last_toggle_result = "entered" if is_now_fullscreen else "exited"
	return {
		"was_fullscreen": was_fullscreen,
		"is_fullscreen": is_now_fullscreen,
		"changed": changed,
		"denied": denied,
		"last_toggle_source": _last_toggle_source,
		"last_toggle_result": _last_toggle_result,
	}

static func toggle_fullscreen(request_source: String = "unknown") -> bool:
	if not can_toggle_fullscreen():
		return false
	_last_toggle_source = request_source
	if is_web_runtime():
		_ensure_web_bridge()
		var requested := _eval_bool("""
window.godotGTAFullscreen.lastDenied = false;
if (
	!document.documentElement
	|| typeof document.documentElement.requestFullscreen !== "function"
	|| typeof document.exitFullscreen !== "function"
) {
	window.godotGTAFullscreen.lastDenied = true;
	false;
} else if (document.fullscreenElement) {
	document.exitFullscreen().catch(function () {
		window.godotGTAFullscreen.lastDenied = true;
	});
	true;
} else {
	document.documentElement.requestFullscreen().catch(function () {
		window.godotGTAFullscreen.lastDenied = true;
	});
	true;
}
""")
		if not requested:
			_last_toggle_result = "denied"
		return requested

	var mode := DisplayServer.window_get_mode()
	var target_mode := DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(target_mode)
	_cached_is_fullscreen = _read_fullscreen_state()
	_last_toggle_result = "entered" if _cached_is_fullscreen else "exited"
	return true

static func get_button_label() -> String:
	return "Exit Fullscreen (F)" if is_fullscreen() else "Enter Fullscreen (F)"

static func _read_fullscreen_state() -> bool:
	if is_web_runtime():
		_ensure_web_bridge()
		return _eval_bool("!!document.fullscreenElement")
	var mode := DisplayServer.window_get_mode()
	return mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN

static func _consume_denied_state() -> bool:
	if not is_web_runtime():
		return false
	_ensure_web_bridge()
	var denied := _eval_bool("!!window.godotGTAFullscreen && !!window.godotGTAFullscreen.lastDenied")
	if denied:
		JavaScriptBridge.eval("window.godotGTAFullscreen.lastDenied = false;", true)
	return denied

static func _ensure_web_bridge() -> void:
	if not is_web_runtime():
		return
	JavaScriptBridge.eval("""
window.godotGTAFullscreen = window.godotGTAFullscreen || {
	lastDenied: false
};
""", true)

static func _eval_bool(code: String) -> bool:
	var value = JavaScriptBridge.eval(code, true)
	if value is bool:
		return value
	if value is int:
		return value != 0
	if value is float:
		return not is_zero_approx(value)
	return false
