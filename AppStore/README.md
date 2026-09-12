# vow App Store preparation

Version 1.0.0 (1), iOS 17+, iPhone/iPad. Bundle ID `me.unvalley.verve` is the existing local identifier; availability and ownership must be checked in the intended Apple Developer team before registration. The app and non-consumable are now registered, and build 1.0.0 (1) is available for internal TestFlight testing. See [TESTFLIGHT.md](TESTFLIGHT.md) for the current distribution state; the checklist below covers the public release too.

## Business model

Free download. Browse all 614 expressions, all 35 diagrams, save/note/sort, and practice 20 stable expressions plus the Meetings & ideas story. One **vow Complete** non-consumable purchase unlocks practice for the whole catalog and all five story scenes. No subscription, countdown trial, or consumable credits. The 20 free IDs are in `AccessPolicy.swift`; catalog additions do not alter them.

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

The archive script copies the app project into a dated source snapshot and records per-file SHA-256 hashes. It does not require committing or include parent blog work. Archives built from an uncommitted snapshot must not be described as a clean Git revision. Preserve the snapshot, exact archive, validation JSON and exported IPA together. Neither script uploads or submits an app.

**Vow** is the production scheme and has no simulated StoreKit configuration. **VowStore** is for local StoreKit testing, with the Japanese ¥900 non-consumable. The `.storekit` file is copied into test bundles only. Debug UI-test paid access is removed by compilation from Release; archive validation checks for launch-argument leaks. Normal Debug launches use real StoreKit too.

## Submission pack

- `metadata.json`: Japanese/English listing, IAP copy and explicit missing inputs. Copy limits checked by `check_submission.py`; `--require-ready` fails until required external fields are filled.
- `REVIEW-NOTES.md`: exact free/purchase/restore paths and microphone alternatives.
- `PRIVACY-ANSWERS.md`: data, API, age-rating and source-rights review.
- `web/privacy.html`, `web/support.html`: standalone page drafts without analytics. Support contact: studio@unvalley.me. Host at the selected public HTTPS URLs, verify reachability, then put those URLs in metadata. These files are not published yet.
- `screenshots/`: twenty actual iPhone 6.9-inch and iPad 13-inch captures, five screens in each explanation language per device, with dimensions and SHA-256 provenance in `manifest.json`. IAP purchase screens belong in review assets; consumer screenshots must describe their paid requirements accurately.

## Remaining App Store Connect work

1. Sign in with the intended team. Check the app name and bundle ID; register the app and create the non-consumable with the exact product ID above.
2. Account Holder completes applicable Paid Apps Agreement, banking, tax and business requirements. No legal or tax declaration was submitted here.
3. Confirm public support/privacy URLs, support and review contacts, copyright holder, and rights to redistribute the supplied CSV content commercially.
4. Confirm Japan ¥900 price point, territory availability and non-consumable localizations. Family Sharing is initially disabled; changing this to enabled is a separate commercial choice.
5. Produce a Distribution-signed App Store export; upload that exact validated artifact, wait for processing and install it through TestFlight.
6. Exercise sandbox purchase, cancel, pending approval, restore/reinstall, offline previously purchased launch, refund/revocation, microphone denial and interruptions on a physical iPhone. Exercise iPad layouts. Local StoreKit testing is not sandbox purchase evidence.
7. Finish privacy, rating and export-compliance questionnaires based on the actual final app. Add screenshots, review notes and contacts. Submit the first non-consumable together with the app version. [Apple first-IAP submission](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
8. Use manual release after approval. An approved app is not publicly released until that step, and upload/processing are not approval.
