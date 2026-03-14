[root](../../README.md) / [specs](../README.md) / [001-foundation-sandbox](./README.md) / next-steps.md

# Next Steps

## Current Checkpoint

The prototype now covers the first pass of User Story 2:

- project boots in Godot 4.6+
- player can move on foot, steal the parked vehicle, and drive
- civilian pedestrians and a traffic placeholder move through the district
- witnessed crimes raise wanted level
- police placeholders spawn and pursue on foot
- wanted state decays after the player escapes pressure
- debug overlay shows wanted level and police count

## Validate First

Run:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

Then manually verify:

- `scenes/main/game.tscn` loads
- the on-foot to vehicle loop works
- stealing the vehicle near civilians raises wanted
- police spawn and wanted can clear again

Manual validation reference:

- [tests/manual/us1_playable_core.md](../../tests/manual/us1_playable_core.md)
- [tests/manual/us2_wanted_loop.md](../../tests/manual/us2_wanted_loop.md)

## Next Target

Stabilize and tune User Story 2 before starting missions:

1. Tune civilian spacing, witness radius, and wanted decay timing
2. Improve police pursuit behavior and spawn selection
3. Decide whether wanted UI stays debug-first or gains lightweight HUD treatment
4. Start User Story 3 mission scaffolding once the pursuit loop is repeatable

Primary task source:

- [tasks.md](./tasks.md)

## Constraints

- Keep scripts short and domain-scoped
- Prefer tunable resources over new hardcoded gameplay values
- Do not commit absolute local paths, machine-specific config, or secrets
- Commit before switching between spec work and code work

## Open Decisions

- Whether civilians should stay on simple rail movement or switch to waypoint logic
- Whether police should remain on-foot in US2 or gain vehicle pursuit before US3
- Whether wanted-state UI should stay debug-first or gain a player-facing HUD treatment in US2
