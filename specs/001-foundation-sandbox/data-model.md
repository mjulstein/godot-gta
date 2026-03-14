# Data Model: Foundation Sandbox

## Player Actor

- `control_mode`: on-foot or vehicle
- `world_position`
- `facing_direction`
- `velocity`
- `health_state`
- `interaction_target`
- `wanted_level`
- `active_mission_id`

## Vehicle

- `vehicle_id`
- `vehicle_type`
- `world_position`
- `heading`
- `velocity`
- `occupancy_state`
- `driver_actor_id`
- `handling_profile_id`
- `damage_state`
- `is_enterable`

## Civilian Actor

- `civilian_id`
- `actor_type`: pedestrian or traffic_driver
- `world_position`
- `behavior_state`
- `panic_state`
- `witness_state`

## Police Unit

- `unit_id`
- `world_position`
- `behavior_state`: patrol, search, chase, engage, cooldown
- `target_actor_id`
- `spawn_source`
- `despawn_state`

## Crime Event

- `event_id`
- `event_type`: vehicle_theft, assault, harmful_collision
- `source_actor_id`
- `target_actor_id`
- `world_position`
- `timestamp`
- `witness_count`
- `wanted_value`

## Mission Instance

- `mission_id`
- `mission_type`
- `state`: available, active, success, failed
- `objective_targets`
- `timer_state`
- `reward_definition`
- `failure_reason`

## District Slice

- `district_id`
- `spawn_points`
- `mission_anchors`
- `road_graph`
- `police_spawn_zones`
- `civilian_spawn_zones`

## Key Relationships

- One `Player Actor` may control one `Vehicle` at a time.
- `Crime Event` objects modify player wanted state and may trigger `Police Unit` responses.
- One active `Mission Instance` may depend on a specific `Vehicle`, actor, or destination marker.
- The `District Slice` owns the placement data needed by civilians, police, and missions.
