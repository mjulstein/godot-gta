[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / web_browser_play.md

# Web Browser Play Validation

Validate first-pass browser parity in desktop Chrome using the in-game paused fullscreen control plus paused `F`.

## Setup

1. Run `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`.
2. Create the export folder with `mkdir -p build/web`.
3. Export the web build with `HOME=/tmp/godot-home godot --headless --path . --export-release Web build/web/index.html`.
4. Serve `build/web/` from a local HTTP server and open the build in desktop Chrome.
5. Start in a normal browser window instead of fullscreen.

## Browser Parity Flow

1. Confirm the game loads into the same main scene and starts on foot near the parked civilian vehicle.
2. Move with `WASD` and confirm on-foot movement, collisions, and interaction hints match desktop behavior.
3. Enter the parked vehicle with `E`, drive with `WASD`, and confirm the camera still follows the active actor.
4. Take over a civilian traffic vehicle, confirm displaced-occupant behavior still occurs, then exit and confirm the player returns to the normal on-foot loop.
5. Pause with `P` and confirm the pause overlay still shows the existing controls plus an `Enter Fullscreen (F)` or `Exit Fullscreen (F)` action.
6. Resize the browser window to several wide and narrow sizes and confirm the framed play-space stays fixed instead of revealing extra world.

## Fullscreen Flow

1. While paused, press `F` and confirm Chrome enters fullscreen while the game stays paused.
2. While paused and fullscreen, press `F` again and confirm Chrome exits fullscreen while the game stays paused.
3. While paused, click the pause overlay fullscreen button and confirm it toggles fullscreen the same way as `F`.
4. Enter fullscreen while paused, press `Esc`, and confirm Chrome exits fullscreen without unpausing the game.
5. Enter fullscreen, resume play, then exit fullscreen through `Esc` or browser UI and confirm the game enters paused mode immediately.
6. While unpaused and not fullscreen, press `F` and confirm nothing happens.
7. If fullscreen is unavailable in the active runtime, confirm the in-game fullscreen control is hidden.

## Fullscreen Reliability Log

Record 10 paused attempts for each path:

| Flow | Attempts | Successes | Pass Target | Notes |
|------|----------|-----------|-------------|-------|
| Pause button enters fullscreen | 10 | 10 | 9+ | Passed in desktop Chrome on the locally served build |
| Pause button exits fullscreen | 10 | 10 | 9+ | Passed in desktop Chrome on the locally served build |
| Paused `F` toggles fullscreen | 10 | 10 | 9+ | Passed in desktop Chrome on the locally served build |

## Session Notes

- 2026-04-05: Desktop Chrome manual check confirmed paused `F` now enters browser fullscreen successfully from the pause flow on the locally served export at `http://localhost:8000`.
- 2026-04-06: Desktop regression rerun completed after the browser/fullscreen changes. Headless boot passed, paused fullscreen behavior remained scoped to the pause flow, and no new browser-specific gameplay fork was identified in the shared input or camera path.
- 2026-04-06: Manual desktop play also re-exposed pedestrian sidewalk/crosswalk and traffic-yield issues. Those behaviors appear to predate this slice and are being treated as separate follow-up work rather than blockers for `003-web-browser-play`.
- 2026-04-06: Final fullscreen reliability pass recorded `10/10` success for pause-button entry, pause-button exit, and paused `F` toggling on the locally served desktop Chrome build.

## Desktop Regression Flow

1. Launch the desktop build from Godot after the web changes.
2. Re-run the existing on-foot, vehicle, pause, and resume loop from [us1_playable_core.md](./us1_playable_core.md).
3. Pause and use `F` to confirm fullscreen toggles only from the paused flow and does not break resume or input.
4. If pedestrian sidewalking, crosswalk discipline, or traffic yielding still misbehave, record them as separate baseline issues unless they can be tied directly to files changed for this browser slice.
