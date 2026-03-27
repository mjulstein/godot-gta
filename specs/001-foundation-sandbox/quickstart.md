[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / quickstart.md

# Quickstart: Foundation Sandbox

## Goal

Boot a Godot project that can demonstrate the first crime-sandbox slice described in the spec.

## Initial Setup

1. Create a new Godot 4.x project in this repository root.
2. Set the main scene to `scenes/main/game.tscn`.
3. Create the baseline folders described in the implementation plan.
4. Define input actions for movement, interact, enter-exit vehicle, brake, accelerate, steer left, steer right, pause, and debug overlay toggle.
5. Set viewport stretch so fullscreen scales the same gameplay framing instead of revealing more world area.

## First Playable Checkpoint

1. Create `district_slice.tscn` with roads, sidewalks, collision, and parameterized road exits.
2. Create `base_level.tscn` to assemble district tiles from layered ASCII maps for roads, building density, and activity density.
3. Add a player scene with top-down movement.
4. Add one drivable parked vehicle.
5. Add a camera that follows the current controlled actor and preserves the same framing across window sizes.
6. Verify the player can walk, enter the vehicle, drive, exit, and keep moving in one session.

## Second Playable Checkpoint

1. Add civilians or simple traffic.
2. Emit crime events from vehicle theft and harmful civilian collisions.
3. Add wanted-level UI or debug display.
4. Spawn police on wanted escalation.
5. Add pause-time palette/debug support for actor role readability.
6. Verify the player can trigger pursuit and later clear it.

## Debug Expectations

- Toggle a development overlay showing player mode, wanted level, and police state count.
- Allow the same overlay to inspect any tracked vehicle's speed, throttle, brake, steering, and motion state when debugging traffic behavior.
- Support a pause overlay that shows the current role palette.
- Keep tuning data editable without rewriting scene logic.

## Current Branch Extensions

The current repository branch layers additional controls and deployment helpers on top of the foundation sandbox slice:

- always-on mobile touch HUD for joystick, action, pause, and driving inputs
- pause-overlay controls for debug toggle, HUD opacity, gameplay input scale, impact vibration, and restart
- debug traffic camera cycling and temporary driver possession for inspecting civilian traffic
- local iOS Xcode project generation and build or deploy helpers under `ios/`
