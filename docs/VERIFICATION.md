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
- **Final native run:** All 23 core tests and three focused UI flows pass in `.build/CoreImagesFinal.xcresult`, log `/tmp/izzy-core-images-final.log`. The flows cover the gallery, movement slider, comparison, phrase links, Easy English, browsing without streak credit, largest accessibility text, alias search, and existing save/note persistence. Unaffected UI flows were not all rerun.
- **Resolved failure:** The initial `.build/CoreImages.xcresult` passed core tests and the normal image flow, but its large-text flow could not find the automatically placed search field. An explicit always-visible navigation search drawer resolves this; both new flows and the save/note regression pass in the final run.
- **Rendered review:** Inspected the gallery, in/into comparison, static on detail at the largest text size, and vertically stacked on/off comparison. Text wraps, diagrams maintain their proportions, and the gallery search field is visible. Comparison explanations and related expressions remain scrollable. VoiceOver listening and physical-device frame pacing remain unverified. There is no autoplay.
- **Build:** Xcode 26.5 / Swift 6 / iOS 17 target, isolated iPhone 17 Pro simulator on iOS 26.3. No Swift compiler warnings; expected App Intents metadata-skipped warnings remain. Source whitespace and parent `git diff --check` pass.

Screenshot provenance: `core-images.png`, `core-into.png`, `core-comparison.png`, `core-with.png`, `core-large-type.png`, `core-comparison-large-type.png`, and `core-phrase-links.png` are unmodified attachments exported from CoreImagesFinal. The semantic approach and limitations are documented in CORE-IMAGES.md.

## Complete collection — 12 September 2026

- **Source integrity:** Four Python tests pass. All 601 source rows preserve their Japanese meaning, English meaning, and example; aliases normalize combined labels without losing search terms. The earlier 374 rows remain unchanged, and the first 389 browsing positions and IDs are retained. Both supplied CSV files are preserved byte-for-byte. Regeneration produces identical catalog and manifest bytes.
- **Current data:** 614 unique expressions, 310 verb families, 16 look expressions; 80 original two-context lessons, 534 example-recall entries, and 67 supplemental usages. Freshly built app resources were checked for these totals and new expressions.
- **Core:** All 21 XCTest tests pass in the fresh `.build/CompleteValidation.xcresult` run. Coverage includes curriculum structure, source-independent decoding of old lessons, alias/supplement search, original IDs, mixed old/new saved progress, scheduling, sorting, streak calendar boundaries, and persistence. The importer additionally checks separated particles, inflection, reflexive forms, and missing matches.
- **Latest native UI:** Both focused flows pass in the same fresh build: newest-file entries and aliases (`log out` → `log off`, `flesh out`), Japanese/Easy English, grouped navigation, a completed new-entry practice, review/streak persistence, saved entries after relaunch, and sorting across collections with persisted order. Result: `.build/CompleteValidation.xcresult`; log: `/tmp/izzy-complete-validation.log`.
- **Other import UI:** The two import flows pass in `.build/Collection614.xcresult`: earlier alias search, original-lesson More usage, Everyday English's 534 entries and six-entry practice limit, cloze → personal sentence → rating, preview restrictions, and Japanese saved results after relaunch. That run still failed its sorting test. The final fresh run above supersedes that sorting failure.
- **Regression evidence:** The earlier `.build/Collection.xcresult` run passed all 21 core tests and 10 of 13 UI tests with the initial 389-entry import, including daily/streak, browsing, large text, notes, languages, scenes, story, typed practice, and look-family navigation. New imported-row taps failed until the entire row received a content shape. The sort test's setup saved only one phrase because it raced the page transition; it now waits for the second phrase before saving. No claim is made that all UI flows were rerun together on the final 614-entry build.
- **Rendered review:** Inspected the 614-entry Phrases screen, new English phrase detail, Japanese/English imported detail, cloze prompt, and expanded supplemental usage. Latest list and detail screenshots show readable wrapping and retain the ice-blue design. New source content has not been independently dictionary-verified or tested in a learning study.
- **Build and scope:** Xcode 26.5 / Swift 6 / iOS 17 target, isolated iPhone 17 Pro simulator. No Swift compiler warnings; expected App Intents metadata-skipped warnings remain. Changes are confined to `ios/Izzy`, preserving the parent blog/branding work. Source whitespace checks and `git diff --check` pass. No commit, upload, or release was performed.

Current screenshot provenance: `complete-collection.png`, `complete-alias.png`, `complete-phrase.png`, `phrases.png`, and `sort-menu.png` come from CompleteValidation. `imported-phrase.png`, `imported-recall.png`, and `supplemental-usage.png` come from the passing import flows in Collection614. Earlier screenshots retain the historical provenance below. Test progress remains separate from normal app data.

`.build/Collection614Final.xcresult` passed one sorting test but did not execute the newly added complete-collection test; the fresh CompleteValidation build above explicitly ran both requested flows and all 21 core tests.

## Pre-import verification

12 September 2026 — learning streak, following essential interface copy and persistent phrase sorting.

## Passed

- **Core:** 19 XCTest tests, zero failures. Includes all 14 prior scheduling, persistence, curriculum, compatibility, and sorting tests plus five streak tests covering duplicate days, yesterday's continuing streak, gaps, longest runs, leap day, both DST transitions, current-time-zone grouping, future timestamps, mixed practice activity, and relaunch. Legacy data decodes without story timestamps.
- **Native UI:** Four affected XCUITests passed on the isolated **Izzy iOS 26.3 QA** iPhone 17 Pro simulator: daily practice and persistence, browsing without streak credit, largest text size and streak navigation, and story-only completion and persistence. The daily flow passed again after the final calendar alignment adjustment. The preceding full sorting run passed all 11 UI tests; unaffected flows were not rerun for this feature.
- **Streak:** Completing a phrase through self-rating or all three story takes counts once per local calendar day. Today retains yesterday's streak until the day ends; a missed day resets current but preserves best. Existing dated phrase reviews contribute immediately; old undated story totals do not receive invented dates.
- **Sorting:** All, Phrasal verbs, Idioms and Saved support A–Z / Z–A / Unpracticed first / Review date. Sorting also controls verb groups and family members. The UI test switches saved order, relaunches and verifies it, changes group order, and selects Review date within a family. Unit tests exercise real review-state dates, equal-date ties, and no-review entries. Older progress without a sort key defaults to A–Z.
- **Preserved behavior:** Daily queue scheduling does not use the browsing sort. The 80 expressions, 160 situations, 28 verb families, source URLs, saved notes, and language choices remain intact.
- **Rendered review:** Today has a compact flame/count link. Practice shows current/best streaks and a seven-day calendar, with explicit checkmarks in addition to color. Verified phrase-practice and story-only states, date-row alignment, and stacked statistics at the largest text size. The large-text calendar below the initial viewport was not separately captured. Prior copy and sorting screenshots remain available.
- **Build:** Xcode 26.5, Swift 6, iOS 17 deployment target, arm64 simulator. No Swift compiler warnings. Expected App Intents metadata-skipped warnings remain.
- **Scope:** implementation changes are under `ios/Izzy`; existing blog and branding work is preserved. `git diff --check` passes.

## Evidence

Streak core result: `.build/Streak.xcresult`, log `/tmp/izzy-streak-tests.log`. That initial run passed all 19 core tests but exposed UI lookups with empty accessibility values. Explicit combined accessibility labels fixed the issue. All four affected UI tests then passed in `.build/StreakFinal.xcresult`, log `/tmp/izzy-streak-final.log`. The final calendar alignment passed the daily flow in `.build/StreakAligned.xcresult`, log `/tmp/izzy-streak-aligned.log`.

`docs/screenshots/streak.png` comes from StreakAligned. Today, large-type, story-streak, and streak-large-type captures come from StreakFinal. Other screenshots retain the preceding full passing `.build/LeanSort.xcresult` run (14 core and 11 UI tests), log `/tmp/izzy-lean-sort-tests.log`. UI test progress uses `Izzy-UI-tests/learning.json`, separate from normal user data.

The preceding ice-blue and language work is retained in `.build/IceLanguage.xcresult` and `.build/IceLanguageConfirmed.xcresult`. Earlier Vocabulary and verb-family runs are also retained locally. The current full run supersedes the earlier test-only search/modal timing corrections. Dictionary URL evidence remains in `docs/dictionary-links.json`; this revision changes no curriculum text or source URLs.

Run the Xcode command in `README.md` with an available simulator ID. `python3 scripts/create_catalog.py` regenerates the collection, and `python3 scripts/check_dictionary_links.py` refreshes source URLs. Raw dictionary text remains in the ignored `.build` audit cache.

## Remaining boundaries

Physical microphone quality, Bluetooth routes, actual-device interruptions, VoiceOver listening, and measured rendering frame rate have not been verified on an iPhone. Adaptive dark tokens are implemented; dark rendering remains unverified. Easy English is editorially simplified, not certified to a CEFR level. Learning effectiveness has not been tested in a user study.

Calendar boundary calculations are unit-tested. Appearance, foreground, calendar-day, and time-zone notifications refresh streak displays; a live midnight or time-zone transition was not manually observed.

No physical-device installation, TestFlight upload, or App Store upload was performed. A device run requires the user's Development Team.


## Meaning reviews, Stats and free 50 — 13 September 2026

Implemented the centered Show Examples control, tap-to-reveal Today meaning, minimal Stats, fifty fixed free phrases and Izzy Pro locks, and an SM-2-derived meaning-review flow. See [contracts and scheduling](spaced-reviews.md).

- **Core:** 33 unit tests pass both in `swift test` (`.build/memory-unit.log`) and the native `.build/StatsMemory.xcresult` run. Meaning scheduling, difficulty, relearning, bounds, early reviews, midnight new-card replenishment, free filtering, legacy decoding and independent speaking/meaning persistence are covered.
- **Native UI:** Nine distinct flows have passing evidence across `.build/StatsMemory.xcresult`, `.build/StatsMemoryFinal.xcresult` and `.build/StatsMemoryAccessibility.xcresult`: meaning toggle/reset and two-stat screen; free vs Debug Pro catalog/search; the 50th Today page and lock; meaning reveal/rating/daily limit/relaunch; largest text; stable examples; language changes/relaunch; completed speaking practice/streak; unavailable-store free practice and lock. The final accessibility run passed all four selected tests. Earlier failures for duplicate offscreen controls and stale text-element queries were corrected; dismissal tests now wait for the tab to become hittable.
- **Visual:** Inspected native iPhone screenshots of Today, the Today/Phrases Pro locks, Stats, the review answer with four interval buttons, and the largest-text review layout. Attachments are in the corresponding `.build/*-attachments` directories. No physical-device or new iPad-layout validation is claimed.
- **Purchases remain unverified:** The two StoreKit integration tests and the new purchase/refund UI flow could not obtain a Product, reproducing the pre-existing local StoreKit service failure. Debug Pro catalog checks only validate rendering and must not be treated as purchase, restore or refund evidence. Existing product ID, verification and transaction handling remain in place. App Store Connect metadata was not updated.


### Today visibility defaults

Settings → Today now persists independent defaults for meaning and examples. Missing keys retain the previous hidden defaults. Page changes restore the saved defaults; per-phrase taps do not overwrite settings, and changing one default preserves the other control's override. The separate Review flow continues to hide answers.

Two persistence/legacy unit tests and the existing reveal/reset UI test pass in `.build/TodayVisibilityDefaults.xcresult`. The all-four-combinations, manual overrides, page reset and relaunch UI flow passes in `.build/TodayVisibilityDefaultsFinal.xcresult`. Its first attempt tapped the SwiftUI switch's label area without changing its value; the test now taps the switch control and asserts its value changes.


### Speaking is free

Removed the Speaking feature paywall and purchase-check wait; speaking sessions use the accessible phrase catalog and keep the free fifty-phrase boundary. Removed story entitlements and story paywalls: all five scenes now open rehearsal directly. Pro purchase copy and local listing drafts describe full-catalog browsing and meaning reviews, while Speaking and all story scenes are described as free. The StoreKit product ID and price are unchanged; no App Store Connect update was made.

`.build/FreeSpeaking.xcresult` passes all three selected tests: the stable free catalog policy, a previously paid Friends & connection story completed and persisted on the free plan, and unavailable-store free Speaking plus the revised Pro copy and paid phrase lock.


### Example highlights

`.build/PhraseHighlight.xcresult` passes five matcher tests and the native Today examples/layout test. All 761 bundled lesson/supplemental examples have matches. Focused cases cover inflection, separated objects, aliases, reflexives, Unicode ranges, repeated occurrences, clause boundaries and masked answers. The same five tests also pass through `swift test --filter PhraseHighlightTests`. The native screenshot was visually checked for accent text, soft background and preserved layout; original example text and its accessibility identifier remain intact.


### Phrase difficulty

All 614 entries have explicit A1–C1 editorial estimates; original fields are unchanged. Five Python collection checks pass, including exact coverage of the generator's ID mapping. `.build/PhraseDifficultyCore.xcresult` passes four difficulty tests and three existing library projection tests. `.build/PhraseDifficultyFinal.xcresult` passes the final four difficulty tests plus the native UI flow covering the reference guide, IELTS selection, relaunch persistence, free A2 filtering, filtered verb-family navigation and phrase details.

The largest Dynamic Type difficulty/guide test and existing Today examples/layout test pass in `.build/PhraseDifficultyUI.xcresult`; its initial settings flow expected Done on a pushed page and was corrected to navigate back to Settings before dismissing. Screenshots of Today in CEFR/IELTS, settings, the A2 collection and largest-type label were inspected. No physical-device or VoiceOver session was performed. Difficulty assignments remain editorial judgments, not independently calibrated exam ratings; see `phrase-difficulty.md` for the rubric, limitations and official score-reference sources.


### Catalog expansion to 700

September 13, 2026: 86 authored two-context lessons append to the previous 614 unchanged, yielding 700 entries, 335 verb families and 933 model/supplemental examples. Six Python collection checks pass, and catalog/import-report regeneration is byte-identical. The complete first 614 objects were compared with the pre-expansion snapshot and match exactly.

`.build/Catalog700.xcresult` passes all 43 core tests and the new native UI flow: 700-entry list, search for `plug in`, A2 label, Japanese explanation, two examples, save, both Speaking contexts and saved-state restoration after relaunch. All 86 additions pass search, language, difficulty, particle-link, free/Pro and both scheduler checks. All 933 examples pass phrase-highlight matching. The new detail screenshot was inspected for correct separated/inflected highlights and readable notes. The earlier Swift Package run passed 42 tests before the additional per-lesson scheduler test; the final 43-test evidence is the simulator run.

Local App Store copy reflects 700 entries. No App Store Connect changes, archive, upload or device installation were performed. Prior 614-entry archive, performance and screenshot evidence above remains historical. Source/content boundaries are in `CATALOG-EXPANSION.md`.

## Phrases header and filter row (2026-09-15)

- **Layout:** Phrases hides the navigation bar and draws the same header row as Home (title left, plain 44pt icons right), an inline search field, the All / Phrasal verbs / Idioms / Saved switch, then the count with the filter and sort menus side by side.
- **Scroll-offset regression found while building it:** applying `.font(.subheadline)` to the sort menu's label (a `Label` or an `HStack`) made the list open thousands of points down on iOS 26 (measured with a throwaway XCUITest: the header sat at y = −4567 with the full catalog, y = −123 with 100 phrases; a plain `Text` label, or the font applied to the inner `Text` only, kept the header at y = 70). The controls therefore apply the font on the `Text` inside the label; keep it that way.
- **Not rerun:** the UI suite was skipped at the user's request. `LibraryResultsTests`, `PhraseDifficultyTests` and `LearningTests` passed after the collection model change.
- **Second trigger of the same offset (2026-09-15):** giving every Phrases row a combined accessibility element (`accessibilityElement(children: .combine)` plus identifier and label on the meaning view) made the list open part-way down again with the full catalog; removing those modifiers from list rows fixed it (screenshots via `simctl io screenshot`, not XCUITests). The meaning view now combines its accessibility only on screens that name it. Both triggers point at UIKit-backed accessibility/layout work inside a `ScrollView` + `LazyVStack`; treat any new "list opens scrolled" report as that class of issue.
