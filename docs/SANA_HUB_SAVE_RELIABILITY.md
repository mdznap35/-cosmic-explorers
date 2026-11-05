# Sana Hub — save reliability contract

## Purpose

A progress action is accepted only after its updated state has been written successfully. A failed write must not leave the current scene looking more complete than the saved game.

## Commit order

1. Take a deep copy of the current in-memory state.
2. Apply the candidate progress change to a new/duplicated value.
3. Attempt to write the save file and inspect the resulting FileAccess error.
4. If the write fails, restore the previous state, refresh the HUD, show a retry message, and return failure to the activity caller.
5. Only after a successful write may the activity remove a world object, publish a gameplay event, or create a completion display.

## Activity-specific guarantees

- **Relay:** rejected or unpersisted route nodes do not advance the checkpoint. `signal.interacted` is published only after the final route checkpoint is saved.
- **CubeSat:** an unpersisted component does not advance the assembly or create the completed display.
- **Lulu:** an unpersisted star stays visible and can be collected again after storage is available.
- **Station visits:** an unpersisted first visit is removed from the in-memory journal and does not emit `ship.room.visited`; the station remains usable.
- **Reem observatory:** retains its pre-existing rollback behavior for both the photo ID and generated image when the state save fails.

## Regression coverage

`tests/validate_sana_hub_prototype.gd` enables a deterministic save-failure test seam and checks rejected visit/Relay/CubeSat/Lulu progress, star visibility, fresh-instance state, and successful retries after storage becomes available.

The test seam is disabled by default and is not used by gameplay. The test proves the transaction/rollback contract, not every physical storage failure mode.

## Known limitation

The current v2 save remains a direct write to the existing user file. The code checks the FileAccess write result, but it does not yet use a temp-file + atomic-replace strategy. Sudden power loss or filesystem-level corruption therefore remain separate durability risks. A future migration to atomic replacement must preserve the existing v1-to-v2 reader and all activity keys.
