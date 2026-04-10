[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / handoff.md

# Handoff

This file is the quick re-entry point for any agent taking over work on `001-foundation-sandbox` after `003-web-browser-play` merges.

## Current Focus

`001-foundation-sandbox` remains the baseline sandbox slice. The current priority is not new features, but stabilizing core pedestrian, traffic, and feel behavior so the sandbox reads clearly under repeated manual play.

In scope:

- on-foot feel, vehicle feel, and shared handling consistency
- pedestrian sidewalk, crosswalk, and grouping behavior
- civilian traffic lane flow, stopping distance, and yielding
- collision readability, takeover flow, and sandbox baseline sign-off

Out of scope:

- browser-specific fullscreen or export work from `003-web-browser-play`
- police escalation or other deferred systems that are no longer active `001` scope
- missions, factions, weapons, or broader progression systems

## Read Order

1. `AGENTS.md`
2. `specs/001-foundation-sandbox/handoff.md`
3. `specs/001-foundation-sandbox/tasks.md`
4. `specs/001-foundation-sandbox/spec.md`
5. `specs/001-foundation-sandbox/next-steps.md`

## Current Checkpoint

Implemented and available in the baseline:

- project boots in Godot 4.6+
- world composition is driven from layered ASCII-tiled level data
- player can move on foot, enter or exit vehicles, and drive
- civilian pedestrians and traffic spawn through separate ambient overlay systems
- takeover, displaced-occupant, and momentum-impact behavior exist
- pause overlay, debug overlay, camera framing, and mobile HUD support all exist

Current status:

- `001` is still in progress because sandbox feel is not yet signed off
- recent browser-slice validation re-exposed baseline pedestrian and traffic issues that belong here
- `003`-specific pedestrian experiments were rolled back; do not assume there is pending uncommitted AI work

Known baseline issues to address here:

- pedestrians can leave sidewalk or crosswalk space and drift onto grass or road
- pedestrian corner behavior can become unstable or unreadable under density
- traffic does not reliably yield to pedestrians at crossings

## Known Coordination Notes

- keep `district_activity_overlay.gd` tile-local and data-oriented
- use tile activity data for spawn placement and cadence, not as the live owner of pedestrian routes after spawn
- keep browser or fullscreen behavior changes isolated to `003` or later slices unless they are true shared-core fixes
- use `specs/001-foundation-sandbox/next-steps.md` for the richer backlog and tuning notes

## Validate First

Run:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

Then manually verify:

- `scenes/main/game.tscn` loads
- the city reads clearly as roads, sidewalks, crossings, and lanes
- pedestrians stay on sidewalk or crosswalk space by default
- traffic follows readable lane flow and yields at crossings
- the player can complete the on-foot to vehicle loop
- takeover and impact behavior still read clearly

Validation references:

- `tests/manual/us1_playable_core.md`
- `tests/manual/web_browser_play.md` for desktop regression notes that surfaced the current baseline AI problems

## Next Target

Work in this order unless redirected:

1. stabilize pedestrian sidewalk and crosswalk behavior
2. stabilize traffic yielding and stopping distance around crossings
3. tune player and vehicle feel only after the baseline pedestrian or traffic readability is back under control
4. complete the open `001` polish and sign-off tasks

Recommended implementation direction:

- prefer stricter pedestrian states such as `sidewalk_walk`, `curb_wait`, `crosswalk_cross`, and `social_follow`
- keep pair or group behavior layered on top of a lead pedestrian's local terrain reading and forward intent
- fix traffic yielding as part of readable crossing behavior, not as isolated distance tuning alone

## Constraints

- keep scripts short and domain-scoped
- prefer tunable resources over new hardcoded gameplay values
- do not commit machine-specific config, secrets, or local paths
- commit before switching between spec work and code work
