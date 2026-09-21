# Landing page assets

The outlined wordmark is the master from `../Brand/izzy-wordmark.svg`, and the
social card pairs it with the mark. The favicon, touch icon and hero mark are
resized from the shipped app icon (`../Brand/izzy-app-icon-1024.png`, the Default
rendition of `../Izzy/Resources/Izzy.icon`), so the site and the Home Screen show
the same mark. Brand provenance is in `../Brand/README.md`.

The September 13 refresh follows the structure of [Art4](https://art4.app/en):
a large product preview, a visible grid of features and FAQs.
No Art4 artwork, screenshots, branding, code or copy is bundled here.

All phone images are real Izzy iOS Simulator captures, proportionally resized to
440, 660 and 990 pixel WebP variants. Screens have not been repainted or had
values edited. The device around them is drawn in CSS — an iPhone 17 body with a
metal edge, a black bezel, side buttons and a Dynamic Island. The island is an
overlay, not part of the capture; it sits in the gap the status bar already
leaves between the clock and the status icons, so it hides nothing. No Apple
product photography or device template is bundled here. Each page uses matching explanation settings: Japanese for `/ja/`, easy English
for `/`. Only the corresponding language image is requested for each placement.

The current mapping and SHA-256 values are in `capture-provenance.json`.
The six screens per language come from `AppStore/screenshots/raw/iPhone-6.9/`,
recaptured on September 20, 2026 from the current build by
`IzzyUITests/BrandScreenshotsUITests`, which runs the app as a Japanese and then
an English device so both the interface and the explanations match each page.
The result bundle for every asset is recorded in the manifest.
The pages claim 1,300+ rather than a number, so a later expansion cannot outrun
them; `scripts/check.mjs` checks the claim against the shipped catalog.
Today uses the simulator free-access capture configuration. The free collection
contains 50 lessons, and the daily goal shown is five new lessons.
Stats uses the app's isolated sample learning history, explicitly recorded as
example data in provenance and image alt text. It is not a learner testimonial.

Regenerate the three WebP sizes with `node scripts/update_landing_captures.mjs`
from this directory; its header records the capture command. The source
screenshots are resized without editing their content.

The hero is the app's own mark on ink: `mark.png` is the shape from the app icon
(`Izzy/Resources/Izzy.icon`), exported by `scripts/build_brand.mjs` together with
the favicon and touch icon, so the tab, the Home Screen and the page all show the
same mark. The earlier mountain photograph is no longer used here; it remains one
of the app's Today backgrounds, recorded in [Today backgrounds](../docs/today-landscape.md).

All processed assets are checked in under `public/assets`; simulator artifacts
are not required to build the site. Screenshots from the previous LP are retained
in `.build/LP-Art4/before/` for comparison.
