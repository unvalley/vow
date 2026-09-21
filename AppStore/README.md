# Izzy App Store preparation

Version 1.0.0 (22), iOS 17+, iPhone/iPad. Bundle ID `me.unvalley.izzy` and the non-consumable are registered in the UNV Studio team. See [TESTFLIGHT.md](TESTFLIGHT.md) for the current distribution state; the checklist below covers the public release too.

## Business model

Free download. Browse, save, annotate and review 50 fixed phrasal verbs and 50 fixed idioms, explore all 36 diagrams, and use Practice for free; Mountains and Ocean backgrounds and the New York and SF Pro phrase fonts are also free. One **Izzy Pro** non-consumable purchase unlocks all 3,021 expressions for browsing and spaced reviews, plus every background and phrase font. No subscription, countdown trial, or consumable credits. The 100 free IDs are in `AccessPolicy.swift`; catalog additions do not alter them.

Product `me.unvalley.izzy.pro.lifetime`. Japan standard price: **¥2,400**, offered at **¥1,920** while the early-release discount runs — 20% off, held as a scheduled price change until it is put back. Japan is the base territory; confirm the offered price point in App Store Connect. The code never substitutes a hardcoded price when Apple product loading fails. Other territories use Apple's configured localized prices. [Apple price setup](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase)

## Local commands

From the repository root:

```sh
xcodegen generate
python3 scripts/check_submission.py
scripts/archive.sh unsigned
# After selecting the real Developer team and configuring signing:
IZZY_TEAM_ID=YOUR_TEAM_ID scripts/archive.sh signed
IZZY_TEAM_ID=YOUR_TEAM_ID scripts/export_app_store.sh /absolute/path/to/signed.xcarchive
```

The archive script copies the app project into a dated source snapshot and records per-file SHA-256 hashes. The standard archive script requires a clean Git checkout. For the explicitly authorized releases from the existing mixed checkout, an isolated, hashed native-source snapshot was prepared instead, preserving all original changes. Archives built from an uncommitted snapshot must not be described as a clean Git revision. Preserve the snapshot, exact archive, validation JSON and exported IPA together. Neither script uploads or submits an app.

**Izzy** is the production scheme and has no simulated StoreKit configuration. **IzzyStore** is for local StoreKit testing, with the Japanese non-consumable at the current ¥1,920 launch price. The `.storekit` file is copied into test bundles only. Debug UI-test paid access is removed by compilation from Release; archive validation checks for launch-argument leaks. Normal Debug launches use real StoreKit too.

## Submission pack

- [Current App Review coverage](APP-REVIEW-CHECKLIST.md): required feature coverage,
  verified boundaries, non-applicable requirements and remaining submission steps.

- `metadata.json`: Japanese/English listing, IAP copy and explicit missing inputs. Copy limits checked by `check_submission.py`; `--require-ready` fails until required external fields are filled.
- `REVIEW-NOTES.md`: exact free/purchase/restore paths.
- `PRIVACY-ANSWERS.md`: data, API, age-rating and source-rights review.
- `web/privacy.html`, `web/support.html`: source pages published at https://izzy.unvalley.me/privacy/ and https://izzy.unvalley.me/support/. Public response bytes were verified against the built files on September 13, 2026. Support: studio@unvalley.me.
- [Store image preview](screenshots/preview.html): 28 presentation PNGs from actual iPhone 6.9-inch and iPad 13-inch captures, seven screens in each explanation language per device, with dimensions and SHA-256 provenance in `manifest.json`. IAP purchase screens belong in review assets; consumer screenshots must describe their paid requirements accurately.

- [IAP review images](review-assets/README.md): Japanese/English native purchase screens captured by a passing UI test. They predate the rename and the new price, so they have to be recaptured before upload.

## Measurement

Izzy has **no third-party analytics and no SDK**. It posts its own events to
`izzy.unvalley.me/e`, a Cloudflare Worker this project already runs, which writes
them to a D1 database on the same account. Nothing is handed to anyone else.

What goes out is a closed list: which screens were opened, that a review was rated
and with which of the four ratings, whether the expression was a phrasal verb or an
idiom, the settings in use, and each step of the Izzy Pro funnel — lock card seen,
purchase screen opened, purchase started, purchased or why not. Alongside it: app
version, iOS version, iPhone or iPad, interface language.

What cannot go out, by construction: anything a person wrote. No phrase text, no
notes, no search terms, no account, no advertising identifier, no location. The
identifier is a UUID the app makes on first launch and keeps in its own defaults
rather than the Keychain, so deleting Izzy ends it. No IP address is stored.
`landing/worker/index.js` enforces the same list a second time and rejects anything
else with a 400, so the claim is checkable rather than a promise.

Settings → Usage data turns it off, and turning it off discards whatever has not
been sent. Sending is compiled out of Debug builds and disabled under UI tests
unless `--analytics-live` asks for it, so development never lands in the customer
table. `Izzy/PrivacyInfo.xcprivacy` declares Product Interaction for Analytics, not
linked to the user and not tracking; `check_submission.py` asserts exactly that
entry, so widening what is collected fails the check until App Store Connect and
the privacy policy are updated to match.

Apple App Analytics still covers what it always did — installs, retention, crashes,
IAP conversion — for App Store installs only, for people who turned on Share With
App Developers, and only above Apple's privacy threshold.

Reading the events:

```sh
cd landing
npx wrangler d1 execute izzy-events --remote --json \
  --command "select date(at,'unixepoch') as day, count(distinct install) as installs from events where name='app_open' group by day order by day desc limit 14"
```

## Remaining App Store Connect work

1. The live records are app `6814155678` and its non-consumable; the old `6811353745` / `6811354276` belong to `me.unvalley.verve` and are not to be edited. See [TESTFLIGHT.md](TESTFLIGHT.md).
2. Account Holder completes applicable Paid Apps Agreement, banking, tax and business requirements. No legal or tax declaration was submitted here.
3. Complete review contact name/phone, copyright holder, and rights to redistribute the supplied CSV content commercially. Public support/privacy URLs are verified and recorded in metadata.
4. Confirm the Japan price points — ¥2,400 standard and the ¥1,920 early-release schedule — territory availability and non-consumable localizations. Family Sharing is initially disabled; changing this to enabled is a separate commercial choice.
5. Produce a Distribution-signed App Store export; upload that exact validated artifact, wait for processing and install it through TestFlight.
6. Exercise sandbox purchase, cancel, pending approval, restore/reinstall, offline previously purchased launch, refund/revocation and audio interruptions on a physical iPhone. Exercise iPad layouts. Local StoreKit testing is not sandbox purchase evidence.
7. Finish privacy, rating and export-compliance questionnaires based on the actual final app. Add screenshots, review notes and contacts. Submit the first non-consumable together with the app version. [Apple first-IAP submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
8. Use manual release after approval. An approved app is not publicly released until that step, and upload/processing are not approval.
