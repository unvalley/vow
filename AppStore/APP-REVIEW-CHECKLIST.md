# App Review coverage — 13 September 2026

Scope: the current native source, including Japanese settings and the support/
permission work added after the build 11 upload. This source was committed as
`85bfcc6` and uploaded to TestFlight as build 12 on 14 September 2026
([TESTFLIGHT.md](TESTFLIGHT.md)); it has not been submitted to App Review.

Later in the same working tree, example-by-example meaning/audio controls,
Apple sentence translation and installed-voice selection were added. Their
scope and evidence are recorded in [EXAMPLE-AUDIO.md](../docs/EXAMPLE-AUDIO.md).
The unsigned preflight archive and 64-unit/4-UI results below precede these
additions; they must not be used as final-artifact evidence for the newer source.

The applicable requirements were checked against Apple's [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/),
particularly 1.5, 2.1, 2.3, 3.1.1 and 5.1.1. The table records the implementation
and the remaining verification boundary, rather than an assurance of approval.

| Area | Implementation and evidence | Remaining boundary |
| --- | --- | --- |
| Usable free app | 50 fixed phrasal verbs and 50 fixed idioms, meaning reviews, speaking, five story scenes and core images; `AccessPolicy`, `LearningStore`, existing unit/UI coverage | Fresh physical-device run of the final build |
| Digital purchase | StoreKit 2 non-consumable; price comes from `Product.displayPrice`; unavailable/retry state keeps free content usable | Final product metadata and sandbox purchase |
| Restore | Explicit restore actions in Settings and Purchase; `AppStore.sync()` then verified current entitlements | Real sandbox restore/reinstall and offline purchased launch |
| Pending/unverified/revoked access | Pending and unverified transactions do not unlock; valid entitlements exclude revoked/upgraded purchases; transaction updates refresh access | Working StoreKit transaction environment and physical verification |
| Purchase disclosures | One-time purchase, no subscription, Pro features and free features described in both languages; terms and privacy links | App Store Connect must attach the first IAP to the app version |
| Support | Settings → Contact support: website, email, copy-email action, offline guidance and app version | Email delivery itself is not exercised |
| Privacy policy | Offline policy and public-policy link; local audio/progress/notifications, Apple purchases, deletion and backup behavior described | Account holder confirms the final App Privacy declaration |
| Microphone consent | English/Japanese `InfoPlist.xcstrings`; permission only on Record; refusal explains alternatives and offers iOS Settings | Physical recording, route changes and interruption checks |
| No required microphone | Speaking without recording and typed replies remain available after refusal | UI permission/alternative test recorded below |
| Recording lifecycle | Exercise exit clears temporary recordings; next launch reclaims abandoned takes; background/interruption handlers stop audio | Hardware playback and interruption timing |
| Optional notifications | Initially off; permission requested on opt-in; local scheduling; off removes requests; denial links to notification settings | Physical delivery, notification tap, Focus/Scheduled Summary |
| Privacy manifest | No tracking, collected data or required-reason categories; source uses no analytics/ads/remote speech or custom network client | Re-audit every future SDK/API change |
| Localization and accessibility | Japanese/English settings, help, permission explanation; Dynamic Type layouts and stable accessibility identifiers | Do not claim full-app Japanese translation or full VoiceOver support without broader evaluation |
| Listing and images | Bilingual listing and existing device images; paid content and illustrative Stats are identified; validators check copy limits | Refresh affected images from final source, upload and review all App Store fields |
| Content rights/rating | Source provenance is documented; targeted scan still finds two non-graphic murder-investigation examples in supplemental usage | Owner confirms commercial rights and the age-rating questionnaire |
| Final artifact | Validator checks IDs, versions, assets, catalog, both localized permission strings, review-facing translations, privacy and absence of test configuration/flags | New unused build number, signed archive/export, upload, processing and physical installation |

Account deletion and Sign in with Apple are not applicable to the current app:
it has no account creation or login. ATT, subscription management and public-UGC
moderation are likewise not applicable because there is no tracking, subscription
or public sharing service. These are implementation-specific conclusions; revisit
them if those features are added. [Apple account and privacy requirements](https://developer.apple.com/app-store/review/guidelines/#privacy)

## Verification record

- `python3 scripts/check_submission.py`: listing/product checks plus source version,
  public URLs, privacy and localized review-facing copy pass.
- `python3 scripts/check_submission.py --require-ready`: intentionally fails until
  `reviewContactName`, `reviewContactPhone`, `copyrightHolder` and
  `contentDistributionRightsConfirmed` are supplied in `metadata.json`.
- Public support/privacy pages were opened in a browser, with visible contact,
  restore/microphone help and local-notification privacy text. Read-only records:
  `.build/app-review-readiness/support-live.json` and `privacy-live.json`.
  A raw HTTP client's 403 is not treated as browser unavailability.
- Native tests: **64 unit tests and 4 focused UI tests pass** across
  `ReviewReadiness-Retry.xcresult` and `MicrophoneConsent-Japanese.xcresult` in
  `.build/app-review-readiness/`. The first result includes a microphone-test
  failure caused by expecting Japanese SpringBoard copy on an English device;
  the corrected test passes after setting the simulator itself to Japanese.
  Settings persistence in both languages, maximum Dynamic Type, free-access
  support/privacy navigation and both microphone-refusal alternatives are covered.
  Japanese permission and refusal screenshots were exported to
  `japanese-consent-screenshots/` and visually inspected.
- The first build attempt ran out of disk space before tests. Only reproducible
  compiler caches were removed; archives, IPAs and prior verification records
  were preserved.
- Release archive and archive validation: **pass**, using the 96-file native
  working-tree snapshot in `native-source/source-manifest.json`. Artifact:
  `Vow-review-unsigned.xcarchive`; report: `vow-validation.json` inside it.
  It contains arm64 code, the reviewed catalog, English/Japanese purpose strings,
  Japanese support/settings copy and privacy manifest, with no test bundles,
  StoreKit configuration or debug overrides. This is an **unsigned preflight**
  retaining source build number 11, not an uploadable or newly uploaded package.
- StoreKit transaction tests: **2 fail before any purchase is attempted** in
  `StoreKit.xcresult`. The Xcode service returns `SKInternalErrorDomain Code=3`
  while applying test configuration, including dialog suppression. The new
  test precondition detects this instead of proceeding into a payment dialog.
  Purchase, restore, refund and pending approval remain unverified; see
  `docs/STOREKIT-TESTING.md`. No production entitlement behavior was bypassed.
- `devicectl list devices` currently reports the registered iPhone unavailable.
  No current physical installation, microphone, notification or sandbox payment
  result is claimed.

## Submission sequence

1. Fill the four missing contact/rights fields. Confirm app and IAP territories,
   price, business agreements, privacy, age rating and export compliance in the
   existing App Store Connect records. Accessibility labels require their own
   [feature-by-feature evaluation](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/overview-of-accessibility-nutrition-labels/).
2. Verify the latest uploaded build number, then increment `CURRENT_PROJECT_VERSION`
   and `metadata.json` together. Build 11 is already used. The archive validator
   now reads the expected version/build from metadata.
3. Freeze the reviewed native source, produce and validate a signed App Store
   archive/export, upload that exact package, wait for processing and exercise it
   on a physical device. Use the existing release flow and preserve its artifact.
4. Update the affected store/review images and reviewer notes, select the new
   build, and attach Vow Pro to the same first submission. [Apple first-IAP instructions](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase)
5. Submit the completed version for review. Manual public release remains the
   configured choice after approval. [Apple submission steps](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app/)
