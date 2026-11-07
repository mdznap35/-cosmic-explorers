# Echo of Mars — Open Asset and Presentation Polish

## Purpose

This increment moves the flagship slice away from placeholder-only construction by staging selected, license-verified open assets and using them in the actual story scene. It preserves the mission, dialogue, reward and save contracts from the previous vertical slice.

## Open assets used

### Kenney Space Station Kit

- Official page: https://kenney.nl/assets/space-station-kit
- Official archive: https://kenney.nl/media/pages/assets/space-station-kit/6475288f2e-1712749919/kenney_space-station-kit.zip
- The official page lists 90 assets under Creative Commons CC0 1.0.
- Eighteen GLB modules are staged in CI only. The Sana bridge uses floor, wall, window, display, computer, table, chair, rail, pipe, container and switch modules; the signal room and relay area reuse selected consoles and screens.
- The staging step verifies the archive, verifies every selected source file exists, and records SHA-256 manifests.

### Kenney Interface Sounds

- Official page: https://kenney.nl/assets/interface-sounds
- Official archive: https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip
- The official page lists 100 audio assets under CC0 1.0.
- Three local clips are staged for click, open and confirmation feedback. Audio is never fetched at runtime, and missing audio cannot block mission logic.

## Runtime polish

- Story camera scene changes now use eased position and orientation transitions instead of abrupt pose replacement.
- Rover follow camera uses frame-rate-independent exponential smoothing.
- Rover movement now accelerates and decelerates rather than snapping immediately to full speed.
- Rover chassis gains clearer solar-panel and sensor details while keeping the same movement and scan contracts.
- UI click, dialogue-open and stage-confirmation moments use local CC0 audio.

## Verification

- A dedicated Godot test instantiates all 18 staged GLB scenes and checks for visible mesh content.
- The same test verifies all three audio streams import correctly.
- The existing Echo of Mars integration test additionally checks that the Sana bridge actually instantiates the Kenney floor, computer and planetary display.
- The full CI workflow still imports the complete project, runs the existing gameplay tests, performs the main-scene smoke test and exports Android APKs.

## Explicit limits

This is an asset and presentation improvement, not the final art pass. It does not yet replace Reem, Salim or Lulu with final rigged character models, nor does it add final character animation, cinematic story sequences, final music or device-verified touch/performance acceptance. Those remain separate acceptance gates. No change is made to the mission or persistence data contracts.
