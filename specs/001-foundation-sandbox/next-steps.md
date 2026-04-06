[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / next-steps.md

# Next Steps

Police and wanted documentation remains in the repository for later reference, but police behavior is not active branch scope for `001-foundation-sandbox`. Any new police behavior work should be captured under `specs/ideas/`.

## Current Checkpoint

The prototype includes a partial implementation beyond the revised branch scope:

- project boots in Godot 4.6+
- world is generated from a layered ASCII-tiled base level with road, building, pedestrian-density, and traffic-density maps
- player can move on foot, steal the parked vehicle, and drive
- civilian pedestrians and traffic are spawned from separate ambient overlay densities
- wanted and police placeholder systems exist as deferred work, but are no longer part of active branch completion
- camera uses fixed viewport stretch, driving look-ahead, speed-aware zoom, debug traffic-camera cycling, and pause palette overlay
- mobile HUD support exists for joystick, action, pause, and driving controls
- pause overlay now includes gameplay HUD opacity, gameplay input scale, impact vibration, and restart controls
- local iOS project generation and build or deploy helpers exist under `ios/`
- debug overlay shows development state for the current sandbox slice

The branch is still considered in-progress until the basic sandbox feel is accepted across on-foot movement, vehicle handling, collisions, and baseline civilian traffic behavior.

## Validate First

Run:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

Then manually verify:

- `scenes/main/game.tscn` loads
- fullscreen keeps the same framed view instead of revealing more world
- the city reads clearly as a tile-based space with sidewalks, crossings, and lanes
- pedestrians stay on curb-adjacent sidewalks and valid crosswalk links
- pedestrian groups read sensibly, including side-by-side pairs and queued larger groups
- civilian traffic follows readable western traffic flow
- dead-end parking-lot arrivals can now resolve as a U-turn or a parked handoff into a roaming pedestrian
- the on-foot to vehicle loop works
- the driving camera pans ahead and eases back from high-speed exits
- taking over a civilian vehicle leaves a displaced pedestrian occupant
- vehicle-to-pedestrian impacts displace pedestrians by momentum without pedestrians pushing cars back
- mobile HUD touch controls can complete the on-foot, vehicle, pause, and resume loop
- pause overlay controls affect gameplay HUD opacity and gameplay input scale without changing keyboard paths

Manual validation reference:

- [tests/manual/us1_playable_core.md](../../tests/manual/us1_playable_core.md)

## Next Target

Stabilize and tune the revised sandbox scope before promoting any new feature ideas into active scope:

1. Tune camera framing, zoom-delay, and driving look-ahead feel through manual play
2. Tune on-foot movement so pedestrians stay responsive, human-scale, and distinct from vehicle handling
3. Tune civilian spacing, lane flow, and crossing behavior under heavier density mixes
4. Tighten curb-constrained pedestrian spawning on all tile profiles through manual play
5. Verify takeover, incident, and post-impact behavior under repeated sandbox runs
6. Expand debug state only where tuning is still hard to compare during play

## Current Follow-Up

Recent validation on `003-web-browser-play` re-exposed baseline sandbox issues that belong here rather than in the browser slice:

- pedestrians wander onto grass and road instead of holding curb-adjacent sidewalk and crosswalk space
- pedestrians can swirl, reverse, or stall near corners instead of making readable sidewalk progress
- traffic does not reliably yield to pedestrians at crossings

Working constraints for the next pedestrian or traffic pass:

- keep `district_activity_overlay.gd` tile-local and data-oriented
- let AI consume tile activity data instead of moving cross-tile ownership into the overlay
- keep sidewalk travel as the default pedestrian mode
- enter the road only through explicit crossing logic
- keep social walking subordinate to sidewalk and crossing safety

Recommended implementation direction:

- move toward clearer pedestrian states such as `sidewalk_walk`, `curb_wait`, `crosswalk_cross`, and `social_follow`
- treat pair or group behavior as a layer on top of route-following, not as free steering
- fix traffic yielding as part of the same readable crossing model instead of as an isolated scan-distance tweak

## Actor TODO

Work one actor at a time until its baseline behavior is reliable before expanding scope again.

### Traffic Cars

- Keep all movement on lane paths with no grass drift
- Keep civilian traffic on the same shared throttle and steering vehicle rule-set as the player vehicle
- Avoid spawning or despawning on screen
- Keep rendering stable across tile transitions
- Keep queueing before intersections instead of bunching inside the junction when lanes are blocked
- Keep reroute choices from falling into repeat turn loops after obstacle avoidance
- Continue tuning lane-prep behavior so cars choose the correct lane one tile early when the next junction requires it
- Reach a higher cruising speed on long straights, then slow before corners
- Keep AI-driven vehicle rotation coupled to actual motion; stopped cars should not pivot in place unless collision response rotates them
- Expose enough debug state to compare civilian and player vehicle motion under the same metrics
- Yield to pedestrians at crossings
- Stop at least half a car length before a pedestrian
- Keep at least half a car length spacing from vehicles or obstacles ahead
- Keep full-car stand-off distance to barriers and other hard blockers
- Keep dead-end parking-lot arrival behavior readable under repeated runs
- Reroute around blocked lanes by changing lane, turning, or making a left-lane u-turn when needed
- Fix failed turns where a car hits the curb, flips direction, and stalls instead of completing the legal corner
- Stop clipping or snagging on overlay collisions

### Pedestrians

- Keep spawns constrained to curb-adjacent sidewalk bands on every tile profile
- Keep local sidewalk walking and crosswalk selection readable under high density
- Keep group movement stable near crosswalk choices, especially for 3-ped and queued formations
- Keep obstacle steering smooth without grass drift or direction flicker
- Keep player on-foot control direct from top-down directional input rather than vehicle steering rules
- Keep pedestrian top speed within believable human limits for the district scale
- Allow only light carry on abrupt direction changes, with room for later surface-based tuning

### Player Vehicle

- Keep player vehicle physics aligned with the same shared throttle and steering rule-set used by civilian traffic
- Re-test road collisions after overlay and tile-profile changes
- Re-check enter or exit flow near sidewalks, lots, and dead ends
- Confirm no invisible blockers remain on drivable routes
- Leave a displaced pedestrian occupant behind when the player takes over a civilian car
- Transfer vehicle momentum to pedestrians on impact without allowing pedestrians to shove the vehicle

Primary task source:

- [tasks.md](./tasks.md)

## Constraints

- Keep scripts short and domain-scoped
- Prefer tunable resources over new hardcoded gameplay values
- Do not commit absolute local paths, machine-specific config, or secrets
- Commit before switching between spec work and code work
