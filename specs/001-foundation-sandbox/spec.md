[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / spec.md

# Feature Specification: Foundation Sandbox

**Feature Branch**: `001-foundation-sandbox`  
**Created**: 2026-03-14  
**Status**: In Progress  
**Input**: User description: "I want to create a Godot-based top-down GTA 2 clone. Start by setting up Spec Kit and drafting the initial project direction."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Move through a living tile-based city (Priority: P1)

As a player, I can move through a compact top-down tile-based city where pedestrians and cars follow readable western traffic rules so that the world already feels like a coherent sandbox.

**Why this priority**: The sandbox has to read as a believable city before deeper systems matter. If streets, sidewalks, crossings, and traffic flow do not make sense, the rest of the game has no solid base.

**Independent Test**: Launch the playable district, move on foot through the city, observe pedestrians and civilian cars using valid lanes and crossings, and verify that the city can be navigated without breaking traffic readability.

**Acceptance Scenarios**:

1. **Given** the player starts in the district on foot, **When** the player uses movement input, **Then** the character moves responsively relative to the top-down camera, collides correctly with world geometry, and remains readable as a pedestrian rather than feeling vehicle-like.
2. **Given** civilian pedestrians are active, **When** they navigate the district, **Then** they remain on curb-adjacent sidewalks and crosswalks except when valid crossing behavior says otherwise.
3. **Given** civilian vehicles are active, **When** they drive the district, **Then** they stay on valid lanes, follow western traffic flow, and slow to reasonable speeds near crossings and turns.

---

### User Story 2 - Take over traffic and hit with momentum (Priority: P2)

As a player, I can walk to a civilian car, enter it, leave a pedestrian behind in the world, and hit pedestrians with momentum-based vehicle impacts so that takeover and collision behavior support the core sandbox loop.

**Why this priority**: Vehicle takeover and collision response are the clearest tests of whether the sandbox rules feel consistent. They depend on the city simulation already being readable, but they do not require police or broader mission systems yet.

**Independent Test**: Start on foot, approach any enterable civilian car, take it over, confirm a pedestrian remains in place, then drive into pedestrians and verify they are displaced according to vehicle momentum.

**Acceptance Scenarios**:

1. **Given** a civilian vehicle is available, **When** the player enters it, **Then** control transfers cleanly to the vehicle and the displaced occupant is represented as a pedestrian left in the world.
2. **Given** the player is driving, **When** the vehicle collides with a pedestrian, **Then** the pedestrian is launched or displaced according to the vehicle's momentum and the pedestrian does not meaningfully push the vehicle back.
3. **Given** the player exits the vehicle, **When** control returns to on-foot movement, **Then** the player can continue navigating the city without scene reload or actor-state corruption.

---

### Edge Cases

- What happens when the player tries to enter a vehicle that is moving, occupied, destroyed, or blocked by level geometry?
- What happens when the active vehicle is flipped, trapped, submerged, or too damaged to continue?
- How should displaced occupants be spawned if the driver's side is blocked by geometry or another actor?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST provide a playable top-down district with roads, sidewalks, obstacles, and enterable vehicles that support the core sandbox loop.
- **FR-002**: The player MUST be able to move on foot with responsive acceleration, facing, collision, and interaction prompts appropriate for a top-down camera.
- **FR-002a**: On-foot movement MUST remain a separate movement model from vehicle driving, using direct top-down directional control rather than throttle and steering rules.
- **FR-002b**: Pedestrian movement speed MUST stay within believable human-scale limits for the district, while remaining responsive enough for play.
- **FR-002c**: Pedestrian movement MAY retain a small amount of directional carry when input changes abruptly, but any carry MUST remain light and SHOULD be tunable by underlying surface properties.
- **FR-003**: The player MUST be able to enter and exit supported vehicles without scene reloads or control loss.
- **FR-003a**: The player MUST be able to enter civilian vehicles from the world and leave a displaced pedestrian occupant behind when takeover rules say the car was occupied.
- **FR-004**: The driving model MUST support acceleration, braking, steering, collision response, and distinct handling from on-foot movement.
- **FR-004a**: All drivable vehicles MUST follow the same core motion rule-set, including throttle or brake driven longitudinal movement, steering-based heading change, and no self-driven rotation while effectively stationary.
- **FR-005**: The camera MUST keep the active player-controlled actor readable during on-foot and vehicle gameplay.
- **FR-006**: The district MUST contain civilian traffic and pedestrians sufficient to create believable street activity in the playable area.
- **FR-006b**: Pedestrian and traffic spawn density MUST be independently tunable by district so one area can skew toward foot traffic while another skews toward vehicle flow.
- **FR-006c**: Civilian pedestrian spawn points MUST stay on curb-adjacent sidewalk space rather than grass or open road space.
- **FR-006a**: Civilian traffic and pedestrians MUST follow readable western traffic rules, including lane usage, direction of travel, and crossing behavior appropriate to the tile-based district layout.
- **FR-007**: Vehicle-to-pedestrian collisions MUST transfer momentum to the pedestrian and MUST NOT allow pedestrians to meaningfully push vehicles.
- **FR-008**: The game MUST expose debugging aids for at least actor state and shared vehicle-motion state during development builds.
- **FR-010a**: Development debugging MUST be able to inspect non-player vehicles using the same motion and handling metrics used for the player vehicle so civilian and player driving behavior can be compared directly.
- **FR-011**: The project MUST use original placeholder or final content for art, naming, UI text, audio, and narrative elements rather than copied GTA assets.
- **FR-012**: Core gameplay tuning values for movement, driving, traffic behavior, and pedestrian response SHOULD be editable without rewriting core system logic.

### Key Entities *(include if feature involves data)*

- **Player Actor**: The currently controlled character or vehicle, including movement state and interaction context.
- **Pedestrian Movement Model**: Shared pedestrian movement expectations covering direct directional control, human-scale top speed, limited carry, and optional surface-dependent traction tuning.
- **Vehicle**: A drivable world actor with seat availability, handling values, damage state, occupancy state, and ownership or faction context.
- **Vehicle Motion Rule Set**: Shared vehicle movement rules covering throttle, brake, steering, collision response, low-speed rotation limits, and debug-visible runtime stats for any inspected vehicle.
- **Civilian Actor**: A pedestrian or non-player vehicle participant used to populate the city and act as traffic participants, displaced occupants, or incidental hazards.
- **District Slice**: The playable city area including roads, intersections, spawn points, and navigation constraints.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new player can begin a run, move on foot, enter a vehicle, and drive within 60 seconds of launching the playable scene.
- **SC-002**: In manual playtests, pedestrians and civilian vehicles follow readable western traffic flow across the district in at least 9 out of 10 observed runs.
- **SC-003**: In manual playtests, the player can take over a civilian vehicle and continue the loop without broken state in at least 9 out of 10 attempts.
- **SC-004**: In manual playtests, vehicle-to-pedestrian impacts produce readable momentum-based displacement in at least 9 out of 10 attempts.
- **SC-005**: The foundation sandbox slice is not considered complete until on-foot feel, vehicle feel, collision behavior, and baseline traffic behavior are manually reviewed together and accepted as a stable base for further features.
