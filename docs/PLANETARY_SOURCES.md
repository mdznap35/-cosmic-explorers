# Planetary content source register

Reviewed for the first child-facing layer on 2026-11-02. Each in-app body record stores its own `source_url` field so provenance stays with the data as the catalog grows.

| Body | Primary NASA fact page | Topics grounded by the page |
|---|---|---|
| Sun | https://science.nasa.gov/sun/facts/ | Star classification, size, energy, gravity, rotation, structure |
| Mercury | https://science.nasa.gov/mercury/facts/ | Smallest planet, nearest to Sun, surface temperature, 88-day orbit |
| Venus | https://science.nasa.gov/venus/venus-facts/ | Hottest planetary surface, thick carbon-dioxide atmosphere, slow retrograde spin |
| Earth | https://science.nasa.gov/earth/facts/ | Liquid water, one Moon, 365.25-day year, 8.35-minute sunlight travel time |
| Mars | https://science.nasa.gov/mars/facts/ | Red planet, rocky surface, exploration, orbital and rotation facts |
| Jupiter | https://science.nasa.gov/jupiter/jupiter-facts/ | Largest planet, Great Red Spot, gas-giant nature, Galilean moons |
| Saturn | https://science.nasa.gov/saturn/facts/ | Ring particles made of ice and rock, atmosphere, moons |
| Uranus | https://science.nasa.gov/uranus/facts/ | 97.77-degree axial tilt, 84-year orbit, ice giant |
| Neptune | https://science.nasa.gov/neptune/neptune-facts/ | Most distant major planet, 165-year orbit, fast winds |

Additional specialist sources:
- Mars' two moons: https://science.nasa.gov/mars/moons/
- Earth's place as the only world currently known to host life: https://science.nasa.gov/exoplanets/can-we-find-life/
- NASA Space Place learning resources: https://spaceplace.nasa.gov/

## Editorial safeguards

- The child-facing copy is a short Arabic adaptation, not a direct reproduction of NASA prose.
- The visualization exaggerates sizes and compresses distances. The app states this in its architecture/learning documentation; later UI should repeat the caveat near the model.
- The orbital animation is a teaching illustration, not a current-position ephemeris.
- The word “planet” is reserved for the eight major planets. The Sun is stored separately as a star; dwarf planets and small bodies belong in later data collections.
- Potential life on Europa or elsewhere is described as a research question, never as confirmed life.
- Any future mission, moon-count, or discovery fact that can change must carry a checked-on date and be reviewed before release.
