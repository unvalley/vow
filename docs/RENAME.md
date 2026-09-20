# Izzy repository and rename — 20 September 2026

The iOS app is maintained in the standalone `unvalley/izzy` repository. The
visible app name is **Izzy**, and the Swift module, Xcode project, targets and
schemes are **Izzy**. Purchase-screen copy, StoreKit test metadata,
support/privacy drafts, App Store metadata and the landing page use that name.

The app has carried three names. It shipped internally as **Verve**, was renamed
to **vow** on 12 September 2026 while every compatibility identifier stayed on
`verve`, and became **Izzy** in this change. This rename moved the identifiers
too, so it is not an upgrade path for anyone holding an earlier build.

## Identifiers

| | Verve / vow | Izzy |
| --- | --- | --- |
| Bundle ID | `me.unvalley.verve` | `me.unvalley.izzy` |
| Widget bundle ID | `me.unvalley.verve.widget` | `me.unvalley.izzy.widget` |
| Non-consumable | `me.unvalley.verve.complete.lifetime` | `me.unvalley.izzy.complete.lifetime` |
| App Store SKU | `verve-ios-001` | `izzy-ios-001` |
| Learning data | `Application Support/Verve/learning.json` | `Application Support/Izzy/learning.json` |
| Temporary-recording prefix | `verve-` | `izzy-` |
| App Group | `group.me.unvalley.izzy` | unchanged |
| URL scheme | `izzy://` | unchanged |

The App Group and URL scheme already used `izzy`; they were introduced with the
home-screen widgets ahead of this rename.

## Consequences of moving the identifiers

- iOS treats the new bundle ID as a different app. Builds 1–23 in TestFlight are
  a separate application record and cannot be updated into this one.
- Existing installs keep their data under `Application Support/Verve/`. The new
  build reads `Application Support/Izzy/` and starts empty. No migration is
  performed.
- `me.unvalley.verve.complete.lifetime` purchases do not unlock
  `me.unvalley.izzy.complete.lifetime`. Both the app record and the
  non-consumable have to be created again in App Store Connect, and the Japan
  base price re-entered.
- Provisioning profiles, the App Store Connect app ID `6811353745` and the
  product ID `6811354276` recorded in `AppStore/TESTFLIGHT.md` belong to the old
  bundle ID and do not carry over.

## Outstanding

- **Artwork.** `Brand/izzy-wordmark.svg` and everything `scripts/build_brand.mjs`
  derives from it — the app icon, favicon, touch icon and social image — still
  contain the outlined letterforms of the word *vow*. `scripts/make_wordmark.swift`
  now sets the word to `izzy`, but regenerating needs the verified Archivo
  Regular Italic file from Fontshare, which is not redistributed here. The icon
  direction for Izzy is a one-line offset mark rather than the first glyph of the
  wordmark, so `build_brand.mjs` will need its symbol step revisited.
- **Store name.** Apple rejected the exact name `vow` as taken, which is why the
  previous Japanese listing read `vow：句動詞を会話に`. Whether `Izzy` is
  available is unverified; check it in App Store Connect before relying on the
  plain name in `AppStore/metadata.json`.
- **Landing domain.** `landing/wrangler.jsonc` now names the `izzy-landing`
  Worker and the `izzy.unvalley.me` custom domain, and `AppStore/metadata.json`
  points support and privacy at that host. The Cloudflare custom domain, DNS and
  first deploy are not done.
- **Simulator names.** `AppStore/screenshots/captures.json` and
  `AppStore/review-assets/manifest.json` still name the `Verve Store iPhone 17
  Pro Max` and `Verve Store iPad 13` simulators, because those devices exist
  under those names on the capture machine. Rename the simulators and these
  entries together.
- **Repository.** The GitHub remote is still `unvalley/vow`; documentation
  already refers to `unvalley/izzy`.
