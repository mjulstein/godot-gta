# Godot GTA

Top-down crime sandbox prototype built in Godot 4.x.

## Status

Active feature branch: `001-foundation-sandbox`

Current implemented baseline:

- Godot project shell
- root game scene
- ASCII-tiled base world with district and empty-ground tiles
- player movement
- drivable vehicle
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

## World Layout

The current world root is [base_level.tscn](./scenes/world/base_level.tscn), which builds the playable area from one-character ASCII tile bindings:

- `D`: district slice
- `0`: empty ground tile

Current default layout:

```text
DDDDDD00
DD0DDD00
D000DDDD
0000DD00
```
