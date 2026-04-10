[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / quickstart.md

# Quickstart: Foundation Sandbox

## Goal

Boot the current baseline sandbox, verify the active `001` slice, and work against the remaining pedestrian, traffic, and feel tasks without reintroducing deferred scope.

## Prerequisites

1. Install Godot 4.6 or newer.
2. Open the repository root as the Godot project.
3. Keep work scoped to the existing main scene and domain folders under `scenes/`, `scripts/`, `data/`, and `tests/`.

## Fast Validation

1. From the repo root, run `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`.
2. Confirm the project boots without script or scene load errors.
3. Launch `scenes/main/game.tscn` in the editor or run the project normally.

## Manual Baseline Loop

1. Start on foot in the district.
2. Verify on-foot movement reads as direct pedestrian control rather than vehicle handling.
3. Observe pedestrians staying on sidewalks or crosswalks and waiting at crossings when traffic is not yielding.
4. Observe civilian traffic holding lane flow, slowing near crossings, and recovering locally when blocked.
5. Approach a valid civilian vehicle and take it over only when it is stopped or moving at walking pace.
6. Confirm a displaced occupant remains in the world when takeover succeeds.
7. Drive through the district, trigger a pedestrian impact, and verify momentum displaces the pedestrian without pushing the vehicle back.
8. Exit the vehicle and confirm the loop continues without scene reload or state corruption.

## Working Files

- `scenes/main/game.tscn`: playable root scene
- `scenes/world/district_slice.tscn`: compact district slice
- `scripts/actors/player/player_controller.gd`: on-foot control
- `scripts/vehicles/vehicle_controller.gd`: shared player or civilian vehicle motion
- `scripts/ai/pedestrian/civilian/`: pedestrian sidewalk and crossing behavior
- `scripts/ai/vehicular/civilian/`: civilian traffic lane, yield, and recovery behavior
- `scripts/world/district_activity_overlay.gd`: tile-local ambient ownership and activity data
- `tests/manual/us1_playable_core.md`
- `tests/manual/us2_takeover_impacts.md`

## Current Target

1. Stabilize pedestrian sidewalk and crosswalk behavior.
2. Stabilize traffic yielding and stopping distance at crossings.
3. Tune player and vehicle feel only after baseline pedestrian and traffic readability are back under control.
4. Finish remaining sign-off tasks in `tasks.md` and update `handoff.md` with the current checkpoint.
