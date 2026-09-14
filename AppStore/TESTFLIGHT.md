# TestFlight — 15 September 2026

## vow 1.0.0 (14)

**Upload accepted at 03:18:38 JST on 15 September 2026; Apple reports processing.**

Build 14 is built from committed revision `5db68ab` on `main`, pushed to
`origin`. It adds a one-to-three-word English gloss to every expression (shown
alone in the Phrases list and above the explanation elsewhere), a Home filter
for phrasal verbs or idioms, colored memory ratings recorded once per phrase per
day, the rating row in Phrase notes, "Use this phrase" in Practice instead of a
hint, a month calendar in Stats replacing the seven-day row and the upcoming
chart, Settings as the third tab, the four-collection Phrases screen with inline
filter and sort, and a Home render that derives its queues once. The Scenes
entry was removed from Phrases, so scene and story practice are unreachable in
this build.

- Tests run before the upload: 84 Swift package tests (`swift test`) and 89 iOS
  unit tests on the iPhone 17 Pro simulator (`.build/TestFlightBuild14Tests.xcresult`).
  **No UI tests were run for this build** (skipped at the user's request); the
  screens were checked by hand on the simulator. Five UI tests that entered
  through Scenes are marked skipped; tests that reference the removed Home
  settings button or the removed Stats chart need updating.
- Frozen source: `.build/Release/20260914T181511Z-source` (380 files from
  `git archive` of `5db68ab`, plus the generated project). Manifest SHA-256:
  `b8315c368abfe6ea13550ac2ceaca20de157d962ed065d3af030c5c4c49e5e09`.
- Signed archive: `.build/Release/Vow-20260914T181511Z-signed.xcarchive`.
  Archive executable SHA-256:
  `01921513c4475910a423b4b640ac2252c2917255ffbf9a6cc435309a23f46df2`.
  `validate_archive.py` (signed mode) passed.
- Local IPA: `.build/TestFlightBuild14Export/Vow.ipa`. SHA-256:
  `05b57ab68dacbbe4cce8a6dbc4e3374069431f4c06a01a9b368d570ba40d589a`.
  Inspection passed: `me.unvalley.verve` 1.0.0 (14), display name `vow`,
  iOS 17.0 minimum, strict code signature (Apple Distribution: UNV Studio),
  `iOS Team Store Provisioning Profile: me.unvalley.verve` (no device UDIDs,
  `get-task-allow` false, expires 2027-08-27), arm64, 1,300-entry catalog,
  `en`/`ja` localizations.
- The same validated archive was uploaded with automatic signing, symbols
  enabled and build-number management disabled
  (`.build/testflight-build14-upload.log`). The local IPA hash is not asserted
  as the separately packaged upload hash.
- Secret scan of the frozen source: no credential findings
  (`.build/testflight-build14-secrets.log`).
- Full record: `.build/TestFlightBuild14Export/release-record.json`.
- Note: the local artifacts of builds 1–13 under `.build/Release` were deleted
  on 15 September 2026 while freeing disk space. Their hashes stay recorded
  below; the uploads themselves are unaffected.

**Processing completion, Internal distribution and physical installation remain
unverified.** [What to Test notes](TESTFLIGHT-BUILD14-NOTES.txt) are prepared
locally, not saved to App Store Connect. Before any App Store submission, verify
on a physical iPhone: the gloss line in both explanation languages, the Home
filter, rating colors, the Stats calendar, the Settings tab, Phrases opening at
the top with Pro unlocked, and the sandbox purchase/restore flow.

## Historical build 13 — vow 1.0.0 (13)

**Upload accepted at 20:50:50 JST on 14 September 2026; Apple reports processing.**

Build 13 is built from committed revision `d2a3963` on `main`, pushed to
`origin`. It adds a three-page first-launch introduction (phrases, spaced
reviews, Vow Pro) that hands over to the daily goal sheet, a device-language
default for the explanation language (Japanese devices start in 日本語, all
others in Easy English), Settings regrouped into Vow Pro / Learning / Practice /
Notifications / Appearance / About, a daily goal of 5, 10 or 20 with a single
note, emphasis levels that reserve the ink fill for the forward action
(Today's mode switch and the onboarding icon are no longer black), consolidated
copy on the Pro page, purchase screen, lock card, Settings footers and reading
voice screen, and the catalog expansion to 1,300 expressions (800 phrasal verbs
and 500 idioms).

- Tests run before the upload: 77 Swift package tests (`swift test`), 82 iOS
  unit tests on the iPhone 17 Pro simulator (`.build/TestFlightBuild13Tests.xcresult`),
  and focused UI tests during development on the same simulator: five
  onboarding flows, settings localization at the largest text size, the
  daily-goal flows, the Pro card in Explore and Phrases, the free-plan copy on
  the purchase screen and the Japanese Home rating labels. **The full UI suite
  was not run.** Known failure independent of this build:
  `SettingsLocalizationUITests.testJapaneseSettingsAndSavedChoicesAcrossLanguages`
  fails on clean `35d0d22` too (the background tile identifier lands on a
  container, not the button).
- Frozen source: `.build/Release/20260914T114625Z-source` (377 files from
  `git archive` of `d2a3963`, plus the generated project). Manifest SHA-256:
  `b60e5a222bc0e8eb14264764534f65571f7b83292733490bfb0efe6192d0fea5`.
- Signed archive: `.build/Release/Vow-20260914T114625Z-signed.xcarchive`.
  Archive executable SHA-256:
  `da0f096a3d1b651d80844c7844a9877d76beefb02541b456af755a50469237b3`.
  `validate_archive.py` (signed mode) passed.
- Local IPA: `.build/TestFlightBuild13Export/Vow.ipa`. SHA-256:
  `02dac210d883ca988a1a636fa8676d760b38bb2a4d176664ad90ba83754e5682`.
  Inspection passed: `me.unvalley.verve` 1.0.0 (13), display name `vow`,
  iOS 17.0 minimum, strict code signature, team `2X266ZCRLV`,
  `iOS Team Store Provisioning Profile: me.unvalley.verve` (no device UDIDs,
  `get-task-allow` false, expires 2027-08-27), arm64, 1,300-entry catalog,
  `en`/`ja` localizations. The IPA executable hash differs from the archive
  executable because export re-signs the binary.
- The same validated archive was uploaded with automatic signing, symbols
  enabled and build-number management disabled
  (`.build/testflight-build13-upload.log`). The local IPA hash is not asserted
  as the separately packaged upload hash.
- Secret scan of the frozen source: no credential findings
  (`.build/testflight-build13-secrets.log`).
- Full record: `.build/TestFlightBuild13Export/release-record.json`.

**Processing completion, Internal distribution and physical installation remain
unverified.** [What to Test notes](TESTFLIGHT-BUILD13-NOTES.txt) are prepared
locally, not saved to App Store Connect. Before any App Store submission, verify
on a physical iPhone: the introduction on a fresh install, the daily-goal sheet,
the regrouped Settings, the explanation-language default on a Japanese-language
device, and the sandbox purchase/restore flow.

## Historical build 12 — vow 1.0.0 (12)

**Upload accepted at 03:30:08 JST on 14 September 2026; Apple reports processing.**

Build 12 is the first upload built from a committed revision: `85bfcc6` on
`main`, pushed to `origin`. It adds continuous listening (Phrases → Listen
continuously, background audio, lock-screen controls, mini-player), per-example
Meaning and Listen/Slower controls with authored Japanese meanings for the free
collection, an installed reading-voice picker, Japanese settings/help/microphone
consent, Contact support and privacy screens, Light/Dark/System theme, eight Today
backgrounds, on-page Again/Hard/Good/Easy rating in Today's learning and 50 fixed
free idioms. The catalog remains 1,200 expressions.

- Tests run before the upload: 76 Swift package tests (`swift test --parallel`),
  81 iOS unit tests on the iPhone 17 Pro simulator
  (`.build/TestFlightBuild12Tests.xcresult`) and nine Python catalog tests. All
  passed. **No UI test was run for this build**; the UI evidence recorded for
  builds 8–11 and in [CONTINUOUS-LISTENING.md](../docs/CONTINUOUS-LISTENING.md)
  and [EXAMPLE-AUDIO.md](../docs/EXAMPLE-AUDIO.md) precedes this source.
- Frozen source: `.build/Release/build12-source` (373 files from `git archive`
  of `85bfcc6`, plus the generated project). Manifest SHA-256:
  `b6ddb043f0ae231049a72e7d95c59b01ba2437d0036f1d576a9a227915bb9aa9`. The frozen
  native sources, tests, scripts, `project.yml` and `Package.swift` match the
  working tree exactly.
- Signed archive: `.build/Release/Vow-1.0.0-12.xcarchive`. Archive executable
  SHA-256: `99a56e9911dfdd0aec65dac83b1eff6b77d028b5e95693ed16cc47d83eb89eae`.
  `validate_archive.py` (signed mode) passed: bundle/version/build, display name,
  iOS 17 minimum, both localized microphone strings, shipped Japanese review-facing
  copy, privacy manifest, exact catalog, no test config/bundles, no Debug launch
  overrides, arm64, strict code signature and embedded provisioning profile.
- Local IPA: `.build/TestFlightBuild12Export/Vow.ipa`.
  SHA-256: `830dc4512fe395ba9cacaa2f7d1f3840cb73966b287bfd10b3af286d3dc125c0`.
  Inspection passed: `Apple Distribution: UNV Studio (2X266ZCRLV)` signature,
  `iOS Team Store Provisioning Profile: me.unvalley.verve` (no device UDIDs,
  `get-task-allow` false, expires 2027-08-27), `UIBackgroundModes = [audio]`,
  `en`/`ja` localizations, 1,200-entry catalog equal to source. The IPA executable
  hash differs from the archive executable because export re-signs the binary.
- The same validated archive was uploaded with automatic signing, symbols enabled
  and build-number management disabled (`.build/testflight-build12-upload.log`).
  The local IPA hash is not asserted as the separately packaged upload hash.
- Secret scan of the frozen source: no credential findings
  (`.build/testflight-build12-secrets.log`).
- Full record: `.build/TestFlightBuild12Export/release-record.json`.

**Processing completion, Internal distribution and physical installation remain
unverified.** [What to Test notes](TESTFLIGHT-BUILD12-NOTES.txt) are prepared
locally, not saved to App Store Connect. Before any App Store submission, verify
on a physical iPhone: audible continuous listening while locked, lock-screen
controls, headphone disconnection and call interruption, example Meaning/Listen
controls, the reading-voice picker and the sandbox purchase/restore flow. The
external submission inputs listed in [readiness](READINESS.md) are still missing.

## Historical build 11 — vow 1.0.0 (11)

**Upload accepted at 18:16:13 JST on 13 September 2026; Apple reports processing.**

Today now groups progress and compact paging above a single Start learning /
Continue learning button. The progress count opens the daily-goal editor;
Practice speaking moves to the waveform button in the upper toolbar. The footer
omits the progress track, visible review-due count and separate Daily goal label.
Explore shows only centered paging in its footer. Accessibility sizes stack the
progress and paging controls vertically.

- Five iPhone UI tests passed in `Today-Simple-Footer-Verified.xcresult`: mode
  swipes and selected recall, completion/refill, free access with a goal over 20,
  largest text/reduced motion, and the moved speaking entry with typed response.
  Final Today, Explore and largest-text screens were visually inspected.
- The initial run exposed a goal-button accessibility issue; this was fixed
  before the final source was frozen and archived. Updated progress assertions
  address its native button instead of the former static text.
- Frozen source: `.build/Release/build11-source` (89 files, uncommitted native
  working-tree snapshot). SHA-256: `0c3bd94b8ac39e3c3d968523c3f5d28407af98f9dbf25002d581b8ca659dc030`.
- Signed archive: `.build/Release/Vow-1.0.0-11.xcarchive`.
- Local IPA: `.build/TestFlightBuild11Export/Vow.ipa`.
  SHA-256: `37d8f879ab0c32c57128278b012d197861ebafa3f05546ab3d3522bc8d6ef37a`.
- Exact archive/IPA inspection passed: arm64, version, bundle/team, Distribution
  signature, App Store profile, catalog, Release configuration and frozen source
  match. No credential findings. The same validated archive was uploaded;
  the local IPA hash is not asserted as the separately packaged upload hash.
- Full record: `.build/TestFlightBuild11Export/release-record.json`.

The browser session still requires App Store Connect login. **Processing
completion, Internal distribution and physical installation remain unverified.**
[What to Test notes](TESTFLIGHT-BUILD11-NOTES.txt) are prepared locally.
Store/landing screenshots were subsequently refreshed from passing build 11
iPhone/iPad capture tests. The public LP now uses the current Today footer;
see [preparation audit](PREPARATION-AUDIT.md).

## Historical build 10 — vow 1.0.0 (10)

**Upload accepted at 17:52:43 JST on 13 September 2026; Apple reports processing.**

Removed the separate verb and particle links from the shared Today/Explore
expression card. The complete expression remains the main title.

- The existing iPhone swipe/selected-recall test passed in
  `.build/BrandRelease/Today-Clean-Labels-Phone.xcresult`; both captured screens
  were visually inspected before upload.
- Frozen source: `.build/Release/build10-source` (89 files, uncommitted native
  working-tree snapshot). Manifest SHA-256: `49f0a7c0a291aa087be7d8bcc94cb98fc84e4c550b50a8774b2d901eed865113`.
- Signed archive: `.build/Release/Vow-1.0.0-10.xcarchive`.
- Local IPA: `.build/TestFlightBuild10Export/Vow.ipa`.
  SHA-256: `b4fec5ae6ebb022d7363d1625c8ff9a3cc80afb5429b22d57136f0b28ec23488`.
- Archive and exact IPA validation passed: version, arm64, bundle/team, strict
  Distribution signature, App Store profile, catalog and Release configuration.
  Frozen source and working native files matched. No credential findings.
- The same validated archive was uploaded. The local IPA hash is not asserted
  as the separately packaged upload hash. Full evidence is in
  `.build/TestFlightBuild10Export/release-record.json`.

App Store Connect's browser session still requires login. **Processing
completion, Internal distribution and physical installation remain unverified.**
[What to Test notes](TESTFLIGHT-BUILD10-NOTES.txt) are prepared locally.

## Historical build 9 — vow 1.0.0 (9)

**Uploaded successfully at 16:58:52 JST on 13 September 2026. Apple reports the package is processing.**

[TestFlight](https://appstoreconnect.apple.com/apps/6811353745/testflight/ios)

Today switches between **Today's learning** and **Explore**, each with its own
swipe position. Learning contains due reviews plus the remaining daily allowance;
Explore contains all accessible expressions. Recall starts at the selected
expression, and rated items leave today's queue. Browsing alone does not consume
the daily goal. At accessibility text sizes, the switch stacks vertically so
both labels remain readable. The catalog remains 1,200 expressions.

- Bundle `me.unvalley.verve`, app `6811353745`, team `2X266ZCRLV`.
- Frozen source: `.build/Release/build9-source`, 89 files from an **uncommitted
  native working-tree snapshot** based on `5d90258`. No commit/push was made.
- Source manifest SHA-256: `d8b9e92b9b13210463d939a23b4c0d18ea95772dd4281c31ab711d5172c103e2`.
- Signed archive: `.build/Release/Vow-1.0.0-9.xcarchive`.
- Archive executable SHA-256: `6a9801a602c088ebc5682be9695e8ca2cb9db5970ed17dc1369e6f3f6ef5e420`.
- Local IPA: `.build/TestFlightBuild9Export/Vow.ipa`.
- Local IPA SHA-256: `afbfb4fe733598f890f45110c3c9032f7b49076c8d0f648642b4bcc9e43b2e9b`.
- Exact archive/IPA inspection passed: arm64, version/bundle/team, strict Apple
  Distribution signature, App Store provisioning, no debugger entitlement,
  matching 1,200-expression catalog, no Debug overrides or test purchase config.
  The frozen manifest and all working native sources match exactly.
- The same validated archive was uploaded with automatic signing and symbols;
  build-number management is disabled. Upload packaging is separate from the
  inspected local IPA, whose hash is not asserted as the upload package hash.
- Build 9 UI checks: two iPhone tests and one iPad test passed, covering normal
  swiping/selected recall and the largest text size with reduced motion.
  `.build/BrandRelease/Today-Accessible-Phone.xcresult` and
  `Today-Accessible-Pad-Verified.xcresult`; final screens were visually inspected.
- The mode baseline passed seven iPhone/iPad tests in `Today-Modes-Phone-Verified`
  and `Today-Modes-Pad-Verified`. The unchanged core passed 64 iOS unit tests and
  eight Python catalog tests for build 8. All core hashes still match build 8.
- Secret scan matches were verified as source-manifest SHA-256 values; no
  credential findings. Full record: `.build/TestFlightBuild9Export/release-record.json`.

App Store Connect still requires browser login. **Processing completion,
Internal-group assignment and physical installation remain unverified.**
No groups/testers were added and no public App Store submission was made.
[What to Test notes](TESTFLIGHT-BUILD9-NOTES.txt) are prepared locally, not saved
to App Store Connect. Purchase verification boundaries remain in
[StoreKit testing](../docs/STOREKIT-TESTING.md).

## Historical build 8 — vow 1.0.0 (8)

Uploaded successfully at **16:48:11 JST** on 13 September 2026. This introduced
the two Today modes. A final visual check found excessive label wrapping at the
largest iPhone text size, corrected by build 9. Source, archive, IPA and the
accepted upload record are preserved in `.build/Release/build8-source`,
`.build/Release/Vow-1.0.0-8.xcarchive` and `.build/TestFlightBuild8Export/`.
The initial UI test drivers were corrected separately without changing production
source, documented in `.build/Release/build8-validation-source/validation-source.json`.

## Historical build 7 — vow 1.0.0 (7)

**Uploaded successfully at 15:24:55 JST on 13 September 2026. Apple reports the uploaded package is processing.**

[TestFlight](https://appstoreconnect.apple.com/apps/6811353745/testflight/ios)

Includes the new white-v/graphite icon, replacing the prior all-black app icon,
and the existing **1,200 expressions: 750 phrasal verbs and 450 idioms**. Daily
goals, combined meaning/examples, spaced reviews and Stats remain included.
The native icon was inspected on the simulator Home Screen and decoded from
the exact Release archive.

- Bundle `me.unvalley.verve`, app `6811353745`, team `2X266ZCRLV`.
- Frozen source: `.build/Release/build7-source`, **88 files from an uncommitted
  native-app working-tree snapshot**, based on `5d90258`. No commit/push was made.
  All source hashes and their match to the working native source were verified.
- Source manifest SHA-256: `3cfcfe5ded9d8a7a6c719fad97b41a904230f1d67ae63b8e2362b3578a566543`.
- Signed archive: `.build/Release/Vow-1.0.0-7.xcarchive`.
- Archive executable SHA-256: `e177ffa3a3f633f7c820432a5be453daffcb4011b8541f10155f97c75cf51263`.
- Local IPA: `.build/TestFlightBuild7Export/Vow.ipa`.
- Local IPA SHA-256: `9b19d9888ae123d2004139801e400a0e4185ee87e362d880a47fac1dd49ba64b`.
- Icon master SHA-256: `b8baefdf7fc32787105b50ba849e3dd3114c5075463cdc6923023bf5c43aa134`.
- Exact archive/IPA checks passed: version, bundle/team, arm64, strict signature,
  Apple Distribution signing, App Store provisioning without device UDIDs or
  debugger entitlement, catalog equality, no Debug overrides/test purchase config.
- The same validated archive was uploaded with automatic signing, symbols enabled
  and build-number management disabled. Xcode packages the upload separately;
  the local IPA hash is not asserted as the uploaded package hash.
- 8 Python catalog tests, 59 Swift package tests and 64 iOS unit tests passed.
  iOS result: `.build/TestFlightBuild7Tests.xcresult`.
- Current native screenshot/navigation evidence: passing
  `.build/BrandRelease/Phone-Final.xcresult` and `Pad-Final.xcresult`, 28 captures.
  These captured the same production source/icon before the build-number bump.
- Secret scan: two source-manifest matches were verified as SHA-256 file hashes;
  no credential findings. Logs: `.build/testflight-build7-*.log`.
- Artifact checks and upload record: `.build/TestFlightBuild7Export/inspection.json`
  and `release-record.json`; archive `vow-validation.json`.

App Store Connect redirected to login during the final check. **Processing
completion, Internal-group assignment and physical installation remain unverified.**
No groups/testers were added. [What to Test notes](TESTFLIGHT-BUILD7-NOTES.txt)
are prepared locally and have **not** been saved to App Store Connect.
At upload time, the local price-bearing UI test had not passed. Subsequent
verification produced passing Japanese/English price-bearing captures and
observed a local Xcode purchase surviving app relaunch. The restore check failed;
physical-device TestFlight transactions remain unverified. See [current StoreKit evidence](../docs/STOREKIT-TESTING.md). No public App Store submission was made.

Brand/store preparation is separate from the native upload: 28 localized store
images and metadata are prepared locally; the updated landing/support/privacy
pages were deployed to `vow.unvalley.me` and eight public URLs verified against
the built bytes. See [readiness](READINESS.md) for remaining commercial inputs.

## Historical build 6 — vow 1.0.0 (6)

**Uploaded successfully at 14:25:38 JST on 13 September 2026. Apple reports the uploaded package is processing.**

[TestFlight](https://appstoreconnect.apple.com/apps/6811353745/testflight/ios)

Contains **1,200 expressions: 750 phrasal verbs and 450 idioms**, an increase of
50 phrasal verbs and 250 idioms over build 5. Existing lesson IDs and learning
order are preserved. New lessons include Japanese and easy-English meanings,
two conversation examples and usage guidance. Highlighting supports `crept`
and `won`. Daily goals, combined meaning/example reveal, Stats and spaced
reviews remain included.

- Version: `1.0.0 (6)`; app `6811353745`; bundle `me.unvalley.verve`; team `2X266ZCRLV`.
- Source: immutable **uncommitted native-app snapshot** at `.build/Release/build6-source`,
  based on `5d90258`. Its 82 files have verified SHA-256 hashes; native source
  also matched the working tree after archive/export. No commit or push was made.
- Source manifest SHA-256: `6d56277b018d5d1cafdbdd19075fa779a40868f889ffaa780c74bfc224bcf306`.
- Signed archive: `.build/Release/Vow-1.0.0-6.xcarchive`.
- Archive executable SHA-256: `9c0b864a09c7ce837401b247bb158a6aae121ef0c21208425ebd25ef3d250376`.
- Local distribution IPA: `.build/TestFlightBuild6Export/Vow.ipa`.
- Local IPA SHA-256: `d70dcacf7a5f47566e72d9f02b980aaf2b99d8b9ea6481372eba3376ec52e878`.
- Archive and IPA checks passed: bundle/version/team, arm64 archive, strict
  signature, Apple Distribution signing, App Store provisioning, no device UDIDs
  or debugger entitlement, no Debug launch overrides or test purchase configuration,
  and an exact 1,200-entry catalog match to the frozen source.
- Catalog SHA-256: `c6b3af30803ea52592e27cafb5324ffcf5ef8727a7b53b25ef610e3bb2824618`.
- The same validated archive was uploaded using Xcode automatic signing,
  symbols enabled and automatic build-number management disabled. Upload packaging
  is separate from the inspected local IPA; the local IPA hash is not an upload hash.
- Frozen-source validation: 8 Python catalog tests, 59 Swift package tests and
  64 iOS unit tests passed. iOS result: `.build/TestFlightBuild6Tests.xcresult`.
- Prior UI evidence for the unchanged native source is
  `.build/Catalog-1200/Catalog-Verified.xcresult`: new phrasal verb and idiom search,
  Japanese meaning and both examples, save and persistence after relaunch.
- Secret scan: two findings were verified source SHA-256 values in the manifest;
  no credential findings remained.
- Logs: `.build/testflight-build6-{archive,export,python,swift,tests,upload}.log`.
- Artifact validation: archive `vow-validation.json`,
  `.build/TestFlightBuild6Export/inspection.json` and `release-record.json`.

The App Store Connect browser session is expired. **Processing completion and
assignment to the existing Internal group are not verified.** No groups or
testers were added. [Japanese What to Test notes](TESTFLIGHT-BUILD6-NOTES.txt)
are prepared locally and have **not** been saved to App Store Connect.
Physical-device installation, notifications and TestFlight purchase/restore
remain unverified. No public App Store submission or website deployment occurred.

## Historical build 5 — vow 1.0.0 (5)

**Uploaded successfully at 12:01:55 JST on 13 September 2026. Apple reports the uploaded package is processing.**

[TestFlight](https://appstoreconnect.apple.com/apps/6811353745/testflight/ios)

Includes 700 phrasal verbs and 200 idioms, a configurable daily new-expression
goal (1–50), combined meaning/example reveal, and expanded Stats with daily
progress, seven-day activity, collection progress, upcoming reviews and an
explicitly illustrative forgetting curve. It includes the current native-app
changes since build 4; landing-page and brand-source work are outside this snapshot.

- Version: `1.0.0 (5)`; app `6811353745`; bundle `me.unvalley.verve`; team `2X266ZCRLV`.
- Source: immutable **uncommitted native-app snapshot** at `.build/Release/build5-source`,
  based on `5d90258`. This is not a clean Git revision. The original checkout is preserved.
- The snapshot contains 81 source/configuration/test/script files with verified
  SHA-256 hashes; native source still matched the working tree after the archive build.
- Signed archive: `.build/Release/Vow-1.0.0-5.xcarchive`.
- Archive executable SHA-256: `38bb07a35c8c0fddd3be169ccb60b3312af00dfdbacc2f9c18818f5be393bf80`.
- Local distribution IPA: `.build/TestFlightBuild5Export/Vow.ipa`.
- Local IPA SHA-256: `f1449d9e91d396920ee698f94a225b329e12a365e7af0717807d723f8ddd5d70`.
- Exact archive and IPA checks passed: bundle/version/team, arm64 archive,
  900-entry catalog identical to frozen source, strict signature, App Store
  provisioning, no device UDIDs/debugger entitlement, no Debug launch overrides
  (including the Stats fixture) or test purchase configuration, and Stats present.
- The same archive was uploaded through Xcode with automatic signing, symbols
  enabled and automatic build-number management disabled. Upload packaging is
  separate from the inspected local IPA; its hash is not asserted as the upload hash.
- Frozen-source validation: 58 Swift package tests and 7 catalog tests passed.
  Existing feature UI evidence: `.build/Stats-Verified-Retry-UI.xcresult` (2 passing
  tests), `.build/Stats-Axes-UI.xcresult` (final large-text check),
  `.build/Idioms-200-UI.xcresult`, and `.build/DailyLearning-Verified-attachments`.
  The UI suite was not rerun just for the build-number bump.
- Secret scan: no credential findings. Two manifest findings were verified as
  SHA-256 hashes of the corresponding source files.
- Logs: `.build/testflight-build5-{archive,export,tests,catalog,upload}.log`.
- Validation: archive `vow-validation.json` and
  `.build/TestFlightBuild5Export/inspection.json`.

The browser App Store Connect session is expired. Processing completion,
assignment to the existing Internal group, and physical-device installation are
**not verified**. No groups or testers were added. The [Japanese What to Test
notes](TESTFLIGHT-BUILD5-NOTES.txt) are prepared locally and have **not** been
saved to App Store Connect. Physical-device notifications and TestFlight
purchase/restore remain unverified; no public App Store submission was made.

## Historical build 4 — vow 1.0.0 (4)

**Uploaded successfully at 09:21:46 JST on 13 September 2026. Apple reports the uploaded package is processing.**

[TestFlight](https://appstoreconnect.apple.com/apps/6811353745/testflight/ios)

The existing Xcode account uploaded the validated archive successfully. The browser
App Store Connect session has expired, so processing completion, assignment to the
existing Internal group, and device installation have not been verified. No groups
or testers were added. [Japanese What to Test notes](TESTFLIGHT-BUILD4-NOTES.txt)
are prepared locally and have **not** been saved to App Store Connect.

- Version: `1.0.0 (4)`; app `6811353745`; bundle `me.unvalley.verve`; team `2X266ZCRLV`.
- Source: immutable **uncommitted native-app snapshot** at `.build/Release/build4-source`,
  based on `5d90258`. This is not a clean Git revision. The original working tree,
  landing page, and brand work remain intact and uncommitted.
- The snapshot contains 57 source/configuration files and a verified SHA-256 manifest.
- Signed archive: `.build/Release/Vow-1.0.0-4.xcarchive`.
- Archive executable SHA-256: `6f89dd2d111f4765b20105c5b3011332810e85f4af7ce0b2e734dee8e82ad659`.
- Local distribution IPA: `.build/TestFlightBuild4Export/Vow.ipa`.
- Local IPA SHA-256: `dfcb42ffe810118fd0d5acda7e2daef6b05f1b6eea2d831f7602926516606195`.
- Archive and IPA checks passed: correct bundle/version/team, 700 catalog entries
  identical to the frozen source, strict code signature, App Store provisioning,
  no device UDIDs or debugger entitlement, reminder code present, no Debug launch
  overrides or test purchase configuration.
- The same archive was uploaded using Xcode automatic signing with symbols enabled
  and automatic build-number management disabled. Upload packaging is separate
  from the inspected local IPA; its hash is not claimed as the uploaded package hash.
- 53 unit tests passed from the frozen source (`.build/TestFlightBuild4Tests.xcresult`).
  The reminder feature also has 11 passing focused/unit/UI checks recorded in
  `.build/ReviewReminderFinal.xcresult` before the version bump.
- Secret scan: no app-source findings. Two generated source-manifest SHA-256 matches
  were verified as file hashes rather than credentials.
- Logs: `.build/testflight-build4-{archive,export,tests,upload}.log`.
- Artifact validation and release record: `.build/TestFlightBuild4Export/`.

Includes Today landscape backgrounds, meaning/example visibility preferences,
example highlights, a 700-phrase catalog with difficulty references, 50 fixed free
phrases and Vow Pro unlock, free Speaking, simplified Stats, SM-2-derived reviews,
and optional review notifications with a configurable time and cancellation on OFF.
Physical-device notification delivery and TestFlight purchase/restore remain unverified.

## Historical build 3 — vow 1.0.0 (3)

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
