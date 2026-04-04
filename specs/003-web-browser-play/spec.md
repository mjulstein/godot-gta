[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / spec.md

# Feature Specification: Web Browser Play

**Feature Branch**: `003-web-browser-play`  
**Created**: 2026-03-30  
**Status**: Proposed  
**Input**: User description: "can we make a new spec for webbrowser play? the game should essentialy behave 1:1 in a browser window as it does on desktop. There should be a full-screen toggle available while the game is pasused, activated by pressing F."

## Feature Summary

Define browser-play support so the current sandbox behaves as close to desktop as practical in a web browser, with the same gameplay loop, pause flow, and readable framing, while allowing a simple fullscreen path that fits common browser behavior.

## Problem Statement

The current project targets desktop and has a separate mobile-controls feature, but browser play is not yet specified. Without a dedicated web spec, implementation would have to guess at what "desktop parity" means for browser builds, how pause and fullscreen should behave under browser restrictions, and which differences are acceptable when the game runs inside a browser window.

Browser distribution workflow is not part of this feature. A GitHub Pages publish helper can be specified later as separate follow-up work once browser runtime behavior is accepted.

## Clarifications

### Session 2026-04-03

- Q: Should `003-web-browser-play` include the manual GitHub Pages publish helper, or should that be separate follow-up work? → A: Exclude the publish helper from `003-web-browser-play` and treat it as separate follow-up work.
- Q: Should browser fullscreen use a custom HTML shell by default, or only as a fallback after trying Godot-native fullscreen? → A: Use a common and obvious browser-compatible fullscreen approach, which may be in-game or outside the game page.
- Q: How should “1:1” browser parity be defined for acceptance: by matching desktop validation outcomes, by matching frame rate and responsiveness, or left qualitative? → A: Browser play should work like the rest of the game without browser-specific responsiveness acceptance logic.
- Q: If a browser fullscreen request is denied, should the game stay paused with explicit UI feedback, stay paused silently, or unpause? → A: Keep the game paused and provide no explicit feedback.
- Q: While paused, should `F` toggle fullscreen regardless of current pause-menu or browser focus, only with gameplay focus, or be disabled when controls are focused? → A: `F` is a simple paused-only toggle attempt with no extra browser-specific logic.
- Q: Should browser parity allow browser-specific gameplay conditionals, or should gameplay stay the same across desktop, browser, and mobile except for the fullscreen boundary? → A: Gameplay stays the same across desktop, browser, and mobile; only the fullscreen toggle boundary may need an alternate implementation.
- Q: Should the fullscreen success criteria require recorded attempt counts, or stay qualitative? → A: Record 10 manual attempts each for fullscreen enter, fullscreen exit, and paused `F` toggle, with at least 9 successes in each set.
- Q: Should civilian traffic be part of browser-play acceptance for this slice? → A: No. Browser play is only about playing the game as-is in the browser; civilian traffic is not part of browser-specific acceptance for this slice.
- Q: If fullscreen is exited externally through browser chrome or `Esc`, what should happen? → A: Always sync the toggle state and exit fullscreen; if the game was paused, it stays paused, and if it was not paused, it enters paused mode.
- Q: If the browser viewport becomes very small or very wide, what should happen? → A: Preserve the fixed framed play-space even if unused space appears.
- Q: If the runtime is effectively fullscreen-only, what should happen? → A: Hide the in-game fullscreen toggle and keep gameplay otherwise unchanged.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Play the sandbox in a browser (Priority: P1)

As a player, I can run the sandbox in a web browser and get the same core behavior I get on desktop, so that browser play feels like the same game rather than a reduced variant.

**Why this priority**: Browser support only matters if the current sandbox loop survives the export with the same readable controls, camera framing, pause flow, and vehicle takeover behavior.

**Independent Test**: Launch the web build in a desktop browser, start a run, move on foot, enter a vehicle, drive, exit, and pause. Verify that the same gameplay loop works without a browser-only ruleset.

**Acceptance Scenarios**:

1. **Given** the game is launched in a supported desktop browser, **When** the player starts a run, **Then** the same playable scene, core input actions, pause flow, and sandbox loop available on desktop are present in the browser build.
2. **Given** the player is on foot in the browser build, **When** the player uses the same movement and interaction inputs used on desktop, **Then** the player can navigate, collide, and interact without browser-only gameplay behavior diverging from desktop expectations.
3. **Given** the player enters a civilian vehicle in the browser build, **When** control transfers into driving, **Then** vehicle handling, camera ownership, exit flow, and displaced-occupant behavior match the desktop rules closely enough that no separate browser design needs to be learned.
4. **Given** the browser build is running in a non-fullscreen window, **When** the player resizes the browser viewport, **Then** the game maintains the same framed play-space behavior expected on desktop rather than revealing extra world due to browser window size alone.

---

### User Story 2 - Toggle fullscreen from pause (Priority: P1)

As a player, I can press `F` while the game is paused to toggle browser fullscreen, so that I can switch between embedded-window play and immersive fullscreen without leaving the game flow.

**Why this priority**: Fullscreen is the main browser-specific interaction the user asked for, and the implementation should use the most obvious browser-friendly approach that keeps pause behavior understandable.

**Independent Test**: Run the web build in Chrome, pause the game, use the available fullscreen control and `F`, and verify that fullscreen behavior remains understandable and does not unpause the game unexpectedly.

**Acceptance Scenarios**:

1. **Given** the browser build is paused and not fullscreen, **When** the player activates the available fullscreen control, **Then** the game or browser requests fullscreen and pause state remains coherent after the transition.
2. **Given** the browser build is paused and already fullscreen, **When** the player activates the available fullscreen control, **Then** fullscreen exits and pause state remains coherent.
3. **Given** the browser build is paused, **When** the player presses `F`, **Then** the game toggles fullscreen from that same paused input flow and remains paused.
4. **Given** the browser build is not paused, **When** the player presses `F`, **Then** no fullscreen toggle is triggered by this feature.
5. **Given** the browser runtime uses a fullscreen control outside the game, **When** that common browser-facing control is the chosen approach, **Then** the pause overlay does not need to duplicate it.

---

### User Story 3 - Keep desktop behavior aligned (Priority: P2)

As a desktop player or developer, I can keep using the current non-browser build without accidental regressions from web support work, so that browser parity layers onto the project instead of replacing the baseline.

**Why this priority**: The repository's current active slice is already playable on desktop. Browser work is acceptable only if it preserves the existing baseline and keeps parity as the goal.

**Independent Test**: Launch the desktop build after browser-play implementation work and verify that the current sandbox loop and pause flow still work as intended for desktop testing.

**Acceptance Scenarios**:

1. **Given** the project is run as a desktop build, **When** the player uses the current controls and pause flow, **Then** existing desktop behavior remains intact.
2. **Given** browser support requires export-specific hooks or guards, **When** the desktop build runs, **Then** those hooks do not force a browser-style code path onto desktop gameplay.

## Edge Cases

- If the browser denies fullscreen, the game stays paused and the pause overlay remains available without additional failure messaging.
- If fullscreen is exited externally through `Esc` or browser chrome, the fullscreen toggle state syncs immediately; if the game was paused it stays paused, and if it was not paused it enters paused mode.
- If the browser viewport becomes very small or very wide compared with the desktop test window, the game preserves the intended fixed framed play-space even if unused space appears.
- If the build is running on a platform or runtime mode that is effectively fullscreen-only, the in-game fullscreen toggle remains hidden and gameplay otherwise stays unchanged.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The project MUST define a supported web-browser play mode for the existing sandbox loop.
- **FR-002**: Browser play MUST preserve the same core gameplay loop available on desktop, including on-foot movement, vehicle entry or exit, pause, and resume.
- **FR-003**: Browser play MUST reuse the same gameplay input actions and gameplay rules as desktop rather than introducing a browser-only control model or browser-specific gameplay conditional path.
- **FR-004**: Browser play MUST preserve the same intended camera framing rules as desktop so browser window size alone does not reveal extra world outside the intended frame.
- **FR-005**: The web build MUST be playable inside a browser window without requiring fullscreen.
- **FR-006**: The browser build MUST provide an obvious fullscreen path that fits common browser usage, either inside the game or via browser-page UI outside the game.
- **FR-007**: If fullscreen is provided by browser-page UI outside the game, the pause overlay MUST NOT duplicate that control.
- **FR-008**: While the game is paused in the browser build, pressing `F` MUST also toggle fullscreen on or off.
- **FR-009**: Activating the pause-screen fullscreen control or pressing `F` for this feature MUST NOT unpause the game.
- **FR-010**: This feature MUST NOT toggle fullscreen when the game is not paused.
- **FR-011**: When the fullscreen toggle is visible in a runtime that supports keyboard input, its visible label or adjacent hint MUST include `F`.
- **FR-012**: Any in-game fullscreen control MUST NOT be visible on platforms or runtime modes where a non-fullscreen display mode is not available.
- **FR-013**: If fullscreen is exited externally by browser UI or `Esc`, the fullscreen toggle state MUST sync immediately; if the game was paused it MUST stay paused, and if it was not paused it MUST enter paused mode.
- **FR-014**: Desktop and browser builds MUST keep the same gameplay code path, with runtime-specific handling limited to the fullscreen toggle boundary and other platform presentation glue that does not alter gameplay behavior.
- **FR-015**: The first supported browser target for this feature MUST be desktop Chrome.
- **FR-016**: The implementation MAY use a custom HTML shell or narrow browser bridge if that is the simplest reliable way to provide fullscreen in the browser build.
- **FR-017**: The Godot-side pause and gameplay flow MUST remain authoritative even if fullscreen entry or exit is brokered outside the main game UI.
- **FR-018**: If a browser fullscreen request is denied, the game MUST remain paused and keep the pause overlay coherent without requiring explicit failure messaging in the pause UI.
### Non-Functional Requirements

- **NFR-001**: Browser play SHOULD feel functionally equivalent to desktop for the current sandbox slice within normal browser platform limits.
- **NFR-002**: The browser feature SHOULD remain a narrow export-platform layer or pause-flow extension so runtime-specific logic stays isolated to presentation boundaries such as fullscreen and remains easy to maintain.
- **NFR-003**: Browser-specific behavior SHOULD remain easy to validate through one documented manual Chrome test flow plus the existing desktop validation flow.

### Assumptions

- **A-001**: The current desktop sandbox loop remains the source of truth for browser parity.
- **A-002**: The first target is desktop Chrome; other browsers can be evaluated later.
- **A-003**: The browser build may need either in-game or browser-page fullscreen UI depending on which common browser approach proves clearest and simplest.
- **A-004**: "1:1" parity means the browser build should match desktop gameplay behavior, controls, pause flow, and framing intent without introducing a separate browser gameplay model.
- **A-005**: "Windowed mode" means any runtime presentation where the game can be shown without filling the entire screen, including both desktop browser windows and desktop non-browser windows.

### Out Of Scope

- **OOS-001**: Mobile-browser touch support beyond what is already covered by the mobile-controls feature.
- **OOS-002**: Matchmaking, cloud saves, or browser-specific platform services.
- **OOS-003**: Browser-specific monetization, portals, embed SDKs, or storefront integrations.
- **OOS-004**: A bespoke browser-only UI redesign beyond the paused fullscreen hint.
- **OOS-005**: Guaranteed identical frame rate, latency, or memory usage across all browsers and desktop builds.
- **OOS-006**: Safari, Firefox, and other non-Chrome browser support for the first implementation.
- **OOS-007**: Any GitHub Pages or similar publish helper workflow.
- **OOS-008**: A full release pipeline or browser distribution automation beyond runtime browser support.

### Implementation Notes

- Keep browser parity scoped to the current playable sandbox slice rather than future systems.
- Prefer a single pause-flow integration point for paused-only fullscreen behavior.
- Use the simplest reliable fullscreen approach for the browser build, whether that is in-game UI or browser-page UI.
- Keep any runtime-specific glue narrow and limited to presentation boundaries such as fullscreen, while gameplay logic and pause state stay inside Godot.
- Hide the pause-screen fullscreen control where the runtime does not present a meaningful choice between non-fullscreen and fullscreen display modes.
- Keep framing validation aligned with the existing expectation that fullscreen should not reveal more world than the intended fixed framing.
- Document a manual validation flow for Chrome windowed play, paused fullscreen-button entry, paused fullscreen-button exit, paused `F` fullscreen toggle, external fullscreen exit, hidden-control cases, and desktop-regression checks, including recorded 10-attempt results for fullscreen entry, exit, and paused `F` toggle.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In manual browser tests, a player can complete the current sandbox loop of moving on foot, entering a vehicle, driving, exiting, pausing, and resuming without learning a separate browser-only ruleset.
- **SC-002**: In manual Chrome tests, the chosen fullscreen control enters fullscreen in at least 9 out of 10 recorded paused attempts.
- **SC-003**: In manual Chrome tests, the chosen fullscreen control exits fullscreen in at least 9 out of 10 recorded paused attempts.
- **SC-004**: In manual Chrome tests, pressing `F` while paused toggles fullscreen in at least 9 out of 10 recorded attempts.
- **SC-005**: In manual Chrome tests, browser window resizing and fullscreen transitions preserve the intended framed view instead of exposing extra world outside the designed play-space.
- **SC-006**: On platforms or runtime modes where a non-fullscreen display mode is not available, any in-game fullscreen control remains hidden.
- **SC-007**: Desktop validation still passes after browser support work, with no regression in the current sandbox loop caused by the web feature.
