# TestFlight — 13 September 2026

## vow 1.0.0 (3)

**vow 1.0.0 (3) is Testing in the existing Internal group.**

Uploaded successfully at 00:34 JST on 13 September 2026. Apple processing completed, automatic internal distribution assigned the build to the existing group, and Japanese What to Test notes were saved. No testers or groups were added.

- [Build 3 and test notes](https://appstoreconnect.apple.com/teams/efa2b77f-c93d-474e-a952-0919f49227fc/apps/6811353745/testflight/ios/eddf46b8-dc3f-4f16-b9ed-5e933cead0b0)
- [Internal group: Testing](https://appstoreconnect.apple.com/teams/efa2b77f-c93d-474e-a952-0919f49227fc/apps/6811353745/testflight/groups/490fb7ef-3547-4ab9-9041-ccd0ab58375a/builds)
- The existing tester is reported as having installed build 2. Build 3 installation and runtime behavior on the physical device remain unverified.

- Source revision: `9813d73c66741480be74a910136ee9feb07714b4` in `unvalley/vow`.
- App Store Connect app: `6811353745`; bundle: `me.unvalley.verve`; team: `2X266ZCRLV`.
- Upload/build ID: `eddf46b8-dc3f-4f16-b9ed-5e933cead0b0`.
- Signed archive: `.build/Release/Vow-20260912T153152Z-signed.xcarchive`.
- Clean source snapshot: `.build/Release/20260912T153152Z-source`.
- Archive executable SHA-256: `31e111847a563288f1cc3670ce8e73a3f28209fbaa6c6432a8e5346d45a0f075`.
- Local distribution IPA: `.build/TestFlightBuild3Export/Vow.ipa`; SHA-256: `6fef5ce7f6cc8c16c28923c677875e89adb8e0437a099241eae2b1de9e4661ae`.
- Archive and exported IPA passed validation: version/build/bundle/team, 614 phrases, strict signature, App Store provisioning without device UDIDs, debugger entitlement disabled, and no Debug test overrides or test purchase configuration.
- Xcode uploaded from that same archive with automatic signing, symbols enabled, and build-number management disabled. Upload packaging is separate from the inspected local IPA; its hash is not asserted as the uploaded package hash.
- Logs: `/tmp/vow-testflight-build3-archive.log`, `/tmp/vow-testflight-build3-export.log`, `/tmp/vow-testflight-build3-upload.log`.
- Validation: 28 core tests, four focused native UI tests, and a repeated final example-layout test passed. Light screenshots were inspected. Dark rendering, physical-device installation, recording, and sandbox purchase/restore remain unverified for this build.

This build introduces soft-white/graphite surfaces, accents limited to meaningful states, New York display phrases with San Francisco examples and controls, shared typography roles, and adaptive timer layout. Explicit accent preferences and learning data remain intact; users without a stored accent now default to Blue.

## Historical build 2 — vow 1.0.0 (2)

**vow 1.0.0 (2) is Testing in the existing Internal group.**

Uploaded successfully at 23:43 JST. Apple processing completed, the build was automatically assigned to Internal, and the updated Japanese What to Test notes were saved. The group has one existing tester; no testers or external groups were added.

- Build ID: `068c62d2-3d44-4a0c-a83c-05aeb8cb0fa3`.
- [Build 2 and test notes](https://appstoreconnect.apple.com/teams/efa2b77f-c93d-474e-a952-0919f49227fc/apps/6811353745/testflight/ios/068c62d2-3d44-4a0c-a83c-05aeb8cb0fa3)
- [Internal group: Testing](https://appstoreconnect.apple.com/teams/efa2b77f-c93d-474e-a952-0919f49227fc/apps/6811353745/testflight/groups/490fb7ef-3547-4ab9-9041-ccd0ab58375a/builds)
- The existing tester is reported as having installed build 1; build 2 installation and runtime behavior on that device remain unverified. Update to 1.0.0 (2) in TestFlight.

- Source revision: `128ce3ec522ed7fcf5d222543f3f33cae1a6e9df` in `unvalley/vow`.
- App display name: `vow`. Japanese App Store Connect name: `vow：句動詞を会話に`; Apple rejected the exact name `vow` as already in use, and saved the descriptive name.
- Bundle: `me.unvalley.verve`; team: `2X266ZCRLV`; existing App Store Connect app: `6811353745`.
- Signed archive: `.build/Release/Vow-20260912T143825Z-signed.xcarchive`.
- Source snapshot: `.build/Release/20260912T143825Z-source`, extracted from the clean Git revision. Local credentials and Git metadata are excluded.
- Archive executable SHA-256: `073049cdf1d171b4648351b3d564737b2462501c0cba0a8b46414426c704b68d`.
- Local IPA: `.build/TestFlightBuild2Export/Vow.ipa`; SHA-256: `4b13dc0e453b0738221d444caf5de4bebe3b90d968cda5d1524267896ea5bd50`.
- Archive validator and exported-IPA inspection passed: correct name/version/build/bundle/team, 614 entries, arm64, strict signature, App Store provisioning without device UDIDs, debugger entitlement off, no Debug purchase overrides or test bundles.
- Xcode uploaded from that same archive using automatic signing, symbols enabled, and automatic build-number changes disabled. Its upload packaging is separate from the inspected local IPA; the local IPA hash is not claimed as the uploaded ZIP hash.
- Logs: `/tmp/vow-testflight-build2-archive.log`, `/tmp/vow-testflight-build2-export.log`, `/tmp/vow-testflight-build2-upload.log`.
- Test coverage: 28 core tests plus the focused navigation, examples, color persistence, diagram, saved browsing, and large-type UI checks. Physical installation and sandbox purchase/restore are not verified.

This build includes the vow rename, the unified Phrases/Scenes navigation, stable example reveal, direct phrase-detail links, shared verb/particle links, clearer arrows, neutral surfaces, configurable accent colors, and the prior library-search optimization.

## Historical build 1

**Verve 1.0.0 (1) is Ready to Test. One internal tester is invited.**

The local working source now includes the [Phrases performance changes](../docs/PERFORMANCE.md).
Those changes are not included in the uploaded build 1. A subsequent upload
must increment the build number and archive the updated source.

- App Store Connect app: `6811353745`, Verve：句動詞を会話に.
- Bundle: `me.unvalley.verve`; team: UNV Studio, `2X266ZCRLV`.
- Build: `3316cfef-f705-47d1-841f-f4d4b2401932`.
- Internal group: `490fb7ef-3547-4ab9-9041-ccd0ab58375a`, named Internal, automatic distribution enabled.
- The signed-in Account Holder was added as the sole tester; Apple displays Invited. No other testers were added.
- [Build and test information](https://appstoreconnect.apple.com/teams/efa2b77f-c93d-474e-a952-0919f49227fc/apps/6811353745/testflight/ios/3316cfef-f705-47d1-841f-f4d4b2401932)
- [Internal group](https://appstoreconnect.apple.com/teams/efa2b77f-c93d-474e-a952-0919f49227fc/apps/6811353745/testflight/groups/490fb7ef-3547-4ab9-9041-ccd0ab58375a/builds)

## Artifact and upload evidence

The existing validated `20260912T115122Z-source` snapshot was archived with automatic signing after the user signed into Xcode. No app-source changes were made for this upload.

- Signed archive: `.build/Release/Verve-TestFlight-1.0.0-1.xcarchive`.
- Archive executable SHA-256: `88b96a0efa03775b7d0166d2fb20d773c2a96d9abd085bdb99e7ec0d2257f723`.
- Local distribution export: `.build/TestFlightExport/Verve.ipa`.
- Local IPA SHA-256: `a73bc3b3942eef476471ca96416192c2f68570856f684bcfaec59cdaa2473299`.
- Local exported IPA checks: correct bundle/version/team; strict code-signature verification; explicit App Store provisioning profile without device UDIDs; get-task-allow false.
- Upload used Xcode's distribution pipeline from the same archive with `destination=upload`, automatic provisioning, and build-number management disabled. It performs its own packaging, so the local export hash is not asserted as the uploaded ZIP hash.
- Logs: `/tmp/verve-testflight-archive-authenticated.log`, `/tmp/verve-testflight-export.log`, `/tmp/verve-testflight-upload.log`.
- Xcode reported Upload succeeded at 21:23 JST. App Store Connect subsequently displayed Ready to Test for build 1 in the Internal group, with one invited tester.

## Purchase configuration

Created the non-consumable `me.unvalley.verve.complete.lifetime` (Apple ID `6811354276`), Japanese and English localizations, Japan base price ¥900, and Japan-only availability. Family Sharing and automatic availability in future territories remain off. Other territory prices were generated by Apple but those territories are not enabled. Product status is Prepare for Submission; no App Store review submission was made.

The app still verifies real StoreKit entitlements; there is no Release beta unlock flag. Product propagation and sandbox purchase/restore/refund must be checked from this TestFlight install. No purchase transaction or physical-device installation has been observed yet. A native IAP review screenshot and the remaining commercial submission requirements are still outstanding.

## Install

Open Apple's invitation using the Account Holder's Apple Account on the iPhone or iPad, accept it in TestFlight, then install Verve 1.0.0 (1). The app is available for internal testing, not public App Store distribution. The beta's What to Test field contains the learning, settings, core-image, recording, and purchase/restore checks.
