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
| Non-consumable | `me.unvalley.verve.complete.lifetime` | `me.unvalley.izzy.pro.lifetime` |
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
  `me.unvalley.izzy.pro.lifetime`. Both the app record and the
  non-consumable have to be created again in App Store Connect, and the Japan
  base price re-entered.
- Provisioning profiles, the App Store Connect app ID `6811353745` and the
  product ID `6811354276` recorded in `AppStore/TESTFLIGHT.md` belong to the old
  bundle ID and do not carry over. The replacement app record is `6814155678`,
  created on 20 September 2026; build 1.0.0 (23) is its first upload. The
  non-consumable has not been created there yet.

## Outstanding

- **Artwork.** The app icon is done: `Izzy/Resources/Izzy.icon` is an Icon Composer
  document holding the adopted mark — a soft inflated shape, white on near-black —
  and iOS renders the dark, clear and tinted versions from that one document.
  `ASSETCATALOG_COMPILER_APPICON_NAME` points at `Izzy`, and the old
  `AppIcon.appiconset` is gone. The wordmark is now outlined Outfit Black `izzy`,
  and the website's favicon, touch icon, hero mark and sharing image are exported
  from those masters by `scripts/build_brand.mjs`. Still outstanding:
  `Brand/izzy-wordmark.pdf` and `izzy-wordmark-preview.png` predate the new
  wordmark, and `scripts/make_wordmark.swift` still shapes Archivo.
- **Store name.** Done. Apple rejects the plain name `Izzy` as taken in English
  (U.S.), as it rejected `vow` before, so both listings carry a descriptive name:
  `Izzy：句動詞と英熟語（イディオム）` in Japanese and `Izzy: Phrasal Verbs & Idioms`
  in English. `AppStore/metadata.json` holds what App Store Connect holds.
- **Landing domain.** Done. The `izzy-landing` Worker serves
  `izzy.unvalley.me`, and `AppStore/metadata.json` points support and privacy at
  that host.
- **Simulator names.** The capture simulators are now `Izzy Store iPhone 17 Pro
  Max` and `Izzy Store iPad 13`, and `AppStore/screenshots/captures.json` was
  regenerated under those names. `AppStore/review-assets/manifest.json` still
  names `Verve Store iPad 13`, which is what those captures were taken on; they
  show the old record's product and have to be recaptured for `6814155678`
  anyway.
- **Repository.** The GitHub remote is still `unvalley/vow`; documentation
  already refers to `unvalley/izzy`.
