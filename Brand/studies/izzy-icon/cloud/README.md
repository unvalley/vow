# Izzy cloud lettering

The shipped app icon and the Sky background on Home are drawn by the scripts in this folder.
Both start from the chosen wordmark geometry — `izzy` in Outfit Black, letters offset and tilted
("bounce"), recentred on its ink and scaled to 92% — recorded in `bounce-center.json`.

## Files

| File | What it is |
| --- | --- |
| `izzy-cloud-icon.png` | The app icon, 1024 × 1024. Copied to `AppIcon.appiconset/AppIcon.png`. |
| `izzy-cloud-icon-dark.png` | Night sky companion for the iOS dark icon. |
| `izzy-cloud-icon-tinted.png` | Greyscale source for the iOS tinted icon: sky near black, clouds white. |
| `study-billow.png` | The earlier round-cloud study, before the surface grain and rim light. |
| `study-square-letters.png` | The version before the letterforms were rounded, whose masses read as lumpy rectangles. |
| `today-sky-source.jpg` | The Sky background at full size, also bundled as `TodaySky`. |
| `cumulus.py` | Icon renderer. `round2` (and `round2-night`) is the shipped setting; the other entries are studies. |
| `cloudscape.py` | Sky background renderer. `today-sky` is the shipped setting. |
| `lib.py`, `cloudword.py` | Shared helpers: glyph outlines, rasterising, noise, tracing. |

## How the clouds are built

1. Rasterise the izzy outline and round it first — an opening takes the corners off and a light
   closing fills the sharpest nooks — so the clouds sit on curves instead of a blocky outline.
2. Fill each letter part with spherical puffs: large ones sized to the stroke, smaller ones along
   the outline for the lobes.
3. Keep every puff clear of its neighbours (at most half the distance to the next part) and stop it
   bulging more than ~38 px past the outline, so the two z's and the i's dot stay separate and the
   notches of z and y stay open. Puffs too small to read as a lobe are skipped.
4. Blend overlapping puffs with a smooth union, so they merge into billows instead of showing each
   sphere's seam, and add medium-scale noise on the surface for cauliflower grain.
5. Light the height map from the upper left, darken the crevices and bases, and brighten the thin
   edges, where a real cloud scatters sunlight through instead of going dark.
6. Feather the silhouette with noise limited to the area around the clouds, composite over a
   vertical sky gradient, and downsample.

The sky background uses the same steps on scattered cloud clusters with soft, flat-ish bases, over a
paler gradient, because Home draws it at 38% opacity under a paper veil.

## Running them

The scripts expect numpy, scipy, Pillow, fontTools and potracer, plus Outfit and Fredoka
(SIL Open Font License) outside the repository; paths at the top of `lib.py` and `cloudword.py`
point at a working directory and need adjusting to rerun. Only rendered pixels are stored here —
no font files. Rendering is seeded, so a rerun with the same settings reproduces the same clouds.
