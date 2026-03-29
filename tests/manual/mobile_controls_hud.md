[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / mobile_controls_hud.md

# Mobile Controls HUD Validation

Validate the current mobile HUD on iPhone, iPad simulator in landscape, or desktop.

## Setup

1. Run `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`.
2. Launch the main scene.
3. Confirm the on-screen HUD appears immediately at launch.

## Flow

1. Drag the lower-left joystick and confirm the player moves on foot with the same direction behavior as keyboard input.
2. Drag the joystick diagonally and confirm diagonal on-foot movement still works.
3. While holding the joystick, tap the top-right `ACT` button below `P` near a vehicle and confirm the enter flow still works.
4. While driving, use the left-hand joystick to steer and confirm it no longer applies throttle or brake by itself.
5. While driving, drag upward on the right-hand vertical `GAS` / `BRK` drive surface and steer, then drag downward on the same surface and steer, and confirm the vehicle responds through the normal drive actions.
6. While driving, tap `ACT` and confirm the player exits the vehicle through the normal interaction flow.
7. Tap the top-right `P` button, then confirm the pause overlay appears with `Debug`, `HUD Opacity`, `Input Scale`, `Impact Vibration`, and `Restart` controls.
8. Use the pause overlay `Debug` button and confirm the debug overlay toggles.
9. Use the pause overlay `HUD Opacity` button, resume gameplay, and confirm the mobile HUD opacity changed during non-paused play.
10. Use the pause overlay `Input Scale` button repeatedly and confirm the gameplay touch surfaces cycle from `1.00x` to `2.00x` in `0.25x` steps.
11. Resume gameplay and confirm the joystick stays anchored from its own center as it scales, `ACT` stays below `P` at the top-right corner, and the right-hand drive surface stays pinned to the lower-right corner.
12. Toggle `Impact Vibration` on, resume gameplay, and confirm low-speed bumps do not vibrate while harder crashes can vibrate the phone briefly; then turn it back off and confirm crashes no longer vibrate.
13. Re-open pause and confirm the lower-right `Restart` button is available but visually separated from the main pause actions.
14. Press `M` and confirm the HUD toggles between the current visible opacity and `0%`, then press `M` again to restore the previous opacity.
15. Repeat joystick plus `ACT`, joystick plus `P`, and steering plus right-hand drive-surface overlap checks to confirm multitouch does not cancel held input unexpectedly.

## Expected Result

- The mobile HUD is always shown at launch unless the player has manually toggled its opacity to `0%`.
- The lower-left joystick drives on-foot movement and steering through the existing action map and sits slightly inward from the screen edge.
- In vehicles, the right-hand vertical `GAS` / `BRK` drive surface provides throttle and brake by dragging up or down.
- `ACT` uses the same interaction behavior as keyboard `E` and sits below the top-right `P` button.
- The top-right `P` button uses the same pause flow as keyboard `P`.
- The pause overlay can toggle debug visibility, cycle gameplay HUD opacity, cycle gameplay input scale, toggle impact vibration, and restart the scene.
- Gameplay input scale changes affect only gameplay touch surfaces and keep each control cluster anchored from a stable center or corner instead of drifting.
- Overlapping touch input keeps held movement active while `ACT` or `PAUSE` is tapped.
