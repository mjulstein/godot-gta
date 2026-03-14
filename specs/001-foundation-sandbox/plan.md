[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / plan.md

# Implementation Plan: Foundation Sandbox

**Branch**: `001-foundation-sandbox` | **Date**: 2026-03-14 | **Spec**: [specs/001-foundation-sandbox/spec.md](specs/001-foundation-sandbox/spec.md)
**Input**: Feature specification from `/specs/001-foundation-sandbox/spec.md`

## Summary

Build the first playable vertical slice of an original top-down crime sandbox in Godot 4.x. The slice will focus on one compact district with responsive on-foot movement, vehicle entry and driving, basic civilian street life, a wanted-level loop with police pursuit, and one short prototype mission. The implementation approach is to keep the world small, split gameplay into clearly bounded systems, and prefer data-driven tuning and debug tooling over broad content scope.

## Technical Context

**Language/Version**: GDScript on Godot 4.x  
**Primary Dependencies**: Godot 4.x built-in nodes and resources, TileMap or GridMap for district layout, NavigationAgent2D or equivalent pathing support, InputMap for keyboard and controller bindings  
**Storage**: Local Godot resources and scene files; JSON or `.tres` data for tuning tables if needed  
**Testing**: Manual playtest scenes plus lightweight Godot test coverage where practical for data and pure logic components  
**Target Platform**: Desktop first, macOS and Windows as primary dev and playtest targets  
**Project Type**: Single Godot game project  
**Performance Goals**: Smooth gameplay at 60 FPS in the prototype district with active traffic, pedestrians, and limited police pursuit  
**Constraints**: Top-down readability must remain high, all content must be original, first slice must stay small enough to implement without procedural generation or streaming  
**Scale/Scope**: One playable district, one player avatar, one drivable civilian vehicle type minimum, one police vehicle or police actor response loop minimum, one end-to-end mission

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `Feel-First Top-Down Gameplay`: Pass. The slice centers on movement, driving, collisions, and pursuit readability from an overhead camera.
- `Original World, Not Asset-Level Imitation`: Pass. The plan assumes original placeholder names, factions, UI text, and art direction only.
- `Small Vertical Slices Over Broad Scope`: Pass. Scope is intentionally limited to one district and one mission loop.
- `Data-Driven Systems Where It Matters`: Pass. Vehicle tuning, wanted escalation, spawn weights, and mission parameters will be resource-driven where practical.
- `Playtestable, Debuggable, Maintainable`: Pass with explicit debug work included for actor state, wanted state, and mission state.

No constitution violations are currently expected.

## Phase 0 Research

- Confirm the best 2D scene composition for the prototype district: static world tiles, dynamic actors, collision layers, and camera framing.
- Decide how vehicle handling and on-foot movement should share or separate control abstractions.
- Decide the simplest police pursuit model that feels responsive without requiring a full traffic simulation.
- Decide which gameplay values should be stored in `.tres` resources versus script constants in the initial implementation.
- Define a low-overhead debug overlay for actor state, wanted state, mission state, and spawn diagnostics.

Research output: [specs/001-foundation-sandbox/research.md](specs/001-foundation-sandbox/research.md)

## Phase 1 Design

### System Breakdown

1. District Slice
Create one compact city district with roads, sidewalks, collision, mission anchors, spawn points, and camera-safe sightlines.

2. Player Controller
Implement top-down on-foot movement, interaction prompts, actor state transitions, and health or defeat hooks needed by future systems.

3. Vehicle System
Implement drivable vehicles with enter and exit flow, handling data, damage state, and camera continuity.

4. Ambient Population
Add a minimal civilian layer made of pedestrians, parked cars, and moving traffic sufficient to support crime detection and street readability.

5. Crime and Wanted System
Track criminal actions, witnesses, escalation, de-escalation, and police dispatch state.

6. Police Response
Spawn police units, navigate them toward the player, and support search or pursuit behavior that works in the prototype district.

7. Mission Prototype
Implement one short objective loop with briefing, activation, completion, failure, and reward resolution.

8. Debug and Tuning Tools
Expose current actor state, wanted level, mission state, and spawn information in a development-only overlay or inspector-friendly format.

### Deliverables

- Plan document
- Research notes
- Data model for gameplay entities and state flow
- Quickstart for building the prototype slice
- Placeholder contracts directory reserved for future data interfaces if needed

## Project Structure

### Documentation (this feature)

```text
specs/001-foundation-sandbox/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md
```

### Source Code (repository root)

```text
project.godot
icon.svg
scenes/
├── main/
│   └── game.tscn
├── world/
│   ├── district_slice.tscn
│   └── props/
├── actors/
│   ├── player/
│   ├── civilians/
│   └── police/
├── vehicles/
│   ├── civilian/
│   └── police/
├── missions/
└── ui/

scripts/
├── core/
├── actors/
├── vehicles/
├── ai/
├── systems/
└── ui/

data/
├── tuning/
├── missions/
└── districts/

assets/
├── placeholder_art/
├── audio/
└── fonts/

tests/
├── manual/
└── logic/
```

**Structure Decision**: Use a single Godot game project with scene files, scripts, and data separated by responsibility. Keep world composition in `scenes/`, reusable logic in `scripts/`, and tunable resources in `data/` so that player feel and system balance can change without restructuring the project.

## Implementation Strategy

### Milestone 1: Playable Core

- Create the Godot project shell and root game scene.
- Build the district slice with collisions and a follow camera.
- Implement the player controller and one enterable vehicle.
- Verify the player can move, enter the vehicle, drive, exit, and continue play in one uninterrupted loop.

### Milestone 2: Living Streets and Consequence

- Add simple civilians and basic traffic behavior.
- Implement crime event emission from vehicle theft, pedestrian attack, and harmful collisions.
- Add wanted-level escalation and police spawning.
- Verify the player can trigger and clear a wanted state through repeatable manual tests.

### Milestone 3: Mission Loop and Tooling

- Add one prototype mission with clear activation and failure conditions.
- Ensure mission-critical objects persist or fail gracefully.
- Add debug overlay and tuning resources.
- Run end-to-end slice tests for free-roam, pursuit, and mission completion.

## Risk Management

- `Vehicle feel risk`: A weak handling model can make the entire prototype feel wrong. Mitigation: tune one vehicle deeply before adding variety.
- `AI complexity risk`: Civilian and police behaviors can grow too complex too early. Mitigation: use state machines with short behavior lists and district-specific assumptions.
- `Scope risk`: Open-world features can expand quickly. Mitigation: reject additional districts, factions, or weapon breadth until the first mission loop is fun.
- `Readability risk`: Top-down action can become visually muddy. Mitigation: test camera distance, actor silhouettes, and collision feedback before adding visual detail.

## Complexity Tracking

No constitution exceptions currently require justification.
