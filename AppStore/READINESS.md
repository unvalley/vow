# Readiness — 12 September 2026

**Current boundary: Verve 1.0.0 (1) is Ready to Test in TestFlight, with the Account Holder invited as the sole internal tester. Physical-device installation and StoreKit transactions remain unverified. Public App Store release has not occurred. See [TestFlight evidence](TESTFLIGHT.md).**

## Prepared

- Free download plus non-consumable `me.unvalley.verve.complete.lifetime`, intended Japan price ¥900. Twenty fixed phrase practices and one story scene are free; purchase unlocks all practice. Every expression and diagram remains browsable free.
- StoreKit 2 product loading and localized price, verified current entitlements, launch/foreground refresh, transaction update listener, purchase, pending/cancel/error states, explicit restore, unfinished-transaction handling and refund/revocation refresh. Entitlements are not stored as an editable local purchase flag. Progress is preserved on access changes.
- Native purchase screen in Japanese and English, settings entry, locked-practice entry, reload/restore states, privacy view, Apple standard EULA link and support contact studio@unvalley.me.
- Japanese/English listing and IAP copy with checked length limits, review notes, privacy manifest, API/data audit, rating review notes, and standalone support/privacy page drafts.
- Local archive/export scripts with source snapshot hashes and exact artifact validation. Production scheme has no StoreKit simulation; test configuration is confined to test targets.

## Earlier local preparation evidence

Archive: `.build/Release/Verve-20260912T115122Z-unsigned.xcarchive`.
Source snapshot: `.build/Release/20260912T115122Z-source`.
Log: `/tmp/verve-release-reviewed.log`.
Executable SHA-256: `c474e820ece2e955e673ccc315a04a7acba2365e8ed139588bcec0475153aed5`.

Validated version 1.0.0 (1), bundle ID, iOS 17 minimum, arm64, iPhone/iPad families, all four iPad orientations, launch-screen declaration, microphone purpose string, system-only encryption flag, bundled privacy manifest and 614-entry catalog. The 1024 × 1024 app icon has no alpha. No test bundle, `.storekit` configuration or debug purchase override is included in the archive. Source conditional compilation excludes test-data reset behavior too. This artifact is unsigned; it is not an App Store IPA. The source manifest was reconciled against the generated snapshot project after archive creation, and every recorded file hash was checked; the archive script now generates the project before recording hashes.

The first archive compiled but the strict string scan found the test reset label retained behind an always-empty Release argument array. The entire test-file branch was then moved under `#if DEBUG`; the final archive above passes validation. No runtime reset bypass was demonstrated in the first archive, and it is superseded by the final archive.

## Purchase test boundary

`VerveStoreTests/PurchaseStoreTests.swift` contains real StoreKit integration scenarios for purchase → new store instance → restore → refund, and Ask to Buy approval. `testFreeAccessPurchaseScreenAndTrialPractice` requires a native ¥900 Product and checks the purchase screen and gate.

These scenarios did **not pass** in this environment. After correcting test-resource membership, StoreKitTest's service rejects configuration/override operations with `SKInternalErrorDomain Code=3`, returns no Product, and prevents reaching a transaction. Evidence: `.build/StoreIntegration.xcresult`, `.build/StoreSignedSimulator.xcresult`, and `.build/StoreRuntime265.xcresult`, plus their `/tmp/verve-store-*.log` files. Reproduced on iOS 26.3 and a newly created matching iOS 26.5 simulator, including ad-hoc signed simulator binaries. No private entitlement or mocked successful purchase was added to conceal the failure.

Purchase, native payment-sheet cancellation, approval, restoration, refund, and offline previously purchased behavior need a working local StoreKit environment and then App Store sandbox/TestFlight evidence. Source inspection and free-access unit tests do not substitute for that integration boundary.

## Remaining public-release requirements

App and IAP records, signing, upload, processing and internal tester setup are now complete for TestFlight. See [TESTFLIGHT.md](TESTFLIGHT.md) for exact IDs, artifacts and evidence.

- Install the invited build and verify physical-device learning, microphone behavior, purchase, restore and refund/revocation. Internal tester invitation is not installation evidence.
- Host the prepared support/privacy pages at confirmed public HTTPS URLs. Complete review contact name/phone, copyright holder, supplied-content commercial rights and final privacy/rating questionnaires.
- Japan ¥900 is configured on the IAP, with Japan-only availability. Confirm final public territories and applicable business agreements before commercial submission. No agreement or tax declaration was submitted by this task.
- Capture the native price-bearing IAP review screen after product loading works. Submit the first non-consumable with an app version only after the remaining release checks pass. No public App Store submission or release was performed.

Run `python3 scripts/check_submission.py --require-ready` for unresolved commercial metadata; this is a separate gate from the now-available internal TestFlight build.

## Passing functional checks

`.build/ReleaseChecks.xcresult` (log `/tmp/verve-release-checks.log`) passes all 24 core tests and four native UI scenarios: newest imported entries/language/saving/persistence, daily practice/streak, story completion, and unavailable-price handling with usable free practice and blocked premium practice. The three pre-existing learning flows use the Debug-only paid UI-test fixture; they verify learning integration, not a real purchase. The unavailable-store scenario uses actual unpurchased access.

`.build/AppStorePhone.xcresult` passes the Japanese/English screenshot navigation flow on an iPhone 17 Pro Max simulator. Ten unmodified captures are in `AppStore/screenshots/iPhone-6.9`, at 1320 × 2868. They show free-access Today, Phrases, core-image gallery, comparison and practice screens. This dimensions category is supported by [Apple screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). No native price-bearing IAP review screenshot is claimed; product loading must be fixed before that capture.

`.build/AppStorePadFinal.xcresult` (log `/tmp/verve-store-pad-final.log`) passes the same Japanese/English capture flow on a 13-inch iPad Pro simulator, with ten 2064 × 2752 captures in `AppStore/screenshots/iPad-13`. The initial iPad attempt failed because its floating tab control is outside XCTest's TabBar query; the screenshot helper now locates the native iPad buttons and the rerun passes. No production navigation change was needed. Visually inspected Today and the side-by-side comparison: text and diagrams remain legible without clipping. All twenty exported images are unmodified RGB PNGs without alpha; `AppStore/screenshots/manifest.json` records dimensions, file hashes and result-bundle provenance.

Source review found no remaining concrete access-policy or task-lifetime issue in this slice. The unverified native transaction paths remain a release blocker. No claim is made that the entire historical UI suite, physical microphone behavior, VoiceOver listening, or rendering frame rate was retested.

## Earlier TestFlight authentication failure — resolved

The user authorized TestFlight distribution. Tried automatic provisioning and a signed Release archive from the already validated source snapshot `20260912T115122Z-source`, targeting the only cached paid team, UNV Studio (`2X266ZCRLV`). This is a candidate team from local Xcode metadata, not confirmation of current account access or bundle ownership.

`xcodebuild ... DEVELOPMENT_TEAM=2X266ZCRLV CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates archive` stopped before signing with `No Accounts: Add a new account in Accounts settings` and no provisioning profile for `me.unvalley.verve`. Log: `/tmp/verve-testflight-archive.log`. Xcode's Apple Accounts pane independently shows no signed-in account and an Add Apple Account button; App Store Connect also shows its login form. No new signed archive, upload or TestFlight build was produced.

The next action at that time was to sign into the intended paid Apple Developer account in Xcode → Settings → Apple Accounts and App Store Connect. Then confirm the team, create/verify the app record, rerun signing with automatic provisioning, export/upload and wait for Apple processing before adding the build to the user's internal TestFlight access. Password and two-factor entry remain in Apple's UI. A local Apple Distribution identity is absent, but automatic/cloud signing should be tried after authentication rather than treating that absence alone as definitive.

The user subsequently signed in. The successful archive/export/upload and Ready to Test result supersede the authentication failure above; details are in [TESTFLIGHT.md](TESTFLIGHT.md).
