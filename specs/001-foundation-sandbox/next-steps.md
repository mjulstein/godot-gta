[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / next-steps.md

# Next Steps

## Current Checkpoint

The prototype now covers the first pass of User Story 2:

- project boots in Godot 4.6+
- world is generated from a layered ASCII-tiled base level with road, building, and activity maps
- player can move on foot, steal the parked vehicle, and drive
- civilian pedestrians and traffic placeholders are spawned from activity overlays
- witnessed crimes raise wanted level
- police placeholders spawn and pursue on foot
- wanted state decays after the player escapes pressure
- camera uses fixed viewport stretch, driving look-ahead, speed-aware zoom, and pause palette overlay
- debug overlay shows wanted level and police count

## Validate First

Run:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

Then manually verify:

- `scenes/main/game.tscn` loads
- fullscreen keeps the same framed view instead of revealing more world
- the on-foot to vehicle loop works
- the driving camera pans ahead and eases back from high-speed exits
- stealing the vehicle near civilians raises wanted
- police spawn and wanted can clear again

Manual validation reference:

- [tests/manual/us1_playable_core.md](../../tests/manual/us1_playable_core.md)
- [tests/manual/us2_wanted_loop.md](../../tests/manual/us2_wanted_loop.md)

## Next Target

Stabilize and tune User Story 2 before promoting any new feature ideas into active scope:

1. Tune camera framing, zoom-delay, and driving look-ahead feel through manual play
2. Tune civilian spacing, witness radius, and wanted decay timing
3. Improve police pursuit behavior and spawn selection across multiple district tiles
4. Decide whether wanted UI stays debug-first or gains lightweight HUD treatment

## Actor TODO

Work one actor at a time until its baseline behavior is reliable before expanding scope again.

### Traffic Cars

- Keep all movement on lane paths with no grass drift
- Avoid spawning or despawning on screen
- Keep rendering stable across tile transitions
- Reach a higher cruising speed on long straights, then slow before corners
- Yield to pedestrians at crossings
- Stop at least half a car length before a pedestrian
- Keep at least half a car length spacing from vehicles or obstacles ahead
- Handle corners, tees, dead ends, and parking-lot entry or exit cleanly
- Reroute around blocked lanes by changing lane, turning, or making a left-lane u-turn when needed
- Fix failed turns where a car hits the curb, flips direction, and stalls instead of completing the legal corner
- Stop clipping or snagging on overlay collisions

### Pedestrians

- Stay on sidewalks and crosswalks only
- Choose sensible turns at corners and intersections
- Cross roads only on valid crossing paths
- Avoid stepping into traffic lanes outside crossings
- Fix pedestrians that oscillate inside intersections instead of using the marked crosswalk path

### Police

- Verify spawned police always move after creation
- Verify police are not blocked by hidden or stale collisions
- Improve pursuit routing across multi-tile streets
- Confirm pressure logic matches visible chase state

### Player Vehicle

- Re-test road collisions after overlay and tile-profile changes
- Re-check enter or exit flow near sidewalks, lots, and dead ends
- Confirm no invisible blockers remain on drivable routes

Primary task source:

- [tasks.md](./tasks.md)

## Constraints

- Keep scripts short and domain-scoped
- Prefer tunable resources over new hardcoded gameplay values
- Do not commit absolute local paths, machine-specific config, or secrets
- Commit before switching between spec work and code work
