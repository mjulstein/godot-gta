[root](../../README.md) / [scenes](../README.md) / world

# World Scenes

World scenes define layout, collision, spawn markers, and static presentation.

Current baseline:

- `district_slice.tscn`: compact test district for the foundation sandbox slice
- `props/`: reusable world props and marker scenes

Keep world layout readable from a top-down camera. Avoid embedding gameplay rules in the world scene where a system script can own them.
