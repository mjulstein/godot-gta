[root](../../README.md) / [specs](../README.md) / [ideas](./README.md) / pedestrian-movement.md

# Pedestrian Movement

## Summary

Keep pedestrian movement separate from vehicle movement.

Player on-foot control should stay direct and top-down, with movement responding naturally to directional input rather than vehicular steering rules.

Pedestrian top speed should stay within believable human limits. Abrupt direction changes may keep a small amount of drift, but that drift should remain light and should be influenced by the underlying surface.

## Why It Might Matter

- on-foot control should feel immediately readable and precise from the top-down camera
- pedestrian movement should not inherit car-like handling that makes walking feel heavy or indirect
- surface-dependent drift can add nuance later without sacrificing responsiveness

## Player-Facing Loop

- move directly with top-down directional input
- feel fast enough to stay playable, but still recognizably human
- notice slight carry or slide only when direction changes sharply or footing is loose

## Open Questions

- What pedestrian top-speed range fits the scale of the district and camera framing?
- Which surfaces should affect traction, and by how much?
- How much directional carry still feels human rather than slippery?
- Should player and civilian pedestrians share the same movement model with different tuning, or should they diverge later?

## Risks

- too much drift will make on-foot control feel unresponsive
- too little surface effect may make terrain feel irrelevant
- overly high pedestrian speed could weaken the contrast between on-foot and vehicle play

## Promotion Checklist

- define a target pedestrian speed range
- define surface categories and traction effects
- decide whether player and civilian pedestrian movement share one rule-set
- add acceptance criteria before promoting this into active scope
