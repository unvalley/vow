# Store preparation audit

Current evidence checked on 2026-09-13T20:25:46+09:00.

| Requirement | Evidence | State |
| --- | --- | --- |
| Reference-led brand direction | `Brand/STRATEGY.md`: Cosmos/Art4 observations, adopted promise, identity, colour, typography, voice and current learning-screen hierarchy | Prepared and implemented |
| Wordmark and app identity | Approved Archivo outlines/license in `Brand/`; `vow-icon-1024.png` and native icon match byte for byte; icon check passes opaque/nonblank 1024px | Verified |
| Landing and supporting pages | Deployment `77fc39de-1d80-4d9d-b33c-0d2d8f514141`; `build11-live-verification.json`, `build11-live-layout.json`, `build11-live-interactions.json` in `.build/BrandRelease/` | Published and verified |
| Store presentation assets | 28 new build 11 captures from passing `Build11-Store-Phone.xcresult` and `Build11-Store-Pad.xcresult`; dimensions/hashes/catalog/provenance checks pass; overview and updated goal captions inspected | Prepared locally; not uploaded to Apple |
| Purchase review images | Two native price-bearing PNGs and passing capture evidence in `review-assets/manifest.json`; local Xcode environment is explicit | Prepared locally; production transaction coverage incomplete |
| Localized listing/product metadata | `metadata.json`; `check_submission.py` passes copy limits and product consistency | Four external fields still missing |
| Native release artifact | Frozen build 11 source matches current native files; Distribution IPA checks and accepted 18:16:13 JST upload in `.build/TestFlightBuild11Export/release-record.json` | Upload accepted; current source/capture alignment verified |
| Current Apple processing and Internal distribution | Browser still shows App Store Connect login with failed authentication; historical build 1 distribution record is not current-build evidence | Requires login |
| Physical device and transactions | `devicectl list devices` reports the registered iPhone unavailable; sandbox/restore boundaries documented in `docs/STOREKIT-TESTING.md` | Physical verification outstanding |

The live check verified 51 responses byte for byte. `robots.txt` has an observed
Cloudflare Managed Content prefix followed by the unchanged built robots file;
that transformation is recorded separately rather than counted as an exact match.
Both languages passed 320/390/768/1440px layout checks and live disclosure,
keyboard advance, three-expression loop, answer reset and FAQ checks.

All store and landing captures now use the current Today layout. The iPad's
local Xcode Pro entitlement is documented in `screenshots/README.md`; goal
presentation copy states that the full collection requires Pro. Images use
actual simulator content, with Stats explicitly identified as sample data.

## Remaining external work

- Reauthenticate App Store Connect to verify processing/distribution and place
  the prepared metadata, screenshots and test notes in the existing app record.
- Supply the review contact name and phone number, formal copyright holder,
  and confirmation that the learning content may be commercially distributed.
  These four fields remain unset; none is inferred.
- Make the physical test device available for learning, microphone,
  notification and StoreKit sandbox/restore checks.

Brand assets and the refreshed presentation package are prepared. Full store
readiness remains unproven until the external requirements above are met.
No public App Store submission, business agreement, tax declaration or manual
public app release was performed. Detailed check record:
`.build/BrandRelease/build11-brand-readiness.json`.
