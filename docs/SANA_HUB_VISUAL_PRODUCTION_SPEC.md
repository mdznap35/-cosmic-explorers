# Sana Hub — Visual Production Specification

> Version 1.0 — 4 November 2026  
> Project: مستكشفو الكون: خريطة الضوء  
> Target branch: `sana-hub-vertical-slice-v1`  
> Status: production specification; **not** a claim that the art assets below have been created or imported.

## 1. Purpose and production decision

The current Sana Hub is a functional graybox: five stations, a temporary player, touch/keyboard movement, proximity interaction, three activities, and local checkpoint persistence. The next meaningful quality leap is not adding more empty rooms or more mini-games. It is turning this already playable space into one visually coherent, characterful environment while preserving its tested gameplay contracts.

This document defines the art target and the order in which it should be produced. It does not authorize replacing the existing main solar-system scene, changing the renderer, or importing unverified asset packs.

## 2. Non-negotiable product identity

- Arabic-first, child-readable, welcoming, and immediately interactive.
- Stylized 3D with deliberate shapes and strong silhouettes; not photorealism and not a collection of unrelated low-poly packs.
- The ship should feel like a small scientific home: practical enough to suggest exploration, warm enough to invite play.
- Deep-space navy, restrained cyan navigation accents, warm gold for important focus states, and near-white Arabic typography remain the global identity.
- Interior lighting may be warmer than the exterior, but must remain part of the same palette.
- The player should understand where to go from geometry, lighting, signage, and character staging—not from paragraphs.
- All essential play remains possible without audio and without a network connection.

## 3. Visual language

### Shape grammar

Use three complementary shape families:

1. **Exploration / navigation:** clear arcs, rings, radial marks, antenna silhouettes, and directional light paths.
2. **Workshop / engineering:** rounded rectangular modules, visible joints, chunky handles, modular sockets, and readable assembly parts.
3. **Comfort / character spaces:** soft curves, large friendly forms, fabric-like panels, plants or playful ornaments, and low visual density.

Avoid sharp spikes, aggressive military styling, cluttered control panels, and tiny unreadable labels.

### Material grammar

- Structural shell: matte blue-grey, with limited roughness variation.
- Navigation glass: dark translucent-looking surfaces with restrained cyan emission; avoid expensive layered transparency where an opaque approximation works.
- Interaction surfaces: warm gold or cyan edge cues with a second non-colour cue such as icon, outline, scale, or motion.
- Character props: saturated accent colours used sparingly and consistently.
- Floors: low-contrast directional patterns that subtly guide movement.
- Screens: authored graphic layouts and iconography, not random decorative code.

### Lighting

- One clear key-light direction per room.
- Soft fill to preserve readable faces and interaction targets.
- Emissive accents are navigational cues, not general decoration.
- Bake/static-light wherever practical. Reserve real-time lights and shadows for elements that visibly need them.
- Every station must remain legible on a small phone display and in a reduced-brightness environment.

## 4. Ship layout and station identities

The graybox's five station IDs and their gameplay contracts remain stable:

| Station ID | Arabic name | Visual identity | Gameplay purpose |
|---|---|---|---|
| `bridge` | جسر القيادة | Forward-facing panoramic viewport, central route table, three large navigation controls, a clear communications mast motif | Mission selection and «رسالة مرقاب» |
| `workshop` | ورشة سليم | Modular workbench, four large component docks, tool wall, compact assembly display | «ابنِ قمرك المصغّر» and future vehicle customization |
| `laboratory` | مختبر مرقاب | Calm analysis bay, sample trays, scan ring, large observation screen, labelled evidence slots | Future sample analysis and evidence classification |
| `observatory` | مرصد ريم | Telescope/camera silhouette, circular viewing aperture, framing guides, image wall | Future observation and photo album |
| `lulu_nook` | ركن لولو | Cozy low-height habitat, safe wide passages, soft nest, small discovery alcoves and five clear hiding-place zones | «أسرار لولو» and companion moments |

### Spatial composition

- Preserve the existing station IDs, interaction entry points, and return path.
- Keep a readable central circulation loop. No station should be hidden behind another station's visual mass.
- Give each station a unique silhouette visible from the hub's central area.
- Use floor inlays, ceiling lights, and colour accents as a quiet wayfinding system.
- The player must be able to approach every interaction without pixel-perfect positioning.
- Avoid decorative props inside the player's movement corridor.
- The ship should look inhabited: a few meaningful props, character traces, and small idle animations are better than hundreds of repeated objects.

## 5. Character art targets

The current temporary player mesh is a placeholder. It must not be presented as a finished character.

### ريم

- Readable explorer silhouette with a practical observation outfit.
- Distinct camera / scanner prop and a clear visual cue for observation.
- Face and eye direction must support looking at discoveries and other characters.
- Required animation set: idle, walk, turn, inspect, photograph, celebrate, gentle surprise.

### سليم

- Readable builder silhouette with a tool pouch and a compact modular tool.
- Workshop colour accent must remain consistent across outfit, props, and station.
- Required animation set: idle, walk, turn, inspect, assemble, adjust, celebrate, gentle surprise.

### لولو

- Custom non-humanoid rig; do not retarget a human animation pack onto the snail.
- Preserve a clear shell/body/eye-stalk silhouette at phone scale.
- Required animation set: rest, glide, turn, peek, look-up, happy reaction, curious reaction, hide/reappear.
- Movement should feel deliberate and charming, never like a humanoid walking cycle.
- His habitat must be safe, wide, and comfortable; no gameplay should require him to enter a hazardous or inaccessible space.

### Shared character requirements

- Consistent stylization, eye scale, outline/edge treatment, material response, and texture density.
- Neutral pose and rig validation before authoring a large animation set.
- Test each model at actual gameplay camera distance; detail that cannot be read at that distance is not a priority.
- Character swapping must continue to use the existing CharacterRoster contract and must not reset activity progress.

## 6. Camera and motion

- Keep the current third-person follow-camera concept, but tune it for comfortable phone play.
- Camera collision must prevent clipping through walls and large props.
- Use a stable horizon and restrained acceleration; no forced camera shake.
- Interaction framing should gently direct attention without taking control away for long.
- Any cinematic movement must be skippable and must return to a known gameplay camera state.
- Touch controls must remain reachable with either hand where practical; UI safe areas must be respected.

## 7. Open-source asset intake policy

Potential resources already recorded in the project's asset ledger include:

- Kenney Space Station Kit — candidate for selected modular station pieces; recorded as CC0 1.0, but no files have been imported in this slice.
- Quaternius Universal Animation Library — candidate for compatible humanoid motion references/animations; it cannot provide Lulu's custom snail rig.
- Poly Haven — candidate for selected materials/HDRI only where the runtime budget justifies them.

No candidate becomes an integrated asset until all of the following are recorded:

1. Exact source URL and immutable release/commit/version.
2. Exact license text and attribution obligations.
3. Downloaded archive size and SHA-256.
4. Selected file list; do not import an entire pack by default.
5. Format/import settings and texture dimensions.
6. Godot 4.7.2 Compatibility renderer import result.
7. APK size delta and runtime memory impact.
8. Visual fit with the project's shape/material grammar.
9. Asset ledger entry and CI validation.

Reference games (including NASA Space Place activities) are design references only. Recreate interaction patterns in original scenes, code, wording, and artwork; do not copy their screenshots, characters, text, or proprietary files.

## 8. Android-first technical art constraints

These are initial engineering targets to measure, not claims about current performance:

- Keep the ship interior as a compact scene with controlled visibility.
- Prefer shared materials, mesh reuse, and MultiMesh for repeated decorative elements.
- Use simple collision shapes; decorative geometry should not carry unnecessary collision.
- Prefer baked/static lighting and a small number of dynamic lights.
- Avoid expensive full-screen effects, heavy transparency, dense particles, and high-frequency shader animation in the hub.
- Use compressed textures and mipmaps where appropriate; author texture sizes from visible screen-space needs.
- Use LOD or simplified meshes for objects that become small at the gameplay camera distance.
- Initial performance goal: stable 30 FPS on the minimum supported Android profile, with 60 FPS as a stretch target on capable devices. Confirm by device profiling before freezing budgets.
- Record startup time, scene transition time, frame pacing, memory, APK size, and thermal behaviour during device acceptance.

The Compatibility renderer remains the baseline. A renderer change or large engine extension requires a separate Android feasibility spike and measured evidence.

## 9. Production sequence

### ART-0 — Style lock and blockout audit

- Capture the current hub from fixed camera positions.
- Approve a one-page palette/material/shape sheet.
- Record each station's dimensions, player path, camera view, and interaction location.
- Identify graybox geometry that can be retained as collision/layout guides.
- Acceptance: all five stations remain navigable and readable in a single visual language.

### ART-1 — One-room asset pilot

- Select only a small number of candidate modular assets.
- Verify source, license, archive size, SHA-256, import settings, and Compatibility rendering.
- Build one representative room section (bridge first) without changing activity logic.
- Compare the imported pieces against the style sheet; reject mismatched assets rather than forcing them into the scene.
- Acceptance: one room looks coherent, imports cleanly, and does not break the hub test or Android export.

### ART-2 — Complete ship shell and station dressing

- Apply the approved modular language to the circulation loop and five station silhouettes.
- Add only props that clarify a function or create a meaningful character moment.
- Keep all station IDs and interaction triggers stable.
- Acceptance: a new player can identify all five destinations without reading a long instruction.

### ART-3 — Character pilot

- Produce one final-quality humanoid pilot model and rig first.
- Validate scale, camera readability, materials, touch movement, and core animation states.
- Build Lulu as a separate custom-rig workstream after the humanoid pipeline is stable.
- Acceptance: character locomotion and interaction work in the actual hub, not just in an isolated render.

### ART-4 — Lighting, UI and feedback polish

- Add restrained station-specific lighting and clear interaction feedback.
- Ensure Arabic text shaping, RTL order, contrast, and safe areas.
- Add short character reactions and optional audio hooks without making audio mandatory.
- Acceptance: the hub is readable and pleasant on the target Android device in normal and reduced brightness.

### ART-5 — Device acceptance

- Install the exact CI artifact on a physical Android device.
- Test movement, camera, all five stations, all three activities, pause/resume, save/restore, and return navigation.
- Measure FPS, frame pacing, memory, heat, startup, and scene transitions.
- Acceptance: record the tested artifact SHA-256, device/build details, test outcomes, and known defects.

## 10. Regression contracts

Visual work must not silently change these existing contracts:

- Scene remains standalone; the current main solar-system scene is untouched.
- Station IDs remain: `bridge`, `workshop`, `laboratory`, `observatory`, `lulu_nook`.
- Relay order and partial checkpoint restoration remain unchanged.
- CubeSat assembly order and partial checkpoint restoration remain unchanged.
- Lulu's five hidden-star IDs and partial checkpoint restoration remain unchanged.
- Closing an activity releases movement/input locks and clears touch state.
- Existing optional GameplayRuntime/InteractionRouter integration remains non-destructive.
- Local save remains isolated at `user://sana_hub_prototype.json` until an explicit migration design is reviewed.

## 11. Definition of done

The art pass is not complete because a screenshot looks attractive. It is accepted only when:

- The environment follows the approved visual language.
- Every station remains functional and easy to navigate.
- Characters are rigged and animated at gameplay distance.
- Arabic UI and touch targets are verified on-device.
- Existing gameplay and persistence tests pass.
- Android export succeeds with no unintended network permission.
- Asset provenance is complete for every external file.
- Performance and thermal results are measured on the target device.

## 12. Current truthful status

- The Sana Hub graybox and three initial activities exist on `sana-hub-vertical-slice-v1`.
- GitHub Actions run #79 succeeded on code commit `e82b96d433be5e6421479a25a315c01d515bf672`; the branch's later top commit `650b49c51ce22f0b2e48dd28515c778dcd806da9` is documentation-only.
- The PR is still open as a draft and has not been merged.
- The Kenney kit and other listed art packs remain candidates, not imported assets.
- Final character models, rigs, animations, polished ship art, and physical-device acceptance remain open.
