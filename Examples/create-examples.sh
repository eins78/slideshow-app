#!/bin/bash
# Regenerate example .slideshow bundles from public domain sources.
# All images are public domain (NASA/US Gov, Rijksmuseum CC0, Wikimedia PD).
# Requires: curl, sips (macOS built-in)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAX_SIZE=1600

download_and_resize() {
    local url="$1" output="$2"
    if [ -f "$output" ]; then
        echo "  Exists: $(basename "$output")"
        return 0
    fi
    echo "  Downloading: $(basename "$output")"
    if ! curl -sfL -H "User-Agent: SlideshowApp/1.0 (example content)" -o "$output" "$url"; then
        echo "  ERROR: Failed to download $(basename "$output")"
        return 1
    fi
    # Convert to JPEG if not already
    if file -b "$output" | grep -qi "png\|webp\|tiff"; then
        sips -s format jpeg "$output" --out "$output.tmp.jpg" >/dev/null 2>&1
        mv "$output.tmp.jpg" "$output"
    fi
    sips --resampleHeightWidthMax "$MAX_SIZE" "$output" >/dev/null 2>&1
}

write_sidecar() {
    local path="$1" content="$2"
    printf '%s\n' "$content" > "$path"
}

# =============================================================================
# 1. My Favorite Space Pictures (NASA, public domain)
# =============================================================================
echo "=== My Favorite Space Pictures ==="
SPACE="$SCRIPT_DIR/My Favorite Space Pictures.slideshow"
mkdir -p "$SPACE"

download_and_resize "https://images-assets.nasa.gov/image/as17-148-22727/as17-148-22727~large.jpg" "$SPACE/001--blue-marble.jpg"
download_and_resize "https://images-assets.nasa.gov/image/GSFC_20171208_Archive_e000842/GSFC_20171208_Archive_e000842~large.jpg" "$SPACE/002--pillars-of-creation.jpg"
download_and_resize "https://images-assets.nasa.gov/image/PIA06193/PIA06193~large.jpg" "$SPACE/003--saturn.jpg"
download_and_resize "https://images-assets.nasa.gov/image/carina_nebula/carina_nebula~large.jpg" "$SPACE/004--cosmic-cliffs.jpg"
download_and_resize "https://images-assets.nasa.gov/image/PIA03606/PIA03606~large.jpg" "$SPACE/005--crab-nebula.jpg"
download_and_resize "https://images-assets.nasa.gov/image/GSFC_20171208_Archive_e000833/GSFC_20171208_Archive_e000833~large.jpg" "$SPACE/006--andromeda.jpg"
download_and_resize "https://images-assets.nasa.gov/image/PIA12110/PIA12110~large.jpg" "$SPACE/007--hubble-deep-field.jpg"
download_and_resize "https://images-assets.nasa.gov/image/PIA19400/PIA19400~large.jpg" "$SPACE/008--mars-sunset.jpg"
download_and_resize "https://images-assets.nasa.gov/image/PIA25970/PIA25970~large.jpg" "$SPACE/009--ingenuity.jpg"
download_and_resize "https://images-assets.nasa.gov/image/PIA20202/PIA20202~large.jpg" "$SPACE/010--pluto.jpg"

write_sidecar "$SPACE/001--blue-marble.jpg.md" '---
caption: The Blue Marble
source: |
  NASA / Apollo 17 crew, 1972
  Public Domain
---

This is Earth from really far away — about 29,000 kilometers.
The Apollo 17 astronauts took this on December 7, 1972.
You can see Africa and Antarctica and the whole Indian Ocean.

It'\''s one of the most copied photos ever. I think it'\''s because
it'\''s the first time people could see that Earth is actually round
and floating in nothing.'

write_sidecar "$SPACE/002--pillars-of-creation.jpg.md" '---
caption: Pillars of Creation
source: |
  NASA / ESA / Hubble Heritage Team
  Public Domain
---

These are called the Pillars of Creation and they'\''re in the
Eagle Nebula. They'\''re columns of gas and dust where new stars
are being born RIGHT NOW.

Each pillar is about 4 to 5 light-years tall. That means if you
could drive a car at highway speed, it would take you about
50 million years to get from the bottom to the top of one pillar.'

write_sidecar "$SPACE/003--saturn.jpg.md" '---
caption: The Greatest Saturn Portrait
source: |
  NASA / JPL-Caltech / Space Science Institute / Cassini
  Public Domain
---

This is made of 126 separate photos stitched together by the
Cassini spacecraft in 2004. It shows the whole planet and all
its rings in real color.

Saturn'\''s rings are mostly made of ice chunks — some as small
as grains of sand, some as big as houses. The rings are super
wide but really thin, like a DVD that'\''s 100,000 kilometers across.'

write_sidecar "$SPACE/004--cosmic-cliffs.jpg.md" '---
caption: Cosmic Cliffs
source: |
  NASA / ESA / CSA / STScI / James Webb Space Telescope
  Public Domain
---

This was the first picture from the James Webb Space Telescope
that made everyone go "whoa." It'\''s the edge of a star nursery
in the Carina Nebula.

The "cliffs" are actually walls of gas and dust being eaten away
by radiation from baby stars. Webb can see through the dust
with infrared light, so it found stars that nobody had ever seen before.'

write_sidecar "$SPACE/005--crab-nebula.jpg.md" '---
caption: Crab Nebula
source: |
  NASA / ESA / Hubble Space Telescope
  Public Domain
---

In the year 1054, Chinese astronomers saw a new star appear in
the sky. It was so bright you could see it during the day for
three weeks. This is what'\''s left of that explosion.

Hubble took 24 separate photos and stitched them together to make
this. In the middle there'\''s a neutron star spinning 30 times per
second — it'\''s the dead core of the star that exploded.'

write_sidecar "$SPACE/006--andromeda.jpg.md" '---
caption: Andromeda Galaxy
source: |
  NASA / ESA / Hubble Space Telescope
  Public Domain
---

This is the Andromeda Galaxy and it'\''s heading straight toward us
at 110 kilometers per SECOND. Don'\''t worry though — it won'\''t get
here for another 4.5 billion years.

Hubble resolved over 100 million individual stars in this picture.
Andromeda is the farthest thing you can see with your naked eye
on a dark night — it'\''s 2.5 million light-years away.'

write_sidecar "$SPACE/007--hubble-deep-field.jpg.md" '---
caption: Hubble Deep Field
source: |
  NASA / STScI / Hubble Space Telescope, 1996
  Public Domain
---

In 1996, scientists pointed Hubble at a tiny patch of sky that
looked completely empty — about the size of a tennis ball seen
from 100 meters away. They left the camera open for 10 days.

They found over 3,000 galaxies. Each galaxy has billions of stars.
Some of the light in this picture has been traveling for over
12 billion years. This one picture changed what we think about
how big the universe is.'

write_sidecar "$SPACE/008--mars-sunset.jpg.md" '---
caption: Sunset on Mars
source: |
  NASA / JPL-Caltech / MSSS / Curiosity Rover, 2015
  Public Domain
---

On Earth, sunsets are red and orange. On Mars, sunsets are BLUE.
This is because Mars dust is the right size to scatter blue light
forward toward the camera, which is the opposite of what happens
on Earth.

The Curiosity rover took this on April 15, 2015. It was the first
color sunset ever photographed on Mars. The Sun looks smaller
because Mars is farther away from it than we are.'

write_sidecar "$SPACE/009--ingenuity.jpg.md" '---
caption: Ingenuity Helicopter on Mars
source: |
  NASA / JPL-Caltech / Perseverance Rover, 2023
  Public Domain
---

This is a helicopter. Flying on Mars. The air on Mars is only 1%
as thick as Earth'\''s air, so the blades have to spin super fast —
about 2,400 revolutions per minute.

Ingenuity was only supposed to fly 5 times as a technology test.
It ended up flying 72 times over almost 3 years. It explored
places the rover couldn'\''t reach and helped plan driving routes.'

write_sidecar "$SPACE/010--pluto.jpg.md" '---
caption: Pluto Close-Up
source: |
  NASA / Johns Hopkins APL / SwRI / New Horizons, 2015
  Public Domain
---

Before New Horizons flew past in 2015, Pluto was just a blurry
dot. Nobody expected it to look like this — it has mountains
made of water ice, glaciers of frozen nitrogen, and a giant
heart-shaped plain.

The spacecraft had been flying for 9.5 years to get there. It
only had a few hours to take pictures because it was moving so
fast. These are some of the sharpest pictures of any world that
far from the Sun.'

# =============================================================================
# 2. Paintings That Tell Secrets (Rijksmuseum CC0 + Wikimedia PD)
# =============================================================================
echo "=== Paintings That Tell Secrets ==="
PAINT="$SCRIPT_DIR/Paintings That Tell Secrets.slideshow"
mkdir -p "$PAINT"

download_and_resize "https://iiif.micr.io/PJEZO/full/2000,/0/default.jpg" "$PAINT/001--night-watch.jpg"
download_and_resize "https://iiif.micr.io/hqxQG/full/2000,/0/default.jpg" "$PAINT/002--love-letter.jpg"
download_and_resize "https://upload.wikimedia.org/wikipedia/commons/e/ea/Van_Gogh_-_Starry_Night_-_Google_Art_Project.jpg" "$PAINT/003--starry-night.jpg"

write_sidecar "$PAINT/001--night-watch.jpg.md" '---
caption: The Night Watch
source: |
  Rembrandt van Rijn, 1642
  Rijksmuseum, Amsterdam — CC0 Public Domain
---

This painting is HUGE — 3.6 meters tall and 4.4 meters wide.
It shows a militia company, which is like a neighborhood army,
getting ready to march. But here'\''s the secret: there'\''s a little
girl in a golden dress near the middle that nobody can explain.

Rembrandt broke all the rules. Other group portraits were boring —
everyone standing in a row. He made it look like a movie scene
with dramatic light and people caught in the middle of moving.
The painting is so important it has its own room at the Rijksmuseum.'

write_sidecar "$PAINT/002--love-letter.jpg.md" '---
caption: The Love Letter
source: |
  Johannes Vermeer, c. 1669
  Rijksmuseum, Amsterdam — CC0 Public Domain
---

You'\''re spying. Vermeer painted this so you'\''re looking through a
doorway into a private moment — a woman has just received a
letter and she'\''s looking at her maid like "what does it mean?"

The secret is on the wall behind them: there'\''s a painting of a
ship on the sea, and in the 1600s, the sea was a metaphor for
love. Calm sea = love is going well. Stormy sea = uh oh.
Vermeer hid the answer to the letter in the background.'

write_sidecar "$PAINT/003--starry-night.jpg.md" '---
caption: The Starry Night
source: |
  Vincent van Gogh, 1889
  MoMA, New York — Public Domain
---

Van Gogh painted this from the window of an asylum in
Saint-Rémy-de-Provence, France. He had checked himself in
because he wasn'\''t doing well. But look what came out of it —
the most famous painting of the night sky ever made.

The secret is that the sky is actually scientifically accurate
in a weird way. Scientists found that the swirling patterns
match something called turbulent flow in physics. Van Gogh
painted real math without knowing it.'

# =============================================================================
# 3. Nature Is Really Good at Shapes (Haeckel 1904, public domain)
# =============================================================================
echo "=== Nature Is Really Good at Shapes ==="
NATURE="$SCRIPT_DIR/Nature Is Really Good at Shapes.slideshow"
mkdir -p "$NATURE"

download_and_resize "https://upload.wikimedia.org/wikipedia/commons/2/21/Haeckel_Orchidae.jpg" "$NATURE/001--orchids.jpg"
download_and_resize "https://upload.wikimedia.org/wikipedia/commons/8/8e/Haeckel_Trochilidae.jpg" "$NATURE/002--hummingbirds.jpg"
download_and_resize "https://upload.wikimedia.org/wikipedia/commons/a/a6/Haeckel_Chelonia.jpg" "$NATURE/003--turtles.jpg"

write_sidecar "$NATURE/001--orchids.jpg.md" '---
caption: Orchidae (Orchids)
source: |
  Ernst Haeckel, Kunstformen der Natur, Plate 74, 1904
  Public Domain
---

Ernst Haeckel was a scientist who was also an incredible artist.
He traveled around the world studying nature and drawing everything
he saw. This plate shows different species of orchids.

Look at the symmetry — orchids have bilateral symmetry, which means
if you fold them in half they match up, just like your face.
Haeckel thought these shapes were so beautiful they proved that
nature is the best designer. He drew 100 plates like this.'

write_sidecar "$NATURE/002--hummingbirds.jpg.md" '---
caption: Trochilidae (Hummingbirds)
source: |
  Ernst Haeckel, Kunstformen der Natur, Plate 99, 1904
  Public Domain
---

This is the last plate in the entire book — number 99 — and
Haeckel saved hummingbirds for the finale. Their feathers aren'\''t
actually colored. The iridescence comes from tiny structures in
the feathers that split light, like a prism.

Hummingbirds can fly backwards. Their hearts beat 1,200 times
per minute. They'\''re the smallest birds in the world but they
migrate thousands of kilometers. Haeckel picked them as the
grand finale because they'\''re basically nature showing off.'

write_sidecar "$NATURE/003--turtles.jpg.md" '---
caption: Chelonia (Turtles)
source: |
  Ernst Haeckel, Kunstformen der Natur, Plate 89, 1904
  Public Domain
---

Look at the shells. Turtles have HEXAGONS on their shells, and
hexagons are one of nature'\''s favorite shapes because they tile
perfectly — no gaps, no waste. Bees figured this out too.

Haeckel drew these to show how mathematical nature is. The shell
pattern is called tessellation, which is when shapes fit together
to cover a surface completely. Turtles have been around for over
200 million years — they'\''re older than dinosaurs, and their
geometry hasn'\''t changed because it already works perfectly.'

echo ""
echo "Done! Total size:"
du -sh "$SCRIPT_DIR"/*.slideshow
