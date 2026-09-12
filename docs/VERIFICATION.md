# Verification

## Today swipe investigation — 12 September 2026

Added a Release-only performance scheme and native left/right gesture measurement.
A lazy horizontal pager showed no meaningful improvement over the current
page-style TabView and was reverted. The restored implementation passes the
ten-pair gesture test in `.build/SwipeRestored.xcresult`. See
[swipe measurements](SWIPE-PERFORMANCE.md) for raw samples, profiling limitations,
and the explicit lack of physical-device frame-rate evidence. This does not
change the previous Phrases search optimization or the TestFlight build.

## Phrases performance — 12 September 2026

The current source shares one search/sort projection per library view update.
Release core tests: 27 passed. Four focused iPhone Simulator UI tests passed in
`.build/PerformanceUI.xcresult`, covering aliases, language settings, saved notes,
relaunch, collection sorting, and complete verb families. The unsigned iOS
Release build also passed. See [performance measurements](PERFORMANCE.md) for
the 100-sample before/after comparison, source hashes, reproducible commands,
and measurement boundaries. These changes are local and are not in the existing
TestFlight build 1.

## App Store and purchase preparation — 12 September 2026

TestFlight build 1 source: 24 core and four focused native UI tests pass in `.build/ReleaseChecks.xcresult`. The local Release archive passes artifact checks. Native StoreKit integration is **not verified**: the local test service rejects configuration operations and provides no product. See [App Store readiness](../AppStore/READINESS.md) for the exact artifact hash, test boundaries, screenshots and external submission requirements. The Japanese/English capture flow also passes on iPhone and iPad, producing twenty native listing screenshots. Update: build 1.0.0 (1) has now been uploaded and is Ready to Test for one invited internal tester; see [TestFlight evidence](../AppStore/TESTFLIGHT.md). Public App Store release and physical-device purchase verification remain outstanding.

The current collection contains 614 expressions from the original 80 lessons and the user-supplied 601-row complete CSV. Import rules and row provenance are in `COLLECTION-IMPORT.md` and `collection-import.json`.

## Core images — 12 September 2026

- **Content and matching:** 35 unique bilingual concepts with valid comparison partners. All 614 expressions have at least one recognized particle. Exact-word matching preserves compound order, ignores object words, and supports upon/on and round/around aliases. Catalog and progress formats are unchanged.
- **Final native run:** All 23 core tests and three focused UI flows pass in `.build/CoreImagesFinal.xcresult`, log `/tmp/verve-core-images-final.log`. The flows cover the gallery, movement slider, comparison, phrase links, Easy English, browsing without streak credit, largest accessibility text, alias search, and existing save/note persistence. Unaffected UI flows were not all rerun.
- **Resolved failure:** The initial `.build/CoreImages.xcresult` passed core tests and the normal image flow, but its large-text flow could not find the automatically placed search field. An explicit always-visible navigation search drawer resolves this; both new flows and the save/note regression pass in the final run.
- **Rendered review:** Inspected the gallery, in/into comparison, static on detail at the largest text size, and vertically stacked on/off comparison. Text wraps, diagrams maintain their proportions, and the gallery search field is visible. Comparison explanations and related expressions remain scrollable. VoiceOver listening and physical-device frame pacing remain unverified. There is no autoplay.
- **Build:** Xcode 26.5 / Swift 6 / iOS 17 target, isolated iPhone 17 Pro simulator on iOS 26.3. No Swift compiler warnings; expected App Intents metadata-skipped warnings remain. Source whitespace and parent `git diff --check` pass.

Screenshot provenance: `core-images.png`, `core-into.png`, `core-comparison.png`, `core-with.png`, `core-large-type.png`, `core-comparison-large-type.png`, and `core-phrase-links.png` are unmodified attachments exported from CoreImagesFinal. The semantic approach and limitations are documented in CORE-IMAGES.md.

## Complete collection — 12 September 2026

- **Source integrity:** Four Python tests pass. All 601 source rows preserve their Japanese meaning, English meaning, and example; aliases normalize combined labels without losing search terms. The earlier 374 rows remain unchanged, and the first 389 browsing positions and IDs are retained. Both supplied CSV files are preserved byte-for-byte. Regeneration produces identical catalog and manifest bytes.
- **Current data:** 614 unique expressions, 310 verb families, 16 look expressions; 80 original two-context lessons, 534 example-recall entries, and 67 supplemental usages. Freshly built app resources were checked for these totals and new expressions.
- **Core:** All 21 XCTest tests pass in the fresh `.build/CompleteValidation.xcresult` run. Coverage includes curriculum structure, source-independent decoding of old lessons, alias/supplement search, original IDs, mixed old/new saved progress, scheduling, sorting, streak calendar boundaries, and persistence. The importer additionally checks separated particles, inflection, reflexive forms, and missing matches.
- **Latest native UI:** Both focused flows pass in the same fresh build: newest-file entries and aliases (`log out` → `log off`, `flesh out`), Japanese/Easy English, grouped navigation, a completed new-entry practice, review/streak persistence, saved entries after relaunch, and sorting across collections with persisted order. Result: `.build/CompleteValidation.xcresult`; log: `/tmp/verve-complete-validation.log`.
- **Other import UI:** The two import flows pass in `.build/Collection614.xcresult`: earlier alias search, original-lesson More usage, Everyday English's 534 entries and six-entry practice limit, cloze → personal sentence → rating, preview restrictions, and Japanese saved results after relaunch. That run still failed its sorting test. The final fresh run above supersedes that sorting failure.
- **Regression evidence:** The earlier `.build/Collection.xcresult` run passed all 21 core tests and 10 of 13 UI tests with the initial 389-entry import, including daily/streak, browsing, large text, notes, languages, scenes, story, typed practice, and look-family navigation. New imported-row taps failed until the entire row received a content shape. The sort test's setup saved only one phrase because it raced the page transition; it now waits for the second phrase before saving. No claim is made that all UI flows were rerun together on the final 614-entry build.
- **Rendered review:** Inspected the 614-entry Phrases screen, new English phrase detail, Japanese/English imported detail, cloze prompt, and expanded supplemental usage. Latest list and detail screenshots show readable wrapping and retain the ice-blue design. New source content has not been independently dictionary-verified or tested in a learning study.
- **Build and scope:** Xcode 26.5 / Swift 6 / iOS 17 target, isolated iPhone 17 Pro simulator. No Swift compiler warnings; expected App Intents metadata-skipped warnings remain. Changes are confined to `ios/Verve`, preserving the parent blog/branding work. Source whitespace checks and `git diff --check` pass. No commit, upload, or release was performed.

Current screenshot provenance: `complete-collection.png`, `complete-alias.png`, `complete-phrase.png`, `phrases.png`, and `sort-menu.png` come from CompleteValidation. `imported-phrase.png`, `imported-recall.png`, and `supplemental-usage.png` come from the passing import flows in Collection614. Earlier screenshots retain the historical provenance below. Test progress remains separate from normal app data.

`.build/Collection614Final.xcresult` passed one sorting test but did not execute the newly added complete-collection test; the fresh CompleteValidation build above explicitly ran both requested flows and all 21 core tests.

## Pre-import verification

12 September 2026 — learning streak, following essential interface copy and persistent phrase sorting.

## Passed

- **Core:** 19 XCTest tests, zero failures. Includes all 14 prior scheduling, persistence, curriculum, compatibility, and sorting tests plus five streak tests covering duplicate days, yesterday's continuing streak, gaps, longest runs, leap day, both DST transitions, current-time-zone grouping, future timestamps, mixed practice activity, and relaunch. Legacy data decodes without story timestamps.
- **Native UI:** Four affected XCUITests passed on the isolated **Verve iOS 26.3 QA** iPhone 17 Pro simulator: daily practice and persistence, browsing without streak credit, largest text size and streak navigation, and story-only completion and persistence. The daily flow passed again after the final calendar alignment adjustment. The preceding full sorting run passed all 11 UI tests; unaffected flows were not rerun for this feature.
- **Streak:** Completing a phrase through self-rating or all three story takes counts once per local calendar day. Today retains yesterday's streak until the day ends; a missed day resets current but preserves best. Existing dated phrase reviews contribute immediately; old undated story totals do not receive invented dates.
- **Sorting:** All phrases and Saved support A–Z / Z–A / Unpracticed first / Review date. Sorting also controls verb groups and family members. The UI test switches saved order, relaunches and verifies it, changes group order, and selects Review date within a family. Unit tests exercise real review-state dates, equal-date ties, and no-review entries. Older progress without a sort key defaults to A–Z.
- **Preserved behavior:** Daily queue scheduling does not use the browsing sort. The 80 expressions, 160 situations, 28 verb families, source URLs, saved notes, and language choices remain intact.
- **Rendered review:** Today has a compact flame/count link. Practice shows current/best streaks and a seven-day calendar, with explicit checkmarks in addition to color. Verified phrase-practice and story-only states, date-row alignment, and stacked statistics at the largest text size. The large-text calendar below the initial viewport was not separately captured. Prior copy and sorting screenshots remain available.
- **Build:** Xcode 26.5, Swift 6, iOS 17 deployment target, arm64 simulator. No Swift compiler warnings. Expected App Intents metadata-skipped warnings remain.
- **Scope:** implementation changes are under `ios/Verve`; existing blog and branding work is preserved. `git diff --check` passes.

## Evidence

Streak core result: `.build/Streak.xcresult`, log `/tmp/verve-streak-tests.log`. That initial run passed all 19 core tests but exposed UI lookups with empty accessibility values. Explicit combined accessibility labels fixed the issue. All four affected UI tests then passed in `.build/StreakFinal.xcresult`, log `/tmp/verve-streak-final.log`. The final calendar alignment passed the daily flow in `.build/StreakAligned.xcresult`, log `/tmp/verve-streak-aligned.log`.

`docs/screenshots/streak.png` comes from StreakAligned. Today, large-type, story-streak, and streak-large-type captures come from StreakFinal. Other screenshots retain the preceding full passing `.build/LeanSort.xcresult` run (14 core and 11 UI tests), log `/tmp/verve-lean-sort-tests.log`. UI test progress uses `Verve-UI-tests/learning.json`, separate from normal user data.

The preceding ice-blue and language work is retained in `.build/IceLanguage.xcresult` and `.build/IceLanguageConfirmed.xcresult`. Earlier Vocabulary and verb-family runs are also retained locally. The current full run supersedes the earlier test-only search/modal timing corrections. Dictionary URL evidence remains in `docs/dictionary-links.json`; this revision changes no curriculum text or source URLs.

Run the Xcode command in `README.md` with an available simulator ID. `python3 scripts/create_catalog.py` regenerates the collection, and `python3 scripts/check_dictionary_links.py` refreshes source URLs. Raw dictionary text remains in the ignored `.build` audit cache.

## Remaining boundaries

Physical microphone quality, Bluetooth routes, actual-device interruptions, VoiceOver listening, and measured rendering frame rate have not been verified on an iPhone. Adaptive dark tokens are implemented; dark rendering remains unverified. Easy English is editorially simplified, not certified to a CEFR level. Learning effectiveness has not been tested in a user study.

Calendar boundary calculations are unit-tested. Appearance, foreground, calendar-day, and time-zone notifications refresh streak displays; a live midnight or time-zone transition was not manually observed.

No physical-device installation, TestFlight upload, or App Store upload was performed. A device run requires the user's Development Team.
