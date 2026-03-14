[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / next-steps.md

# Next Steps

## Current Checkpoint

The MVP foundation is in place and User Story 1 is complete enough to build on:

- project boots in Godot 4.6+
- player can move on foot
- player can enter and exit a vehicle
- vehicle can drive and collide with world geometry
- camera follows the active actor
- debug overlay and interaction prompt are wired

## Validate First

Run:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

Then manually verify:

- `scenes/main/game.tscn` loads
- the on-foot to vehicle loop works
- the interaction prompt appears without the debug overlay

Manual validation reference:

- [tests/manual/us1_playable_core.md](../../tests/manual/us1_playable_core.md)

## Next Target

Start User Story 2:

1. Create civilian placeholder scenes
2. Add minimal civilian or traffic behavior
3. Introduce crime event emission
4. Add wanted-state tracking
5. Add police placeholders and basic pursuit behavior

Primary task source:

- [tasks.md](./tasks.md)

## Constraints

- Keep scripts short and domain-scoped
- Prefer tunable resources over new hardcoded gameplay values
- Do not commit absolute local paths, machine-specific config, or secrets
- Commit before switching between spec work and code work

## Open Decisions

- Whether civilian traffic should move on rails first or use waypoint logic
- Whether police should begin as on-foot pursuers, vehicle pursuers, or both
- Whether wanted-state UI should stay debug-first or gain a player-facing HUD treatment in US2
