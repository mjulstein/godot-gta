[root](../../../README.md) / [specs](../../README.md) / [003-web-browser-play](../README.md) / contracts / browser_fullscreen_bridge.md

# Contract: Browser Fullscreen Bridge

## Purpose

Define the narrow interface between Godot and the custom HTML shell used by `003-web-browser-play` for paused fullscreen behavior in desktop Chrome.

## Ownership

- **Godot owns**: pause state, gameplay state, whether a fullscreen request is allowed, pause overlay content, and interpretation of fullscreen state inside the game.
- **Browser shell owns**: calling the browser fullscreen API and reporting resulting fullscreen state back to Godot.

## Godot → Browser Shell

### Request: `toggleFullscreenFromPausedFlow`

- **When called**: only from the paused flow, via pause button or paused `F`
- **Inputs**:
  - `request_source`: `pause_button` or `paused_f_shortcut`
  - `requested_while_paused`: boolean, must be `true`
  - `desired_action`: `toggle`
- **Required behavior**:
  - If browser fullscreen is available, attempt the fullscreen toggle immediately from the browser-owned input path
  - If the browser denies the request, do not force an unpause

### Request: `getFullscreenState`

- **When called**: on pause-overlay refresh and after browser fullscreen events
- **Returns**:
  - `is_fullscreen`: boolean

## Browser Shell → Godot

### Callback: `onFullscreenStateChanged`

- **Payload**:
  - `is_fullscreen`: boolean
  - `change_source`: `shell_request`, `browser_ui`, `esc_key`, or `unknown`
- **Required behavior**:
  - Godot reconciles pause overlay state and button label
  - Godot keeps the game paused if the fullscreen transition happened from the paused flow

### Callback: `onFullscreenRequestDenied`

- **Payload**:
  - `request_source`: `pause_button` or `paused_f_shortcut`
- **Required behavior**:
  - Godot keeps the game paused
  - Pause overlay stays available
  - No explicit failure message is required by this feature

## Invariants

- Gameplay logic must not move into the browser shell.
- The shell must not become a second gameplay input path.
- Paused `F` remains valid regardless of current pause-menu or browser focus state.
- The fullscreen control must be hidden when the runtime does not expose a meaningful choice between non-fullscreen and fullscreen modes.
