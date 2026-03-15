[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / data-model.md

# Data Model: Foundation Sandbox

## Player Actor

- `control_mode: "on_foot" | "vehicle"`
- `world_position: Vector2`
- `facing_direction: float` - radians
- `velocity: Vector2`
- `health_state: HealthState`
- `interaction_target: StringName`
- `wanted_level: int`

## Vehicle

- `vehicle_id: Unique StringName`
- `vehicle_type: StringName`
- `world_position: Vector2`
- `heading: float` - radians
- `velocity: Vector2`
- `speed: float`
- `throttle_input: float` - normalized `0.0` to `1.0`
- `brake_input: float` - normalized `0.0` to `1.0`
- `steer_input: float` - normalized `-1.0` to `1.0`
- `occupancy_state: OccupancyState`
- `driver_actor_id: StringName`
- `handling_profile_id: Resource`
- `damage_state: DamageState`
- `is_enterable: bool`
- `is_reversing: bool`
- `debug_inspection_label: String`

## Civilian Actor

- `civilian_id: Unique StringName`
- `actor_type: "pedestrian" | "traffic_driver"`
- `world_position: Vector2`
- `behavior_state: CivilianBehaviorState`
- `panic_state: PanicState`
- `witness_state: WitnessState`

## Police Unit

- `unit_id: Unique StringName`
- `world_position: Vector2`
- `behavior_state: PoliceBehaviorState`
- `target_actor_id: StringName`
- `spawn_source: SpawnSource`
- `despawn_state: DespawnState`

## Crime Event

- `event_id: Unique StringName`
- `event_type: "vehicle_theft" | "assault" | "harmful_collision"`
- `source_actor_id: StringName`
- `target_actor_id: StringName`
- `world_position: Vector2`
- `timestamp: float`
- `witness_count: int`
- `wanted_value: int`

## District Slice

- `district_id: Unique StringName`
- `spawn_points: Array[Vector2]`
- `road_graph: Dictionary`
- `police_spawn_zones: Array[Rect2]`
- `civilian_spawn_zones: Array[Rect2]`

## Enum Types

- `HealthState = "healthy" | "downed" | "defeated"`
- `OccupancyState = "empty" | "occupied" | "disabled"`
- `DamageState = "intact" | "damaged" | "disabled"`
- `CivilianBehaviorState = "idle" | "walk" | "cross" | "drive" | "blocked" | "reroute"`
- `PanicState = "calm" | "alerted" | "panicked"`
- `WitnessState = "unaware" | "witnessing" | "reporting"`
- `PoliceBehaviorState = "patrol" | "search" | "chase" | "engage" | "cooldown"`
- `SpawnSource = "ambient_spawn" | "wanted_response" | "mission_spawn" | "recycle_spawn"`
- `DespawnState = "active" | "cooling_down" | "despawned"`

## Key Relationships

- One `Player Actor` may control one `Vehicle` at a time.
- All controllable or AI-driven `Vehicle` entities share one motion rule-set and differ primarily through handling profiles and intent sources.
- `Crime Event` objects modify player wanted state and may trigger `Police Unit` responses.
- The `District Slice` owns the placement data needed by civilians and police.
