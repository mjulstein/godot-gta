[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / mobile_controls_hud.md

# Mobile Controls HUD Validation

Validate the first-pass mobile HUD on iPhone, iPad simulator in landscape, or a desktop run with the HUD override temporarily enabled in the scene for development.

## Setup

1. Run `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`.
2. Launch the main scene.
3. On mobile hardware or simulator, confirm the on-screen HUD appears. On desktop, confirm it stays hidden unless a temporary local override is enabled for testing.

## Flow

1. Hold `U`, `D`, `L`, or `R` on the bottom-left cluster and confirm the player moves on foot with the same direction behavior as keyboard input.
2. Hold two direction buttons together and confirm diagonal on-foot movement still works.
3. While holding a direction, tap `ACT` near a vehicle and confirm the enter flow still works.
4. While driving, use the same directional cluster and confirm it now accelerates, brakes, and steers the vehicle.
5. While driving, tap `ACT` and confirm the player exits the vehicle through the normal interaction flow.
6. Hold a direction and tap `PAUSE`, then confirm the game pauses and can be resumed by tapping `PAUSE` again.
7. Repeat movement plus `ACT` and movement plus `PAUSE` overlap checks to confirm multitouch does not cancel the held direction unexpectedly.

## Expected Result

- The mobile HUD is shown only for mobile play unless deliberately overridden for development.
- Direction buttons drive on-foot movement and vehicle driving through the existing action map.
- `ACT` uses the same interaction behavior as keyboard `E`.
- `PAUSE` uses the same pause flow as keyboard `P`.
- Overlapping touch input keeps held movement active while `ACT` or `PAUSE` is tapped.
