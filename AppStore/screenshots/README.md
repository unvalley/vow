# Izzy store screenshots

[Open the complete preview](preview.html). There are 28 upload-size PNGs: seven
screens in Japanese and English for iPhone 6.9-inch (1320 × 2868) and iPad
13-inch (2064 × 2752). Select only the seven `app-store-ja-*` or `app-store-en-*`
files for the matching device and App Store localization.

Sequence: Today → idioms → meaning and examples → recall → daily goal → core
images → Stats. Consumer images state Izzy Pro where applicable. Stats uses
sample learning history, not measurements from a real learner. The forgetting
curve is illustrative, not an estimate of an individual's memory.

`raw/` preserves the original simulator PNGs. Presentation images add the Izzy
wordmark and localized headings on a neutral canvas and scale the complete
capture proportionally. App text, data, controls and screenshots are not painted
over. `captures.json` records the capture test result, containing run result and original hashes;
`manifest.json` records final PNG hashes, source hashes and access provenance.

Both simulators run with an overridden status bar — 9:41, full signal, full
battery — set with `xcrun simctl status_bar <udid> override` before the run, so
the clock does not date the listing. It changes nothing inside the app; iPadOS
still draws its own date beside the time.

Verified capture tests, recaptured on 20 September 2026 from the renamed build:

- `.build/shots/Brand.xcresult`: 14 iPhone captures, passed.
- `.build/shots/Pad.xcresult`: 14 iPad captures, passed.

Each run launches the app twice per language, as a Japanese and then an English
device, so the interface and the explanations match the localization the image is
filed under. Stats opens from the streak on Home and shows the streaks and the
month calendar; the goal editor no longer states a collection size. The
simulators are `Izzy Store iPhone 17 Pro Max` and `Izzy Store iPad 13`.

Regenerate from passing capture tests, then inspect the gallery:

```sh
python3 scripts/import_store_captures.py --phone .build/shots/Brand.xcresult --ipad .build/shots/Pad.xcresult
node scripts/build_store_artwork.mjs
node scripts/check_store_artwork.mjs
```

The scripts require the exact capture test to pass and reject incomplete captures and changed source images.
The output was checked against the current 1,370-expression catalog. These
images are prepared locally and have not been uploaded to App Store Connect.
Native price-bearing IAP review screenshots are prepared separately in
[review-assets](../review-assets/README.md). Consumer images are not transaction evidence.

Capture entitlement note: the iPad simulator retains a local Xcode StoreKit Pro
purchase, and the free-access launch flag does not override a verified StoreKit
entitlement. Goal selection itself is free and the goal editor no longer names a
collection size; presentation copy states that the full collection requires Izzy
Pro. This is a simulator state, not a customer account or a verified production
purchase.
