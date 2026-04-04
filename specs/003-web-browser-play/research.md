[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / research.md

# Research: Web Browser Play

## Decision 1: Use a custom HTML shell as the default fullscreen path

- **Decision**: Browser fullscreen will be routed through a custom HTML shell plus narrow JavaScript bridge instead of relying on `DisplayServer.window_set_mode()` as the primary browser path.
- **Rationale**: The clarified spec now requires the browser-owned input path to be the default fullscreen mechanism. Godot 4.6 supports custom HTML shell templates for web export, and browser-facing JavaScript integration can stay narrow while preserving Godot authority over gameplay and pause state.
- **Alternatives considered**:
  - Godot-native fullscreen first with shell fallback: rejected because the spec now explicitly prefers the shell as the default path.
  - Godot-native fullscreen only: rejected because browser fullscreen restrictions can require direct browser-event ownership.

## Decision 2: Keep the bridge limited to fullscreen requests and state sync

- **Decision**: The browser bridge will expose fullscreen request, fullscreen exit, fullscreen-state query, and fullscreen-change notification only.
- **Rationale**: This matches the constitution requirement to keep platform glue narrow and maintainable. Gameplay, pause state, camera ownership, and actor control remain in Godot.
- **Alternatives considered**:
  - Rich browser bridge with gameplay input routing: rejected because it would create a browser-only gameplay path.
  - No state callback from browser to Godot: rejected because external fullscreen exit through `Esc` or browser UI must keep paused state coherent.

## Decision 3: Target desktop Chrome only for this slice

- **Decision**: Desktop Chrome remains the only supported browser target for `003-web-browser-play`.
- **Rationale**: The spec explicitly sets Chrome as the first supported browser. Keeping a single browser target limits matrix size and reduces validation noise while the fullscreen shell path is introduced.
- **Alternatives considered**:
  - Multi-browser support in the first pass: rejected because it expands validation and compatibility scope too early.
  - Progressive-web-app packaging: rejected because browser distribution and packaging are out of scope.

## Decision 4: Treat browser responsiveness as a parity concern, but not a hard identical-performance promise

- **Decision**: Manual validation should assess whether browser input feel and responsiveness remain close enough to desktop that testers do not need compensating behavior, while accepting unavoidable browser-platform differences.
- **Rationale**: The clarified spec asks for desktop-like responsiveness, but the feature still cannot guarantee identical browser and desktop performance across machines. Manual acceptance should focus on meaningful input feel rather than exact telemetry parity.
- **Alternatives considered**:
  - Qualitative parity only: rejected because it is too soft for validation.
  - Hard FPS equivalence target: rejected because browser runtime variance makes it brittle for this slice.

## Decision 5: Exclude publish workflows from this feature

- **Decision**: GitHub Pages or similar publish helpers are not part of `003-web-browser-play`.
- **Rationale**: The clarification explicitly removes publish automation from scope, keeping this feature centered on runtime behavior rather than distribution mechanics.
- **Alternatives considered**:
  - Keep publish helper as conditional scope: rejected because it diluted the feature and produced task/spec drift.
  - Make publish helper a user story in this feature: rejected because it is not part of the clarified user value for this slice.

## Sources

- Godot 4.6 web export documentation on custom HTML shell support
- Godot 4.6 `JavaScriptBridge` documentation for browser integration
- Existing project runtime code in `scripts/core/fullscreen_support.gd`, `scripts/ui/pause_controller.gd`, and `scripts/ui/palette_overlay.gd`
