[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / tasks.md

# Tasks: Web Browser Play

**Input**: Design documents from `/specs/003-web-browser-play/`
**Prerequisites**: plan.md, spec.md

**Tests**: This feature relies on headless Godot boot validation, focused manual browser validation in desktop Chrome, and desktop non-regression checks. Optional publish-helper verification is only needed if the publish path is implemented for this feature.

**Organization**: Tasks are grouped by user story to preserve independently testable slices and keep browser support layered onto the existing desktop sandbox.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when capacity exists
- **[Story]**: Which user story the task belongs to
- Paths use the current Godot project structure at repo root

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the minimum export and documentation scaffolding needed for browser support

- [ ] T001 Create or refresh the feature documentation set for `003-web-browser-play` in `specs/003-web-browser-play/`
- [ ] T002 Add a desktop Chrome-focused web export target and required export-side assets in `export_presets.cfg` and export-support files
- [ ] T003 [P] Document the first-pass browser target, limitations, and validation entry points in `README.md` or `tests/manual/web_browser_play.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the browser/runtime integration points that all browser user stories depend on

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [ ] T004 Add runtime detection for browser contexts and fullscreen availability in `scripts/core/game_root.gd` or `scripts/core/fullscreen_support.gd`
- [ ] T005 [P] Add shared fullscreen state helpers and pause-safe toggle plumbing in `scripts/core/fullscreen_support.gd` and `scripts/ui/pause_controller.gd`
- [ ] T006 [P] Add manual validation notes for browser resize, framing parity, and fullscreen-state coherence in `tests/manual/web_browser_play.md`

**Checkpoint**: Browser state detection, fullscreen helpers, and validation notes are ready

---

## Phase 3: User Story 1 - Play the sandbox in Chrome (Priority: P1) 🎯 MVP

**Goal**: Deliver a desktop Chrome web build that preserves the current sandbox loop and intended camera framing without a browser-only gameplay fork

**Independent Test**: Launch the web build in desktop Chrome, complete the current sandbox loop, and verify that browser play follows the same gameplay rules, pause flow, and framing intent as desktop

### Implementation for User Story 1

- [ ] T007 [P] [US1] Export and load the current playable scene correctly in a desktop Chrome web build using `scenes/main/game.tscn`, `project.godot`, and `export_presets.cfg`
- [ ] T008 [US1] Preserve the existing gameplay input-action path for browser play without adding a browser-only controller in `project.godot`, `scripts/actors/player/player_controller.gd`, and `scripts/vehicles/vehicle_controller.gd`
- [ ] T009 [US1] Preserve intended camera framing under browser window resize and fullscreen transitions in `scripts/core/follow_camera.gd` and `scripts/core/game_root.gd`
- [ ] T010 [US1] Add repeatable manual Chrome checks for on-foot play, vehicle entry or exit, driving, pause, resume, and resize behavior in `tests/manual/web_browser_play.md`

**Checkpoint**: The current sandbox loop is playable in desktop Chrome with intended framing preserved

---

## Phase 4: User Story 2 - Toggle fullscreen from pause (Priority: P1)

**Goal**: Add a paused fullscreen control and paused-only `F` shortcut for browser play while hiding the control where non-fullscreen mode is unavailable

**Independent Test**: Run the web build in Chrome, pause the game, toggle fullscreen using the pause-screen control and `F`, and verify that the game remains paused and coherent before, during, and after the transition

### Implementation for User Story 2

- [ ] T011 [P] [US2] Add a pause-screen fullscreen control and `F` shortcut hint in `scenes/ui/` and `scripts/ui/pause_controller.gd`
- [ ] T012 [US2] Implement paused-only fullscreen toggling that ignores `F` while unpaused and does not resume gameplay in `scripts/ui/pause_controller.gd` and `scripts/core/fullscreen_support.gd`
- [ ] T013 [US2] Hide the pause-screen fullscreen control on runtimes where a non-fullscreen display mode is not available in `scripts/core/fullscreen_support.gd` and pause UI scenes
- [ ] T014 [US2] Reconcile fullscreen state if Chrome exits fullscreen through `Esc` or browser UI instead of the in-game control in `scripts/core/fullscreen_support.gd`
- [ ] T015 [US2] Add a custom HTML shell or narrow browser bridge only if Godot-native fullscreen toggling is unreliable in Chrome using export web-shell files and `scripts/core/fullscreen_support.gd`
- [ ] T016 [US2] Document repeatable manual Chrome checks for paused fullscreen-button entry or exit, paused `F` toggle, external fullscreen exit, and hidden-control cases in `tests/manual/web_browser_play.md`

**Checkpoint**: Paused fullscreen entry and exit work in desktop Chrome without breaking pause state

---

## Phase 5: User Story 3 - Keep desktop behavior aligned (Priority: P2)

**Goal**: Preserve the existing desktop sandbox behavior while layering browser support on top

**Independent Test**: Launch the desktop build after browser work and verify that the current sandbox loop, pause flow, and fullscreen behavior still work without browser-only regressions

### Implementation for User Story 3

- [ ] T017 [P] [US3] Re-run headless and desktop non-regression validation after browser changes using the main project boot path and current desktop gameplay flow
- [ ] T018 [US3] Verify browser-specific hooks stay isolated from desktop gameplay paths in `scripts/core/`, `scripts/ui/`, and `project.godot`
- [ ] T019 [US3] Record desktop non-regression coverage and outcomes alongside browser validation notes in `tests/manual/web_browser_play.md`

**Checkpoint**: Desktop behavior remains aligned after browser support changes

---

## Phase 6: Optional Publish Helper (Conditional Scope)

**Purpose**: Add the manual GitHub Pages publish path only if this feature explicitly includes the optional publish workflow

- [ ] T020 [P] Add a small manual publish helper at repo root that exports the web build to temporary output instead of the working tree in `publish_web_docs.sh`
- [ ] T021 Publish the exported web build to the `docs` branch with hosted files under `docs/` in `publish_web_docs.sh`
- [ ] T022 Ensure the publish helper records and restores the starting branch rather than assuming a fixed branch in `publish_web_docs.sh`
- [ ] T023 Document the manual publish flow, required GitHub Pages settings, and verification steps in `README.md` or dedicated publish notes
- [ ] T024 Add a manual checklist for publish verification, branch restoration, and clean working-tree behavior in `tests/manual/web_browser_play.md`

**Checkpoint**: Optional publish flow exists without tracking build artifacts on working branches

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Tighten validation, documentation, and repo hygiene across the feature

- [ ] T025 [P] Re-run desktop Chrome browser validation and record the result in `tests/manual/web_browser_play.md`
- [ ] T026 [P] Review changed files for repo hygiene, including secrets, tokens, emails, and machine-specific paths before any commit
- [ ] T027 Confirm the final task list, spec status, and completion state stay aligned across `specs/003-web-browser-play/spec.md`, `specs/003-web-browser-play/plan.md`, and `specs/003-web-browser-play/tasks.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Depends on Setup and blocks all user stories
- **User Story 1 (Phase 3)**: Starts after Foundational and defines the browser MVP
- **User Story 2 (Phase 4)**: Starts after Foundational and builds on browser playability and pause integration
- **User Story 3 (Phase 5)**: Starts after browser support work exists and verifies desktop non-regression
- **Optional Publish Helper (Phase 6)**: Starts only if the publish path remains in scope for this feature
- **Polish (Phase 7)**: Starts after the desired user stories are implemented

### User Story Dependencies

- **US1**: Depends on shared browser export and framing foundations
- **US2**: Depends on the pause flow and fullscreen integration points from the foundational phase
- **US3**: Depends on browser support changes being present and must validate they do not regress desktop behavior

### Parallel Opportunities

- T002 and T003 can run in parallel during setup
- T005 and T006 can run in parallel during foundational work
- T007 and T009 can run in parallel once the web export path exists
- T011 and T013 can run in parallel around the pause UI work
- T020 and T023 can run in parallel if the optional publish helper is included

---

## Implementation Strategy

### MVP First

1. Complete Setup
2. Complete Foundational work
3. Complete User Story 1
4. Validate browser parity in desktop Chrome before adding paused fullscreen work

### Incremental Delivery

1. Deliver browser play parity in desktop Chrome
2. Deliver paused fullscreen entry or exit with correct visibility rules
3. Re-run desktop non-regression checks to confirm parity remains layered rather than forked
4. Add the optional publish helper only if the team still wants browser distribution in this feature

## Notes

- Keep browser support narrow and explicit rather than splitting gameplay logic
- Treat the custom HTML shell as a fallback for fullscreen restrictions, not a separate runtime design
- Keep generated web artifacts out of normal working branches
- If the optional publish path is not being delivered in this feature, leave Phase 6 undone and keep the spec artifacts explicit about that choice
