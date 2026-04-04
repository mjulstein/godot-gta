[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / plan.md

# Implementation Plan: Web Browser Play

**Branch**: `003-web-browser-play` | **Date**: 2026-04-05 | **Spec**: [specs/003-web-browser-play/spec.md](specs/003-web-browser-play/spec.md)
**Input**: Feature specification from `/specs/003-web-browser-play/spec.md`

## Summary

Add desktop Chrome browser play for the current sandbox while keeping the same gameplay code path used by desktop. Prefer Godot-native fullscreen handling first, and only use browser-page UI or a narrow browser bridge when native behavior cannot satisfy the paused-only toggle, fullscreen-state sync, or runtime-visibility requirements. Keep runtime-specific work limited to the fullscreen boundary and related presentation glue, and keep publish workflows out of scope.

## Technical Context

**Language/Version**: GDScript on Godot 4.6+ plus optional narrow browser-side JavaScript when a web fullscreen bridge is needed  
**Primary Dependencies**: Godot 4.x web export, optional `JavaScriptBridge`, existing pause flow, existing camera framing logic, existing input actions  
**Storage**: Scene files, scripts, export preset configuration, manual validation docs, and optional web-shell assets only; no new persistent gameplay storage  
**Testing**: Godot headless boot validation, manual desktop regression checks, manual desktop Chrome browser validation with recorded fullscreen attempts  
**Target Platform**: Desktop Chrome for the browser build plus the existing desktop Godot runtime for shared gameplay-path parity  
**Project Type**: Single Godot game project  
**Performance Goals**: Preserve normal playable browser behavior for the current sandbox slice while keeping framing fixed and pause/fullscreen behavior coherent  
**Constraints**: Gameplay code paths must remain shared across desktop and browser; fullscreen must only toggle while paused; `F` remains a simple paused-only toggle attempt; fullscreen denial keeps the game paused without extra failure messaging; runtime-specific glue must stay narrow and limited to presentation boundaries; publish helpers remain out of scope  
**Scale/Scope**: One browser-export slice, one browser-friendly fullscreen path, one documented manual Chrome flow with 10-attempt fullscreen checks, no release pipeline work in this feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `Feel-First Top-Down Gameplay`: Pass. The feature preserves current movement, vehicle, pause, and camera behavior instead of inventing a browser-specific gameplay mode.
- `Original World, Not Asset-Level Imitation`: Pass. The slice changes runtime support only and introduces no borrowed content.
- `Small Vertical Slices Over Broad Scope`: Pass. Scope is limited to browser runtime parity and paused fullscreen behavior for the existing playable slice.
- `Data-Driven Systems Where It Matters`: Pass. No new gameplay data system is added; any bridge logic is narrow platform glue rather than a hardcoded gameplay expansion.
- `Playtestable, Debuggable, Maintainable`: Pass. Manual Chrome validation, desktop regression checks, and pause-overlay state keep the work observable and reproducible.

No constitution violations are expected.

## Project Structure

### Documentation (this feature)

```text
specs/003-web-browser-play/
├── README.md
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── browser_fullscreen_bridge.md
└── tasks.md
```

### Source Code (repository root)

```text
scenes/
├── main/
│   └── game.tscn
└── ui/
    ├── debug_overlay.tscn
    ├── mobile_controls_hud.tscn
    └── palette_overlay.tscn

scripts/
├── core/
│   ├── follow_camera.gd
│   ├── fullscreen_support.gd
│   └── game_root.gd
├── ui/
│   ├── palette_overlay.gd
│   └── pause_controller.gd
├── actors/
│   └── player/
└── vehicles/
    └── vehicle_controller.gd

tests/
└── manual/
    ├── us1_playable_core.md
    └── web_browser_play.md

build/
└── web/

export_presets.cfg
project.godot
README.md
```

**Structure Decision**: Keep the feature inside the existing single Godot project. Shared gameplay stays in the current scripts and scenes, while any browser-specific fullscreen bridge or web shell customization remains isolated to the export-facing boundary so desktop continues to use the same gameplay path.

## Phase 0: Research Outcomes

- Confirm the simplest reliable fullscreen approach for desktop Chrome without assuming a custom shell by default.
- Prefer Godot-native fullscreen first; use browser-page UI or a narrow browser bridge only if native behavior cannot satisfy paused-only toggle, fullscreen-state sync, or visibility requirements in desktop Chrome.
- Confirm any browser integration stays limited to fullscreen requests, fullscreen state sync, and related presentation boundaries.
- Confirm browser validation remains manual and Chrome-specific, with recorded 10-attempt checks for paused fullscreen entry, exit, and `F` toggle behavior.
- Confirm publish and release automation remain out of scope for `003-web-browser-play`.

## Phase 1: Design Outputs

- `research.md`: decisions and alternatives for fullscreen approach, shared gameplay-path constraints, browser target, validation method, and scope limits
- `data-model.md`: runtime state model for browser fullscreen capabilities, fullscreen session state, and pause-overlay fullscreen control
- `contracts/browser_fullscreen_bridge.md`: optional Godot↔browser fullscreen contract if a browser bridge is needed for the chosen path
- `quickstart.md`: validation flow for headless boot, web export, local serving, manual browser checks, and desktop regression checks

## Post-Design Constitution Check

- `Feel-First Top-Down Gameplay`: Pass. The design keeps gameplay logic in Godot and restricts platform-specific work to fullscreen presentation.
- `Original World, Not Asset-Level Imitation`: Pass. No content scope changes are introduced.
- `Small Vertical Slices Over Broad Scope`: Pass. Design artifacts stay constrained to runtime parity and omit publish automation.
- `Data-Driven Systems Where It Matters`: Pass. The design documents transient runtime state only and does not expand hardcoded gameplay systems.
- `Playtestable, Debuggable, Maintainable`: Pass. The plan uses explicit manual validation and a narrow, inspectable fullscreen state boundary.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution exceptions are required for this plan.
