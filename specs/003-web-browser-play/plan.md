[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / plan.md

# Implementation Plan: Web Browser Play

**Branch**: `003-web-browser-play` | **Date**: 2026-04-03 | **Spec**: [specs/003-web-browser-play/spec.md](specs/003-web-browser-play/spec.md)
**Input**: Feature specification from `/specs/003-web-browser-play/spec.md`

## Summary

Add desktop Chrome browser play for the current sandbox with runtime behavior that stays close to desktop, while moving paused fullscreen toggling onto a custom HTML shell plus narrow JavaScript bridge so fullscreen requests remain in the browser-owned input path. Keep gameplay, pause state, and camera rules inside Godot, validate parity against desktop behavior, and leave browser publishing workflows out of this feature.

## Technical Context

**Language/Version**: GDScript on Godot 4.6+ plus narrow browser-side JavaScript in a custom HTML shell  
**Primary Dependencies**: Godot 4.x web export, `JavaScriptBridge`, custom HTML shell support, existing pause flow, existing camera and input actions  
**Storage**: Scene files, scripts, export preset configuration, manual validation docs, and web-shell assets only; no new persistent gameplay storage  
**Testing**: Godot headless boot validation, manual desktop regression checks, manual desktop Chrome browser validation  
**Target Platform**: Desktop Chrome for the browser build plus existing desktop Godot runtime for regression checks  
**Project Type**: Single Godot game project  
**Performance Goals**: Preserve browser responsiveness as close to desktop as practical for the current sandbox slice while keeping framing fixed and pause/fullscreen coherent  
**Constraints**: Fullscreen must only toggle while paused, `F` remains active while paused regardless of current pause-menu focus, fullscreen-denial keeps the game paused without extra failure messaging, browser-specific code must stay narrow, publish helper is out of scope  
**Scale/Scope**: One browser-export slice, one custom fullscreen shell bridge, one manual Chrome validation flow, no publish or release pipeline work in this feature

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- `Feel-First Top-Down Gameplay`: Pass. The work preserves player feel, pause behavior, and framing rather than adding a new gameplay fork.
- `Original World, Not Asset-Level Imitation`: Pass. The feature is platform and runtime support only.
- `Small Vertical Slices Over Broad Scope`: Pass. Scope is limited to browser runtime parity and paused fullscreen behavior.
- `Data-Driven Systems Where It Matters`: Pass. No new gameplay data model is required; the new bridge is configuration and runtime glue, not a hardcoded gameplay expansion.
- `Playtestable, Debuggable, Maintainable`: Pass. Manual Chrome validation, desktop regression checks, and explicit fullscreen-state plumbing keep the work observable and testable.

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

**Structure Decision**: Keep the feature inside the existing single Godot project. Runtime browser integration belongs in `scripts/core/` and `scripts/ui/`; the custom shell and bridge contract are isolated to export-facing browser support so gameplay scripts remain shared with desktop.

## Phase 0: Research Outcomes

- Confirm Godot 4.6 custom HTML shell support is the correct foundation for browser-owned fullscreen handling.
- Confirm `JavaScriptBridge` is the narrow Godot-side mechanism for browser fullscreen requests and state callbacks.
- Confirm browser parity validation should remain manual and Chrome-specific for this slice.
- Confirm browser publish workflows stay out of scope for `003-web-browser-play`.

## Phase 1: Design Outputs

- `research.md`: decisions and alternatives for fullscreen architecture, browser target, validation, and scope limits
- `data-model.md`: runtime state model for browser capabilities, fullscreen state, and pause-overlay integration
- `contracts/browser_fullscreen_bridge.md`: Godot↔browser shell interface for fullscreen requests and state reporting
- `quickstart.md`: plan-level validation flow for headless boot, browser export, local serving, and manual checks

## Post-Design Constitution Check

- `Feel-First Top-Down Gameplay`: Pass. The custom shell stays at the fullscreen boundary and does not fork movement, camera, or vehicle behavior.
- `Original World, Not Asset-Level Imitation`: Pass. No content borrowing or thematic scope expansion is introduced.
- `Small Vertical Slices Over Broad Scope`: Pass. Design artifacts stay constrained to runtime parity and exclude publish automation.
- `Data-Driven Systems Where It Matters`: Pass. The design adds state definitions and a bridge contract without expanding hardcoded gameplay systems.
- `Playtestable, Debuggable, Maintainable`: Pass. The design introduces explicit fullscreen-state ownership and validation checkpoints that are easy to inspect and test manually.

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

No constitution exceptions are required for this plan.
