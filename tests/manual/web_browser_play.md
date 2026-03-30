[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / web_browser_play.md

# Web Browser Play Validation

Validate first-pass browser parity in desktop Chrome.

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
4. Exit the vehicle with `E` and confirm the player returns to the normal on-foot loop.
5. Pause with `P` and confirm the pause overlay still shows the existing controls plus a `Fullscreen: Off (F)` action.
6. Resize the browser window to several wide and narrow sizes and confirm the framed play-space stays fixed instead of revealing extra world.

## Fullscreen Flow

1. While paused, press `F` and confirm Chrome enters fullscreen while the game stays paused.
2. While paused and fullscreen, press `F` again and confirm Chrome exits fullscreen while the game stays paused.
3. While paused, click the pause overlay fullscreen button and confirm it toggles fullscreen the same way as `F`.
4. Enter fullscreen while paused, press `Esc`, and confirm Chrome exits fullscreen without unpausing the game.
5. While unpaused, press `F` and confirm nothing happens.

## Desktop Regression Flow

1. Launch the desktop build from Godot after the web changes.
2. Re-run the existing on-foot, vehicle, pause, and resume loop from [us1_playable_core.md](./us1_playable_core.md).
3. Pause and use `F` to confirm fullscreen toggles only from the paused flow and does not break resume or input.

## Publish Flow

1. Start from a clean working tree on the branch you want to publish from.
2. Run `./publish_web_docs.sh`.
3. Confirm the script exports the `Web` preset, pushes the `docs` branch, and leaves the current working branch clean.
4. Confirm the published branch contains the exported site under `docs/`.
5. Confirm the repository still has the same checked-out branch after the script finishes.
