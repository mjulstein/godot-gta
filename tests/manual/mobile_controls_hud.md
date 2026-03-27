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
3. While holding the joystick, tap the top-right `ACT` button near a vehicle and confirm the enter flow still works.
4. While driving, use the left-hand joystick to steer and confirm it no longer applies throttle or brake by itself.
5. While driving, hold `GAS` and steer, then hold `BRK` and steer, and confirm the vehicle responds through the normal drive actions.
6. While driving, tap `ACT` and confirm the player exits the vehicle through the normal interaction flow.
7. Tap the top-right `P` button, then confirm the pause overlay appears with `Debug` and `HUD Opacity` buttons.
8. Use the pause overlay `Debug` button and confirm the debug overlay toggles.
9. Use the pause overlay `HUD Opacity` button, resume gameplay, and confirm the mobile HUD opacity changed during non-paused play.
10. Press `M` and confirm the HUD toggles between the current visible opacity and `0%`, then press `M` again to restore the previous opacity.
11. Repeat joystick plus `ACT`, joystick plus `P`, and steering plus `GAS` overlap checks to confirm multitouch does not cancel held input unexpectedly.

## Expected Result

- The mobile HUD is always shown at launch unless the player has manually toggled its opacity to `0%`.
- The lower-left joystick drives on-foot movement and steering through the existing action map.
- In vehicles, `GAS` and `BRK` provide throttle and brake on the right-hand side.
- `ACT` uses the same interaction behavior as keyboard `E`.
- The top-right `P` button uses the same pause flow as keyboard `P`.
- The pause overlay can toggle debug visibility and cycle gameplay HUD opacity.
- Overlapping touch input keeps held movement active while `ACT` or `PAUSE` is tapped.
