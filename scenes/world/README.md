[root](../../README.md) / [scenes](../README.md) / world

# World Scenes

World scenes define layout, collision, spawn markers, and static presentation.

Current baseline:

- `base_level.tscn`: ASCII-driven tile layout root for stitching slices together
- `district_slice.tscn`: compact test district for the foundation sandbox slice
- `empty_ground_tile.tscn`: temporary ground-only filler tile for holes and outer empty space
- `props/`: reusable world props and marker scenes

`district_slice.tscn` is parameterized with `open_north`, `open_south`, `open_east`, and `open_west` so instances can behave as center, edge, or corner tiles in a district grid. Closed exits swap the outgoing road for a sidewalk cap.

`base_level.tscn` uses one-character ASCII bindings for tile types. Current bindings:

- `D`: district slice
- `0`: empty ground tile

Keep world layout readable from a top-down camera. Avoid embedding gameplay rules in the world scene where a system script can own them.
