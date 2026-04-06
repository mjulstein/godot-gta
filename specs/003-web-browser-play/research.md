[root](../../README.md) / [specs](../README.md) / [003-web-browser-play](./README.md) / research.md

# Research: Web Browser Play

## Decision 1: Use an in-game paused fullscreen control as the documented Chrome path

- **Decision**: The documented fullscreen path for the desktop Chrome build is an in-game pause control paired with paused `F`, using narrow browser glue only if needed to make that path reliable.
- **Rationale**: The spec requires one documented fullscreen path for desktop Chrome, and the existing validation flow already depends on a paused in-game control plus the paused `F` shortcut. This keeps the player-facing path explicit while still allowing the implementation to use a small browser bridge behind the scenes if Godot-native behavior alone is not sufficient.
- **Alternatives considered**:
  - Browser-page UI outside the game as the primary documented path: rejected because it weakens the paused-flow requirement and makes the player-facing path less explicit inside the game.
  - Custom HTML shell as the default path: rejected as a mandatory default because it is too prescriptive.
  - Godot-native fullscreen only: acceptable only if it satisfies the chosen paused-control flow without extra glue.

## Decision 2: Keep gameplay shared and limit runtime glue to the fullscreen boundary

- **Decision**: Desktop, browser, and mobile must keep the same gameplay code path. If browser-specific glue is needed, it should expose fullscreen request, fullscreen exit, fullscreen-state query, and fullscreen-change notification only.
- **Rationale**: This matches the clarified spec and constitution requirement to keep platform glue narrow and maintainable. Gameplay, pause state, camera ownership, and actor control remain in Godot.
- **Alternatives considered**:
  - Rich browser bridge with gameplay input routing: rejected because it would create a browser-only gameplay path.
  - Runtime-specific gameplay branches: rejected because they break parity across desktop, browser, and mobile.
  - No browser glue at all: acceptable only if the chosen fullscreen approach does not need it.

## Decision 3: Target desktop Chrome only for this slice

- **Decision**: Desktop Chrome remains the only supported browser target for `003-web-browser-play`.
- **Rationale**: The spec explicitly sets Chrome as the first supported browser. Keeping a single browser target limits matrix size and reduces validation noise while the fullscreen shell path is introduced.
- **Alternatives considered**:
  - Multi-browser support in the first pass: rejected because it expands validation and compatibility scope too early.
  - Progressive-web-app packaging: rejected because browser distribution and packaging are out of scope.

## Decision 4: Keep browser validation focused on normal playability with recorded fullscreen reliability checks

- **Decision**: Manual validation should confirm that the sandbox plays normally in Chrome without adding a separate browser-only responsiveness acceptance burden, and should record 10 paused attempts each for fullscreen enter, exit, and `F` toggle.
- **Rationale**: Browser support should behave like the rest of the game, while the fullscreen-specific success criteria still need deterministic evidence.
- **Alternatives considered**:
  - Hard FPS equivalence target: rejected because browser runtime variance makes it brittle for this slice.
  - Browser-specific input-feel instrumentation: rejected because it adds complexity without clear value for this feature.
  - Qualitative fullscreen checks only: rejected because they leave `SC-002` to `SC-004` untestable.

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
