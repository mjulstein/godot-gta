# Godot GTA

Top-down crime sandbox prototype built in Godot 4.x.

## Status

Current branch: `001-foundation-sandbox`

Current gameplay slice: `001-foundation-sandbox`

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
- always-on mobile HUD with joystick, action, and driving touch controls
- pause overlay controls for debug toggle, HUD opacity, input surface scale, impact vibration, and restart
- paused fullscreen toggle on `F` and in the pause overlay where fullscreen and windowed modes both make sense, including desktop Chrome web export
- local iOS project generation and device deploy helpers
- first-pass desktop Chrome web export target
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
- [Current handoff](./specs/001-foundation-sandbox/handoff.md)
- [Web browser play spec](./specs/003-web-browser-play/spec.md)
- [Idea backlog](./specs/ideas/README.md)

## Documentation Map

- [Project workflow and agent rules](./AGENTS.md)
- [Scenes](./scenes/README.md)
- [Scripts](./scripts/README.md)
- [Data](./data/README.md)
- [Assets](./assets/README.md)
- [iOS build helpers](./ios/README.md)
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

Web export target:

```sh
mkdir -p build/web
HOME=/tmp/godot-home godot --headless --path . --export-release Web build/web/index.html
```

## Controls

- `WASD`: move or drive
- `E`: enter or exit vehicle
- `O`: toggle debug overlay
- `P`: pause game and toggle palette key
- `C`: cycle traffic debug camera
- `E` while traffic camera is active: possess or return the tracked driver
- `M`: toggle the mobile HUD between hidden and the last visible opacity level
- `F` while paused: toggle fullscreen without unpausing

## Touch Controls

- lower-left joystick: move on foot or steer while driving, positioned slightly inward from the screen edge
- top-right `P`: trigger the same pause flow as keyboard `P`
- top-right `ACT` below `P`: trigger the same interaction path as keyboard `E`
- right-side vertical `GAS` / `BRK` drive surface: drag up to accelerate and down to brake while driving
- pause overlay buttons: debug toggle, HUD opacity, input scale, impact vibration, and restart
- pause overlay fullscreen button: the same paused-only fullscreen toggle as keyboard `F`, hidden on fullscreen-only contexts

## Browser Target

Initial browser support targets desktop Chrome only.

- Browser play uses the same gameplay actions and pause flow as desktop.
- Window resize and fullscreen should preserve the fixed framed view instead of revealing extra world.
- The documented browser fullscreen path is the in-game pause overlay button, with paused `F` as the matching shortcut.
- Fullscreen toggling is only supported from the paused flow so the request stays in a live input event path for web exports.

## Publish

Manual GitHub Pages publish helper for testing the current web build online:

```sh
./publish_web_docs.sh
```

Notes:

- The publish helper is a repository utility, not part of `001-foundation-sandbox`.
- The publish helper is a repository utility for publishing the current web build to GitHub Pages so the live browser build can be tested outside the local machine.
- The script exports the `Web` preset to a temporary directory.
- It force-pushes a dedicated publish branch, defaulting to `docs`, with site files under `docs/`.
- It requires a clean working tree.
- It leaves generated web artifacts out of feature branches and restores the starting branch if anything changes during publish.

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
