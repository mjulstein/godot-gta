[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / handoff.md

# Handoff

This file is the quick re-entry point for any agent taking over work on `003-web-browser-play`.

## Current Focus

The active slice is first-pass browser play parity for desktop Chrome plus paused-only fullscreen support.

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

The feature artifacts exist and the current implementation path is defined in `spec.md`, `plan.md`, and `tasks.md`.

Before implementation continues, keep these points in focus:

- browser support must stay a narrow runtime layer rather than a gameplay fork
- fullscreen must only toggle while paused
- pause state remains authoritative in Godot even when browser glue is involved
- desktop Chrome is the first supported browser target
- desktop regression checks remain part of done criteria

## Known Coordination Notes

- `AGENTS.md` now points at this slice; treat this handoff as the first continuity document for future agents
- the current task list likely needs small follow-up tightening around:
  - explicit coverage for `FR-011` shortcut labeling when an in-game fullscreen control is used
  - explicit browser parity validation for civilian traffic presence
  - explicit 10-attempt validation notes for the 9/10 fullscreen success criteria

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

1. refresh export and browser-entry documentation
2. add runtime capability detection and fullscreen-state plumbing
3. deliver browser parity for the current sandbox loop
4. add paused fullscreen behavior through the chosen browser-friendly path
5. re-run desktop regression coverage and align docs

## Constraints

- keep scripts short and domain-scoped
- keep browser-specific code isolated to export or fullscreen boundaries
- prefer relative paths in docs and scripts
- do not commit machine-specific config, secrets, or local paths
- commit before switching between spec work and code work
