# Godot GTA

Top-down crime sandbox prototype built in Godot 4.x.

## Status

Active feature branch: `001-foundation-sandbox`

Current implemented baseline:

- Godot project shell
- root game scene
- compact district test map
- player movement
- drivable vehicle
- follow camera
- debug overlay

## Specs

- [Constitution](./.specify/memory/constitution.md)
- [Feature spec](./specs/001-foundation-sandbox/spec.md)
- [Implementation plan](./specs/001-foundation-sandbox/plan.md)
- [Tasks](./specs/001-foundation-sandbox/tasks.md)

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
- `P`: reserved pause action
