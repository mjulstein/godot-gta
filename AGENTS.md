[root](./README.md) / AGENTS.md

# AGENTS.md

## Project Context

This repository is a Godot 4.x project for a top-down crime sandbox inspired by GTA 2. The current active slice is `001-foundation-sandbox`.

Active feature directory (`$FEATURE_DIR`): `specs/001-foundation-sandbox/`

## Source Of Truth

- Constitution: `.specify/memory/constitution.md`
- Feature spec: `$FEATURE_DIR/spec.md`
- Implementation plan: `$FEATURE_DIR/plan.md`
- Task list: `$FEATURE_DIR/tasks.md`

If implementation diverges from these files, update the spec artifacts first or in the same change.

## Working Rules

- Commit before switching between spec work and code work.
- Keep file and directory structure modular by domain.
- Prefer short scripts with one responsibility over large scene scripts.
- Prefer `git mv` over plain `mv` when relocating tracked files so history stays easier to follow.
- Avoid mixing world composition with gameplay logic when a separate script can own the behavior.
- Do not introduce copied GTA assets, names, UI, or story content.
- Keep `$FEATURE_DIR/handoff.md` current whenever the active scope, current checkpoint, next target, or other takeover-critical context changes.
- Treat `$FEATURE_DIR/handoff.md` as the first continuity document for the active slice; keep it brief, practical, and easy for another agent to resume from.

## Privacy And Repo Hygiene

- Never commit absolute local filesystem paths, machine-specific config, local editor state, or secrets.
- Prefer relative paths in documentation, scripts, and examples.
- Before committing, scan changed files for usernames in paths, tokens, API keys, passwords, and other host-specific data.
- Do not use a personal email address in Git author or committer metadata for this repository.

## Read Order

- Read the active feature handoff at `$FEATURE_DIR/handoff.md`.
- Then read `$FEATURE_DIR/tasks.md`.
- Read `$FEATURE_DIR/spec.md` and `$FEATURE_DIR/plan.md` only if the task requires deeper product or design context.
- Read module `README.md` files only for the part of the codebase you are changing.

## Directory Guidance

- `scenes/`: scene composition and reusable scene assets
- `scripts/core/`: bootstrap, camera, shared state, cross-cutting helpers
- `scripts/actors/`: player and actor-specific behavior
- `scripts/vehicles/`: vehicle-specific behavior
- `scripts/systems/`: orchestration systems such as interaction, wanted, missions
- `scripts/ui/`: HUD and debug UI
- `data/`: tunable resources and mission data

## Validation

Use Godot for local validation after scene or script changes:

```sh
HOME=/tmp/godot-home godot --headless --path . --quit-after 1
```

The custom `HOME` is needed in this sandbox because default Godot editor paths under the user home directory are not writable here.

## Current Baseline

The current bootstrap should provide:

- a Godot project file
- a root game scene
- a compact district scene
- a player scene
- a drivable civilian vehicle scene
- a follow camera
- a debug overlay

The next implementation target is `001-foundation-sandbox`, focusing on sandbox feel, pedestrian sidewalk and crosswalk behavior, traffic yielding, and final baseline sign-off in `tasks.md` and `handoff.md`.

## Active Technologies
- GDScript on Godot 4.6-stable with layered ASCII-tiled world composition, shared player and civilian vehicle motion rules, pedestrian and traffic AI, pause flow, debug overlay, and mobile HUD support (001-foundation-sandbox)
- Scene files, scripts, `.tres` tuning resources, markdown manual validation docs, and lightweight export configuration; no persistent gameplay storage (001-foundation-sandbox)
- GDScript on Godot 4.6-stable + Godot 4.6 built-in scene system, `CharacterBody2D`/physics processing patterns, input actions, `Resource`-based tuning data, `.tscn` scenes, `.tres` resources (001-foundation-sandbox)
- No persistent gameplay storage; repository assets are scene files, scripts, tuning resources, and markdown validation docs (001-foundation-sandbox)

## Recent Changes
- 003-web-browser-play merged into `001-foundation-sandbox`: browser export support, paused fullscreen flow, spec cleanup, and updated handoff docs are now part of the baseline branch.
