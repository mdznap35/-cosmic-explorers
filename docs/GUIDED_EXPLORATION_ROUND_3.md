# Round 3 — guided discovery expedition

## Goal

Add a calm, touch-first path through all eight major planets for a young child who is still beginning to read. The child follows one clue at a time and finds the matching planet in the 3D scene or the planet strip.

## Child experience

- One short discovery clue is shown at a time.
- The child can select a planet directly in the scene or use the named planet strip.
- A correct discovery receives immediate positive feedback, reveals a short fact from that planet's existing content record, and unlocks the next stop.
- Choosing another world does not deduct points, fail the activity, or use a timer; the child can simply try again.
- The route follows the planet catalog from the Sun outward.
- The existing nine-question Explorer Challenge remains a separate activity.
- The current planet stage is saved locally and restored after the route is closed or the app is reopened.
- Completing all eight planets increments the completion history and resets the saved stage for a fresh replay.

## Progress and privacy

The route has eight stages, one per major planet. Completion increments a local counter in the existing user:// save file. Save format version 4 keeps version-1 through version-3 discovery, quiz, and completion history while adding the current guided-expedition stage (0–8). Closing the route preserves the stage; completing all eight planets increments the completion counter and resets the stage for a fresh replay. No account, network request, analytics, or personal profile is introduced.

## Verification

The automated test now instantiates the real UI and runs all eight stages: wrong choices must not advance, correct choices reveal each planet's first catalog fact, the next-stage action advances, completion persists exactly once, replay does not count prematurely, and close leaves the panel inactive. The same test also checks unique IDs, catalog order, non-empty clues, NASA source linkage, stage resume after closing/reopening, and stage reset after completion.

## Acceptance limits

A successful headless test and Android export establish resource, script, and packaging integrity. They do not replace a real-device review of touch accuracy, layout, rendering, and performance.
