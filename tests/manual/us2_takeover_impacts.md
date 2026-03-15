[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / us2_takeover_impacts.md

# US2 Takeover And Impacts Validation

## Goal

Validate the rescoped sandbox interaction loop:

- take over a moving civilian vehicle
- leave a displaced occupant behind
- hit a pedestrian with vehicle momentum
- confirm pedestrians do not shove the vehicle backward on impact

## Steps

1. Launch the project and start `scenes/main/game.tscn`.
2. Wait near a lane until a civilian traffic vehicle comes within interaction range.
3. Press `E` to take over the civilian vehicle.
4. Confirm the debug overlay changes `Vehicle` and `Takeover` state and a pedestrian remains behind the stolen car.
5. Drive into a pedestrian at low speed, then again at higher speed.
6. Confirm the pedestrian is displaced in the vehicle travel direction instead of stopping the vehicle in place.
7. Exit the stolen vehicle and confirm on-foot control resumes cleanly.

## Pass Criteria

- Civilian traffic vehicles can be taken over without reloading the scene.
- A displaced pedestrian occupant spawns when a civilian vehicle is taken over.
- Pedestrian displacement scales with vehicle momentum closely enough to read as a hit reaction.
- Pedestrians do not push the vehicle backward during impact recovery.
- Debug overlay reflects takeover state and impact state during the sequence.
