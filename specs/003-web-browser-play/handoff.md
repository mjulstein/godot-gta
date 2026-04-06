[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / handoff.md

# Handoff

This file is the quick re-entry point for any agent taking over work on `003-web-browser-play`.

## Current Focus

The active slice is still `003-web-browser-play`, and the browser/fullscreen work is implemented. The remaining work is merge-oriented validation and documentation cleanup.

In scope:

- browser export support for the existing sandbox loop
- parity with the current desktop gameplay flow, input rules, and camera framing
- a browser-friendly fullscreen path that only toggles while paused
- keeping desktop behavior intact after browser support lands

Out of scope:

- publish helpers such as GitHub Pages automation
- non-Chrome browser support for the first pass
- browser-only gameplay rules or a browser-only UI redesign

## Read Order

1. `AGENTS.md`
2. `specs/003-web-browser-play/handoff.md`
3. `specs/003-web-browser-play/tasks.md`
4. `specs/003-web-browser-play/spec.md`
5. `specs/003-web-browser-play/plan.md`

## Current Checkpoint

Implemented and committed:

- `ebcb003` / `983620e`: spec/task/doc refinement
- `8cd2943`: web pause fullscreen flow
- `45f4059`: traffic vehicle render order
- `f998f41`: district runtime ownership cleanup

Current validated state:

- paused `F` fullscreen works in desktop Chrome on the web export
- web export and headless boot both pass locally
- district tiles are now ground/profile only; spawns are level-owned through the runtime overlay

Observed desktop behavior from manual regression testing:

- pedestrian sidewalk/crosswalk discipline and traffic yielding still need follow-up work outside this slice

Scope conclusion:

- these behaviors appear to predate `003-web-browser-play`
- they are not caused by the committed browser/fullscreen boundary changes in this slice
- attempted pedestrian fixes were rolled back; the working tree is clean again
- detailed follow-up notes belong under `001-foundation-sandbox`

## Known Coordination Notes

- `AGENTS.md` now points at this slice; treat this handoff as the first continuity document for future agents
- remaining spec tasks are still:
  - `T021` full quickstart validation and reliability log
- recent runtime bugs that were fixed:
  - stale police spawn marker references in `wanted_system.gd`
  - invalid/null incident-driver signal payload handling in `civilian_vehicle_ai.gd`
  - embedded invisible traffic car ownership in `district_slice.tscn`

## Validate First

Run:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

Then use the feature docs and manual checks in:

- `tests/manual/web_browser_play.md`
- `tests/manual/us1_playable_core.md`

## Next Target

Work through the feature in this order unless the user redirects:

1. finish `T021` quickstart validation and complete the fullscreen reliability log
2. merge `003-web-browser-play`
3. track pedestrian and traffic AI cleanup separately from this slice under `001-foundation-sandbox`

## Constraints

- keep scripts short and domain-scoped
- keep browser-specific code isolated to export or fullscreen boundaries
- prefer relative paths in docs and scripts
- do not commit machine-specific config, secrets, or local paths
- commit before switching between spec work and code work
