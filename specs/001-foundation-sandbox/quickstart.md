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
2. Create `base_level.tscn` to assemble district tiles from one-character ASCII bindings.
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

## Third Playable Checkpoint

1. Add one short mission.
2. Show mission objective state.
3. Handle success and failure cleanly.
4. Verify the mission works both with and without an active wanted state if supported by the design.

## Debug Expectations

- Toggle a development overlay showing player mode, wanted level, police state count, and mission state.
- Support a pause overlay that shows the current role palette.
- Keep tuning data editable without rewriting scene logic.
