# Godot GTA

Top-down crime sandbox prototype built in Godot 4.x.

## Current Scope

The active feature branch is `001-foundation-sandbox`. The current implementation target is the first playable slice:

- on-foot movement
- vehicle entry and driving
- a compact test district
- debug overlay and project bootstrap

Police, civilians, and mission systems are specified but not fully implemented yet.

## Specs

Planning lives under [specs/001-foundation-sandbox](./specs/001-foundation-sandbox/README.md):

- [spec.md](specs/001-foundation-sandbox/spec.md)
- [plan.md](specs/001-foundation-sandbox/plan.md)
- [tasks.md](specs/001-foundation-sandbox/tasks.md)

The project constitution lives at [.specify/memory/constitution.md](.specify/memory/constitution.md).

## Project Layout

```text
project.godot
icon.svg
scenes/
scripts/
data/
assets/
tests/
specs/
```

Conventions:

- `scenes/` holds composition only
- `scripts/` holds gameplay logic, split by domain
- `data/` holds tunable resources and mission data
- `tests/manual/` holds reproducible playtest instructions
- `specs/` is the source of truth for scope and sequencing

## Running The Project

Open the repo in Godot 4.6+ and run `scenes/main/game.tscn`, or use:

```sh
godot --path .
```

For headless validation inside this workspace sandbox, use:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

## Current Controls

- `WASD`: move on foot / drive
- `E`: enter or exit vehicle
- `O`: toggle debug overlay
- `P`: reserved pause action

## Workflow

1. Update the relevant spec artifact first when scope changes.
2. Commit before switching between spec work and code work.
3. Implement tasks in priority order from [tasks.md](specs/001-foundation-sandbox/tasks.md).
4. Keep systems modular and scripts short.
5. Validate with Godot before committing code.
