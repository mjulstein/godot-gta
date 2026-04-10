[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / data-model.md

# Data Model: Foundation Sandbox

## Player Actor

- `actor_id: StringName`
- `control_mode: "on_foot" | "driving"`
- `world_position: Vector2`
- `facing_direction: float`
- `velocity: Vector2`
- `interaction_target_id: StringName`
- `current_vehicle_id: StringName`
- `movement_profile: Resource`
- `is_pause_blocked: bool`

**Validation rules**

- `control_mode` is `driving` only when `current_vehicle_id` is valid.
- On-foot movement uses direct directional input and cannot reuse vehicle throttle or steering logic.
- Vehicle handoff must not require scene reload or actor recreation.

## Player Movement Model

- `max_speed: float`
- `acceleration: float`
- `deceleration: float`
- `directional_carry: float`
- `surface_grip_scale: float`

**Validation rules**

- Speed remains human-scale relative to district roads and sidewalks.
- `directional_carry` stays light and tunable, not vehicle-like.

## Vehicle

- `vehicle_id: StringName`
- `vehicle_type: StringName`
- `world_position: Vector2`
- `heading: float`
- `velocity: Vector2`
- `speed: float`
- `occupancy_state: "empty" | "civilian_driver" | "player_driver"`
- `usability_state: "usable" | "blocked_entry" | "blocked_exit" | "destroyed" | "unusable"`
- `handling_profile: Resource`
- `damage_state: "intact" | "damaged" | "critical"`
- `collision_state: "clear" | "impacting" | "recovering"`
- `last_valid_exit_positions: Array[Vector2]`

**Validation rules**

- Entry is rejected when the vehicle is destroyed or no valid entry side is reachable.
- Civilian takeover is allowed only when the vehicle is stopped or moving at walking pace.
- If the vehicle becomes unusable and no valid exit exists, the player remains in the vehicle.

## Civilian Pedestrian

- `pedestrian_id: StringName`
- `world_position: Vector2`
- `state: "idle" | "sidewalk_walk" | "curb_wait" | "crosswalk_cross" | "social_follow" | "displaced"`
- `forward_intent: Vector2`
- `terrain_probe: Dictionary`
- `danger_memory: Array[Vector2]`
- `target_crosswalk_id: StringName`
- `group_anchor_id: StringName`
- `paired_partner_id: StringName`
- `preferred_sidewalk_side: String`
- `spawn_source: "ambient" | "displaced_occupant" | "parked_driver"`
- `is_on_valid_walk_surface: bool`

**Validation rules**

- Ambient or parked-driver spawns must resolve onto curb-adjacent sidewalk space.
- Pedestrians stay on sidewalks or crosswalks unless displaced by impact.
- After spawn, pedestrians choose movement from local terrain assessment rather than pre-owned tile routes.
- Stable social formations cannot exceed two abreast.

## Civilian Traffic Agent

- `traffic_actor_id: StringName`
- `vehicle_id: StringName`
- `state: "cruise" | "approach_crossing" | "yield" | "stopped" | "recover" | "park" | "u_turn" | "despawn_pending"`
- `lane_id: StringName`
- `next_crossing_id: StringName`
- `local_obstacle_snapshot: Dictionary`
- `desired_speed: float`
- `stopping_buffer: float`
- `recovery_mode: "none" | "lane_change" | "turn" | "u_turn"`
- `offscreen_ready: bool`

**Validation rules**

- Traffic stays on valid lanes and western flow directions.
- After spawn, traffic relies on local lane-following and obstacle sensing rather than long-lived route ownership from district activity tiles.
- Yielding must leave readable stopping distance before pedestrians and forward obstacles.
- Recovery despawn is only legal when `offscreen_ready` is true.

## District Slice

- `district_id: StringName`
- `level_scene: String`
- `activity_tiles: Dictionary`
- `activity_spawn_interval_range: Vector2`
- `pedestrian_spawn_points: Array[Vector2]`
- `traffic_spawn_points: Array[Vector2]`
- `crosswalk_segments: Array[StringName]`
- `lane_segments: Array[StringName]`
- `parking_lot_tiles: Array[Vector2i]`

**Validation rules**

- Activity data distinguishes sidewalk, road, crosswalk, and blocked space for ambient spawning and nearby terrain assessment.
- Spawn points and lane data must support the manual validation paths in `tests/manual/`.

## Debug State Snapshot

- `active_control_mode: String`
- `active_vehicle_id: StringName`
- `tracked_vehicle_metrics: Dictionary`
- `pedestrian_state_counts: Dictionary`
- `traffic_state_counts: Dictionary`
- `interaction_hint: String`
- `takeover_state: String`
- `collision_state: String`

**Validation rules**

- The overlay must expose enough state to compare player and civilian vehicle behavior directly.
- Snapshot fields should be derivable from live gameplay state without hidden debug-only logic.

## Relationships

- One `Player Actor` controls zero or one `Vehicle`.
- Each `Civilian Traffic Agent` owns exactly one active `Vehicle` while driving.
- A `Civilian Pedestrian` may become a displaced occupant when the player takes over a civilian vehicle.
- The `District Slice` supplies spawn activity, crossing, lane, and nearby terrain data to pedestrian and traffic agents.
- `Debug State Snapshot` aggregates runtime state from player, vehicle, pedestrian, and traffic systems without becoming the source of truth for gameplay.

## State Transitions

- `Player Actor`: `on_foot -> driving -> on_foot`
- `Civilian Pedestrian`: `idle -> sidewalk_walk -> curb_wait -> crosswalk_cross -> sidewalk_walk`, with local turn or avoid decisions inside movement states and `displaced` as an interrupt state
- `Civilian Traffic Agent`: `cruise -> approach_crossing -> yield -> stopped -> cruise`, with `recover`, `park`, or `u_turn` used for blocked or dead-end cases
- `Vehicle`: `usable -> unusable` when critically damaged, trapped, flipped, or submerged; `unusable -> usable` only after the player exits and the vehicle state is valid again
