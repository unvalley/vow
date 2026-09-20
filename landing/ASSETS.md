# Landing page assets

The outlined wordmark is the approved master from `../Brand/izzy-wordmark.svg`.
The favicon and social card retain those same outlines. Brand provenance is in
`../Brand/README.md`.

The September 13 refresh follows the structure of [Art4](https://art4.app/en):
a large product preview, a visible grid of features, concise plans and FAQs.
No Art4 artwork, screenshots, branding, code or copy is bundled here.

All phone images are real Izzy iOS Simulator captures, proportionally resized to
440, 660 and 990 pixel WebP variants. The hardware outline and image-window crop
are CSS. Screens have not been repainted or had values edited. Each page uses matching explanation settings: Japanese for `/ja/`, easy English
for `/`. Only the corresponding language image is requested for each placement.

The current mapping and SHA-256 values are in `capture-provenance.json`.
The six screens per language come from `AppStore/screenshots/raw/iPhone-6.9/`.
The exact passing capture result for each asset is recorded in the manifest.
The collection shows 450 idioms from the current 1,200-expression catalogue.
Today uses the simulator free-access capture configuration. The free collection
contains 50 lessons, and the daily goal shown is five new lessons.
Stats uses the app's isolated sample learning history, explicitly recorded as
example data in provenance and image alt text. It is not a learner testimonial.

Regenerate the three WebP sizes with `node scripts/update_landing_captures.mjs`.
The source screenshots are copied without editing their content.

The mountain background is the same m wrona photograph used by Izzy, from
`Izzy/Resources/Assets.xcassets/TodayMountains.imageset/today-mountains.jpg`.
Its source and Unsplash license are recorded in
[Today backgrounds](../docs/today-landscape.md). The LP uses proportional WebP
variants at 640, 1280 and 1600 pixels; a CSS veil keeps text readable.

The three practice previews are rendered from `Izzy/Resources/phrases.json` at
build time, keeping the Japanese/easy-English meanings and example replies in
sync with the app. They do not write learning data or use a microphone.

All processed assets are checked in under `public/assets`; simulator artifacts
are not required to build the site. Screenshots from the previous LP are retained
in `.build/LP-Art4/before/` for comparison.
