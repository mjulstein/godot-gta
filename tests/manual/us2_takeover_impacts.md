[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / us2_takeover_impacts.md

# US2 Takeover And Impacts Validation

## Goal

Validate the rescoped sandbox interaction loop:

- take over a moving civilian vehicle
- leave a displaced occupant behind
- hit a pedestrian with vehicle momentum
- confirm stopped or incident pedestrians still read as part of ambient foot traffic
- confirm pedestrians do not shove the vehicle backward on impact

## Steps

1. Launch the project and start `scenes/main/game.tscn`.
2. Wait near a lane until a civilian traffic vehicle comes within interaction range.
3. Press `E` to take over the civilian vehicle.
4. Confirm the debug overlay changes `Vehicle` and `Takeover` state and a pedestrian remains behind the stolen car.
5. Watch the displaced occupant for a few seconds and confirm they at least orient toward nearby pedestrians instead of freezing permanently.
6. Drive into a pedestrian at low speed, then again at higher speed.
7. Confirm the pedestrian is displaced in the vehicle travel direction instead of stopping the vehicle in place.
8. Exit the stolen vehicle and confirm on-foot control resumes cleanly.
9. Move up to a vehicle whose driver side is blocked or whose usability is no longer `usable` and confirm the interaction hint surfaces a blocked-entry reason instead of starting takeover.
10. Stop a vehicle in a tight space, press `E`, and confirm blocked exits keep the player in the vehicle until there is clear space.
11. With the debug overlay open, inspect a civilian traffic car and confirm it reports motion metrics, traffic state, and usability alongside takeover feedback.

## Current Status

- Headless boot passed on 2026-04-10 with `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`.
- Manual takeover and blocked-exit validation is still pending in-editor or in a desktop run.

## Pass Criteria

- Civilian traffic vehicles can be taken over without reloading the scene.
- A displaced pedestrian occupant spawns when a civilian vehicle is taken over.
- Displaced occupants and incident pedestrians remain readable as pedestrians rather than freezing as static props.
- Pedestrian displacement scales with vehicle momentum closely enough to read as a hit reaction.
- Pedestrians do not push the vehicle backward during impact recovery.
- Debug overlay reflects takeover state and impact state during the sequence.
- Blocked entry and blocked exit cases fail cleanly with readable interaction feedback.
