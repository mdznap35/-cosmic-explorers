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


## Kenney Space Station Kit

- Asset pack: Space Station Kit (selected GLB models only).
- Creator: Kenney.
- Source: https://kenney.nl/assets/space-station-kit
- Download: https://kenney.nl/media/pages/assets/space-station-kit/6475288f2e-1712749919/kenney_space-station-kit.zip
- License: CC0 1.0 Universal.
- Selected GLB files are fetched and integrity-checked by GitHub Actions. Per-file SHA-256 and sizes are recorded in the generated `assets/vendor/kenney_space_station_kit/SOURCE_MANIFEST.json`.
- The pack dresses the Sana Hub bridge, workshop, laboratory, observatory, and Lulu nook. Gameplay code and original characters remain project-authored.
