[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / tasks.md

# Tasks: Web Browser Play

**Input**: Design documents from `/specs/003-web-browser-play/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: This feature relies on Godot headless boot validation, manual desktop Chrome validation, and desktop non-regression checks. The task list emphasizes manual validation artifacts rather than a large automated test suite.

**Organization**: Tasks are grouped by user story so browser runtime parity, paused fullscreen behavior, and desktop regression coverage can each be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when capacity exists
- **[Story]**: Which user story the task belongs to
- Paths use the existing Godot project structure at repo root

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Refresh browser-export scaffolding and feature-facing documentation for the clarified slice

- [ ] T001 Align `specs/003-web-browser-play/README.md`, `spec.md`, `plan.md`, and `tasks.md` with the clarified browser-only scope in `specs/003-web-browser-play/`
- [ ] T002 Add or refresh the desktop Chrome web export preset and custom HTML shell configuration in `export_presets.cfg` and export web-shell files
- [ ] T003 [P] Update browser-target and validation entry-point notes in `README.md` and `tests/manual/web_browser_play.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the shared runtime capabilities, bridge plumbing, and pause-state synchronization needed by all browser stories

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [ ] T004 Implement browser runtime capability detection and fullscreen availability state in `scripts/core/fullscreen_support.gd` using the `BrowserRuntimeCapability` model from `specs/003-web-browser-play/data-model.md`
- [ ] T005 [P] Add the custom HTML shell bridge described in `specs/003-web-browser-play/contracts/browser_fullscreen_bridge.md` using export web-shell assets and Godot-side bridge access in `scripts/core/fullscreen_support.gd`
- [ ] T006 [P] Reconcile pause-overlay fullscreen state with shell callbacks and external fullscreen exits in `scripts/ui/pause_controller.gd` and `scripts/ui/palette_overlay.gd`
- [ ] T007 Add foundational manual validation notes for shell bridge behavior, fullscreen denial handling, and fullscreen-only contexts in `tests/manual/web_browser_play.md`

**Checkpoint**: Browser capability state, shell bridge plumbing, and pause-state synchronization are ready

---

## Phase 3: User Story 1 - Play the sandbox in a browser (Priority: P1) 🎯 MVP

**Goal**: Deliver a desktop Chrome web build that preserves the current sandbox loop, shared input rules, and fixed framing behavior

**Independent Test**: Launch the web build in desktop Chrome, complete the current sandbox loop, and confirm on-foot play, driving, pause flow, and resize behavior remain aligned with desktop

### Implementation for User Story 1

- [ ] T008 [P] [US1] Export and load the current playable scene correctly in a desktop Chrome web build using `scenes/main/game.tscn`, `project.godot`, and `export_presets.cfg`
- [ ] T009 [US1] Keep the existing gameplay input-action path shared between desktop and browser in `project.godot`, `scripts/actors/player/player_controller.gd`, and `scripts/vehicles/vehicle_controller.gd`
- [ ] T010 [US1] Preserve fixed framed-view behavior under browser resize and window changes in `scripts/core/follow_camera.gd` and `scripts/core/game_root.gd`
- [ ] T011 [US1] Record repeatable browser parity checks for on-foot play, vehicle entry or exit, driving, pause, resume, and resize behavior in `tests/manual/web_browser_play.md`

**Checkpoint**: The current sandbox loop is playable in desktop Chrome without a browser-only gameplay fork

---

## Phase 4: User Story 2 - Toggle fullscreen from pause (Priority: P1)

**Goal**: Add paused fullscreen toggling through the shell bridge while keeping pause state authoritative in Godot

**Independent Test**: Run the web build in Chrome, pause the game, use the pause-screen fullscreen control and paused `F`, and confirm fullscreen entry or exit stays coherent before, during, and after the transition

### Implementation for User Story 2

- [ ] T012 [P] [US2] Add the pause-screen fullscreen control and state label updates in `scenes/ui/palette_overlay.tscn` and `scripts/ui/palette_overlay.gd`
- [ ] T013 [US2] Route paused `F` toggles through the shell bridge without unpausing in `scripts/ui/pause_controller.gd` and `scripts/core/fullscreen_support.gd`
- [ ] T014 [US2] Keep paused `F` active regardless of pause-menu or browser focus state while the game is paused in `scripts/ui/pause_controller.gd` and shell bridge files
- [ ] T015 [US2] Keep fullscreen denial silent but coherent by maintaining paused state and overlay availability in `scripts/core/fullscreen_support.gd` and `scripts/ui/palette_overlay.gd`
- [ ] T016 [US2] Hide the pause-screen fullscreen control when the runtime has no meaningful windowed/fullscreen choice in `scripts/core/fullscreen_support.gd` and `scripts/ui/palette_overlay.gd`
- [ ] T017 [US2] Add manual validation coverage for paused fullscreen button entry or exit, paused `F`, denial handling, external exit, and hidden-control cases in `tests/manual/web_browser_play.md`

**Checkpoint**: Paused fullscreen entry and exit work through the custom shell path without breaking pause state

---

## Phase 5: User Story 3 - Keep desktop behavior aligned (Priority: P2)

**Goal**: Ensure browser-support plumbing does not regress the current desktop sandbox loop or fullscreen behavior

**Independent Test**: Launch the desktop build after browser changes and verify the current sandbox loop, pause flow, and paused fullscreen behavior still work without browser-specific regressions

### Implementation for User Story 3

- [ ] T018 [P] [US3] Re-run headless boot and desktop gameplay regression validation after browser changes using the current desktop flow and `tests/manual/us1_playable_core.md`
- [ ] T019 [US3] Verify browser-specific hooks remain isolated from desktop code paths in `scripts/core/fullscreen_support.gd`, `scripts/ui/pause_controller.gd`, `scripts/ui/palette_overlay.gd`, and `project.godot`
- [ ] T020 [US3] Record desktop regression coverage and outcomes in `tests/manual/web_browser_play.md`

**Checkpoint**: Desktop behavior remains aligned after browser runtime changes

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tighten docs, validation, and repo hygiene across the whole feature

- [ ] T021 [P] Refresh `specs/003-web-browser-play/quickstart.md` and `README.md` so the documented browser flow matches the implemented shell-based fullscreen path
- [ ] T022 [P] Review changed files for repo hygiene, including secrets, tokens, emails, and machine-specific paths before any commit
- [ ] T023 Confirm `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `contracts/`, and manual validation docs stay aligned in `specs/003-web-browser-play/` and `tests/manual/web_browser_play.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories
- **User Story 1 (Phase 3)**: Starts after Foundational and defines the browser MVP
- **User Story 2 (Phase 4)**: Starts after Foundational and builds on the shared shell bridge plus paused-flow plumbing
- **User Story 3 (Phase 5)**: Starts after browser runtime work exists and validates desktop non-regression
- **Polish (Phase 6)**: Starts after the desired user stories are implemented

### User Story Dependencies

- **US1**: Depends on the shared browser export and runtime foundations from Phase 2
- **US2**: Depends on the shell bridge, capability state, and pause synchronization from Phase 2
- **US3**: Depends on browser runtime changes being present and must confirm they do not alter desktop behavior

### Parallel Opportunities

- T002 and T003 can run in parallel during setup
- T005 and T006 can run in parallel during foundational work
- T008 and T010 can run in parallel once the web export path exists
- T012 and T016 can run in parallel around pause UI integration
- T021 and T022 can run in parallel during polish

---

## Implementation Strategy

### MVP First

1. Complete Setup
2. Complete Foundational work
3. Complete User Story 1
4. Validate browser parity in desktop Chrome before adding paused fullscreen behavior

### Incremental Delivery

1. Deliver browser play parity in desktop Chrome
2. Deliver paused fullscreen behavior through the custom shell bridge
3. Re-run desktop regression checks to confirm browser plumbing did not fork gameplay behavior
4. Tighten docs and validation once the runtime path is stable

## Notes

- Keep the custom shell limited to the fullscreen boundary
- Keep gameplay logic, pause state, and camera behavior inside Godot
- Do not reintroduce publish-helper work into this slice
- Treat manual Chrome validation as the primary acceptance path for this feature
