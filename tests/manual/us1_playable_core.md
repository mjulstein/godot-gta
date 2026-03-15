[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / us1_playable_core.md

# US1 Playable Core Validation

## Goal

Validate the first playable sandbox loop:

- move on foot
- read pedestrian and traffic flow in the district
- approach a parked or civilian vehicle
- enter the vehicle
- drive through the district
- collide with walls or buildings
- exit the vehicle
- continue on foot

## Steps

1. Launch the project and start `scenes/main/game.tscn`.
2. Confirm the player starts on foot near the vehicle.
3. Move with `WASD` and verify movement is immediate and readable.
4. Observe at least two pedestrian groups and verify pedestrians stay near curbs, use valid crossings, and do not pace through the middle of intersections.
5. Check that pairs can walk side by side, groups of three use a two-front one-back shape, and larger same-direction groups queue.
6. Approach the yellow car and at least one civilian traffic car until the debug overlay hint changes to enter the vehicle.
7. Press `E` to enter the vehicle.
8. Drive using `WASD` and verify the camera follows the active actor.
9. Hit a wall or building and verify the collision state changes in the debug overlay and the vehicle flashes red briefly.
10. Press `E` to exit the vehicle.
11. Confirm the player is placed next to the car and can continue moving on foot.

## Pass Criteria

- No scene reload is needed during the loop.
- Pedestrian ambient motion stays on sidewalks and marked crossings, without obvious grass wandering.
- Pedestrian grouping reads coherently enough to assess pairs, trios, and queues in motion.
- Camera ownership switches cleanly between player and vehicle.
- Parked-vehicle entry and traffic-vehicle takeover both work repeatedly.
- Collision feedback is visible and the vehicle remains controllable.
- Debug overlay reflects mode, vehicle source, hint, takeover state, speed, and collision state correctly.
