[root](../../README.md) / [specs](../README.md) / [002-mobile-controls](./README.md) / plan.md

# Implementation Plan: Mobile Controls

**Branch**: `002-mobile-controls` | **Date**: 2026-03-26 | **Spec**: [specs/002-mobile-controls/spec.md](specs/002-mobile-controls/spec.md)
**Input**: Feature specification from `/specs/002-mobile-controls/spec.md`

## Summary

Add a minimal mobile touch HUD that makes the current sandbox loop playable on iPhone by mapping a lower-left on-screen joystick, top-right action buttons, and right-hand driving pedals to the existing action-driven input model. Keep the implementation UI-local, preserve desktop keyboard play, avoid automatic platform-based HUD switching, and expose pause-time HUD controls for opacity, gameplay input scale, impact vibration, and restart.

## Technical Context

**Language/Version**: GDScript on Godot 4.x  
**Primary Dependencies**: Godot 4.x UI and input systems, `Control`, `CanvasLayer` or current UI layer pattern, touch drag events, existing `InputMap` actions  
**Storage**: Scene files and scripts only; no new persistent storage expected  
**Testing**: Godot headless boot validation plus manual playtest on desktop and iPhone or iOS simulator  
**Target Platform**: Existing desktop targets plus iPhone/iOS for touch playability  
**Project Type**: Single Godot game project  
**Performance Goals**: Preserve current gameplay feel and responsiveness while adding always-on touch controls during mobile play  
**Constraints**: Reuse existing input actions, support multitouch, avoid desktop regressions, keep v1 button-based and simple  
**Scale/Scope**: One mobile HUD, one control mapping layer, scene wiring in the existing main gameplay UI stack

## Constitution Check

*GATE: Must pass before implementation starts.*

- `Feel-First Top-Down Gameplay`: Pass. The work extends the current sandbox loop to touch input without changing the core feel targets.
- `Original World, Not Asset-Level Imitation`: Pass. The feature is interface-only and does not require copied GTA UI.
- `Small Vertical Slices Over Broad Scope`: Pass. Scope is limited to first-pass mobile playability on iPhone.
- `Data-Driven Systems Where It Matters`: Pass. The feature reuses action-driven input and can keep layout values local to the mobile HUD scene or tunable UI properties.
- `Playtestable, Debuggable, Maintainable`: Pass. The work can be validated through one mobile HUD scene, existing gameplay actions, and manual device tests.

No constitution violations are expected.

## Project Structure

### Documentation (this feature)

```text
specs/002-mobile-controls/
├── README.md
├── spec.md
└── plan.md
```

### Source Code (repository root)

```text
scenes/
├── main/
│   └── game.tscn
└── ui/
    └── mobile_controls_hud.tscn

scripts/
└── ui/
    └── mobile_controls_hud.gd

project.godot
tests/
└── manual/
```

**Structure Decision**: Keep mobile controls isolated to a dedicated HUD scene and UI script under the existing `scenes/ui/` and `scripts/ui/` structure. Wire the HUD into `scenes/main/game.tscn` so gameplay logic continues to consume only the established input actions.

## Implementation Approach

### Phase 1: HUD Scene And Layout

Create a mobile HUD scene under `scenes/ui/` with:

- a bottom-left joystick for movement and steering
- top-right `ACT` and `P` buttons
- right-hand `GAS` and `BRK` buttons while driving
- pause-overlay buttons for debug visibility, HUD opacity, gameplay input scale, impact vibration, and restart

Prefer Godot-native touch events for joystick drag handling and action button press or release handling.

### Phase 2: Action Mapping

Connect HUD button states to the existing gameplay actions instead of calling actor or vehicle methods directly.

- On foot, joystick input should drive `move_up`, `move_down`, `move_left`, and `move_right`.
- In vehicles, the same joystick should drive `steer_left` and `steer_right` only.
- In vehicles, right-hand `GAS` and `BRK` buttons should drive `accelerate` and `brake`.
- `interact` and `pause` should always trigger the existing action paths used by desktop play.

The current control state should determine which action set the directional cluster emits, with the state sourced from existing gameplay ownership or actor mode rather than a mobile-only gameplay path.

### Phase 3: Scene Integration And Platform Gating

Instance the mobile HUD beneath the main gameplay UI layer in `scenes/main/game.tscn`.

- Keep the HUD available on every platform.
- Keep desktop keyboard controls unchanged.
- Let the player fade the HUD to `0%` opacity instead of automatically hiding it by platform.
- Let the player scale gameplay touch surfaces from `1.00x` to `2.00x` in `0.25x` steps from the pause overlay.
- Ensure the HUD supports overlapping touches so movement can continue while `interact` or `pause` is pressed.

### Phase 4: Validation

Validate with:

- `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`
- desktop manual verification that keyboard play still works
- iPhone or iOS simulator manual verification for walking, vehicle entry or exit, driving, pause, multitouch overlap, gameplay input resizing, crash vibration, and restart

## Implementation Notes

- Reuse the current action names already present in `project.godot`.
- Do not add a separate mobile gameplay controller.
- Keep touch-specific code out of player and vehicle scripts unless a small state exposure is required to choose the current directional mapping.
- If platform detection is ambiguous during development, prefer a narrow, explicit gating point in the HUD scene or bootstrap layer so desktop behavior stays predictable.
- Keep art and styling minimal for v1; clarity, reachability, and safe-area spacing matter more than polish.
- Keep gameplay input scaling anchored to each control cluster's existing corner so larger surfaces do not drift across the screen.
- Keep pause-only controls visually separate from frequent gameplay controls.

## Risks And Mitigations

- `State mapping risk`: The same joystick means full movement on foot and steering-only in vehicles. Mitigation: derive mapping from existing player-control state, not duplicated mobile state.
- `Multitouch risk`: Button interactions can cancel each other if press and release handling is naive. Mitigation: use Godot-native touch controls and verify overlapping press paths on device.
- `Desktop regression risk`: UI focus or unconditional HUD loading could affect current play. Mitigation: keep keyboard input untouched and let the player fade the HUD to `0%` opacity.
- `Layout risk`: Buttons can overlap notches or reduce play-area readability on iPhone. Mitigation: keep v1 layout simple and validate against safe-area constraints during device testing.
- `Control crowding risk`: Extra pause-time options can blur the difference between gameplay buttons and meta controls. Mitigation: keep new options in the pause overlay and keep restart de-emphasized near the lower-right edge rather than mixing it with gameplay surfaces.

## Open Questions

- Whether the existing UI stack already has a preferred `CanvasLayer` pattern the HUD should attach to directly in `scenes/main/game.tscn`.
- Whether the desktop override should support mouse-drag joystick testing without deploying to iOS.
