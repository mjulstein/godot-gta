[root](./README.md) / AGENTS.md

# AGENTS.md

## Project Context

This repository is a Godot 4.x project for a top-down crime sandbox inspired by GTA 2. The current active slice is `001-foundation-sandbox`.

## Source Of Truth

- Constitution: `.specify/memory/constitution.md`
- Feature spec: `specs/001-foundation-sandbox/spec.md`
- Implementation plan: `specs/001-foundation-sandbox/plan.md`
- Task list: `specs/001-foundation-sandbox/tasks.md`

If implementation diverges from these files, update the spec artifacts first or in the same change.

## Working Rules

- Commit before switching between spec work and code work.
- Keep file and directory structure modular by domain.
- Prefer short scripts with one responsibility over large scene scripts.
- Prefer `git mv` over plain `mv` when relocating tracked files so history stays easier to follow.
- Avoid mixing world composition with gameplay logic when a separate script can own the behavior.
- Do not introduce copied GTA assets, names, UI, or story content.

## Privacy And Repo Hygiene

- Never commit absolute local filesystem paths, machine-specific config, local editor state, or secrets.
- Prefer relative paths in documentation, scripts, and examples.
- Before committing, scan changed files for usernames in paths, tokens, API keys, passwords, and other host-specific data.
- Do not use a personal email address in Git author or committer metadata for this repository.

## Read Order

- Start with `AGENTS.md`.
- Then read the active feature handoff at `specs/001-foundation-sandbox/next-steps.md`.
- Then read `specs/001-foundation-sandbox/tasks.md`.
- Read `spec.md` and `plan.md` only if the task requires deeper product or design context.
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

The next implementation target after bootstrap is the rest of User Story 1 in `tasks.md`.
