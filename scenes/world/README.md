[root](../../README.md) / [scenes](../README.md) / world

# World Scenes

World scenes define layout, collision, spawn markers, and static presentation.

Current baseline:

- `base_level.tscn`: ASCII-driven tile layout root for stitching slices together
- `district_slice.tscn`: road-and-curb tile for the foundation sandbox slice
- `empty_ground_tile.tscn`: temporary ground-only filler tile for holes and outer empty space
- `overlays/`: layered building and activity overlay scenes
- `props/`: reusable world props and marker scenes

`district_slice.tscn` is parameterized with `open_north`, `open_south`, `open_east`, and `open_west` so instances can render different road profiles:

- `4` connections: intersection
- `3` connections: tee
- `2` opposite connections: continuous straight road
- `1` connection: dead-end road feeding a parking lot

Buildings and ambient activity are layered in separately by overlay scenes.

`base_level.tscn` uses layered ASCII maps:

- `tile_rows`
  - `D`: district road tile
  - `0`: empty ground tile
- `building_rows`
  - `0` to `9`: building density for that tile
- `activity_rows`
  - `0` to `9`: civilian and traffic density for that tile

Keep world layout readable from a top-down camera. Avoid embedding gameplay rules in the world scene where a system script can own them.
