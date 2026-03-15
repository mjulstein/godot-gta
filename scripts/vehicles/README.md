[root](../../README.md) / [scripts](../README.md) / vehicles

# Vehicle Scripts

This directory owns vehicle-specific behavior.

Current file:

- `vehicle_controller.gd`: driving, friction, acceleration, occupancy

Vehicle interaction flow belongs in `scripts/systems/`, not here.

Vehicle physics rules should be shared across player and civilian vehicles. Differences in feel should come from tuning profiles and control intent, not separate movement rule-sets.
