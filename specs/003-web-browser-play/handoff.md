[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / handoff.md

# Handoff

This file is the quick re-entry point for any agent taking over work on `003-web-browser-play`.

## Current Focus

The active slice is still `003-web-browser-play`, but the blocking work is now desktop-regression cleanup after the browser/fullscreen implementation landed.

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

Current blocker:

- desktop regression `T017` is still failing because NPC pedestrian movement is not respecting sidewalk/crosswalk behavior
- several attempted fixes are currently uncommitted in:
  - `scripts/ai/pedestrian/civilian/pedestrian_ai.gd`
  - `scripts/ai/vehicular/civilian/civilian_vehicle_ai.gd`
  - `scripts/world/district_activity_overlay.gd`

Observed regression behavior from manual desktop testing:

- pedestrians wander onto grass and road
- pedestrians swirl/reverse near corners
- pedestrians appear tile-limited unless the graph is stitched
- cars do not reliably yield to pedestrians

Strong conclusion from current investigation:

- the existing ambient pedestrian system is too loose for the desired behavior
- the current graph/steering hybrid keeps fighting the intended sidewalk-first, curb-wait, crosswalk-cross rules
- the next likely successful fix is a stricter pedestrian state model instead of more incremental steering patches

## Known Coordination Notes

- `AGENTS.md` now points at this slice; treat this handoff as the first continuity document for future agents
- remaining spec tasks are still:
  - `T017` desktop regression rerun
  - `T019` desktop regression notes
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

1. stabilize pedestrian behavior on desktop so NPCs:
   - stay on sidewalks by default
   - only enter roads through crosswalk logic
   - wait at crosswalk ends for unsafe cars
   - form at most two-abreast social groups
2. re-run `T017` desktop regression
3. record results for `T019`
4. finish `T021` full validation only after desktop regression is clean

Recommended implementation direction:

- stop trying to salvage the current free-steered ambient walker if it keeps failing
- replace it with clearer pedestrian states such as `sidewalk_walk`, `curb_wait`, `crosswalk_cross`, and `social_follow`
- keep social behavior subordinate to sidewalk/crosswalk safety rules

## Constraints

- keep scripts short and domain-scoped
- keep browser-specific code isolated to export or fullscreen boundaries
- prefer relative paths in docs and scripts
- do not commit machine-specific config, secrets, or local paths
- commit before switching between spec work and code work
