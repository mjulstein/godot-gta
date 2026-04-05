[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / tasks.md

# Tasks: Web Browser Play

**Input**: Design documents from `/specs/003-web-browser-play/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/

**Tests**: This feature relies on Godot headless boot validation, manual desktop Chrome validation with recorded fullscreen attempts, and desktop non-regression checks. The task list emphasizes reproducible manual validation artifacts rather than a large automated test suite.

**Organization**: Tasks are grouped by user story so browser runtime parity, paused fullscreen behavior, and desktop regression coverage can each be implemented and validated independently.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when capacity exists
- **[Story]**: Which user story the task belongs to
- Paths use the existing Godot project structure at repo root

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Refresh browser-export scaffolding and feature-facing docs for the clarified slice

- [X] T001 Align `specs/003-web-browser-play/README.md`, `research.md`, `data-model.md`, `contracts/browser_fullscreen_bridge.md`, and `quickstart.md` with the chosen fullscreen-path rules, Chrome-only scope, and `SC-002` through `SC-007`
- [X] T002 Add or refresh the desktop Chrome web export preset in `export_presets.cfg` and confirm the export target paths used by `build/web/`
- [X] T003 [P] Update browser-target, local-serve, and validation entry-point notes in `README.md` and `tests/manual/web_browser_play.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the shared runtime capability and pause/fullscreen state plumbing required by all browser stories

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [X] T004 Implement browser runtime capability detection and fullscreen availability state in `scripts/core/fullscreen_support.gd` using the `BrowserRuntimeCapability` model from `specs/003-web-browser-play/data-model.md`
- [X] T005 [P] Implement the chosen browser-friendly fullscreen boundary, using browser-page UI or narrow browser glue only if needed, in `scripts/core/fullscreen_support.gd`, `export_presets.cfg`, and browser export assets under `build/web/`
- [X] T006 [P] Reconcile pause-overlay fullscreen state, visible `F` labeling, and external fullscreen exits in `scripts/ui/pause_controller.gd` and `scripts/ui/palette_overlay.gd`, ensuring any external fullscreen exit syncs state immediately and activates pause if the game is not already paused
- [X] T007 Add foundational manual validation notes for fullscreen capability detection, denial handling, external exit handling, fullscreen-only contexts, and recorded fullscreen attempts in `tests/manual/web_browser_play.md`

**Checkpoint**: Browser capability state and pause/fullscreen synchronization are ready

---

## Phase 3: User Story 1 - Play the sandbox in a browser (Priority: P1) 🎯 MVP

**Goal**: Deliver a desktop Chrome web build that preserves the current sandbox loop, shared input rules, vehicle takeover behavior, and fixed framing without introducing a browser-only gameplay path

**Independent Test**: Launch the web build in desktop Chrome, complete the current sandbox loop, and confirm on-foot play, vehicle entry, displaced-occupant behavior, driving, exit, pause flow, and resize behavior remain aligned with desktop

### Implementation for User Story 1

- [X] T008 [P] [US1] Export and load the current playable scene correctly in a desktop Chrome web build using `scenes/main/game.tscn`, `project.godot`, and `export_presets.cfg`
- [X] T009 [US1] Keep the existing gameplay input-action path, vehicle takeover flow, and displaced-occupant behavior shared between desktop and browser in `project.godot`, `scripts/actors/player/player_controller.gd`, and `scripts/vehicles/vehicle_controller.gd`
- [X] T010 [US1] Preserve fixed framed-view behavior under browser resize and fullscreen transitions in `scripts/core/follow_camera.gd` and `scripts/core/game_root.gd`
- [X] T011 [US1] Record repeatable browser parity checks for on-foot play, vehicle entry, displaced-occupant behavior, driving, exit, pause, resume, and resize behavior in `tests/manual/web_browser_play.md`

**Checkpoint**: The current sandbox loop is playable in desktop Chrome without a browser-only gameplay fork

---

## Phase 4: User Story 2 - Toggle fullscreen from pause (Priority: P1)

**Goal**: Add paused fullscreen toggling while keeping pause state authoritative in Godot

**Independent Test**: Run the web build in Chrome, pause the game, use the available fullscreen control and paused `F`, and confirm fullscreen entry or exit stays coherent before, during, and after the transition

### Implementation for User Story 2

- [X] T012 [P] [US2] Add the chosen in-game fullscreen control only if the selected browser approach needs one, keep state label updates coherent, and show the visible `F` shortcut hint whenever the toggle is visible in a keyboard-capable runtime in `scenes/ui/palette_overlay.tscn` and `scripts/ui/palette_overlay.gd`
- [X] T013 [US2] Implement paused `F` as a simple paused-only fullscreen toggle attempt in `scripts/ui/pause_controller.gd` and `scripts/core/fullscreen_support.gd`
- [X] T014 [US2] Keep fullscreen denial silent but coherent by maintaining paused state and overlay availability in `scripts/core/fullscreen_support.gd` and `scripts/ui/palette_overlay.gd`
- [X] T015 [US2] Hide any in-game fullscreen control when the runtime has no meaningful windowed/fullscreen choice or when browser-page UI is the selected fullscreen approach in `scripts/core/fullscreen_support.gd` and `scripts/ui/palette_overlay.gd`
- [X] T016 [US2] Add manual validation coverage for the chosen fullscreen control, visible `F` shortcut hint behavior, paused `F`, denial handling, external fullscreen exit while paused, external fullscreen exit while unpaused triggering pause, hidden-control cases, and recorded 10-attempt fullscreen results in `tests/manual/web_browser_play.md`

**Checkpoint**: Paused fullscreen entry and exit work through the chosen browser-friendly path without breaking pause state

---

## Phase 5: User Story 3 - Keep desktop behavior aligned (Priority: P2)

**Goal**: Ensure browser-support plumbing does not regress the current desktop gameplay path

**Independent Test**: Launch the desktop build after browser changes and verify the current sandbox loop and pause flow still work without browser-specific regressions

### Implementation for User Story 3

- [ ] T017 [P] [US3] Re-run headless boot and desktop gameplay regression validation after browser changes using the current desktop flow and `tests/manual/us1_playable_core.md`
- [X] T018 [US3] Verify browser-specific fullscreen handling remains isolated from the shared gameplay path in `scripts/core/fullscreen_support.gd`, `scripts/ui/pause_controller.gd`, `scripts/ui/palette_overlay.gd`, and `project.godot`
- [ ] T019 [US3] Record desktop regression coverage and outcomes in `tests/manual/web_browser_play.md`

**Checkpoint**: Desktop behavior remains aligned after browser runtime changes

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tighten docs and final validation across the whole feature

- [X] T020 [P] Refresh `specs/003-web-browser-play/quickstart.md`, `README.md`, and `tests/manual/web_browser_play.md` so the documented browser flow matches the chosen fullscreen path, Chrome-only scope, and `SC-001` through `SC-007`
- [ ] T021 Run the complete quickstart and validation flow from `specs/003-web-browser-play/quickstart.md` to satisfy `SC-001` through `SC-007`, and capture final notes in `tests/manual/web_browser_play.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories
- **User Story 1 (Phase 3)**: Starts after Foundational and defines the browser MVP
- **User Story 2 (Phase 4)**: Starts after Foundational and builds on the chosen fullscreen path plus paused-flow plumbing
- **User Story 3 (Phase 5)**: Starts after browser runtime work exists and validates that shared gameplay paths stay intact
- **Polish (Phase 6)**: Starts after the desired user stories are implemented

### User Story Dependencies

- **US1**: Depends on the shared browser export and runtime foundations from Phase 2
- **US2**: Depends on the chosen fullscreen path, capability state, and pause synchronization from Phase 2
- **US3**: Depends on browser runtime changes being present and must confirm they do not alter the shared gameplay path

### Parallel Opportunities

- T002 and T003 can run in parallel during setup
- T005 and T006 can run in parallel during foundational work
- T008 and T010 can run in parallel once the web export path exists
- T012 and T016 can run in parallel around fullscreen UI integration
- T017 and T019 can run in parallel during desktop regression validation
- T020 can run in parallel with final validation preparation

---

## Parallel Example: User Story 1

```bash
Task: "Export and load the current playable scene correctly in a desktop Chrome web build using scenes/main/game.tscn, project.godot, and export_presets.cfg"
Task: "Preserve fixed framed-view behavior under browser resize and fullscreen transitions in scripts/core/follow_camera.gd and scripts/core/game_root.gd"
```

## Parallel Example: User Story 2

```bash
Task: "Add the chosen in-game fullscreen control only if the selected browser approach needs one, keep state label updates coherent, and show the visible F shortcut hint whenever the toggle is visible in a keyboard-capable runtime in scenes/ui/palette_overlay.tscn and scripts/ui/palette_overlay.gd"
Task: "Add manual validation coverage for the chosen fullscreen control, visible F shortcut hint behavior, paused F, denial handling, external fullscreen exit while paused, external fullscreen exit while unpaused triggering pause, hidden-control cases, and recorded 10-attempt fullscreen results in tests/manual/web_browser_play.md"
```

---

## Implementation Strategy

### MVP First

1. Complete Setup
2. Complete Foundational work
3. Complete User Story 1
4. Validate browser parity in desktop Chrome before adding paused fullscreen behavior

### Incremental Delivery

1. Deliver browser play parity in desktop Chrome
2. Deliver paused fullscreen behavior through the chosen browser-friendly fullscreen path
3. Re-run desktop regression checks to confirm browser support did not fork gameplay behavior
4. Tighten docs and validation once the runtime path is stable

## Notes

- Keep any browser-specific fullscreen glue limited to the fullscreen boundary
- Keep gameplay logic, pause state, and camera behavior inside Godot
- Treat recorded 10-attempt fullscreen checks as part of the acceptance path
- Do not reintroduce publish-helper work into this slice
