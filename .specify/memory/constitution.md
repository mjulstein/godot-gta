# Godot GTA Constitution

## Core Principles

### I. Feel-First Top-Down Gameplay
Every implemented feature must serve the top-down action sandbox fantasy first: responsive movement, readable combat, clear traffic flow, and systemic chaos that is easy to understand from an overhead camera. If a feature adds complexity without making moment-to-moment play more legible or more fun, it should be cut or deferred.

### II. Original World, Not Asset-Level Imitation
This project may be inspired by the structure and pacing of GTA 2, but it must ship with original names, world fiction, art direction, writing, audio, UI, and mission content. Direct copying of Rockstar assets, dialogue, maps, logos, faction names, or mission scripts is prohibited.

### III. Small Vertical Slices Over Broad Scope
Work must be organized into independently playable slices. Each feature spec must define a minimal playable outcome that can be tested on its own before more systems are layered in. The team should prefer one polished district, one solid vehicle, and one complete police loop over many unfinished systems.

### IV. Data-Driven Systems Where It Matters
Rules for pedestrians, vehicles, police escalation, pickups, weapons, missions, and district tuning should live in configurable resources or data tables whenever practical. Hardcoding is acceptable only for short-lived prototypes or glue logic, and must be called out explicitly in plans.

### V. Playtestable, Debuggable, Maintainable
Core gameplay systems must be observable during development through debug overlays, logging, or editor-visible state. New systems should be structured so they can be exercised in isolated test scenes or automated checks where practical, especially for spawning, AI state transitions, wanted logic, and mission state progression.

## Technical Constraints

- Engine baseline: Godot 4.x for all gameplay and tooling unless an approved amendment says otherwise.
- Camera model: primary gameplay is top-down or near-top-down and must preserve spatial readability on keyboard/mouse and controller.
- Performance target: the default gameplay slice must remain smooth on a mid-range desktop while simulating the active district population, traffic, and police systems defined by the current spec.
- Source of truth: game rules, balance assumptions, and content scope must be documented in Spec Kit artifacts before implementation expands them.
- Legal/IP guardrail: any reference material from existing games is for analysis only, not for direct reuse.

## Workflow and Quality Gates

- Each major effort starts with a spec in `specs/###-feature-name/spec.md`.
- Plans and tasks must trace back to explicit user stories and functional requirements in the spec.
- New gameplay loops should be verified in an in-engine test scene or reproducible manual test flow before being considered complete.
- Changes that affect player feel should include tuning notes: what changed, why it changed, and how it was validated.
- If a feature introduces systemic behavior, the implementation should include a debugging affordance such as a state label, spawn visualizer, event log, or inspector-friendly state exposure.

## Governance

This constitution overrides ad hoc preferences when scope, architecture, or quality decisions conflict. Amendments require updating this file, describing the reason for the change, and ensuring any active plans/specs remain consistent with the new rules. Reviews should reject work that expands scope without a playable slice, copies protected source material, or weakens gameplay readability for the top-down camera.

**Version**: 1.0.0 | **Ratified**: 2026-03-14 | **Last Amended**: 2026-03-14
