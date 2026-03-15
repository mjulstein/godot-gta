[root](../../README.md) / [tests](../README.md) / [manual](./README.md) / us2_wanted_loop.md

# Deferred Wanted Loop Reference

Police and wanted behavior is out of active branch scope for `001-foundation-sandbox`. This file remains only as a deferred reference for later work.

## Goal

Validate the first consequence loop:

- witness-driven crime reporting
- wanted escalation
- police spawn and pursuit
- wanted decay after escape

## Steps

1. Launch the project and start `scenes/main/game.tscn`.
2. Confirm the debug overlay shows `Wanted: 0` and `Police: 0`.
3. Walk to the parked civilian vehicle while a nearby civilian is visible.
4. Press `E` to steal the vehicle and verify wanted increases and at least one police unit appears.
5. Drive into a civilian pedestrian or the moving traffic car and verify the wanted level increases again.
6. Drive away until police fall behind and no unit is visibly chasing the player.
7. Avoid new crimes and wait through the decay window.
8. Confirm wanted drops step-by-step back to `0` and police eventually disappear.

## Pass Criteria

- Vehicle theft only reports when civilians witness it.
- Crimes increase wanted without restarting the scene.
- Police units spawn consistently and chase the player.
- Wanted decays after the player escapes active pressure.
- Debug overlay reflects wanted level and police count correctly.
