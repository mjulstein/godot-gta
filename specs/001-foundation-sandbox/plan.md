# Implementation Plan: Foundation Sandbox

**Branch**: `001-foundation-sandbox` | **Date**: 2026-04-10 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `specs/001-foundation-sandbox/spec.md`

## Summary

Stabilize the foundation sandbox as one readable playable slice: direct on-foot control, shared vehicle motion, sidewalk and crosswalk-bound pedestrians, and civilian traffic that yields and recovers locally without route ownership from ambient tiles after spawn. The implementation stays Godot-native and data-driven by keeping feel-sensitive values in `.tres` tuning resources, preserving tile-local district activity overlays for spawn and cadence only, and validating the slice through headless boot plus repeatable manual playtest flows.

## Technical Context

**Language/Version**: GDScript on Godot 4.6-stable  
**Primary Dependencies**: Godot 4.6 built-in scene system, `CharacterBody2D`/physics processing patterns, input actions, `Resource`-based tuning data, `.tscn` scenes, `.tres` resources  
**Storage**: No persistent gameplay storage; repository assets are scene files, scripts, tuning resources, and markdown validation docs  
**Testing**: `HOME=/tmp/godot-home godot --headless --path . --quit-after 1` plus manual validation in `tests/manual/us1_playable_core.md` and `tests/manual/us2_takeover_impacts.md`  
**Target Platform**: Desktop-first Godot runtime with browser-export-compatible baseline behavior already merged into the slice  
**Project Type**: Single Godot game project  
**Performance Goals**: Smooth 60 FPS on a mid-range desktop while simulating the active district slice; clean headless boot with no scene or script load failures  
**Constraints**: Top-down readability first; no copied GTA assets or naming; pedestrians stay on valid walk space by default; traffic only despawns off-screen; tune behavior through resources where practical; keep scripts domain-scoped and short  
**Scale/Scope**: One compact district, one player controller, shared civilian vehicle controller, ambient pedestrian and traffic population, debug overlay, pause/mobile HUD support, and manual sign-off for baseline sandbox feel

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Pre-Research Gate

- **Feel-first top-down gameplay**: Pass. The slice is explicitly scoped to readable on-foot movement, crossing behavior, lane flow, takeover, and impact readability.
- **Original world, not asset-level imitation**: Pass. The spec and repo rules require original placeholder or final content only.
- **Small vertical slices over broad scope**: Pass. Work remains constrained to the baseline district and existing US1 or US2 sandbox loop rather than expanding into police, missions, or progression.
- **Data-driven systems where it matters**: Pass. Player, vehicle, and traffic feel values remain in `data/tuning/`, with district activity data limited to spawn or cadence concerns.
- **Playtestable, debuggable, maintainable**: Pass. Manual validation docs, headless boot, and debug overlay requirements are already part of the slice contract.

### Post-Design Gate

- **Feel-first top-down gameplay**: Pass. The design keeps local pedestrian and traffic state readable instead of hiding behavior inside opaque global routing.
- **Original world, not asset-level imitation**: Pass. No design artifact introduces protected source material.
- **Small vertical slices over broad scope**: Pass. Contracts and quickstart preserve the current baseline loop without adding new systems.
- **Data-driven systems where it matters**: Pass. The data model and research keep tuning in resources and treat runtime state as inspectable data.
- **Playtestable, debuggable, maintainable**: Pass. Runtime contracts require stable input actions, debug-visible state, and reproducible validation surfaces.

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
├── tasks.md
└── handoff.md
```

### Source Code (repository root)

```text
scenes/
├── main/
├── world/
│   ├── overlays/
│   └── props/
├── actors/
│   ├── player/
│   ├── civilians/
│   └── police/
├── vehicles/
│   ├── civilian/
│   └── police/
└── ui/

scripts/
├── core/
├── actors/
│   └── player/
├── vehicles/
├── systems/
├── world/
├── ui/
└── ai/
    ├── pedestrian/
    │   └── civilian/
    └── vehicular/
        └── civilian/

data/
└── tuning/

tests/
└── manual/
```

**Structure Decision**: Use the existing single-project Godot layout already present in the repository. Scene composition stays under `scenes/`, gameplay code stays split by domain under `scripts/`, frequently tuned gameplay values stay in `data/tuning/`, and validation remains manual-first under `tests/manual/`.

## Complexity Tracking

No constitution violations or justified complexity exceptions were identified in this planning pass.
