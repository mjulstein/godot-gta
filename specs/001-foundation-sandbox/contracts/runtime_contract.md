[root](../../../README.md) / [specs](../../README.md) / [001-foundation-sandbox](../README.md) / [contracts](./) / runtime_contract.md

# Runtime Contract: Foundation Sandbox

## Purpose

Capture the runtime-facing interfaces this slice already exposes so implementation changes preserve the playable loop and validation surface.

## Entry Surface

- Primary scene entry: `scenes/main/game.tscn`
- Project run target: `project.godot` `run/main_scene = res://scenes/main/game.tscn`
- Minimum boot validation: `HOME=/tmp/godot-home godot --headless --path . --quit-after 1`

## Input Action Contract

The playable slice must continue to provide these action names because player control, mobile HUD wiring, and manual test docs depend on them:

- `move_up`
- `move_down`
- `move_left`
- `move_right`
- `interact`
- `accelerate`
- `brake`
- `steer_left`
- `steer_right`
- `pause`
- `debug_overlay`
- `debug_camera`
- `toggle_mobile_controls`
- `toggle_fullscreen`

## Gameplay Contract

- On-foot control remains direct top-down movement and does not require throttle or steering inputs.
- Civilian vehicle takeover succeeds only when the target vehicle is stopped or moving at walking pace.
- Vehicle entry, exit, and displaced-occupant placement fail cleanly when blocked instead of teleporting to fallback positions.
- Pedestrians remain on sidewalk or crosswalk space by default and wait at crossings when traffic is not yielding clearly.
- Civilian traffic stays in valid lanes, yields with readable stopping distance, and only despawns for lifecycle or recovery while off-screen.

## Debug Contract

Development builds must keep enough debug visibility to inspect:

- active control mode
- interaction hint and takeover state
- inspected vehicle motion stats for both player and civilian vehicles
- collision state
- pedestrian and traffic state summaries needed to diagnose crossing or lane issues

## Validation Contract

The slice is not complete unless these validation surfaces remain usable:

- `tests/manual/us1_playable_core.md`
- `tests/manual/us2_takeover_impacts.md`
- headless boot validation from the repo root

Manual docs may evolve, but they must continue to cover on-foot movement, traffic readability, takeover, and momentum impact behavior.
