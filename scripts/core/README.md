[root](../../README.md) / [scripts](../README.md) / core

# Core Scripts

Core scripts own project-wide bootstrap and shared utilities.

Current files:

- `game_root.gd`: root scene orchestration
- `follow_camera.gd`: camera target following
- `debug_state.gd`: shared state for development UI

Keep this directory small. Gameplay systems should live under `systems/`, `actors/`, or `vehicles/`.
