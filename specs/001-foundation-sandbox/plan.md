[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / plan.md

# Implementation Plan: Foundation Sandbox

**Branch**: `001-foundation-sandbox` | **Date**: 2026-04-10 | **Spec**: [spec.md](./spec.md)  
**Input**: Feature specification from `specs/001-foundation-sandbox/spec.md`

## Summary

Stabilize the current Godot 4.6 foundation sandbox into a readable, replayable baseline by tightening on-foot feel, explicit pedestrian sidewalk and crosswalk behavior, traffic yielding and recovery, and the existing takeover and collision loop. The implementation stays scene-light and script-heavy, keeps ambient district ownership tile-local in world overlays for spawn behavior only, relies on local actor heuristics after spawn, and pushes feel-sensitive values into tuning resources and manual validation docs.

## Technical Context

**Language/Version**: GDScript on Godot 4.6-stable  
**Primary Dependencies**: Godot 4.6 runtime/editor, built-in scene system, `.tres` resource tuning, existing debug and mobile HUD scenes  
**Storage**: Scene files, GDScript, `.tres` tuning resources, markdown manual validation docs; no persistent gameplay storage  
**Testing**: Headless boot check with `HOME=/tmp/godot-home godot --headless --path . --quit-after 1` plus reproducible manual playtests in `tests/manual/`  
**Target Platform**: Desktop baseline with browser-export-compatible pause/fullscreen behavior already merged into the slice  
**Project Type**: Single Godot game project  
**Performance Goals**: Maintain readable real-time play in one compact district on a mid-range desktop while simulating ambient pedestrians and civilian traffic  
**Constraints**: Preserve top-down readability, keep scene logic thin, keep overlay ownership tile-local for spawn behavior only, use original placeholder content only, avoid fallback teleports for blocked vehicle entry/exit or displaced occupants, and only despawn recovery traffic off-screen  
**Scale/Scope**: One compact district slice, one player actor, one civilian vehicle class, ambient civilian pedestrian and traffic population, takeover loop, collision response, debug overlay, and mobile HUD baseline

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Feel-First Top-Down Gameplay**: Pass. The plan targets movement readability, crossing behavior, and traffic response before any new feature expansion.
- **Original World, Not Asset-Level Imitation**: Pass. The slice uses original placeholder content and does not introduce copied GTA assets, names, or UI.
- **Small Vertical Slices Over Broad Scope**: Pass. Scope remains one compact district and the existing US1 or US2 sandbox loop rather than expanding into police, missions, or wider progression.
- **Data-Driven Systems Where It Matters**: Pass. Movement, traffic, and pedestrian feel remain tunable through `data/tuning/` and district overlay data instead of hardcoded scene behavior.
- **Playtestable, Debuggable, Maintainable**: Pass. The slice keeps the debug overlay, manual validation docs, and domain-scoped scripts as explicit quality gates.

Post-design re-check: Pass. Research, data model, quickstart, and the runtime contract all preserve the same constraints and introduce no constitution violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-foundation-sandbox/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── runtime_contract.md
└── tasks.md
```

### Source Code (repository root)

```text
data/
├── districts/
├── missions/
└── tuning/
    ├── civilian_vehicle_tuning.tres
    ├── player_tuning.tres
    ├── vehicle_tuning.tres
    └── wanted_tuning.tres

scenes/
├── actors/
│   ├── civilians/
│   ├── player/
│   └── police/
├── main/
├── ui/
├── vehicles/
│   ├── civilian/
│   └── police/
└── world/
    ├── overlays/
    └── props/

scripts/
├── actors/player/
├── ai/
│   ├── pedestrian/
│   └── vehicular/
├── core/
├── systems/
├── ui/
├── vehicles/
└── world/

tests/
├── logic/
└── manual/
```

**Structure Decision**: Keep the single Godot project structure already established in the repo. Scene files remain composition-oriented under `scenes/`, behavior stays domain-scoped under `scripts/`, tunable gameplay values live in `data/tuning/`, and validation remains manual-first under `tests/manual/` with optional pure-logic coverage in `tests/logic/`.

## Phase 0: Research Summary

- Confirm Godot 4.6-stable as the engine baseline and preserve the existing headless boot command as the minimum validation gate.
- Resolve pedestrian and traffic behavior through explicit state machines and local terrain heuristics, with tile activity data limited to spawn placement and cadence rather than runtime route ownership.
- Treat the project’s exposed interfaces as runtime contracts around the main scene, input actions, debug visibility, and reproducible validation flow rather than external network APIs.

## Phase 1: Design Summary

- Model sandbox actors around player control, vehicle usability, pedestrian crossing state, local terrain sensing, traffic recovery state, district spawn activity cells, and debug snapshots.
- Keep contracts limited to the runtime surface the slice already exposes: entry scene, required input actions, debug observability, and validation expectations.
- Keep quickstart focused on local validation and the current `001` checkpoint rather than reintroducing deferred police or mission scope.

## Complexity Tracking

No constitution violations or justified complexity exceptions were required for this plan.
