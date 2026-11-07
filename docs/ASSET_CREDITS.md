# Asset credits

## Noto Sans Arabic

- Asset: NotoSansArabic[wdth,wght].ttf
- Copyright: The Noto Project Authors
- Source: https://github.com/google/fonts/tree/main/ofl/notosansarabic
- License: SIL Open Font License 1.1
- License text: assets/fonts/OFL.txt

The font is bundled locally so Arabic text shaping and glyph availability do not depend on a network connection or the font configuration of the phone.

## Planetary surface maps — Solar System Scope

- Assets: Sun, Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, and Neptune equirectangular maps.
- Original source: https://www.solarsystemscope.com/textures/
- License: Creative Commons Attribution 4.0 International (CC BY 4.0).
- Attribution: © Solar System Scope. Planet maps are based on NASA elevation and imagery data, with artistic color tuning and documented unmapped regions.
- Pinned distribution mirror: https://github.com/Sanghel/solar-system-3d
- Pinned source commit: `47c8bbc6b63f4c6c2310911238c2c4b6bff6d20b`
- Source attribution record: `assets/planetary_textures/SOURCE_ATTRIBUTION.md`
- Build-time SHA-256 record: `assets/planetary_textures/SHA256SUMS` (generated from the pinned source checkout).

The Android build checks out only the texture directory at the pinned commit, copies the nine maps into the project before Godot import/export, and removes the temporary source checkout. The APK therefore contains the maps and remains usable offline; the app does not make runtime network requests. The maps are not committed as opaque binary blobs in the source tree, keeping provenance and version pinning explicit.

## Procedural visual assets

The planet shader's procedural treatment, Earth cloud and atmosphere layers, Saturn ring treatment, and solar corona remain project-authored effects. They are used as a restrained overlay and as fallback when the licensed map pack is not staged.

## Third-party project evaluation

CelestialSim (MIT) was evaluated as a possible terrain engine: https://github.com/CelestialSim/CelestialSim. It is not integrated into the mobile app because its current documented path requires Vulkan (Forward+ or Mobile renderer), while this project targets Godot Compatibility/OpenGL ES; its own installation guide also describes Android as experimental and unsupported. It remains a research candidate, not a runtime dependency.


## Kenney Space Station Kit — selected station modules

- Original asset page: https://kenney.nl/assets/space-station-kit
- License: Creative Commons CC0 1.0; the official asset page identifies this license.
- Build-time distribution mirror: https://github.com/FOXSGX/Lost-in-Space
- Pinned source commit: `891b4ea3bffc94bdec1401be3acacbac0b4483d3`
- Verified source archive Git blob: `7c597f55b831249ede0467e9c72ef0899b777af8`
- Runtime subset: 18 selected GLB modules plus the shared colour-map texture.
- Build verification: every selected model exists; the source archive and texture are checked against pinned Git object IDs; the source licence is staged with the subset.
- Build behavior: fetched in GitHub Actions, copied into the project before Godot import/export, then temporary source files are removed. No runtime download is required.

## KayKit Space Base Bits — selected exterior and base modules

- Original source: https://github.com/KayKit-Game-Assets/KayKit-Space-Base-Bits-1.0
- Pinned source commit: `6dfbcac9927d06283752c4defd4882cfe0d29666`
- License: the source package's `Assets/LICENSE.txt`, staged with the selected models; the upstream package declares CC0.
- Runtime subset: eight selected glTF scenes, eight buffer files, and one shared texture.
- Build behavior: fetched at the pinned commit in GitHub Actions, hash-manifested, included in the exported APK, and available offline.

## Kenney Interface Sounds — selected interface cues

- Original asset page: https://kenney.nl/assets/interface-sounds
- License: Creative Commons CC0 1.0; the official Kenney page and support page identify Kenney asset packs as CC0.
- Pinned distribution source: https://github.com/Calinou/kenney-interface-sounds
- Pinned source commit: `4596a49eaf5a533948d49a47467f606bcdea70ff`
- Runtime subset: `click_001.wav`, `open_001.wav`, and `bong_001.wav` (used as the confirm cue).
- Build behavior: the three selected WAV files are fetched at the pinned commit, checked against their expected Git blob IDs, and bundled locally. The current introductory sequence uses the click and confirm cues; no sound is fetched while the app runs.

## Design references are not redistributed assets

- NASA Space Place and its games are used only as design references for original activities such as signal routing, rover exploration, satellite assembly, and observation.
- Their screens, illustrations, copy, and game files are not copied into this project. Each original activity uses project-authored content and rules.
