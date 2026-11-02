# Architecture

## Runtime layers

- Main coordinator — connects the 3D scene, UI signals, content catalog, and local save service.
- SolarSystemView — owns the world environment, camera, light, star field, orbital paths, planet placement, tap ray-casting, focus, and zoom.
- PlanetBody — creates a planet mesh, specialized procedural surface material, tap collision shape, and layered body-specific visual objects such as Earth's cloud/atmosphere shells and Moon, Saturn's ring shader, and the Sun's corona shells.
- PlanetCatalog — data-only definitions. New bodies and localizations should be data additions, not renderer rewrites.
- UIController — builds the screen-space interface and emits intent signals; it does not own astronomy or save logic.
- SaveService — persists only discovered planet IDs in a versioned JSON file under Godot's user data directory.

## Rendering decisions

Godot 4.7.2 stable with the Compatibility renderer is the baseline. This favors broad GLES support and mobile reach over high-end post-processing. Geometry and procedural shaders keep the scene self-contained and offline. The second visual pass adds distinct surface profiles, a separate Earth cloud shell and atmospheric rim, a banded Saturn ring material, and layered solar corona.

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
- Reuse simple meshes where measurements justify it; keep specialized shader variants limited to the few distinct body profiles.
- Keep shader animation clocks frozen when the user pauses motion.
- Profile on the actual target phone before raising polygon counts or enabling additional effects.

## Android delivery

The repository's Android export preset targets arm64-v8a and produces a debug-signed APK in GitHub Actions. The CI signing key is ephemeral and must never be reused for a release. A future store release requires a separately generated and securely managed release keystore.
