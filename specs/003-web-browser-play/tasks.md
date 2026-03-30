[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / tasks.md

# Tasks: Web Browser Play

**Input**: Design documents from `/specs/003-web-browser-play/`
**Prerequisites**: plan.md, spec.md

**Tests**: This feature relies on a mix of focused manual browser validation in desktop Chrome, existing desktop non-regression checks, and a manual publish verification path when the optional GitHub Pages helper is implemented.

**Organization**: Tasks are grouped by user story to preserve independently verifiable slices.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when capacity exists
- **[Story]**: Which user story the task belongs to
- Paths use the Godot project structure already present in the repository

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Add the web-export and browser-support scaffolding needed for the feature

- [x] T001 Create the feature documentation set and keep `specs/README.md` aligned for `003-web-browser-play`
- [x] T002 Add a first-pass Godot web export target and any minimal export-side assets needed for desktop Chrome play in `export_presets.cfg` and export-support files
- [x] T003 [P] Document the initial browser validation target and limitations for desktop Chrome in `README.md` or `tests/manual/`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Add the shared browser and pause integration points before user-story work

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [x] T004 Add or expose any runtime detection needed to distinguish contexts that support both non-fullscreen and fullscreen display modes from fullscreen-only contexts in the appropriate bootstrap or UI layer
- [x] T005 [P] Add or expose any fullscreen state helpers needed by the pause flow while keeping browser-specific logic narrow
- [x] T006 [P] Add manual validation notes for browser window resizing, framing parity, and fullscreen state coherence in `tests/manual/`

**Checkpoint**: Browser-specific state and pause integration points are ready

---

## Phase 3: User Story 1 - Play the sandbox in Chrome (Priority: P1) 🎯 MVP

**Goal**: Deliver a desktop Chrome web build that preserves the current desktop sandbox loop and intended framed view

**Independent Test**: Launch the web build in desktop Chrome, complete the current sandbox loop, and verify that browser play follows the same rules and framing intent as desktop.

### Implementation for User Story 1

- [x] T007 [P] [US1] Export and load the current playable scene correctly in a desktop Chrome web build
- [x] T008 [US1] Preserve the existing gameplay input-action path for browser play without adding a browser-only gameplay controller
- [x] T009 [US1] Preserve intended camera framing under browser window resize and fullscreen transitions in the relevant camera or root-scene wiring
- [x] T010 [US1] Document repeatable manual Chrome checks for on-foot play, vehicle entry or exit, driving, pause, and resize behavior in `tests/manual/`

**Checkpoint**: The current sandbox loop is playable in desktop Chrome with intended framing preserved

---

## Phase 4: User Story 2 - Toggle fullscreen from pause (Priority: P1)

**Goal**: Add a paused fullscreen control and paused `F` shortcut for browser play, while hiding the control where a non-fullscreen display mode is not available

**Independent Test**: Run the web build in desktop Chrome, pause the game, toggle fullscreen using the pause-screen control and `F`, and verify that the game remains paused and coherent before, during, and after the fullscreen transition.

### Implementation for User Story 2

- [x] T011 [P] [US2] Add a pause-screen fullscreen control and `F` shortcut hint in the pause UI under `scenes/ui/` and `scripts/ui/`
- [x] T012 [US2] Implement paused-only fullscreen toggling that does not unpause gameplay and ignores `F` while unpaused
- [x] T013 [US2] Hide the pause-screen fullscreen control on platforms or runtime modes where a non-fullscreen display mode is not available
- [x] T014 [US2] Reconcile fullscreen state if Chrome exits fullscreen through `Esc` or browser UI instead of the in-game control
- [ ] T015 [US2] Add a custom HTML shell or narrow browser bridge only if Godot-native fullscreen toggling is unreliable in Chrome
- [x] T016 [US2] Document repeatable manual Chrome checks for pause-screen fullscreen button entry or exit, paused `F` toggle, and external fullscreen exit in `tests/manual/`

**Checkpoint**: Paused fullscreen entry and exit work in desktop Chrome without breaking pause state

---

## Phase 5: User Story 3 - Publish a playable build without tracking build artifacts (Priority: P2)

**Goal**: Provide an optional manual publish helper that makes the current browser build available online through GitHub Pages without checking generated web artifacts into working branches

**Independent Test**: From a clean working tree on any feature branch, run the manual publish helper, verify that the site is available online after publish completes, verify that exported files were pushed to the `docs` publish branch under `docs/`, and verify that the local repository returns to the original branch without tracked build artifacts.

### Implementation for User Story 3

- [x] T017 [P] [US3] Add a small manual publish helper at the repo root that exports the web build to temporary output rather than the working tree
- [ ] T018 [US3] Publish the exported web build to the `docs` branch with site files under `docs/`
- [x] T019 [US3] Ensure the publish helper records the starting branch and restores that same branch after publish completes
- [x] T020 [US3] Ensure the publish helper does not require generated web artifacts to be committed on feature branches or other working branches
- [x] T021 [US3] Document the manual publish flow, GitHub Pages source expectation, and any required repo settings in `README.md` or dedicated publish notes
- [x] T022 [US3] Add a manual verification checklist covering online availability after publish, branch restoration, and clean working-tree behavior in `tests/manual/`

**Checkpoint**: A manual GitHub Pages publish path exists without tracking generated build files on working branches

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Tighten browser support, documentation, and validation across the feature

- [ ] T023 [P] Re-run desktop non-regression checks after browser and publish-path work
- [ ] T024 [P] Re-run desktop Chrome browser validation and record the result in `tests/manual/`
- [x] T025 Review changed files for repo hygiene, including secrets, tokens, emails, and machine-specific paths before any commit

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Depends on Setup and blocks user-story work
- **User Story 1 (Phase 3)**: Starts after Foundational and defines the browser MVP
- **User Story 2 (Phase 4)**: Starts after Foundational and builds on browser playability and pause flow
- **User Story 3 (Phase 5)**: Starts after browser export basics are in place; best implemented after US1 and US2 are stable enough to publish
- **Polish (Phase 6)**: Starts after the desired user stories are implemented

### User Story Dependencies

- **US1**: Depends on shared browser export and framing foundations
- **US2**: Depends on the pause flow and browser/runtime fullscreen integration
- **US3**: Depends on having a working web export path worth publishing

### Parallel Opportunities

- T002 and T003 can run in parallel during setup
- T005 and T006 can run in parallel during foundational work
- T007 and T009 can run in parallel once the web export path exists
- T011 and T013 can run in parallel around the pause UI work
- T017 and T021 can run in parallel once the publish-path behavior is defined

## Implementation Strategy

### MVP First

1. Add the web export and browser support foundations
2. Make the current sandbox loop playable in desktop Chrome
3. Add paused fullscreen controls and state handling
4. Validate Chrome playability before adding the optional publish helper

### Incremental Delivery

1. Deliver browser play parity in desktop Chrome
2. Deliver paused fullscreen entry or exit with proper visibility rules
3. Add the optional GitHub Pages publish helper on top of the working web build
4. Re-run desktop and browser validation before sign-off

## Notes

- Keep browser support layered onto the existing gameplay rules rather than splitting gameplay paths
- Keep browser-only logic narrow and explicit
- Treat the custom HTML shell as a fallback for browser fullscreen restrictions, not as a second gameplay implementation
- Keep generated web artifacts out of normal working branches
