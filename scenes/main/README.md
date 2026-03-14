[root](../../README.md) / [scenes](../README.md) / main

# Main Scene

`game.tscn` is the root playable bootstrap.

It wires together:

- district
- player
- vehicle
- camera
- debug state
- interaction system
- UI

Do not put feature-heavy logic directly in the scene. Keep orchestration in `scripts/core/game_root.gd`.
