[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / tasks.md

# Tasks: Foundation Sandbox

**Input**: Design documents from `/specs/001-foundation-sandbox/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md

**Tests**: This feature relies primarily on playable manual validation in Godot. Tasks below include manual verification checkpoints and development debug support rather than a large automated test suite.

**Organization**: Tasks are grouped by user story to preserve independently playable slices.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when capacity exists
- **[Story]**: Which user story the task belongs to
- Paths use the Godot project structure defined in `plan.md`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Initialize the Godot project and create the agreed repo structure

- [x] T001 Create the baseline Godot project files at `project.godot` and `icon.svg`
- [x] T002 Create the directory structure from the plan under `scenes/`, `scripts/`, `data/`, `assets/`, and `tests/`
- [x] T003 [P] Configure project input actions in `project.godot` for movement, interact, vehicle entry-exit, driving, pause, and debug overlay toggle
- [x] T004 [P] Create the root scene `scenes/main/game.tscn` and bootstrap script `scripts/core/game_root.gd`
- [x] T005 [P] Create a basic debug overlay scene at `scenes/ui/debug_overlay.tscn` and controller script `scripts/ui/debug_overlay.gd`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core systems required before any user story can be implemented cleanly

**⚠️ CRITICAL**: No user story work should begin until this phase is complete

- [x] T006 Create shared actor state definitions in `scripts/core/actor_state.gd`
- [x] T007 [P] Create reusable camera follow logic in `scripts/core/follow_camera.gd`
- [x] T008 [P] Create interaction detection utilities in `scripts/core/interaction_sensor.gd`
- [x] T009 Create tuning resources for player, vehicle, and wanted values under `data/tuning/`
- [x] T010 [P] Create the prototype district scene shell at `scenes/world/district_slice.tscn`
- [x] T011 [P] Create spawn-point marker scenes or scripts under `scenes/world/props/` and `scripts/core/`
- [x] T012 Implement debug state plumbing for player mode and vehicle inspection in `scripts/core/debug_state.gd`

**Checkpoint**: Project shell, shared systems, tuning resources, and debug foundations are ready

---

## Phase 3: User Story 1 - Move through a living tile-based city (Priority: P1) 🎯 MVP

**Goal**: Deliver a playable top-down tile-based district where the player can move on foot through readable sidewalks, crossings, and traffic lanes

**Independent Test**: Launch the main scene, walk around the district, and verify that the player can navigate the city while civilian pedestrians and cars follow readable western traffic rules

### Implementation for User Story 1

- [x] T013 [P] [US1] Build the first pass of roads, sidewalks, and blocking geometry in `scenes/world/district_slice.tscn`
- [x] T014 [P] [US1] Create the player scene at `scenes/actors/player/player.tscn`
- [x] T015 [US1] Implement top-down player movement and interaction logic in `scripts/actors/player/player_controller.gd`
- [x] T016 [P] [US1] Create the base vehicle scene at `scenes/vehicles/civilian/civilian_vehicle.tscn`
- [x] T017 [US1] Implement base vehicle handling and occupancy hooks in `scripts/vehicles/vehicle_controller.gd`
- [x] T018 [US1] Connect camera ownership switching between player and active vehicle in `scripts/core/follow_camera.gd`
- [x] T019 [US1] Wire the district, player, vehicle, camera, and debug overlay together in `scenes/main/game.tscn`
- [ ] T020 [US1] Tune civilian pedestrians and traffic so sidewalks, crossings, lane usage, and western traffic flow stay readable in `scripts/ai/pedestrian/civilian/pedestrian_ai.gd` and `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [ ] T021 [US1] Add validation notes for readable city movement, crossings, and traffic flow in `tests/manual/us1_playable_core.md`
- [x] T022 [US1] Document the manual MVP validation flow in `tests/manual/us1_playable_core.md`

**Checkpoint**: User Story 1 is playable and validates the city-navigation baseline

---

## Phase 4: User Story 2 - Take over traffic and hit with momentum (Priority: P2)

**Goal**: Add civilian vehicle takeover, displaced occupants, and momentum-based pedestrian impacts

**Independent Test**: Start on foot, enter a civilian vehicle, verify a pedestrian remains behind as the displaced occupant, drive through the district, and confirm pedestrians are displaced by vehicle momentum without pushing the vehicle back

### Implementation for User Story 2

- [x] T023 [P] [US2] Create civilian pedestrian and traffic placeholder scenes in `scenes/actors/civilians/` and `scenes/vehicles/civilian/`
- [x] T024 [US2] Implement simple civilian movement or traffic behavior in `scripts/ai/pedestrian/civilian/pedestrian_ai.gd` and `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [ ] T025 [US2] Upgrade civilian pedestrian movement so crossings and sidewalk use stay aligned with western traffic expectations in `scripts/ai/pedestrian/civilian/pedestrian_ai.gd`
- [ ] T026 [US2] Upgrade civilian vehicle behavior so lane usage, direction of travel, and crossing approach stay aligned with western traffic expectations in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [ ] T027 [US2] Implement player takeover of civilian vehicles while leaving a displaced pedestrian occupant in `scripts/systems/vehicle_interaction_system.gd` and `scripts/actors/player/player_controller.gd`
- [ ] T028 [US2] Add momentum-based vehicle-to-pedestrian collision response so pedestrians are displaced by vehicle motion and cannot push vehicles in `scripts/vehicles/vehicle_controller.gd` and pedestrian scripts
- [ ] T029 [US2] Expose debug state for takeover and collision momentum through `scripts/ui/debug_overlay.gd`
- [ ] T030 [US2] Wire civilian spawns and takeover-ready occupied vehicles into `scenes/world/district_slice.tscn`
- [ ] T031 [US2] Document repeatable traffic, takeover, and impact validation steps in `tests/manual/`

**Checkpoint**: User Stories 1 and 2 work together, and the city now supports the baseline sandbox loop

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Improve feel, readability, and handoff quality across the entire slice

- [ ] T041 [P] Tune player movement, vehicle handling, traffic response, and collision response values in `data/tuning/`
- [ ] T042 [P] Improve district readability with placeholder signage, landmarks, and collision cleanup in `scenes/world/district_slice.tscn`
- [ ] T043 Improve debug overlay clarity and add missing state outputs in `scripts/ui/debug_overlay.gd`
- [x] T044 [P] Update the project quickstart and workflow notes in `specs/001-foundation-sandbox/quickstart.md`
- [ ] T045 Run full manual validation for US1 and US2 and record results in `tests/manual/`
- [ ] T046 [P] Keep civilian traffic spawn and despawn transitions off-screen in `scripts/world/district_activity_overlay.gd` and `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [ ] T047 Tune civilian traffic speed targets so cars cruise faster than the player on long straights and brake for turns in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd` and `data/tuning/`
- [ ] T048 Improve civilian traffic stopping distance so cars hold at least half a car length before pedestrians, vehicles, and other forward obstacles in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [ ] T049 Add civilian traffic obstruction recovery so blocked cars can change lane, turn, or make a left-lane u-turn instead of stalling into collisions in `scripts/world/district_activity_overlay.gd` and `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [ ] T050 Tune pedestrian movement so on-foot control stays direct, human-scale, and distinct from vehicle handling, with only light carry on abrupt direction changes in `scripts/actors/player/player_controller.gd` and `data/tuning/`
- [ ] T051 Verify and document sandbox baseline sign-off for on-foot feel, vehicle feel, collision behavior, and civilian traffic behavior in `tests/manual/`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Depends on Setup and blocks all story work
- **User Story 1 (Phase 3)**: Starts after Foundational and defines the MVP
- **User Story 2 (Phase 4)**: Starts after Foundational, but integrates best once US1 is playable
- **Polish (Phase 5)**: Starts after desired user stories are implemented

### User Story Dependencies

- **US1**: No dependency on other stories after foundational work
- **US2**: Depends on shared actor and vehicle systems; should build on US1 scenes and control flow
### Parallel Opportunities

- T003, T004, and T005 can run in parallel after project initialization
- T007, T008, T010, and T011 can run in parallel in the foundational phase
- T013, T014, and T016 can run in parallel for US1
- T023 and T028 can run in parallel for US2
- Polish tuning and documentation tasks can be split once the slice is playable

## Implementation Strategy

### MVP First

1. Finish Setup
2. Finish Foundational work
3. Complete User Story 1
4. Validate the readable city-navigation loop before expanding scope

### Incremental Delivery

1. Deliver US1 as the first playable prototype
2. Layer in US2 to add takeover, momentum impacts, and stronger city interaction
3. Stabilize and tune the sandbox loop before promoting additional feature ideas into active scope

## Notes

- Prefer original placeholder art and names at every stage
- Keep debug visibility high while systems are still forming
- Resist adding police escalation, extra districts, weapons, factions, or mission systems before US1 and US2 are validated
