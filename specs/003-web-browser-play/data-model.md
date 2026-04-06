[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / data-model.md

# Data Model: Web Browser Play

This feature does not add persistent gameplay data. The relevant model is transient runtime state shared between Godot pause logic, browser fullscreen capabilities, and an optional browser fullscreen bridge.

## Entity: BrowserRuntimeCapability

- **Purpose**: Describes what the current browser/runtime can do for this feature.
- **Fields**:
  - `browser_target`: expected browser family for the active build, initially `desktop_chrome`
  - `supports_windowed_and_fullscreen`: whether both display modes are meaningfully available
  - `supports_browser_fullscreen_api`: whether the shell can request fullscreen
  - `supports_external_fullscreen_exit_signal`: whether the browser can report fullscreen changes back to Godot
- **Validation rules**:
  - `supports_windowed_and_fullscreen` must be false on fullscreen-only contexts
  - Browser-specific UI affordances must key off capability state rather than platform name alone
  - Capability state must not change the gameplay code path

## Entity: FullscreenSessionState

- **Purpose**: Tracks the browser-visible fullscreen state used by pause UI and state reconciliation.
- **Fields**:
  - `is_fullscreen`: current fullscreen state
  - `last_toggle_source`: `pause_button`, `paused_f_shortcut`, `browser_ui`, or `unknown`
  - `last_toggle_result`: `entered`, `exited`, `denied`, or `unchanged`
  - `is_pause_required`: always true for in-game toggle requests
- **Validation rules**:
  - In-game toggle requests are valid only while paused
  - `denied` must not force an unpause
  - External exits must update `is_fullscreen` without desynchronizing pause state

## Entity: FullscreenBridgeRequest

- **Purpose**: Represents a single Godot→browser shell fullscreen action request.
- **Fields**:
  - `action`: `enter`, `exit`, or `toggle`
  - `requested_while_paused`: boolean
  - `request_source`: `pause_button` or `paused_f_shortcut`
  - `focus_context`: `game_canvas`, `pause_control`, `browser_surface`, or `unknown`
- **Validation rules**:
  - `requested_while_paused` must be true for any request emitted from gameplay
  - `focus_context` may vary, but the request still proceeds because paused `F` is allowed regardless of focus

## Entity: PauseOverlayFullscreenControl

- **Purpose**: Captures the user-facing pause UI state for fullscreen interaction.
- **Fields**:
  - `visible`: whether the control is shown
  - `label`: expected button text, including current fullscreen state and `F` hint
  - `enabled`: whether the button can currently request a toggle
- **Validation rules**:
  - `visible` must be false when `supports_windowed_and_fullscreen` is false
  - `label` must stay synchronized with `FullscreenSessionState.is_fullscreen`
  - When `visible` is true in a keyboard-capable runtime, `label` or an adjacent hint must include `F`

## Relationships

- `BrowserRuntimeCapability` controls visibility and availability of `PauseOverlayFullscreenControl`.
- `FullscreenBridgeRequest` mutates `FullscreenSessionState`.
- `FullscreenSessionState` feeds back into `PauseOverlayFullscreenControl` label and state.
- Godot pause flow owns when requests are allowed; any browser bridge owns only the fullscreen boundary.
