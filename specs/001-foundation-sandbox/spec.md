[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / spec.md

# Feature Specification: Foundation Sandbox

**Feature Branch**: `001-foundation-sandbox`  
**Created**: 2026-03-14  
**Status**: Draft  
**Input**: User description: "I want to create a Godot-based top-down GTA 2 clone. Start by setting up Spec Kit and drafting the initial project direction."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Move, steal, and survive in the city (Priority: P1)

As a player, I can walk around a compact city block, enter a vehicle, drive it, collide with the environment, and escape immediate danger so that the game already feels like a playable top-down crime sandbox.

**Why this priority**: This is the core fantasy. If on-foot movement, vehicle entry, and driving do not work together, the project does not yet feel like the intended game.

**Independent Test**: Launch the playable district, move on foot, enter a nearby vehicle, drive through streets and obstacles, exit the vehicle, and continue exploring without reloading the scene.

**Acceptance Scenarios**:

1. **Given** the player starts in the district on foot, **When** the player uses movement input, **Then** the character moves responsively relative to the top-down camera and collides correctly with world geometry.
2. **Given** an enterable parked vehicle is nearby, **When** the player enters it, **Then** control transfers from the pedestrian to the vehicle and the camera continues to frame the active actor clearly.
3. **Given** the player is driving, **When** the vehicle hits props, traffic, or walls, **Then** collision feedback is readable and the vehicle remains controllable unless destroyed or disabled by defined rules.

---

### User Story 2 - Trigger and evade police response (Priority: P2)

As a player, I can commit simple crimes such as assaulting pedestrians, stealing a vehicle, or colliding with civilians, and the police react with escalating pressure that I can try to evade.

**Why this priority**: A GTA-like sandbox needs consequence and pursuit. Wanted-level pressure turns free movement into emergent play rather than a static driving demo.

**Independent Test**: Start a clean session, commit one crime, observe police spawn or engagement behavior, break line of sight or leave the search zone, and verify the wanted state can return to neutral.

**Acceptance Scenarios**:

1. **Given** the player has no wanted status, **When** the player steals a civilian vehicle in view of witnesses, **Then** the wanted meter increases and police begin searching or engaging within a defined response window.
2. **Given** the player is wanted, **When** the player escapes the active pursuit conditions for long enough, **Then** the wanted state decreases and eventually clears.

---

### Edge Cases

- What happens when the player tries to enter a vehicle that is moving, occupied, destroyed, or blocked by level geometry?
- What happens when the active vehicle is flipped, trapped, submerged, or too damaged to continue?
- How does police spawning behave when nearby roads are blocked or no valid spawn points are available near the player?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST provide a playable top-down district with roads, sidewalks, obstacles, and enterable vehicles that support the core sandbox loop.
- **FR-002**: The player MUST be able to move on foot with responsive acceleration, facing, collision, and interaction prompts appropriate for a top-down camera.
- **FR-003**: The player MUST be able to enter and exit supported vehicles without scene reloads or control loss.
- **FR-004**: The driving model MUST support acceleration, braking, steering, collision response, and distinct handling from on-foot movement.
- **FR-005**: The camera MUST keep the active player-controlled actor readable during on-foot and vehicle gameplay.
- **FR-006**: The district MUST contain civilian traffic and or pedestrians sufficient to create believable street activity in the playable area.
- **FR-007**: The game MUST detect at least the following crime events: vehicle theft, pedestrian assault, and harmful collisions involving civilians.
- **FR-008**: The game MUST track a wanted state that can increase from crime events and decrease when pursuit conditions are no longer met.
- **FR-009**: Police units MUST be able to spawn, navigate toward the player, and apply pressure appropriate to the current wanted state.
- **FR-010**: The game MUST expose debugging aids for at least actor state and wanted state during development builds.
- **FR-011**: The project MUST use original placeholder or final content for art, naming, UI text, audio, and narrative elements rather than copied GTA assets.
- **FR-012**: Core gameplay tuning values for movement, driving, and police escalation SHOULD be editable without rewriting core system logic.

### Key Entities *(include if feature involves data)*

- **Player Actor**: The currently controlled character or vehicle, including movement state, health or defeat state, current wanted status, and interaction context.
- **Vehicle**: A drivable world actor with seat availability, handling values, damage state, occupancy state, and ownership or faction context.
- **Civilian Actor**: A pedestrian or non-police vehicle participant used to populate the city and act as witnesses, traffic, or incidental hazards.
- **Police Unit**: A law-enforcement actor with patrol, search, and pursuit state, spawn rules, escalation level, and target tracking behavior.
- **Crime Event**: A recorded gameplay event that may affect wanted level, witness response, and police dispatch behavior.
- **District Slice**: The playable city area including roads, intersections, spawn points, and navigation constraints.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new player can begin a run, move on foot, enter a vehicle, and drive within 60 seconds of launching the playable scene.
- **SC-002**: In manual playtests, the police response triggers correctly for the defined crime set in at least 9 out of 10 attempts.
- **SC-003**: In manual playtests, the wanted state can be both escalated and cleared without restarting the scene in at least 9 out of 10 attempts.
- **SC-004**: At least 80% of internal playtest notes for the first vertical slice rate movement, driving, camera readability, and pursuit clarity as clear enough to continue building on.
