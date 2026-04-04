[root](./README.md) / AGENTS.md

# AGENTS.md

## Project Context

This repository is a Godot 4.x project for a top-down crime sandbox inspired by GTA 2. The current active slice is `003-web-browser-play`.

Active feature directory (`$FEATURE_DIR`): `specs/003-web-browser-play/`

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

The next implementation target is `003-web-browser-play`, starting with the shared browser-export and fullscreen foundations, then User Story 1 browser parity work in `tasks.md`.

## Active Technologies
- GDScript on Godot 4.6+ plus narrow browser-side JavaScript in a custom HTML shell + Godot 4.x web export, `JavaScriptBridge`, custom HTML shell support, existing pause flow, existing camera and input actions (003-web-browser-play)
- Scene files, scripts, export preset configuration, manual validation docs, and web-shell assets only; no new persistent gameplay storage (003-web-browser-play)
- GDScript on Godot 4.6+ plus optional narrow browser-side JavaScript when a web fullscreen bridge is needed + Godot 4.x web export, optional `JavaScriptBridge`, existing pause flow, existing camera framing logic, existing input actions (003-web-browser-play)
- Scene files, scripts, export preset configuration, manual validation docs, and optional web-shell assets only; no new persistent gameplay storage (003-web-browser-play)

## Recent Changes
- 003-web-browser-play: Added GDScript on Godot 4.6+ plus narrow browser-side JavaScript in a custom HTML shell + Godot 4.x web export, `JavaScriptBridge`, custom HTML shell support, existing pause flow, existing camera and input actions
