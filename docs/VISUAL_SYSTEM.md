# Visual system — Cosmic Explorers

## Art direction

The interface uses a calm observatory identity: deep-space navy surfaces, restrained cyan guidance, warm gold for the primary learning action, and clear near-white Arabic typography. Decorative treatment must never compete with the selected celestial body or the learning objective.

## Layout hierarchy

1. Welcome experience — a short first screen that introduces the journey and offers two direct paths: free exploration or the explorer mission.
2. Exploration header — product identity, local discovery progress, mission access, motion preference, scene reset, and zoom.
3. World navigation — a horizontal, touch-friendly selector for the Sun and eight planets. Discovered planets receive a subtle completion mark; the selected body receives a gold focus treatment.
4. Discovery station — selected body name, English identifier, body classification, one-sentence headline, concise description, one quick fact, and an expandable fact layer.
5. Scene hint — a compact instruction for drag rotation and tap selection.

## Interface design tokens

- Space base: #030A1D to #07152B.
- Main panels: deep navy with a cool blue-grey border.
- Secondary panels: slightly lighter navy for depth without harsh contrast.
- Guidance accent: cyan.
- Primary learning action and selected state: warm gold.
- Main text: near-white; secondary text: muted blue-grey.
- Panels use restrained rounded corners and low-opacity shadows.
- Buttons have explicit hover, pressed, focus, and disabled states.

## Celestial material profiles

The current rendering layer uses distinct procedural shader branches for:
- Mercury: mineral ground and crater-like relief.
- Venus: turbulent golden cloud bands.
- Earth: blue ocean, irregular green land masses, and cloud detail.
- Mars: rusty terrain and polar regions.
- Jupiter: atmospheric stripes and a stylized Great Red Spot.
- Saturn: layered atmospheric bands; its rings are separate geometry.
- Uranus: quiet cyan-green atmospheric bands.
- Neptune: deep-blue bands and a darker storm.
- Sun: warm convection-like texture and a soft corona.

These are visual interpretations, not mapped spacecraft images or measured surface data. Any later photographic or scanned texture pack must cite its original source, usage rights, and alterations in docs/ASSET_CREDITS.md.

## Child-first interaction rules

- Keep the primary exploration action obvious.
- Use concise Arabic instructions and one main learning idea at a time.
- Keep touch targets comfortably large.
- Do not depend on color alone: selected/discovered states also change border, text, or marker.
- Preserve a clear route back to the main scene.
- Motion can be paused from the header.
- The welcome layer is dismissible through explicit actions and does not require network access.
- A single tap selects a body; dragging rotates the view rather than selecting a body.

## Scientific visualization caveats

The scene compresses orbital distances and exaggerates body sizes to fit a phone display. The orbital animation is illustrative and accelerated, not a live ephemeris or a scale-accurate model. The Sun is a star, not one of the eight planets, and is excluded from the eight-planet discovery count.

## Responsive and device acceptance

The layout is authored against the 16:9 landscape design viewport and uses proportional panel anchors. This is a design baseline, not proof of device fit. Every release must be checked on the target Android phone for Arabic shaping, clipping, touch areas, safe areas, and frame pacing. Device acceptance remains open until a real-device test is recorded.
