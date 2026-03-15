[root](../../README.md) / [specs](../README.md) / [ideas](./README.md) / sandbox-followups.md

# Sandbox Follow-Ups

Future-facing ideas that came up during foundation-sandbox implementation but are not part of the active stabilization handoff.

## Mission Scope

- Future mission concepts should stay in `specs/ideas/` until they are ready for a dedicated feature spec.

## Open Design Ideas

- Civilians may eventually move from simple rail behavior to fuller waypoint logic.
- Mission vehicles may eventually support baked multi-tile routes, but ambient traffic should keep choosing its next tile reactively at runtime.
- Police may remain on-foot for the current slice but could gain vehicle pursuit in a later slice.
- The ASCII world layout may later move into data files instead of staying scene-export driven.
- Traffic barriers should not be statically placed by default. Add a dedicated ASCII grid layer where `0` means no barrier and later map other per-tile characters to barrier directions or predefined barrier formations.
- Wanted-state UI may stay debug-first for now, then later become a lightweight player-facing HUD.
- Traffic barriers may later become movable physics props so player vehicles can shove them with impact velocity, while traffic still treats them as lane obstacles.
- A future same-device multiplayer mode could keep players on one shared camera while they remain in the same framed area, then transition into split viewports once they drift too far apart.
