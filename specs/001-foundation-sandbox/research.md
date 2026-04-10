[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / research.md

# Research Notes: Foundation Sandbox

## Goal

Resolve implementation choices for the current `001` baseline so pedestrian, traffic, takeover, and collision behavior can be tuned as one readable sandbox loop.

## Decisions

### 1. Lock the slice to Godot 4.6-stable and keep validation manual-first

- **Decision**: Use Godot 4.6-stable with the existing headless boot command and manual validation documents as the baseline acceptance flow.
- **Rationale**: The repo already targets Godot 4.6+, current completion criteria are built around boot validation plus repeated playable checks, and current Godot 4.6 docs still align with `CharacterBody2D` plus `_physics_process` movement loops and command-line headless validation for this kind of 2D project.
- **Alternatives considered**: Downgrade to an older Godot baseline, or block planning on broader automated coverage. Both would slow the active slice without solving the immediate readability issues.

### 2. Keep world overlays tile-local and data-oriented

- **Decision**: Keep district activity data in `scripts/world/district_activity_overlay.gd` tile-local, but limit it to initial ambient behavior such as spawn placement and semi-random spawn cadence.
- **Rationale**: This preserves modular world data without turning the overlay into the runtime owner of every actor route.
- **Alternatives considered**: Let tile activity drive live route ownership after spawn, centralize all movement decisions inside one global AI manager, or push behavior directly into scenes. All three would increase coupling and weaken local actor autonomy.

### 3. Use explicit pedestrian and traffic states instead of broad free steering

- **Decision**: Model pedestrians with states such as `sidewalk_walk`, `curb_wait`, `crosswalk_cross`, and `social_follow`, but drive moment-to-moment movement from local terrain intuition. A lead pedestrian should try to continue forward, assess upcoming terrain, and turn when forward space is a no-go because of danger or invalid walk surface.
- **Rationale**: This keeps the actors readable and autonomous without making their routes feel like they are being puppeteered by invisible tile ownership after spawn.
- **Alternatives considered**: Let tile activity keep assigning routes after spawn, keep primarily steering-based wandering with more avoidance forces, or add a larger pathfinding overhaul. Those options are either too coupled or too noisy for the current slice.

### 4. Keep feel-sensitive rules in tuning resources

- **Decision**: Continue storing player, shared vehicle, and civilian traffic feel values in `data/tuning/` resources, with district-specific spawn or lane bias data kept outside core scripts.
- **Rationale**: The constitution prefers data-driven tuning where gameplay feel changes often, the remaining open tasks are mostly tuning and readability work, and Godot's `Resource` workflow remains the cleanest built-in way to expose gameplay values without pushing balance decisions into scene scripts.
- **Alternatives considered**: Hardcode final values into controllers for speed, stopping distance, or crossing timing. This would slow iteration and hide balancing assumptions.

### 5. Define contracts around runtime surfaces, not network APIs

- **Decision**: Treat the foundation slice’s public contracts as the playable runtime surface: main scene entry point, named input actions, debug-visible state, and repeatable validation steps.
- **Rationale**: This slice is an internal game application with no external web or service API, but it still exposes interfaces that implementation work must preserve.
- **Alternatives considered**: Skip contracts entirely, or invent service-style contracts that do not exist in the repo. Both would make the plan less useful.

## Notes

- Context7 was used against the Godot 4.6 documentation set to confirm the current engine baseline, command-line workflow, `CharacterBody2D` movement loop, input-action handling, and `Resource`-based tuning approach at a high level.
- No unresolved technical clarifications remain for this planning pass.
