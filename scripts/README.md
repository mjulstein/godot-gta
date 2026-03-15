[root](../README.md) / scripts

# Scripts

Scripts are split by domain to keep files short and ownership clear.

## Structure

- [core](./core/README.md): bootstrap, camera, shared debug state
- [actors/player](./actors/player/README.md): player-specific control
- [vehicles](./vehicles/README.md): vehicle control
- [systems](./systems/README.md): cross-entity orchestration
- `ui/`: HUD and debug UI scripts
- `ai/pedestrian/`: pedestrian AI domain, split by occupation such as `civilian/` and later `law_enforcement/`
- `ai/vehicular/`: vehicular AI domain, split by occupation such as `civilian/` and later `law_enforcement/`
- `ai/`: legacy AI roots not yet moved under the traffic hierarchy

## Rule

Prefer one responsibility per script. If a script starts coordinating unrelated systems, split it.
