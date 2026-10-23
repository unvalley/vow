# Izzy landing page

Mobile-first, Japanese (`/`, the default) and English (`/en/`) static landing pages for
https://izzy.unvalley.me. `/ja/`, where the Japanese page used to live, redirects to `/`
through `public/_redirects`. Privacy and support pages reuse the app's existing
bilingual content. The app itself is unchanged by this directory.

## Run

Requires Node.js 22 or later.

```sh
npm ci
npm run dev
```

Visit http://localhost:4321. No framework, third-party fonts, analytics or runtime
API requests. The only script is `hero.js`, the hero video's pause button. FAQs use
native HTML details.

## Check and publish

```sh
npm run check
npm run deploy
```

Wrangler must be authenticated for the configured Cloudflare account. Static
assets are deployed as the `izzy-landing` Worker with the custom domain
`izzy.unvalley.me`. Cloudflare manages the custom domain and TLS. `dist/`, local
Wrangler state, and dependencies are ignored.

`npm run check` checks generated routes, asset links, in-page anchors, ARIA
references, and the pages' "1,300+" catalog claim against the shipped catalog
before a Wrangler dry run. Also
review `/` and `/en/` at 320, 390, 768, and 1440 px; test the FAQs, language links,
and support/privacy links.

## Public availability

`site.config.mjs` holds `downloadURL`. It is intentionally empty until a public
App Store or TestFlight URL is verified. The page displays a plain release status and
an active “Try a phrase” link. Set the URL and rebuild to replace the release status
with download links. Do not link to the private App Store Connect testing page.
Pro pricing is shown in the app, not invented for this website.

## Design and assets

The current reference is [Art4](https://art4.app/en): a compact hero, large real
product screens, four features visible without tabs, and FAQs.
The app icon sits to the left of the wordmark. The hero stacks the headline over a
screen recording of the app on ink at every width, and like the feature images, after
[Dot](https://new.computer/dot), it is the bare screen with rounded corners, with no
device drawn around it. Colors retain Izzy's paper,
ink and blue accent. The wordmark is outlined Figtree Medium; text uses system
fonts and phrase examples use a serif.

The FAQs use native `details`, so every page works with JavaScript off. The hero
recording plays muted on a loop with a pause button beside it; with Reduce Motion it
starts paused on its first frame. There is no scroll-triggered reveal or tracking.
Reduced Motion also disables smooth scrolling.

See `ASSETS.md` for the real simulator screenshots and brand provenance.

## Brand assets

See [brand direction](../Brand/STRATEGY.md) and [visual reference](../Brand/preview.html). `node scripts/build_brand.mjs` from the repository root regenerates the native icon, website symbol and social image from the approved outlined wordmark. `node scripts/update_landing_captures.mjs` refreshes product imagery from verified captures; `capture-provenance.json` records the sources.
