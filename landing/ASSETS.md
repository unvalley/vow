# Landing page assets

The outlined wordmark is the master from `../Brand/izzy-wordmark.svg`, and the
social card pairs it with the mark. The favicon, touch icon and header icon are
resized from the shipped app icon (`../Brand/izzy-app-icon-1024.png`, the Default
rendition of `../Izzy/Resources/Izzy.icon`), so the site and the Home Screen show
the same mark. Brand provenance is in `../Brand/README.md`.

The September 13 refresh follows the structure of [Art4](https://art4.app/en):
a large product preview, a visible grid of features and FAQs.
No Art4 artwork, screenshots, branding, code or copy is bundled here.

All phone images are real Izzy iOS Simulator captures, proportionally resized to
440, 660 and 990 pixel WebP variants. Screens have not been repainted or had
values edited. They are shown as the bare screen with rounded corners; no device
is drawn around them, and no Apple product photography or device template is
bundled here. Each page uses matching explanation settings: Japanese for `/`, easy English
for `/en/`. Only the corresponding language image is requested for each placement.

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

The header and footer put the app icon (`favicon.png`, exported from
`Izzy/Resources/Izzy.icon` by `scripts/build_brand.mjs` together with the touch
icon) to the left of the wordmark, so the tab, the Home Screen and the page all
show the same mark. The same script also writes `mark.png`, the bare shape, which
the page no longer uses. The earlier mountain photograph is no longer used here; it remains one
of the app's Today backgrounds, recorded in [Today backgrounds](../docs/today-landscape.md).

The hero recording (`hero-ja.mp4`, `hero-en.mp4`) is a real Izzy iOS Simulator
screen recording on an iPhone 17 Pro (iOS 26.5), taken on September 23, 2026 with
`xcrun simctl io <UDID> recordVideo --codec=h264`. The app ran with
`--ui-tests --reset-ui-tests --locale-language --free-access` as a Japanese or an
English device, the same free-access state as the Today capture, and the status bar
was overridden to 9:41 with a full battery. It shows Today's bring up, its phrase
notes and examples, a Good rating and the next two expressions. The idle time
between taps was cut and a pause held on some frames; nothing on screen was edited.
The clips are scaled to 720 px wide and encoded as H.264 (CRF 25, `+faststart`), and
`hero-<lang>.webp` is the first frame, used as the poster.

All processed assets are checked in under `public/assets`; simulator artifacts
are not required to build the site. Screenshots from the previous LP are retained
in `.build/LP-Art4/before/` for comparison.
