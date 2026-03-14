[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / research.md

# Research Notes: Foundation Sandbox

## Goal

Identify the simplest technical and design choices that still deliver a convincing top-down crime sandbox slice in Godot.

## Decisions

### 1. Use a deliberately small district

- Keep the first district to a few intersections and blocks.
- Prioritize readable roads, escape routes, and mission landmarks over map size.
- This supports the constitution's vertical-slice rule and keeps police logic tractable.

### 2. Separate actor control from actor presentation

- Use shared actor state concepts for both pedestrian and vehicle control.
- Keep input ownership and movement logic separate so control can transfer cleanly between the player avatar and a vehicle.
- This reduces rework when police, civilians, and mission actors later share similar state transitions.

### 3. Start police behavior with search and chase, not full simulation

- Initial police behavior should cover spawn, target acquisition, pursuit, and timed de-escalation.
- Avoid advanced traffic-law behavior, roadblocks, radio chatter systems, or squad coordination in the first slice.
- This is enough to satisfy the spec without turning the prototype into an AI-heavy project too early.

### 4. Store tuning in resources where gameplay feel will change often

- Vehicle handling
- Player movement values
- Wanted thresholds and cooldowns
- Spawn weights and caps
- Mission timing and reward data

This keeps tuning fast and protects the code from repeated balance churn.

### 5. Add debug tooling from the first implementation pass

- Show current player mode: on foot or in vehicle
- Show wanted level and active pursuit timers
- Show current mission state
- Optionally show simple spawn markers for police and civilians in development builds

This makes systemic bugs much easier to diagnose than relying on visual inspection alone.

## Open Questions

- Whether the project should use pixel art, low-poly 3D rendered from a high camera, or stylized 2D sprites is still undecided.
- Whether combat is part of the first slice or deferred behind vehicle and wanted systems remains open.
- Whether mission structure should be fully diegetic or use overt arcade-style UI prompts is still open.
