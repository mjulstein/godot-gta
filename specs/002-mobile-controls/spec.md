[root](../../README.md) / [specs](../README.md) / [002-mobile-controls](./README.md) / spec.md

# Feature Specification: Mobile Controls

**Feature Branch**: `002-mobile-controls`  
**Created**: 2026-03-26  
**Status**: Implemented  
**Input**: User description: "Add a mobile controls feature spec using the repo's existing Spec Kit workflow so the game is playable on iPhone/iOS with simple on-screen controls."

## Feature Summary

Define a first-pass mobile touch control scheme that lets an iPhone player use the current sandbox loop with a lower-left on-screen joystick and simple action buttons mapped to the existing action-driven input model.

## Problem Statement

The current prototype is playable through the existing input actions, but it does not yet define how those actions should be triggered on iPhone. Without a mobile control spec, iOS support is underspecified and an engineer would have to guess at layout, multitouch behavior, desktop coexistence, and how walking and driving should share the same touch inputs.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Play the sandbox on iPhone (Priority: P1)

As an iPhone player, I can control the character and vehicles using simple on-screen touch controls, so that I can fully play the game on iOS without a keyboard.

**Why this priority**: This is the whole value of the feature. If walking, vehicle use, and pause do not work from touch input, the game is not meaningfully playable on iPhone.

**Independent Test**: Run the game on an iPhone or iOS simulator with touch input, then verify that the player can walk, enter a vehicle, drive, exit, and pause using only the on-screen controls.

**Acceptance Scenarios**:

1. **Given** the player is on foot on an iPhone, **When** the player drags the lower-left on-screen joystick, **Then** the player actor moves using the existing `move_up`, `move_down`, `move_left`, and `move_right` actions.
2. **Given** the player is on foot near an interactable vehicle or object, **When** the player presses the top-right `ACT` button beside pause, **Then** the game triggers the existing `interact` action and performs the same enter, exit, or interaction behavior as desktop input.
3. **Given** the player is driving a vehicle, **When** the player steers with the lower-left joystick and uses right-hand `GAS` or `BRK` buttons, **Then** the game routes that input through the existing driving actions so the vehicle accelerates, brakes, and steers without a separate mobile-only control system.
4. **Given** the player is in active gameplay on iPhone, **When** the player presses the top-right `P` button, **Then** the game triggers the existing `pause` action and opens the same pause flow used on desktop.
5. **Given** the player holds a movement control and taps interact or pause, **When** the touches overlap, **Then** both inputs are handled correctly through multitouch without losing the held directional input.
6. **Given** the player opens the pause overlay, **When** the player cycles gameplay input scale, **Then** the joystick and gameplay action surfaces scale from their existing screen corners without resizing pause-only controls.
7. **Given** the player opens the pause overlay, **When** the player toggles impact vibration or presses restart, **Then** those controls affect only pause-time mobile quality-of-life behavior and not the core gameplay input mapping.

---

### User Story 2 - Keep desktop play unchanged (Priority: P2)

As a desktop player or developer, I can keep using the current keyboard controls while the mobile HUD remains available, so that mobile support does not regress the existing playable baseline.

**Why this priority**: The repository's current active slice is desktop-first. Mobile support is only acceptable if it layers onto the existing action map without breaking current play or testing.

**Independent Test**: Launch the game on desktop after the mobile controls feature is implemented and verify that keyboard play still works while the mobile HUD remains visible unless manually hidden by opacity.

**Acceptance Scenarios**:

1. **Given** the game is running on desktop, **When** the player uses the existing keyboard input, **Then** gameplay behavior remains unchanged.
2. **Given** the game is running on desktop, **When** the mobile HUD is visible, **Then** keyboard play still works and the HUD can be faded to `0%` by the player without changing gameplay input paths.

## Edge Cases

- What happens when the player holds two directional buttons at once to produce diagonal on-foot movement?
- What happens when the player holds a driving direction and taps `interact` to exit a vehicle while the vehicle is still moving?
- What happens when touch input begins on one control and slides off the button area?
- What happens on iPhone layouts with notches or safe-area insets that reduce the usable bottom corners?
- What happens when touch controls are available but an external keyboard or controller is also connected?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The game MUST provide an on-screen mobile control HUD for touchscreen play that can be added under the main gameplay UI layer.
- **FR-002**: The mobile HUD MUST expose a bottom-left on-screen joystick for movement and driving.
- **FR-003**: The mobile HUD MUST expose a top-right `ACT` button to the left of pause that triggers the existing `interact` action.
- **FR-004**: The mobile HUD MUST expose a top-right `P` pause button that triggers the existing `pause` action.
- **FR-005**: On foot, the directional controls MUST drive the existing `move_up`, `move_down`, `move_left`, and `move_right` actions rather than bypassing the input map.
- **FR-006**: In vehicles, the lower-left joystick MUST steer only through the existing `steer_left` and `steer_right` actions, while separate right-hand buttons MUST trigger the existing `accelerate` and `brake` actions.
- **FR-007**: The `interact` button MUST support the same enter, exit, and contextual interaction behavior already defined for desktop play.
- **FR-008**: The pause button MUST invoke the same pause behavior already defined for desktop play.
- **FR-009**: The mobile controls MUST support multitouch so directional input can overlap with `interact` or `pause`.
- **FR-010**: The mobile controls MUST be visible by default on every platform and MUST NOT interfere with existing desktop keyboard play.
- **FR-011**: The first implementation MUST prefer a simple lower-left virtual joystick plus a small set of action buttons over gestures, tilt controls, or a separate mobile-only gameplay controller.
- **FR-012**: The pause overlay MUST expose a button to toggle the debug overlay and a button to cycle on-screen HUD opacity for gameplay.
- **FR-013**: The pause overlay MUST expose a button to cycle gameplay input surface scale from `1.00x` to `2.00x` in `0.25x` steps.
- **FR-014**: Gameplay input surface scaling MUST affect only gameplay touch surfaces, with each surface growing from its existing screen corner rather than from the pause overlay layout.
- **FR-015**: The pause overlay MUST expose a vibration toggle for crash feedback, defaulted off.
- **FR-016**: Crash vibration MUST ignore low-speed bumps and scale duration with impact severity up to `0.25` seconds for strong impacts.
- **FR-017**: The pause overlay MUST expose a restart control placed away from the main pause actions so it remains available without reading as a common gameplay input.
- **FR-018**: The feature spec MUST define the control layout, behavior, and implementation approach clearly enough that an engineer can implement it without guessing.

### Non-Functional Requirements

- **NFR-001**: The first implementation SHOULD use Godot-native UI and touch input nodes, with `TouchScreenButton` preferred unless an equivalent built-in control better matches the repo's scene structure.
- **NFR-002**: The control layout SHOULD respect iPhone safe-area constraints well enough that buttons remain reachable and visible on common portrait-safe bottom corners used in landscape gameplay layouts.
- **NFR-003**: The mobile HUD SHOULD be easy to test on an iOS device without requiring a separate gameplay input path.
- **NFR-004**: Desktop keyboard controls MUST remain intact, with no mandatory mobile-only code path for core gameplay actions.
- **NFR-005**: The implementation SHOULD remain modular by keeping touch UI scene composition separate from actor and vehicle gameplay logic.

### Assumptions

- **A-001**: The existing input actions named in the repo context remain the source of truth for gameplay input.
- **A-002**: Walking and driving can share one visible directional cluster as long as the HUD maps those presses to the correct existing actions for the current control state.
- **A-003**: A first-pass iOS layout can be delivered with fixed button regions and does not require customizable remapping in v1.
- **A-004**: iPhone support is the immediate target, while broader Android tuning can be deferred unless implementation choices naturally support both.

### Out Of Scope

- **OOS-001**: Gesture-based movement, swipe actions, or multitouch gestures beyond button presses.
- **OOS-002**: Tilt or accelerometer steering.
- **OOS-003**: Gesture-recognition or swipe-combo input beyond the single movement joystick and action buttons.
- **OOS-004**: A broader HUD redesign outside the minimum controls needed for mobile playability.
- **OOS-005**: App Store packaging, release automation, or production iOS shipping requirements beyond basic playability considerations.

### Implementation Notes

- Add a dedicated mobile HUD scene such as `scenes/ui/mobile_controls_hud.tscn`.
- Keep touch UI logic in a small script such as `scripts/ui/mobile_controls_hud.gd`.
- Prefer Godot-native touch handling for the joystick drag area and for the action buttons.
- Bind button press and release behavior to the existing input actions instead of calling gameplay methods directly.
- Instance the mobile controls scene under the main gameplay UI layer used by `scenes/main/game.tscn`.
- Keep the first version simple, with a lower-left joystick, top-right `ACT` and `P` buttons, and right-hand `GAS` and `BRK` buttons for driving.
- Keep debug toggle, HUD opacity, input scale, impact vibration, and restart controls inside the pause overlay rather than in the always-on gameplay HUD.
- Treat HUD visibility as player-controlled opacity, not as an automatic platform decision.
- Treat iOS device testing as the main validation target for the first implementation.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: On iPhone, a player can start the main gameplay scene and move on foot using only the lower-left joystick and on-screen action buttons.
- **SC-002**: On iPhone, a player can enter and exit vehicles using the top-right `ACT` control in repeatable manual tests.
- **SC-003**: On iPhone, a player can drive vehicles using left-hand steering plus right-hand `GAS` and `BRK` controls in repeatable manual tests.
- **SC-004**: On iPhone, a player can pause gameplay using touch input without losing the ability to resume and continue play.
- **SC-005**: On iPhone, a player can use the pause overlay to adjust gameplay HUD opacity, gameplay input scale, impact vibration, and restart without affecting the desktop keyboard path.
- **SC-006**: Desktop keyboard play remains functional after the feature is implemented, with no regression in the current sandbox loop while the HUD remains available.
- **SC-007**: The spec and plan define the feature clearly enough that implementation work can proceed without inventing new control behavior during coding.
