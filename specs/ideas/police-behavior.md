[root](../../README.md) / [specs](../README.md) / [ideas](./README.md) / police-behavior.md

# Police Behavior

## Summary

Police and wanted systems are retained as deferred design context, but they are not active branch scope for `001-foundation-sandbox`.

The current branch should finish the basic sandbox first: readable city movement, civilian traffic that follows western rules, vehicle takeover, and momentum-based pedestrian impacts.

## Why It Might Matter

- police response is still part of the broader game direction
- existing placeholder work should stay documented so it can be resumed later
- deferring it now keeps the branch focused on sandbox feel instead of escalation systems

## Player-Facing Loop

- commit visible traffic or pedestrian violations
- trigger a readable police response
- evade or outlast the pressure

## Open Questions

- Should the first police slice stay on-foot only, or resume with mixed on-foot and vehicle response?
- Which crime events should matter once police work resumes?
- Should police obey the same lane and traffic constraints as civilians during vehicle pursuit?
- How should wanted state be exposed once it moves beyond debug-only UI?

## Risks

- resuming police too early could distract from unfinished sandbox feel work
- police pathing and spawn logic can quickly dominate the branch if not constrained
- collision and traffic rules may need to settle first so police inherit stable world behavior

## Promotion Checklist

- finish baseline sandbox tuning and sign-off first
- decide the smallest possible police response slice
- define acceptance criteria separate from sandbox traversal and takeover work
- move active police behavior back into a numbered spec only when sequencing is clear
