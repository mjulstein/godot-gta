[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / spec.md

# Feature Specification: Foundation Sandbox

**Feature Branch**: `001-foundation-sandbox`  
**Created**: 2026-03-14  
**Status**: In Progress  
**Input**: User description: "I want to create a Godot-based top-down GTA 2 clone. Start by setting up Spec Kit and drafting the initial project direction."

## Clarifications

### Session 2026-04-06

- Q: When can the player take over a civilian vehicle? → A: The player can only enter civilian vehicles that are stopped or moving at walking pace.
- Q: What should happen when exit or displaced-occupant spawn space is blocked? → A: Cancel the exit or displaced-occupant spawn if no clear nearby spot exists.
- Q: What validation gate defines baseline sign-off for this slice? → A: The documented manual validation checklist must pass on desktop/headless boot plus playtest steps.
- Q: How should blocked civilian traffic recover? → A: Vehicles must recover locally using lane change, turn, or U-turn behavior, and may only despawn when off-screen.

### Session 2026-04-07

- Q: What happens when the active vehicle is flipped, trapped, submerged, or critically damaged? → A: The vehicle becomes unusable and the player must exit if possible.

### Session 2026-04-10

- Q: What happens when the player tries to enter a vehicle that is destroyed or blocked by level geometry? → A: Reject the entry attempt if the vehicle is destroyed or no valid entry side is reachable.
- Q: What happens if an unusable vehicle has no valid exit space? → A: The player remains in the unusable vehicle until a valid exit space becomes available.
- Q: How should pedestrian and traffic activity data guide movement after spawn? → A: Tile activity data is only for initial behavior such as spawn points and semi-random spawn cadence; once spawned, actors rely on local intuition to assess nearby terrain and move or turn away from danger.
- Q: How should civilian traffic decide where to go after spawn? → A: Use local lane-following and obstacle sensing after spawn, while picking road crossings as the next structural decisions.
- Q: How should pedestrians choose and keep a sidewalk side after spawn? → A: Each pedestrian chooses a side at spawn and keeps it unless forced to switch.
- Q: When should pedestrians initiate a road crossing? → A: Only at valid crossing points when their local forward intent would continue across the road and traffic is yielding clearly enough.
- Q: What should pedestrians do when forward space is blocked after spawn? → A: Try a short local turn or sidestep search, then wait briefly if no safe option exists.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Move through a living tile-based city (Priority: P1)

As a player, I can move through a compact top-down tile-based city where pedestrians and cars follow readable western traffic rules so that the world already feels like a coherent sandbox.

**Why this priority**: The sandbox has to read as a believable city before deeper systems matter. If streets, sidewalks, crossings, and traffic flow do not make sense, the rest of the game has no solid base.

**Independent Test**: Launch the playable district, move on foot through the city, observe pedestrians and civilian cars using valid lanes and crossings, and verify that the city can be navigated without breaking traffic readability.

**Acceptance Scenarios**:

1. **Given** the player starts in the district on foot, **When** the player uses movement input, **Then** the character moves responsively relative to the top-down camera, collides correctly with world geometry, and remains readable as a pedestrian rather than feeling vehicle-like.
2. **Given** civilian pedestrians are active, **When** they navigate the district, **Then** they remain on curb-adjacent sidewalks and crosswalks except when valid crossing behavior says otherwise.
3. **Given** civilian pedestrians share a sidewalk direction, **When** they move through the district, **Then** they may form readable social pairs or join a nearby flow, but SHOULD avoid expanding beyond two abreast in ways that block crossings or vehicle readability.
4. **Given** a civilian pedestrian reaches a crosswalk edge, **When** traffic is still approaching without slowing sufficiently, **Then** the pedestrian waits at the curb instead of stepping into the road.
5. **Given** civilian vehicles are active, **When** they drive the district, **Then** they stay on valid lanes, follow western traffic flow, and slow to reasonable speeds near crossings and turns.
6. **Given** a civilian driver reaches a dead-end parking-lot tile, **When** the route resolves at the lot, **Then** the driver either makes a U-turn or parks, exits the car, and becomes a roaming pedestrian on the curb-side sidewalk.

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

- The player cannot take over civilian vehicles that are moving faster than walking pace; those entry attempts are rejected without transferring control.
- Entry attempts fail when the target vehicle is destroyed or when no valid entry side is reachable because geometry blocks access.
- Flipped, trapped, submerged, or critically damaged vehicles become unusable; the player must exit if a clear exit space is available.
- If an unusable vehicle has no valid exit space, the player remains inside it until a valid exit space becomes available.
- If no clear nearby spot exists for a vehicle exit or displaced-occupant spawn, the action is canceled instead of teleporting the actor to a fallback location.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST provide a playable top-down district with roads, sidewalks, obstacles, and enterable vehicles that support the core sandbox loop.
- **FR-002**: The player MUST be able to move on foot with responsive acceleration, facing, collision, and interaction prompts appropriate for a top-down camera.
- **FR-002a**: On-foot movement MUST remain a separate movement model from vehicle driving, using direct top-down directional control rather than throttle and steering rules.
- **FR-002b**: Pedestrian movement speed MUST stay within believable human-scale limits for the district, while remaining responsive enough for play.
- **FR-002c**: Pedestrian movement MAY retain a small amount of directional carry when input changes abruptly, but any carry MUST remain light and SHOULD be tunable by underlying surface properties.
- **FR-003**: The player MUST be able to enter and exit supported vehicles without scene reloads or control loss.
- **FR-003a**: The player MUST be able to enter civilian vehicles from the world and leave a displaced pedestrian occupant behind when takeover rules say the car was occupied.
- **FR-003b**: The player MUST only be able to take over civilian vehicles when they are stopped or moving no faster than walking pace.
- **FR-003c**: Vehicle exit and displaced-occupant spawn actions MUST fail cleanly when no clear nearby placement space exists, rather than forcing a fallback teleport.
- **FR-003d**: Vehicle entry attempts MUST fail cleanly when the target vehicle is destroyed or when no valid entry side is reachable because of blocking geometry.
- **FR-004**: The driving model MUST support acceleration, braking, steering, collision response, and distinct handling from on-foot movement.
- **FR-004a**: All drivable vehicles MUST follow the same core motion rule-set, including throttle or brake driven longitudinal movement, steering-based heading change, and no self-driven rotation while effectively stationary.
- **FR-004b**: Vehicles that are flipped, trapped, submerged, or critically damaged MUST become unusable until the player exits, rather than auto-resetting or remaining controllable.
- **FR-004c**: If an unusable vehicle has no valid exit space, the player MUST remain in the vehicle until a valid exit space becomes available rather than being teleported to a fallback position.
- **FR-005**: The camera MUST keep the active player-controlled actor readable during on-foot and vehicle gameplay.
- **FR-006**: The district MUST contain civilian traffic and pedestrians sufficient to create believable street activity in the playable area.
- **FR-006b**: Pedestrian and traffic spawn density MUST be independently tunable by district so one area can skew toward foot traffic while another skews toward vehicle flow.
- **FR-006c**: Civilian pedestrian spawn points MUST stay on curb-adjacent sidewalk space rather than grass or open road space.
- **FR-006a**: Civilian traffic and pedestrians MUST follow readable western traffic rules, including lane usage, direction of travel, and crossing behavior appropriate to the tile-based district layout.
- **FR-006aa**: District activity data MUST only govern initial ambient behavior such as spawn placement and semi-random spawn timing, and MUST NOT be the runtime source of route ownership for spawned pedestrians.
- **FR-006ab**: After spawn, civilian traffic MUST use local lane-following and obstacle sensing rather than route ownership from district activity data, while choosing road crossings or equivalent road-graph decisions as its next structural navigation targets.
- **FR-006e**: Civilian pedestrians MUST prefer sidewalk travel over grass or open road space, and SHOULD only enter the road through valid crossing behavior.
- **FR-006ea**: After spawn, civilian pedestrians MUST navigate by local terrain assessment, with a lead pedestrian preferring forward progress, checking upcoming space for no-go conditions, and turning away when forward movement would enter danger or invalid walk space.
- **FR-006eb**: Each civilian pedestrian MUST choose a sidewalk-side preference at spawn and keep it unless local terrain, crowding, or crossing behavior forces a side switch.
- **FR-006ec**: Civilian pedestrians MUST only initiate road crossings at valid crossing points, and only when their local forward intent would continue across the road and approaching traffic is yielding clearly enough.
- **FR-006ed**: When forward pedestrian movement is blocked after spawn, the pedestrian MUST try a short local turn or sidestep search first, and only wait briefly when no safe nearby option exists.
- **FR-006f**: Civilian pedestrians MAY form social walking pairs or join nearby pedestrian flow when routes align, but SHOULD avoid stable formations wider than two abreast.
- **FR-006g**: Civilian pedestrians MUST wait at crosswalk or curb edges when approaching vehicles are not yielding clearly enough for a safe crossing.
- **FR-006h**: Civilian traffic MUST yield to pedestrians at crossings with enough stopping distance to keep the crossing behavior readable.
- **FR-006d**: Civilian drivers reaching dead-end parking-lot tiles MUST either perform a valid turnaround or park, leave the vehicle, and continue as a civilian pedestrian on nearby curb-adjacent sidewalk space.
- **FR-006i**: Blocked civilian traffic MUST attempt local recovery through lane change, turn, or U-turn behavior before despawn is considered.
- **FR-006j**: Civilian traffic despawn used for recovery or lifecycle management MUST only occur when the vehicle is off-screen.
- **FR-007**: Vehicle-to-pedestrian collisions MUST transfer momentum to the pedestrian and MUST NOT allow pedestrians to meaningfully push vehicles.
- **FR-008**: The game MUST expose debugging aids for at least actor state and shared vehicle-motion state during development builds.
- **FR-010a**: Development debugging MUST be able to inspect non-player vehicles using the same motion and handling metrics used for the player vehicle so civilian and player driving behavior can be compared directly.
- **FR-011**: The project MUST use original placeholder or final content for art, naming, UI text, audio, and narrative elements rather than copied GTA assets.
- **FR-012**: Core gameplay tuning values for movement, driving, traffic behavior, and pedestrian response SHOULD be editable without rewriting core system logic.
- **FR-013**: Baseline sign-off for this slice MUST require the documented manual validation checklist to pass, including headless boot validation and desktop playtest steps covering on-foot, traffic, takeover, and collision behavior.

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
- **SC-006**: Slice sign-off requires a passing headless boot check and completion of the documented manual validation checklist for US1 and US2 without unresolved blocker failures.
- **SC-007**: In manual playtests, blocked civilian traffic recovers with a visible lane change, turn, or U-turn in at least 9 out of 10 observed off-nominal encounters without on-screen despawn.
