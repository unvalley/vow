# Readiness — 13 September 2026

The current native source adds Japanese settings, localized microphone consent,
support, public privacy links and review checks after the build 11 upload.
See [current App Review coverage](APP-REVIEW-CHECKLIST.md) for implementation,
verification and submission gates. Build 11's archive does not include this work;
a new build must be prepared before submission. The release evidence below is
retained as historical evidence for build 11.

Branding and the store presentation package are prepared. Current TestFlight
upload, processing and installation evidence is recorded in [TESTFLIGHT.md](TESTFLIGHT.md).
Public App Store submission has not occurred.
The latest requirement-by-requirement check is in [preparation audit](PREPARATION-AUDIT.md).

## Prepared and verified

- Brand direction: **英語を、自分の言葉に。 / Make English your own.**
  The approved outlined Archivo italic wordmark, graphite/paper palette, app
  typography, restrained copy and actual product imagery form one system.
  [Strategy](../Brand/STRATEGY.md) · [Visual reference](../Brand/preview.html).
- Opaque 1024 × 1024 native icon, favicon, touch icon and 1200 × 630 social
  image share the wordmark's v. The prior all-black native icon is corrected.
  Native icon appearance was verified on the simulator Home Screen and the
  actual build 7 archive icon was decoded and inspected.
- Japanese/English App Store and IAP copy, review notes, privacy/API audit,
  microphone alternatives and length checks. `check_submission.py` passes
  local constraints and reports four missing commercial inputs below.
- **28 store images**: seven screens × two explanation languages × two device
  sizes. Actual captures from passing iPhone/iPad XCTest capture tests, with immutable
  raw files, proportional presentation and SHA-256 provenance. All files pass
  dimensions, alpha, count, catalog and source-hash checks. [Preview](screenshots/preview.html).
  Both device capture tests now pass on build 11, including the simpler Today
  footer. Phone captures show the full forgetting curve and legend after scrolling.
  Paid requirements are described; Stats uses sample history and its curve is
  explicitly illustrative. Images are local, not uploaded to App Store Connect.
- The bilingual landing page, support and privacy pages are publicly deployed:
  [Website](https://vow.unvalley.me/ja/) · [Support](https://vow.unvalley.me/support/)
  · [Privacy](https://vow.unvalley.me/privacy/). The latest deployment is
  `77fc39de-1d80-4d9d-b33c-0d2d8f514141`: 51 public responses match built bytes;
  robots.txt retains the built text after a Cloudflare-managed prefix. Each locale
  uses matching Japanese/easy-English app images from build 11.
  Mobile/desktop layout, image loading, meaning reveal
  and next-expression reset were verified. No public Apple download URL is
  invented; the page says the app is coming soon.
- Catalog: 750 phrasal verbs + 450 idioms, stable existing IDs/order and 50
  fixed free expressions. Daily goal 1–50, combined meaning/examples, spaced
  reviews and Stats remain included. Full Speaking and all five story scenes
  are free; Vow Pro unlocks full browsing and meaning reviews.
- Today now has Today's learning / Explore modes with independent swipe positions,
  selected-expression recall and daily queue updates. Accessibility text sizes use
  vertically stacked mode buttons.
- Build 11's five focused iPhone UI tests and both device capture tests passed;
  final screens were inspected. The seven mode tests, 64 iOS unit tests and eight catalog tests passed
  for build 8; core source hashes are unchanged. Signed arm64 archive and Apple
  Distribution IPA passed exact signature, provisioning, bundle/build/catalog,
  source-manifest and Debug-override checks. [Release record](TESTFLIGHT.md).


## Purchase test boundary

The app uses real StoreKit 2 products and verified entitlements. It displays an
unavailable state when Apple returns no Product; it never substitutes a fake
price or unlocks Release with a test flag.

The native price-bearing purchase screen is now verified in Japanese and English.
Launching **VowStore** from Xcode on the same iPad simulator made the local
product available; the subsequent UI capture test passed. The two unmodified
2064 × 2752 PNGs are in [review-assets](review-assets/README.md), with hashes and
successful test provenance. No price was mocked or painted into the images.

Transaction coverage is partial. An additional UI run confirmed the Xcode local
payment sheet, purchased Vow Pro and observed unlocked access after relaunch.
That run **failed** while waiting 10 seconds for the restore-completion notice, so it is
not a passing purchase/restore test. The experimental test source and result are
preserved under `.build/BrandRelease/Purchase-UI-Transaction*`; it is not added
to the regular UI suite as a state-dependent test.

StoreKitTest mutation calls still log `SKInternalErrorDomain Code=3`. The host
integration run after IDE warmup was interrupted while awaiting a dialog; direct
IDE execution also failed/cancelled without proving approval/refund. These are
environment observations, not proof that restore is broken in the shipped app.
Exact results and reproduction steps are in [StoreKit verification](../docs/STOREKIT-TESTING.md).

Physical-device TestFlight/sandbox purchase, restore, refund/revocation, pending
approval and offline previously purchased launch remain unverified. The local
Xcode payment confirmation is not a production payment or a TestFlight install.

## Remaining public-release requirements

1. Reauthenticate App Store Connect to verify the latest build's processing and
   existing Internal-group assignment, and save metadata/screenshots/test notes.
   App `6811353745` and IAP `6811354276` already exist; no duplicate records needed.
2. Supply review contact name/phone, formal copyright holder, and confirmation
   of commercial redistribution rights for the supplied content. These four
   fields remain explicit in `metadata.json`; none has been guessed.
3. Verify physical-device learning, microphone denial/interruption, purchase,
   restore/refund and optional notification delivery. Invitation/upload is not
   installation evidence. Current hardware VoiceOver and frame pacing remain
   unverified.
4. Confirm final public territories and applicable business agreements; complete
   privacy/rating declarations using the prepared audit. Japan ¥900 and
   Japan-only IAP availability were configured previously. No agreement, banking
   entry or tax declaration was submitted by this task.
5. Upload the prepared native IAP review image with the other metadata, submit
   the first non-consumable with the app version after verification, and use
   manual public release after review approval.

`python3 scripts/check_submission.py --require-ready` is the separate commercial
metadata gate. Historical build and authentication evidence is retained in
[TESTFLIGHT.md](TESTFLIGHT.md); its earlier successful distribution does not
prove current browser authentication or installation of the latest build.
