[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / tasks.md

# Tasks: Foundation Sandbox

**Input**: Design documents from `/specs/001-foundation-sandbox/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: This slice uses headless boot and reproducible manual playtests in Godot rather than a broad automated suite. Tasks below include validation and debug-support work where the spec requires it.

**Organization**: Tasks are grouped by user story so each story remains independently playable and reviewable.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel when capacity exists
- **[Story]**: Which user story the task belongs to
- Paths use the Godot project structure defined in `plan.md`

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Establish the project shell, runtime entry points, and top-level tooling the slice depends on

- [x] T001 Create the baseline Godot project files at `project.godot` and `icon.svg`
- [x] T002 Create the directory structure from the plan under `scenes/`, `scripts/`, `data/`, `assets/`, and `tests/`
- [x] T003 [P] Configure project input actions in `project.godot` for movement, interact, vehicle entry or exit, driving, pause, and debug toggles
- [x] T004 [P] Create the root playable scene in `scenes/main/game.tscn` and bootstrap orchestration in `scripts/core/game_root.gd`
- [x] T005 [P] Create the baseline debug overlay scene in `scenes/ui/debug_overlay.tscn` and controller logic in `scripts/ui/debug_overlay.gd`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Build core systems that every story depends on

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

**Goal**: Deliver a readable top-down district where on-foot movement, pedestrians, and civilian traffic all support a believable sandbox baseline

**Independent Test**: Launch the main scene, walk the district, and verify that on-foot control stays direct while pedestrians stay on valid walk space, crossings remain readable, and civilian traffic follows lanes and yields cleanly

### Implementation for User Story 1

- [x] T013 [P] [US1] Build the first pass of roads, sidewalks, crossings, and blocking geometry in `scenes/world/district_slice.tscn`
- [x] T014 [P] [US1] Create the player scene at `scenes/actors/player/player.tscn`
- [x] T015 [US1] Implement top-down player movement and interaction logic in `scripts/actors/player/player_controller.gd`
- [x] T016 [P] [US1] Create the base civilian vehicle scene at `scenes/vehicles/civilian/civilian_vehicle.tscn`
- [x] T017 [US1] Implement shared vehicle handling and occupancy hooks in `scripts/vehicles/vehicle_controller.gd`
- [x] T018 [US1] Connect camera ownership switching between the player and active vehicle in `scripts/core/follow_camera.gd`
- [x] T019 [US1] Wire the district, player, vehicle, camera, and debug overlay together in `scenes/main/game.tscn`
- [x] T020 [US1] Refactor civilian pedestrian states to enforce `sidewalk_walk`, `curb_wait`, `crosswalk_cross`, and `social_follow` behavior in `scripts/ai/pedestrian/civilian/pedestrian_ai.gd`
- [x] T021 [US1] Add local terrain assessment, sidewalk-side preference, and short sidestep or wait recovery for pedestrians in `scripts/ai/pedestrian/civilian/pedestrian_ai.gd`
- [x] T022 [US1] Tighten civilian pedestrian spawn placement to curb-adjacent sidewalk space using tile-local activity data in `scripts/world/district_activity_overlay.gd` and `scenes/world/district_slice.tscn`
- [x] T023 [US1] Rework civilian traffic lane following to use local sensing plus next-crossing decisions instead of route ownership in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [x] T024 [US1] Improve crossing approach and pedestrian yield timing so traffic stops with readable distance in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd` and `data/tuning/civilian_vehicle_tuning.tres`
- [ ] T025 [US1] Add dead-end parking lot resolution so civilian drivers either park and convert to pedestrians or perform a U-turn in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`, `scripts/world/district_activity_overlay.gd`, and `scenes/world/district_slice.tscn`
- [ ] T026 [US1] Improve district readability with placeholder signage, landmarks, and collision cleanup in `scenes/world/district_slice.tscn`
- [x] T027 [US1] Update the readable city movement and crossing validation checklist in `tests/manual/us1_playable_core.md`

**Checkpoint**: User Story 1 is playable and validates the readable city-navigation loop on its own

---

## Phase 4: User Story 2 - Take over traffic and hit with momentum (Priority: P2)

**Goal**: Support civilian vehicle takeover, blocked-entry handling, unusable-vehicle exits, and momentum-based impacts without breaking the readable sandbox loop

**Independent Test**: Start on foot, approach an enterable civilian vehicle, take it over, confirm a displaced occupant remains in the world, drive into pedestrians with momentum-based impacts, and verify entry or exit edge cases fail cleanly

### Implementation for User Story 2

- [x] T028 [P] [US2] Create civilian pedestrian and traffic placeholder scenes in `scenes/actors/civilians/` and `scenes/vehicles/civilian/`
- [x] T029 [US2] Implement the baseline civilian pedestrian and traffic behavior in `scripts/ai/pedestrian/civilian/pedestrian_ai.gd` and `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [x] T030 [US2] Implement player takeover of civilian vehicles while leaving a displaced pedestrian occupant in `scripts/systems/vehicle_interaction_system.gd` and `scripts/actors/player/player_controller.gd`
- [x] T031 [US2] Add momentum-based vehicle-to-pedestrian collision response in `scripts/vehicles/vehicle_controller.gd` and `scripts/ai/pedestrian/civilian/pedestrian_ai.gd`
- [x] T032 [US2] Expose debug state for takeover and collision momentum through `scripts/ui/debug_overlay.gd`
- [x] T033 [US2] Wire civilian spawns and takeover-ready occupied vehicles into `scenes/world/district_slice.tscn`
- [x] T034 [US2] Reject entry attempts for destroyed vehicles or blocked entry sides in `scripts/systems/vehicle_interaction_system.gd` and `scripts/vehicles/vehicle_controller.gd`
- [ ] T035 [US2] Enforce unusable-vehicle state transitions for flipped, trapped, submerged, or critically damaged vehicles in `scripts/vehicles/vehicle_controller.gd`
- [x] T036 [US2] Keep the player inside unusable vehicles until a valid exit space exists and cancel blocked exits or displaced spawns cleanly in `scripts/systems/vehicle_interaction_system.gd`, `scripts/vehicles/vehicle_controller.gd`, and `scripts/actors/player/player_controller.gd`
- [x] T037 [US2] Update debug outputs so inspected civilian vehicles expose the same motion metrics as the player vehicle in `scripts/core/debug_state.gd` and `scripts/ui/debug_overlay.gd`
- [x] T038 [US2] Document repeatable takeover, blocked-entry, unusable-vehicle, and impact validation steps in `tests/manual/us2_takeover_impacts.md`

**Checkpoint**: User Stories 1 and 2 work together, including takeover and impact edge cases

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Finish tuning, recovery behavior, validation, and handoff for the full sandbox baseline

- [ ] T039 [P] Tune player movement so on-foot control stays direct, human-scale, and only lightly carries momentum in `scripts/actors/player/player_controller.gd` and `data/tuning/player_tuning.tres`
- [ ] T040 [P] Tune civilian traffic cruise speed, turn braking, and shared vehicle handling values in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`, `scripts/vehicles/vehicle_controller.gd`, and `data/tuning/civilian_vehicle_tuning.tres`
- [ ] T041 Add civilian traffic obstruction recovery with lane change, turn, or left-lane U-turn behavior in `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd` and `scripts/world/district_activity_overlay.gd`
- [x] T042 [P] Keep civilian traffic spawn and despawn transitions off-screen in `scripts/world/district_activity_overlay.gd` and `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
- [x] T043 Improve debug overlay clarity and add missing state outputs in `scripts/ui/debug_overlay.gd`
- [x] T044 [P] Update the project quickstart and workflow notes in `specs/001-foundation-sandbox/quickstart.md`
- [ ] T045 Run the headless boot gate and full manual validation for US1 and US2, then record results in `tests/manual/us1_playable_core.md` and `tests/manual/us2_takeover_impacts.md`
- [x] T046 Update the active checkpoint, remaining risks, and next target in `specs/001-foundation-sandbox/handoff.md`
- [ ] T047 Verify and document slice sign-off for on-foot feel, vehicle feel, collision behavior, pedestrian readability, and civilian traffic behavior in `specs/001-foundation-sandbox/handoff.md` and `tests/manual/README.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: Starts immediately
- **Foundational (Phase 2)**: Depends on Setup and blocks all story work
- **User Story 1 (Phase 3)**: Starts after Foundational and defines the MVP
- **User Story 2 (Phase 4)**: Starts after Foundational, but integrates best once US1 is readable
- **Polish (Phase 5)**: Starts after desired user stories are implemented

### User Story Dependencies

- **US1**: No dependency on other stories after Foundational
- **US2**: Depends on shared actor, vehicle, and district systems from Foundational and should be validated against the readable US1 baseline

### Parallel Opportunities

- T003, T004, and T005 can run in parallel after project initialization
- T007, T008, T010, and T011 can run in parallel in the Foundational phase
- T020 and T023 can run in parallel once the current US1 baseline is stable enough for focused pedestrian and traffic refactors
- T022 and T026 can run in parallel because spawn placement and district readability touch different primary files
- T034 and T037 can run in parallel in US2 because entry validation and debug exposure have separate primary write scopes
- T039 and T040 can run in parallel during Polish after behavior correctness is back under control

---

## Parallel Example: User Story 1

```bash
Task: "Refactor civilian pedestrian states to enforce sidewalk_walk, curb_wait, crosswalk_cross, and social_follow behavior in scripts/ai/pedestrian/civilian/pedestrian_ai.gd"
Task: "Rework civilian traffic lane following to use local sensing plus next-crossing decisions instead of route ownership in scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd"

Task: "Tighten civilian pedestrian spawn placement to curb-adjacent sidewalk space using tile-local activity data in scripts/world/district_activity_overlay.gd and scenes/world/district_slice.tscn"
Task: "Improve district readability with placeholder signage, landmarks, and collision cleanup in scenes/world/district_slice.tscn"
```

---

## Parallel Example: User Story 2

```bash
Task: "Reject entry attempts for destroyed vehicles or blocked entry sides in scripts/systems/vehicle_interaction_system.gd and scripts/vehicles/vehicle_controller.gd"
Task: "Update debug outputs so inspected civilian vehicles expose the same motion metrics as the player vehicle in scripts/core/debug_state.gd and scripts/ui/debug_overlay.gd"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational
3. Complete the remaining US1 tasks
4. Stop and validate `tests/manual/us1_playable_core.md`

### Incremental Delivery

1. Finish the readable city baseline in US1
2. Add US2 edge-case completion for takeover and vehicle usability
3. Finish tuning, recovery behavior, validation, and handoff in Polish

### Suggested MVP Scope

The current MVP scope remains **User Story 1**. The shortest path is T020 through T027, with T024 and T025 carrying the highest risk for sandbox readability.

---

## Notes

- All tasks use the required checklist format with IDs, optional `[P]` markers, story labels where needed, and exact file paths
- Manual validation is part of the feature contract and should not be deferred past T045
- Keep district activity data limited to spawn placement and cadence rather than runtime route ownership
- Avoid adding police, mission, or progression scope before the slice passes sign-off
