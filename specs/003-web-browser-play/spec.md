[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / spec.md

# Feature Specification: Web Browser Play

**Feature Branch**: `003-web-browser-play`  
**Created**: 2026-03-30  
**Status**: Proposed  
**Input**: User description: "can we make a new spec for webbrowser play? the game should essentialy behave 1:1 in a browser window as it does on desktop. There should be a full-screen toggle available while the game is pasused, activated by pressing F."

## Feature Summary

Define browser-play support so the current sandbox behaves as close to desktop as practical in a web browser, with the same gameplay loop, pause flow, and readable framing, while adding a paused fullscreen toggle through the pause UI and `F`.

## Problem Statement

The current project targets desktop and has a separate mobile-controls feature, but browser play is not yet specified. Without a dedicated web spec, implementation would have to guess at what "desktop parity" means for browser builds, how pause and fullscreen should behave under browser restrictions, and which differences are acceptable when the game runs inside a browser window.

Browser distribution workflow is not part of this feature. A GitHub Pages publish helper can be specified later as separate follow-up work once browser runtime behavior is accepted.

## Clarifications

### Session 2026-04-03

- Q: Should `003-web-browser-play` include the manual GitHub Pages publish helper, or should that be separate follow-up work? → A: Exclude the publish helper from `003-web-browser-play` and treat it as separate follow-up work.
- Q: Should browser fullscreen use a custom HTML shell by default, or only as a fallback after trying Godot-native fullscreen? → A: Use a custom HTML shell as the default fullscreen implementation for browser builds.
- Q: How should “1:1” browser parity be defined for acceptance: by matching desktop validation outcomes, by matching frame rate and responsiveness, or left qualitative? → A: Define “1:1” parity as matching desktop frame rate and responsiveness as closely as possible.
- Q: If a browser fullscreen request is denied, should the game stay paused with explicit UI feedback, stay paused silently, or unpause? → A: Keep the game paused and provide no explicit feedback.
- Q: While paused, should `F` toggle fullscreen regardless of current pause-menu or browser focus, only with gameplay focus, or be disabled when controls are focused? → A: `F` toggles fullscreen whenever the game is paused, regardless of current UI or browser focus.

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

**Why this priority**: Fullscreen is the main browser-specific interaction the user asked for, and browser platforms impose direct-input restrictions that need to be designed explicitly.

**Independent Test**: Run the web build in Chrome, pause the game, use the pause-screen fullscreen control and `F`, and verify that the browser enters or exits fullscreen from the paused state without unpausing the game or breaking input.

**Acceptance Scenarios**:

1. **Given** the browser build is paused and not fullscreen, **When** the player activates the pause-screen fullscreen control, **Then** the game requests browser fullscreen and remains paused after the transition.
2. **Given** the browser build is paused and already fullscreen, **When** the player activates the pause-screen fullscreen control, **Then** the game exits fullscreen and remains paused.
3. **Given** the browser build is paused, **When** the player presses `F`, **Then** the game toggles fullscreen from that same paused input flow and remains paused.
4. **Given** the browser build is paused, **When** the player presses `F` while a pause-menu control or browser-managed focus surface is active, **Then** the game still attempts the paused fullscreen toggle and remains paused.
5. **Given** the browser build is not paused, **When** the player presses `F`, **Then** no fullscreen toggle is triggered by this feature.
6. **Given** the game is running on a platform or runtime mode where a non-fullscreen display mode does not exist, **When** the pause overlay is shown, **Then** the fullscreen toggle control is not shown.

---

### User Story 3 - Keep desktop behavior aligned (Priority: P2)

As a desktop player or developer, I can keep using the current non-browser build without accidental regressions from web support work, so that browser parity layers onto the project instead of replacing the baseline.

**Why this priority**: The repository's current active slice is already playable on desktop. Browser work is acceptable only if it preserves the existing baseline and keeps parity as the goal.

**Independent Test**: Launch the desktop build after browser-play implementation work and verify that the current sandbox loop, pause flow, and fullscreen behavior still work as intended for desktop testing.

**Acceptance Scenarios**:

1. **Given** the project is run as a desktop build, **When** the player uses the current controls and pause flow, **Then** existing desktop behavior remains intact.
2. **Given** browser support requires export-specific hooks or guards, **When** the desktop build runs, **Then** those hooks do not force a browser-style code path onto desktop gameplay.

## Edge Cases

- What happens if the browser denies fullscreen because the request is no longer tied to the active `F` keypress?
- What happens if the player presses `F` while a pause-menu control has focus or while a text-input-like browser surface has focus?
- What happens if the browser exits fullscreen through `Esc` or browser chrome rather than through the in-game `F` shortcut?
- What happens if the browser viewport becomes very small or very wide compared with the desktop test window?
- What happens if browser performance is lower than desktop and parity can only be achieved at reduced resolution or quality settings?
- What happens if the build is running on a platform or runtime mode that is effectively fullscreen-only, where a non-fullscreen display mode is not available?
- If the browser denies fullscreen, the game stays paused and the pause overlay remains available without additional failure messaging.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The project MUST define a supported web-browser play mode for the existing sandbox loop.
- **FR-002**: Browser play MUST preserve the same core gameplay loop available on desktop, including on-foot movement, vehicle entry or exit, civilian traffic presence, pause, and resume.
- **FR-003**: Browser play MUST reuse the same gameplay input actions and gameplay rules as desktop rather than introducing a browser-only control model.
- **FR-004**: Browser play MUST preserve the same intended camera framing rules as desktop so browser window size alone does not reveal extra world outside the intended frame.
- **FR-005**: The web build MUST be playable inside a browser window without requiring fullscreen.
- **FR-006**: While the game is paused in the browser build, the pause overlay MUST expose a clickable fullscreen toggle control.
- **FR-007**: The fullscreen request MUST be issued directly from the active pressed input event that triggered `F`, so the feature remains compatible with browser fullscreen restrictions documented by current Godot web-export guidance.
- **FR-008**: While the game is paused in the browser build, pressing `F` MUST also toggle fullscreen on or off.
- **FR-009**: Activating the pause-screen fullscreen control or pressing `F` for this feature MUST NOT unpause the game.
- **FR-010**: This feature MUST NOT toggle fullscreen when the game is not paused.
- **FR-011**: The pause overlay in the browser build MUST show the fullscreen control and the `F` shortcut together where the control is available.
- **FR-012**: The pause-screen fullscreen control MUST NOT be visible on platforms or runtime modes where a non-fullscreen display mode is not available.
- **FR-013**: If fullscreen is exited externally by browser UI or `Esc`, the game MUST continue running and paused state MUST remain coherent.
- **FR-014**: Desktop builds MUST remain playable without requiring browser-only code paths or browser-only input assumptions.
- **FR-015**: The first supported browser target for this feature MUST be desktop Chrome.
- **FR-016**: The implementation MUST use a custom HTML shell or narrow browser bridge as the default fullscreen path for browser builds so fullscreen requests stay in the browser-owned input event chain.
- **FR-017**: The Godot-side pause and gameplay flow MUST remain authoritative even when fullscreen entry or exit is brokered through the custom HTML shell or browser bridge.
- **FR-018**: If a browser fullscreen request is denied, the game MUST remain paused and keep the pause overlay coherent without requiring explicit failure messaging in the pause UI.
- **FR-019**: While the game is paused, pressing `F` MUST attempt the fullscreen toggle regardless of current pause-menu or browser focus state.
### Non-Functional Requirements

- **NFR-001**: Browser play SHOULD feel functionally equivalent to desktop for the current sandbox slice, including frame rate and responsiveness that match desktop as closely as practical within browser platform constraints.
- **NFR-002**: The browser feature SHOULD be implemented as a narrow export-platform layer or pause-flow extension rather than a separate gameplay fork, with the custom HTML shell limited to the fullscreen boundary.
- **NFR-003**: Browser-specific behavior SHOULD remain easy to validate through one documented manual Chrome test flow plus the existing desktop validation flow.

### Assumptions

- **A-001**: The current desktop sandbox loop remains the source of truth for browser parity.
- **A-002**: The first target is desktop Chrome; other browsers can be evaluated later.
- **A-003**: Godot 4.x web export and current browser security rules allow fullscreen changes only when requested from the active user-input event, so paused `F` handling must execute in that direct key event path.
- **A-004**: "1:1" parity means the browser build should match desktop gameplay behavior, controls, pause flow, framing intent, and responsiveness as closely as practical, while still allowing unavoidable browser-specific performance differences.
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
- Prefer a clickable pause-overlay fullscreen control as the main affordance, with `F` as a matching shortcut while paused.
- Treat browser fullscreen as a direct-input action, not a deferred request made after the keypress has been abstracted away.
- Use a custom HTML5 shell and a narrow JavaScript bridge as the default fullscreen path so browser fullscreen requests remain in the active browser input event path.
- Keep the custom shell limited to the fullscreen boundary, while gameplay logic and pause state stay inside Godot.
- Hide the pause-screen fullscreen control where the runtime does not present a meaningful choice between non-fullscreen and fullscreen display modes.
- Keep framing validation aligned with the existing expectation that fullscreen should not reveal more world than the intended fixed framing.
- Document a manual validation flow for Chrome windowed play, paused fullscreen-button entry, paused fullscreen-button exit, paused `F` fullscreen toggle, external fullscreen exit, hidden-control cases, and desktop-regression checks.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: In manual browser tests, a player can complete the current sandbox loop of moving on foot, entering a vehicle, driving, exiting, pausing, and resuming without learning a separate browser-only ruleset.
- **SC-002**: In manual Chrome tests, the pause-screen fullscreen control enters fullscreen in at least 9 out of 10 attempts while paused.
- **SC-003**: In manual Chrome tests, the pause-screen fullscreen control exits fullscreen in at least 9 out of 10 attempts while paused.
- **SC-004**: In manual Chrome tests, pressing `F` while paused toggles fullscreen in at least 9 out of 10 attempts.
- **SC-005**: In manual Chrome tests, browser window resizing and fullscreen transitions preserve the intended framed view instead of exposing extra world outside the designed play-space.
- **SC-006**: On platforms or runtime modes where a non-fullscreen display mode is not available, the fullscreen pause control remains hidden.
- **SC-007**: Desktop validation still passes after browser support work, with no regression in the current sandbox loop caused by the web feature.
- **SC-008**: In manual browser tests, on-foot movement, pause handling, and vehicle control responsiveness remain close enough to desktop that testers do not need to compensate for a meaningfully different input feel.
