[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / us1_playable_core.md

# US1 Playable Core Validation

## Goal

Validate the first playable sandbox loop:

- move on foot
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
4. Approach the yellow car and at least one civilian traffic car until the debug overlay hint changes to enter the vehicle.
5. Press `E` to enter the vehicle.
6. Drive using `WASD` and verify the camera follows the active actor.
7. Hit a wall or building and verify the collision state changes in the debug overlay and the vehicle flashes red briefly.
8. Press `E` to exit the vehicle.
9. Confirm the player is placed next to the car and can continue moving on foot.

## Pass Criteria

- No scene reload is needed during the loop.
- Camera ownership switches cleanly between player and vehicle.
- Parked-vehicle entry and traffic-vehicle takeover both work repeatedly.
- Collision feedback is visible and the vehicle remains controllable.
- Debug overlay reflects mode, vehicle source, hint, takeover state, speed, and collision state correctly.
