[root](../README.md) / scenes

# Scenes

Scene files are composition only. Keep orchestration light and move behavior into `scripts/`.

## Structure

- [main](./main/README.md): root playable scene
- [world](./world/README.md): district layout and static world pieces
- [actors/player](./actors/player/README.md): player scene
- [vehicles/civilian](./vehicles/civilian/README.md): baseline drivable vehicle
- `ui/`: HUD and debug scenes
- `missions/`: mission-specific scenes

## Rule

If a scene needs more than simple wiring, put the logic in a script under the matching domain in `scripts/`.
