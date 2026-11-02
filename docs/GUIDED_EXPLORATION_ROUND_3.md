# Round 3 — guided discovery expedition

## Goal

Add a calm, touch-first path through all eight major planets for a young child who is still beginning to read. The child follows one clue at a time and finds the matching planet in the 3D scene or the planet strip.

## Child experience

- One short discovery clue is shown at a time.
- The child can select a planet directly in the scene or use the named planet strip.
- A correct discovery receives immediate positive feedback and unlocks the next stop.
- Choosing another world does not deduct points, fail the activity, or use a timer; the child can simply try again.
- The route follows the planet catalog from the Sun outward.
- The existing nine-question Explorer Challenge remains a separate activity.

## Progress and privacy

The route has eight stages, one per major planet. Completion increments a local counter in the existing user:// save file. Save format version 3 keeps version-1 and version-2 discovery and quiz progress while adding the guided-expedition count. No account, network request, analytics, or personal profile is introduced.

## Verification

The new catalog test checks stage count, unique stable IDs, the expected catalog order, non-empty clues, and linkage to each planet's NASA source record. The Android workflow runs this test before the main-scene smoke test and export.

## Acceptance limits

A successful headless test and Android export establish resource, script, and packaging integrity. They do not replace a real-device review of touch accuracy, layout, rendering, and performance.
