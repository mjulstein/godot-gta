[root](../../README.md) / [specs](../README.md) / [ideas](./README.md) / mission-loops.md

# Mission Loop Ideas

## Summary

Working area for mission concepts that are not yet part of the active implementation scope.

## Candidate Loops

### Stolen Vehicle Delivery

- Player steals a marked civilian vehicle
- Player delivers it to a drop point
- Wanted pressure may escalate if the theft is witnessed

Open questions:

- Should delivery require a specific vehicle condition threshold?
- Should police pressure be mandatory or optional for the first mission?
- Does success reward money, unlock state, or only prove the loop works?

### Package Pickup And Drop

- Player reaches a pickup point
- Player survives or evades pressure while carrying the package state
- Player reaches a destination marker

Open questions:

- Is the package abstract state or a world object?
- Does entering a vehicle help or cancel the objective?
- Should failure come from timeout, arrest, or abandoning the area?

## Promotion Checklist

- Core loop fits inside the current district
- Start, active, success, and failure states are clear
- Required UI/debug output is defined
- Failure handling is understood
- The loop can be tested in a few minutes
