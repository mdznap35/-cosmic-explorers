# Echo of Mars — Open Asset and Presentation Polish

## Purpose

This increment moves the flagship slice away from placeholder-only construction by staging selected, license-verified open assets and using them in the actual story scene. It preserves the mission, dialogue, reward and save contracts from the previous vertical slice.

## Open assets used

### Kenney Space Station Kit

- Official page: https://kenney.nl/assets/space-station-kit
- Original ZIP is fetched from pinned mirror commit `FOXSGX/Lost-in-Space@891b4ea3bffc94bdec1401be3acacbac0b4483d3`; the file's Git blob is checked before extraction, and Kenney's included CC0 license is retained.
- The official page lists 90 assets under Creative Commons CC0 1.0.
- Eighteen GLB modules are staged in CI only. The Sana bridge uses floor, wall, window, display, computer, table, chair, rail, pipe, container and switch modules; the signal room and relay area reuse selected consoles and screens.
- The staging step verifies the archive, verifies every selected source file exists, and records SHA-256 manifests.

### Kenney Interface Sounds

- Official page: https://kenney.nl/assets/interface-sounds
- Official archive: https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip
- The official page lists 100 audio assets under CC0 1.0. The Godot-ready mirror `Calinou/kenney-interface-sounds@4596a49eaf5a533948d49a47467f606bcdea70ff` includes Kenney's CC0 license and README documenting lossless WAV conversions.
- Three local WAV clips are staged for click, open and confirmation feedback. Audio is never fetched at runtime, and missing audio cannot block mission logic.

## Runtime polish

- Story camera scene changes now use eased position and orientation transitions instead of abrupt pose replacement.
- Rover follow camera uses frame-rate-independent exponential smoothing.
- Rover movement now accelerates and decelerates rather than snapping immediately to full speed.
- Rover chassis gains clearer solar-panel and sensor details while keeping the same movement and scan contracts.
- UI click, dialogue-open and stage-confirmation moments use local CC0 audio.

## Opening sequence — the signal becomes visible

- The Sana bridge opening now presents an illuminated Mars globe using the already-staged Mars surface map, with three independently pulsing orbital rings and a slow-moving signal marker.
- A wall display renders three identical 32-bar traces using one Godot MultiMesh (96 instances, one batched mesh), so players can visually notice that the three received pulses share the same pattern before the story names the explanation.
- The player can tap each of the three waveform rows directly in the 3D display; each row has its own ray-pickable Area3D hit target that accepts touchscreen taps and mouse clicks. The same labeled HUD actions remain available as an accessible fallback.
- Each inspection highlights its own trace and is saved immediately; the comparison action remains locked until all three have been examined.
- The integration test emits both touch and mouse input through the real Area3D signal wiring and checks all three independent hit targets.
- Re-entering the first stage restores the highlighted traces from the local save. Existing version-1 saves safely default to an empty inspection list; the save version and mission event contract remain unchanged.
- The globe texture is sourced from the existing Solar System Scope planetary-map staging step. Its upstream attribution/license notice is carried into the exported project; the texture is not downloaded at runtime.
- The hologram exists only in the first signal stage. The subsequent Sana scenes keep their existing layout, mission stages and reward behavior.
- The integration test checks the texture binding, all three pulse rings, the 96-instance waveform, equality of the repeated signal traces, per-pulse actions, progression lock and save-facing inspection state.

- The Sana bridge opening now presents an illuminated Mars globe using the already-staged Mars surface map, with three independently pulsing orbital rings and a slow-moving signal marker.
- A wall display renders three identical 32-bar traces using one Godot MultiMesh (96 instances, one batched mesh), so players can visually notice that the three received pulses share the same pattern before the story names the explanation.
- The globe texture is sourced from the existing Solar System Scope planetary-map staging step. Its upstream attribution/license notice is carried into the exported project; the texture is not downloaded at runtime.
- The hologram exists only in the first signal stage. The subsequent Sana scenes keep their existing layout, mission stages, event IDs and persistence behavior.
- The integration test checks the texture binding, all three pulse rings, the 96-instance waveform and equality of the repeated signal traces.

## Verification

- A dedicated Godot test instantiates all 18 staged GLB scenes and checks for visible mesh content.
- The same test verifies the shared colormap imports as a Texture2D and all three WAV audio streams import correctly.
- The existing Echo of Mars integration test additionally checks that the Sana bridge actually instantiates the Kenney floor, computer and planetary display.
- The full CI workflow still imports the complete project, runs the existing gameplay tests, performs the main-scene smoke test and exports Android APKs.

## Explicit limits

This is an asset and presentation improvement, not the final art pass. It does not yet replace Reem, Salim or Lulu with final rigged character models, nor does it add final character animation, cinematic story sequences, final music or device-verified touch/performance acceptance. Those remain separate acceptance gates. No change is made to the mission or persistence data contracts.
