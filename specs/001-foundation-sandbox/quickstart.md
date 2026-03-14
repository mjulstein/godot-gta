[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / quickstart.md

# Quickstart: Foundation Sandbox

## Goal

Boot a Godot project that can demonstrate the first crime-sandbox slice described in the spec.

## Initial Setup

1. Create a new Godot 4.x project in this repository root.
2. Set the main scene to `scenes/main/game.tscn`.
3. Create the baseline folders described in the implementation plan.
4. Define input actions for movement, interact, enter-exit vehicle, brake, accelerate, steer left, steer right, pause, and debug overlay toggle.

## First Playable Checkpoint

1. Create `district_slice.tscn` with roads, sidewalks, and collision.
2. Add a player scene with top-down movement.
3. Add one drivable parked vehicle.
4. Add a camera that follows the current controlled actor.
5. Verify the player can walk, enter the vehicle, drive, exit, and keep moving in one session.

## Second Playable Checkpoint

1. Add civilians or simple traffic.
2. Emit crime events from vehicle theft and harmful civilian collisions.
3. Add wanted-level UI or debug display.
4. Spawn police on wanted escalation.
5. Verify the player can trigger pursuit and later clear it.

## Third Playable Checkpoint

1. Add one short mission.
2. Show mission objective state.
3. Handle success and failure cleanly.
4. Verify the mission works both with and without an active wanted state if supported by the design.

## Debug Expectations

- Toggle a development overlay showing player mode, wanted level, police state count, and mission state.
- Keep tuning data editable without rewriting scene logic.
