# Round 4 — art pipeline foundation

## Why this work exists

The first three rounds improved scene structure and interaction, but did not deliver the visual leap expected from a polished planetarium product. The most important missing ingredient was a real, provenance-tracked surface-map library. Procedural noise alone cannot convincingly reproduce the recognizable geography and atmospheric patterns of the planets.

## Integrated source project

The project now consumes only the planetary texture assets from [Sanghel/solar-system-3d](https://github.com/Sanghel/solar-system-3d), pinned to commit `47c8bbc6b63f4c6c2310911238c2c4b6bff6d20b`. Its own texture attribution file identifies Solar System Scope as the source and CC BY 4.0 as the asset license. No React/Three.js application code is copied: it is not the target runtime and would duplicate the Godot application rather than improve it.

The nine staged maps are Sun, Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, and Neptune. The Moon remains procedural pending a separately verified source.

## Runtime integration

- `PlanetBody` resolves a texture by celestial-body ID.
- `planet_surface.gdshader` samples the equirectangular map using the sphere UVs.
- A small procedural blend preserves controlled authored treatment without replacing the source map.
- If a map is unavailable in a local editor checkout, the original procedural surface remains available as a fallback.
- CI stages the pinned source before Godot import, verifies all nine files are present, records SHA-256 checksums, and removes the temporary checkout.
- Exported app remains offline at runtime; no Internet permission or remote texture request is introduced.

## Why CelestialSim is not bundled

[CelestialSim](https://github.com/CelestialSim/CelestialSim) is a promising MIT-licensed Godot planet-terrain extension, but its published install requirements specify Vulkan and Forward+/Mobile rendering. This app currently targets Compatibility/OpenGL ES, and CelestialSim's own install guide calls Android experimental and unsupported. Bundling it now would add native-extension risk without a verified Android path. Re-evaluate only after a real-device Vulkan/Android compatibility spike and memory/performance profiling.

## Acceptance for this foundation slice

- All nine maps are staged from an immutable source commit.
- Texture provenance and license are recorded.
- Each map is loaded as a Godot `Texture2D` in the visual-resource test.
- Surface shader exposes explicit real-map and fallback controls.
- CI performs asset staging before resource import and APK export.
- Existing procedural effects and the offline runtime contract remain intact.

## Not yet claimed

This is an asset-pipeline and surface-map integration milestone, not proof of final visual quality. It does not yet provide close-up terrain displacement, normal/roughness maps, a photographic skybox, final UI art direction, or measured performance on the target phone. Those require separate art passes and visual/device acceptance.
