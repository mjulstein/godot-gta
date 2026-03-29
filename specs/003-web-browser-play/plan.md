[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / plan.md

# Implementation Plan: Web Browser Play

**Branch**: `003-web-browser-play` | **Date**: 2026-03-30 | **Spec**: [specs/003-web-browser-play/spec.md](specs/003-web-browser-play/spec.md)
**Input**: Feature specification from `/specs/003-web-browser-play/spec.md`

## Summary

Add first-pass desktop Chrome support for the current sandbox so the browser build preserves the desktop gameplay loop, pause behavior, and intended framing. Add a pause-screen fullscreen button plus a paused-only `F` shortcut, using Godot-native fullscreen control when it works reliably in the active input event path and a custom HTML shell workaround when the browser fullscreen boundary requires JavaScript ownership.

If distribution on GitHub Pages is desired, support a simple manual publish helper that exports the current web build into temporary output and pushes it to a dedicated publish branch with site files under `docs/`, keeping built artifacts out of the working branch.

## Technical Context

**Language/Version**: GDScript on Godot 4.x plus minimal browser-side JavaScript in a custom web shell if needed  
**Primary Dependencies**: Godot 4.x web export, existing input actions, pause overlay flow, `DisplayServer` window APIs, custom HTML shell support for web export  
**Storage**: Scene files, scripts, export template assets, optional publish helper scripts, and web shell files only; no new persistent gameplay storage expected  
**Testing**: Godot headless boot validation, manual desktop validation, and manual browser validation in desktop Chrome  
**Target Platform**: Desktop Chrome plus existing desktop builds for non-regression  
**Project Type**: Single Godot game project  
**Performance Goals**: Preserve readable sandbox play and camera framing in browser builds without introducing a browser-only gameplay fork  
**Constraints**: Browser fullscreen requests must stay tied to the active user input event; browser play should stay as close to desktop as practical; fullscreen controls must only operate while paused; the pause-screen fullscreen control must be hidden where a non-fullscreen display mode is not available  
**Scale/Scope**: One export-facing browser support slice, one paused fullscreen path, one manual browser validation flow

## Constitution Check

*GATE: Must pass before implementation starts.*

- `Feel-First Top-Down Gameplay`: Pass. The work protects the existing sandbox feel in browser play rather than redefining it.
- `Original World, Not Asset-Level Imitation`: Pass. The feature is platform support and fullscreen behavior only.
- `Small Vertical Slices Over Broad Scope`: Pass. Scope is limited to current-slice browser parity and paused fullscreen.
- `Data-Driven Systems Where It Matters`: Pass. The work can reuse the existing input and pause flow, with minimal export-layer additions.
- `Playtestable, Debuggable, Maintainable`: Pass. Browser support can be validated through a focused manual browser checklist plus current desktop checks.

No constitution violations are expected.

## Project Structure

### Documentation (this feature)

```text
specs/003-web-browser-play/
├── README.md
├── plan.md
└── spec.md
```

### Source Code (repository root)

```text
scenes/
├── main/
│   └── game.tscn
└── ui/
    └── ...

scripts/
├── core/
│   └── ...
└── ui/
    └── ...

export/
└── web/
    └── ...

scripts/
└── ...

tests/
└── manual/
```

**Structure Decision**: Keep browser support centered in existing pause and bootstrap code where possible. If fullscreen needs browser-owned control, isolate that boundary in a custom web shell and a narrow bridge instead of scattering browser-specific behavior through gameplay scripts. If a publish helper is added, keep it as a small repo-level script that writes only to temporary output locally.

## Implementation Approach

### Phase 1: Define Browser Parity Boundaries

Confirm the exact behaviors that must remain aligned with desktop:

- same playable scene and sandbox loop
- same input-action model
- same pause or resume flow
- same framed view expectations when resizing or entering fullscreen
- no browser-only gameplay controller or browser-only actor rules
- Chrome is the only supported browser target for v1

### Phase 2: Add Paused Fullscreen Toggle

Integrate a pause-screen fullscreen control and paused-only `F` handling through the existing pause flow.

- add a clickable fullscreen control to the pause UI
- detect `F` in the active input event path
- only act when the game is paused
- toggle fullscreen without unpausing
- keep paused state coherent if fullscreen is exited externally
- show the `F` shortcut alongside the fullscreen control
- hide the fullscreen control on platforms or runtime modes where a non-fullscreen display mode is not available

Prefer `DisplayServer.window_set_mode()` for the first pass if it works reliably in browser builds from the active input callback.

### Phase 3: Add Custom Shell Fallback

If browser fullscreen cannot be triggered reliably from Godot alone, add a custom HTML shell for web export.

- use Godot's custom HTML shell support
- keep the fullscreen API boundary in JavaScript
- let JavaScript own `requestFullscreen()` or `exitFullscreen()` when browser policy requires it
- call into that boundary only from the same browser-owned input event chain needed for fullscreen compliance
- keep game pause state and gameplay behavior inside Godot

This phase is a workaround layer, not a second gameplay path.

### Phase 4: Browser Validation

Validate with:

- `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`
- desktop validation for current sandbox non-regression
- manual Chrome validation for:
  - windowed play
  - resize behavior
  - pause and resume
  - paused fullscreen-button entry
  - paused fullscreen-button exit
  - paused `F` fullscreen entry
  - paused `F` fullscreen exit
  - external fullscreen exit through browser UI or `Esc`
  - hidden-control behavior on platforms or runtime modes where a non-fullscreen display mode is not available
  - desktop parity for the current playable loop

### Phase 5: Optional GitHub Pages Publish Path

If a manual publish path is wanted:

- capture the currently checked out branch before any publish branch switching
- export the web build to a temporary directory
- publish from a dedicated branch rather than the working branch
- keep hosted files under `docs/` on that publish branch
- avoid tracking exported build artifacts in the main working branch
- restore the originally checked out branch after publish completes
- keep the publish helper manual and explicit rather than automatic

## Implementation Notes

- Prefer Godot-native handling first, because it keeps the platform code surface smaller.
- Use the custom shell only at the fullscreen boundary if browser restrictions force it.
- Keep browser-specific conditionals narrow and explicit.
- Avoid embedding gameplay decisions in JavaScript.
- Keep the pause overlay fullscreen control and `F` hint simple and discoverable.
- Preserve the existing fixed framing intent across browser resize and fullscreen changes.
- If a GitHub Pages publish helper is added, prefer a branch-local publish flow that does not leave build products in the local working tree.
- If a GitHub Pages publish helper is added, never assume the user's base branch is `main`; restore whichever branch was active when publish started.

## Risks And Mitigations

- `Fullscreen policy risk`: Browsers can reject fullscreen if the request is no longer tied to the live input event. Mitigation: issue the request in the active input callback, and keep a custom-shell fallback available.
- `Visibility risk`: The fullscreen button could appear where it makes no sense. Mitigation: gate visibility on whether the runtime exposes both non-fullscreen and fullscreen display modes.
- `Parity drift risk`: Browser support can turn into a second gameplay path. Mitigation: reuse existing actions, pause state, and gameplay logic.
- `Framing regression risk`: Browser resize or fullscreen can reveal more world than intended. Mitigation: validate framing explicitly against the current fixed-view expectation.
- `Desktop regression risk`: Export-specific hooks can leak into desktop play. Mitigation: isolate browser code behind explicit web checks and re-run desktop validation.
- `External exit risk`: Browser `Esc` or chrome exits can desync UI and window state. Mitigation: reconcile paused state and fullscreen state after external exits.
- `Publish hygiene risk`: A deploy helper can accidentally dirty the working branch with generated files. Mitigation: export to temporary directories and publish from a dedicated branch.
- `Wrong branch return risk`: A deploy helper can switch the repo back to the wrong branch after publishing. Mitigation: record the starting branch explicitly and restore it at the end.

## Open Questions

- Whether the current pause overlay already has a clean location for the fullscreen button and `F` hint without adding clutter.
- Whether Godot-only fullscreen toggling is reliable enough in the target browsers, or whether the custom-shell workaround should be treated as the default implementation.
- Whether the publish branch should be named `docs` or `gh-pages` if a GitHub Pages helper is added.
