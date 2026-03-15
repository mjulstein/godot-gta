# Godot GTA

Top-down crime sandbox prototype built in Godot 4.x.

## Status

Active feature branch: `001-foundation-sandbox`

Current implemented baseline:

- Godot project shell
- root game scene
- layered ASCII-tiled base world with road, building, and activity maps
- player movement
- drivable vehicle
- shared throttle and steering rule-set target for player and civilian vehicles
- follow camera with fixed viewport stretch, driving look-ahead, and speed-aware zoom
- debug overlay
- pause palette overlay
- first-pass civilian, wanted, and police response loop
- idea backlog for future features before they become active specs

## Role Key

The debug build uses a fixed role palette to keep actor reads consistent:

- Player: yellow
- Enterable civilian vehicle: orange
- Civilian pedestrians: green
- Civilian traffic: cyan
- Police actors and vehicles: blue
- Traffic barriers: orange with a pale stripe

The in-game palette key is a separate overlay with shaped icons instead of plain color names. Press `P` to pause the game and show or hide it.

## Specs

- [Constitution](./.specify/memory/constitution.md)
- [Feature spec](./specs/001-foundation-sandbox/spec.md)
- [Implementation plan](./specs/001-foundation-sandbox/plan.md)
- [Tasks](./specs/001-foundation-sandbox/tasks.md)
- [Idea backlog](./specs/ideas/README.md)

## Documentation Map

- [Project workflow and agent rules](./AGENTS.md)
- [Scenes](./scenes/README.md)
- [Scripts](./scripts/README.md)
- [Data](./data/README.md)
- [Assets](./assets/README.md)
- [Tests](./tests/README.md)
- [Specs](./specs/README.md)

## Run

Open the repo in Godot 4.6+ or run:

```sh
godot --path .
```

Headless validation in this workspace:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

## Controls

- `WASD`: move or drive
- `E`: enter or exit vehicle
- `O`: toggle debug overlay
- `P`: pause game and toggle palette key

## Vehicle Rules

The intended simulation rule is that all vehicles share the same core motion model:

- throttle or brake drives forward or reverse motion
- steering changes heading while the vehicle is actually moving
- AI and player vehicles differ by intent and tuning, not by separate physics rules
- debug tooling should be able to inspect civilian vehicles with the same movement stats used for the player vehicle

## World Layout

The current world root is [base_level.tscn](./scenes/world/base_level.tscn), which builds the playable area from layered ASCII maps:

- `tile_rows`
  - `D`: district road tile
  - `0`: empty ground tile
- `building_rows`
  - `0` to `9`: building density by tile
- `activity_rows`
  - `0` to `9`: civilian and traffic density by tile

Current default road layout:

```text
DDDDDD00
DD0DDD00
D000DDDD
0000DD00
```

Road tile profiles:

- `4` connections: intersection
- `3` connections: tee
- `2` opposite connections: continuous straight road
- `1` connection: dead-end road into a parking lot
