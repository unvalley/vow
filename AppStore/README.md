# vow App Store preparation

Version 1.0.0 (21), iOS 17+, iPhone/iPad. Bundle ID `me.unvalley.verve` and the non-consumable are registered in the UNV Studio team. See [TESTFLIGHT.md](TESTFLIGHT.md) for the current distribution state; the checklist below covers the public release too.

## Business model

Free download. Browse, save, annotate and review 50 fixed phrasal verbs and 50 fixed idioms, explore all 36 diagrams, and use Practice for free; Mountains and Ocean backgrounds and the New York and SF Pro phrase fonts are also free. One **Vow Pro** non-consumable purchase unlocks all 1,370 expressions for browsing and spaced reviews, plus every background and phrase font. No subscription, countdown trial, or consumable credits. The 100 free IDs are in `AccessPolicy.swift`; catalog additions do not alter them.

Product `me.unvalley.verve.complete.lifetime`. Intended Japan customer price: **¥900**. Select Japan as base territory and confirm the offered price point in App Store Connect. The code never substitutes a hardcoded price when Apple product loading fails. Other territories use Apple's configured localized prices. [Apple price setup](https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/set-a-price-for-an-in-app-purchase)

## Local commands

From the repository root:

```sh
xcodegen generate
python3 scripts/check_submission.py
scripts/archive.sh unsigned
# After selecting the real Developer team and configuring signing:
VOW_TEAM_ID=YOUR_TEAM_ID scripts/archive.sh signed
VOW_TEAM_ID=YOUR_TEAM_ID scripts/export_app_store.sh /absolute/path/to/signed.xcarchive
```

The archive script copies the app project into a dated source snapshot and records per-file SHA-256 hashes. The standard archive script requires a clean Git checkout. For the explicitly authorized releases from the existing mixed checkout, an isolated, hashed native-source snapshot was prepared instead, preserving all original changes. Archives built from an uncommitted snapshot must not be described as a clean Git revision. Preserve the snapshot, exact archive, validation JSON and exported IPA together. Neither script uploads or submits an app.

**Vow** is the production scheme and has no simulated StoreKit configuration. **VowStore** is for local StoreKit testing, with the Japanese ¥900 non-consumable. The `.storekit` file is copied into test bundles only. Debug UI-test paid access is removed by compilation from Release; archive validation checks for launch-argument leaks. Normal Debug launches use real StoreKit too.

## Submission pack

- [Current App Review coverage](APP-REVIEW-CHECKLIST.md): required feature coverage,
  verified boundaries, non-applicable requirements and remaining submission steps.

- `metadata.json`: Japanese/English listing, IAP copy and explicit missing inputs. Copy limits checked by `check_submission.py`; `--require-ready` fails until required external fields are filled.
- `REVIEW-NOTES.md`: exact free/purchase/restore paths.
- `PRIVACY-ANSWERS.md`: data, API, age-rating and source-rights review.
- `web/privacy.html`, `web/support.html`: source pages published at https://vow.unvalley.me/privacy/ and https://vow.unvalley.me/support/. Public response bytes were verified against the built files on September 13, 2026. Support: studio@unvalley.me.
- [Store image preview](screenshots/preview.html): 28 presentation PNGs from actual iPhone 6.9-inch and iPad 13-inch captures, seven screens in each explanation language per device, with dimensions and SHA-256 provenance in `manifest.json`. IAP purchase screens belong in review assets; consumer screenshots must describe their paid requirements accurately.

- [IAP review images](review-assets/README.md): Japanese/English native purchase screens with a StoreKit-supplied ¥900 price, captured by a passing UI test. Not yet uploaded.

## Remaining App Store Connect work

1. Reauthenticate App Store Connect to edit the existing app `6811353745` and non-consumable `6811354276`. Both records already exist; do not create duplicates.
2. Account Holder completes applicable Paid Apps Agreement, banking, tax and business requirements. No legal or tax declaration was submitted here.
3. Complete review contact name/phone, copyright holder, and rights to redistribute the supplied CSV content commercially. Public support/privacy URLs are verified and recorded in metadata.
4. Confirm Japan ¥900 price point, territory availability and non-consumable localizations. Family Sharing is initially disabled; changing this to enabled is a separate commercial choice.
5. Produce a Distribution-signed App Store export; upload that exact validated artifact, wait for processing and install it through TestFlight.
6. Exercise sandbox purchase, cancel, pending approval, restore/reinstall, offline previously purchased launch, refund/revocation and audio interruptions on a physical iPhone. Exercise iPad layouts. Local StoreKit testing is not sandbox purchase evidence.
7. Finish privacy, rating and export-compliance questionnaires based on the actual final app. Add screenshots, review notes and contacts. Submit the first non-consumable together with the app version. [Apple first-IAP submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
8. Use manual release after approval. An approved app is not publicly released until that step, and upload/processing are not approval.
