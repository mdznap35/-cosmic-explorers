# Architecture

## Runtime layers

- Main coordinator — connects the 3D scene, UI signals, content catalog, and local save service.
- SolarSystemView — owns the world environment, camera, light, star field, orbital paths, planet placement, tap ray-casting, focus, and zoom.
- PlanetBody — creates a planet mesh, material, tap collision shape, and optional planet-specific child objects such as Earth's moon or Saturn's rings.
- PlanetCatalog — data-only definitions. New bodies and localizations should be data additions, not renderer rewrites.
- UIController — builds the screen-space interface and emits intent signals; it does not own astronomy or save logic.
- SaveService — persists only discovered planet IDs in a versioned JSON file under Godot's user data directory.

## Rendering decisions

Godot 4.7.2 stable with the Compatibility renderer is the baseline. This favors broad GLES support and mobile reach over high-end post-processing. Geometry and procedural materials keep the first scene self-contained and offline.

The current scene intentionally compresses orbital distances and exaggerates body sizes so all planets can be discovered on a phone display. Orbital animation is illustrative and accelerated; the scene is not an ephemeris and does not claim true scale.

## Extension points

- Replace PlanetCatalog with versioned JSON resources and localized content packs.
- Replace PlanetBody material selection with reusable material/shader profiles.
- Add reusable CelestialBody types for dwarf planets, moons, asteroids, comets, and spacecraft.
- Add a LearningActivity contract for experiments and missions.
- Add audio manifests and cached audio assets without making the core scene network-dependent.

## Performance guardrails

- One primary 3D scene and one camera.
- Batched star field through MultiMesh.
- No real-time shadows in the first mobile scene.
- No bloom or screen-space effects in the baseline.
- Reuse materials and meshes where measurements justify it.
- Profile on the actual target phone before raising polygon counts or enabling additional effects.

## Android delivery

The repository's Android export preset targets arm64-v8a and produces a debug-signed APK in GitHub Actions. The CI signing key is ephemeral and must never be reused for a release. A future store release requires a separately generated and securely managed release keystore.
