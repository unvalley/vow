# vow

A native SwiftUI app for the gap between knowing a phrasal verb or idiom and being able to use it in conversation.

Previously named Verve. This is the standalone repository for vow. The Bundle
ID, purchase product ID, and existing learning-data location are retained to
preserve updates, purchases, and history. Version 1.0.0 (11) has been uploaded
to TestFlight. See [distribution status](AppStore/TESTFLIGHT.md) for processing
and installation verification boundaries.

Historical verification documents record the original Verve checkout and local
artifacts. Those build products and private signing material are not in this repository.

**iOS 17 or later · Swift 6 · no server or API key**

## Open and run

Open `Vow.xcodeproj`, select the **Vow** scheme and an iPhone simulator, then Run. The generated project is included; XcodeGen is only needed if you change `project.yml`.

For your iPhone, choose your own development team in Signing & Capabilities, select your device, and Run. Device installation requires your signing identity; no distribution certificate is included.

```sh
# Regenerate the project after changing its manifest.
xcodegen generate

# Fast core tests on macOS, without booting a simulator.
swift test --scratch-path .build/SwiftPackage --jobs 2

# Full application and UI tests. Replace the ID with your available simulator.
xcodebuild -project Vow.xcodeproj -scheme Vow \
  -destination 'platform=iOS Simulator,id=YOUR-SIMULATOR-ID' \
  -derivedDataPath .build -parallel-testing-enabled NO -jobs 2 \
  CODE_SIGNING_ALLOWED=NO test
```

## Try it

The three tabs are **Today**, **Phrases**, and **Stats**. Phrases includes **Scenes** and **Core images**, alongside the searchable phrase collection.

1. Switch between **Today’s learning** and **Explore** on **Today**. Each mode keeps its own browsing position. Today’s learning contains due reviews and the remaining daily new-expression allowance; Explore shows all accessible expressions. Swipe horizontally or use the previous/next buttons; listen, save, open details, or tap **Show meaning & examples**. Tap the phrase to open its details. The verb and particle chips in the detail screen link to related phrases and core images. Meanings and examples reveal together in a reserved area, keeping the controls in place. **Settings → Today** has one default-visibility switch for both; each new phrase uses that saved choice, while taps only override the current phrase. The settings button sets **Appearance → Accent color**, conversation focus, and **Meaning language → 日本語 / Easy English**. The language choice is saved and shared by browsing, phrase notes, and practice hints/comparisons.
2. On first launch, choose **1–50 new expressions per day** in **Daily learning**. Today shows your new-expression progress beside compact page controls. Tap **Start learning** or **Continue learning** to recall the meaning, reveal the meaning and examples together, then choose Again / Hard / Good / Easy. Due cards come first; the chosen new-expression allowance persists across sessions and restarts. Change it anytime by tapping the progress count or through **Settings → Learning plan**. Each answer shows its next interval. Meaning recall uses a separate SM-2-derived schedule from speaking practice. See [daily learning](docs/daily-learning.md).

   Tap the waveform button at the top right for **Practice speaking**. Produce a reply before revealing the example. You can record, speak without recording, or type.
3. Compare the model, word order, and tone. Try the same meaning in a new situation.
4. Rate your initial recall. A phrase previewed on Today cannot be rated as unprompted recall in a practice session started from that screen. Reviews return after a gap; difficult phrases also get one immediate retry.
5. Browse **Phrases → Scenes** for a specific conversation, or try **Story practice** to retell the same message.
6. Choose **Phrases → By verb** to browse the available verb families (335 with Pro). With Pro, open **look** to compare 16 expressions, including **look for**, **look into**, and **look ahead**, with their meanings. Search works in the grouped view too, including alternative forms such as **drop in** for **drop by**.
7. Use the sort button in **Phrases** or a verb family: **A–Z**, **Z–A**, **Unpracticed first**, or **Review date**. The shared choice persists across launches and applies to saved results too. Review date puts scheduled items first, earliest date first, followed by unpracticed items. Learning-sort ties use A–Z; groups use their first ordered member.
8. Save phrases and write personal examples in **Phrases**. **Stats** shows your daily goal, current/best streak, seven days of practice, expressions started and upcoming meaning reviews. Compare spaced reviews with an illustrative forgetting curve. See [Stats](docs/stats.md) for counting rules and sources.

The **Today** flame links to **Stats**. For streaks, one completed phrase review or one completed three-take story qualifies; repeated practice on the same day counts once. Yesterday’s streak remains current until today ends. Missed days reset the current streak, while the best remains. Counts use the device’s current calendar/time zone, so travel can change day grouping. Historical phrase-review timestamps contribute; older story totals have no timestamps and are not backfilled. Activity charts count individual answers and completed stories separately from streak days. The forgetting curve explains the effect of review; it is not a measured or predicted personal recall percentage.

The collection contains **1200 expressions**: 80 original meaning-specific lessons, 534 additions from the supplied 601-row CSV, 136 additional phrasal-verb lessons, and 450 idiom lessons with two authored contexts each. The original lessons retain their 160 situations, IDs, explanations, and learning history. The 67 overlapping CSV rows appear under **More usage** in their existing phrase details. All CSV Japanese meanings, English meanings, and examples are retained; combined labels are normalized with searchable aliases. The 136 additional lessons cover everyday life, travel, digital tasks and work, with bilingual meanings, usage notes, editorial difficulty and dictionary references. See [the latest expansion record](docs/CATALOG-1200.md).

**Phrases → Idioms** shows 450 everyday idioms, including **break the ice**, **read between the lines** and **play it by ear**. Each includes two original conversation examples, bilingual meanings, a usage pattern, a note and a dictionary reference. Idioms appear in Today, search, saved phrases, scenes, meaning reviews and speaking practice with Pro. They are learned as whole expressions, without verb-family or particle-image links. See [the idiom collection](docs/IDIOMS.md).

Every phrase has an editorial **A1–C1 difficulty estimate**. Today, details and rows display CEFR by default; **Settings → Difficulty display** can add IELTS, TOEFL iBT (1–6), or EIKEN CSE references independently of the meaning language. **Phrases → All levels** filters by difficulty, including saved results and verb families. Tap a phrase's difficulty label for the reference guide. These are learning estimates, not official exam ratings or score predictions; see [the rubric and sources](docs/phrase-difficulty.md).

CSV entries use **example recall**: complete a sentence with the phrase hidden, compare the supplied example, then make your own sentence and assess your first attempt. Inflected verbs and separated particles are hidden while objects remain visible. There is no invented second model answer or automatic correctness score. **Phrases → Scenes → Everyday English** opens this collection; scene sessions select up to six due/new entries. Meaning language, saving, sorting, spaced reviews, and streaks work for these entries too. Starting practice from a phrase detail counts as a preview, so unprompted-recall ratings are disabled for that session.

All teaching copy is bundled for offline use. System speech voices provide model audio. The CSV was supplied by the user, not independently dictionary-verified; dictionary links continue to support the original lesson senses. See [the import record](docs/COLLECTION-IMPORT.md) for the exact merge rules.

## Design and learning

**Phrases → Core images** opens 35 consistent diagrams for prepositions and particles. Phrase details link directly to their component words, including both parts of combinations such as `put up with`. Compare pairs such as **in / into** or **out / off**, and scrub the movement slider to inspect a path. Image explanations follow the existing Japanese / Easy English setting. These are memory cues; the full phrase and example still determine the intended sense. See [Core images](docs/CORE-IMAGES.md).

The current brand direction is **Make English your own. / 英語を、自分の言葉に。**
Paper and graphite surfaces, serif phrase typography, the approved Archivo italic
wordmark and quiet landscape backgrounds connect the app, website and store
images. Cosmos informed the restrained composition; Art4 informed the early
product demonstration. Native navigation, Dynamic Type, semantic colours and
Reduce Motion remain part of the interface. See [brand direction](Brand/STRATEGY.md)
and [store readiness](AppStore/READINESS.md) for assets and verification.

The learning loop draws on retrieval practice, spaced practice, speech repetition, and meaning-specific vocabulary instruction. Exact timings are product choices. The app does not claim to measure fluency, diagnose a learning problem, or automatically assess pronunciation. Typed and spoken reviews are labeled separately.

- [Research and design decisions](docs/RESEARCH.md)
- [Verification and remaining boundaries](docs/VERIFICATION.md)
- [Dictionary link checks](docs/dictionary-links.json)

## Project layout

- `Vow/Core`: curriculum models, scheduler, queue, and local persistence; shared by the app and package tests.
- `Vow/Views`: native Today, Scenes, Phrases, Practice, guided replies, and story rehearsal.
- `Vow/Services`: temporary recording, playback, and system speech synthesis.
- `Vow/Resources/phrases.json`: the editable curriculum.
- `scripts/create_catalog.py`: regenerates original lessons and merges the supplied CSV.
- `scripts/data/phrasal_verbs_complete_550.csv`: preserved source file; regeneration never depends on Downloads.
- `scripts/import_collection.py`: normalization, stable IDs, cloze generation, and import manifest.
- `scripts/test_collection.py`: checks all source rows, aliases, separated particles, inflections, and ID rules.
- `scripts/build_brand.mjs`: icon and web identity exports from the approved vector; `scripts/make_icon.swift` is a compatibility entry point.
- `VowTests`, `VowUITests`: core invariants and user flows.

## Data

Review history, settings, saved phrases, and notes live in `Application Support/Verve/learning.json` in the app sandbox. Writes are atomic. Unreadable or unknown-schema files are preserved. Temporary takes are removed on exercise exit and abandoned takes are reclaimed on the next launch. No audio enters the progress file. There is no account, analytics SDK, cloud backend, or background recording.

This repository contains the standalone iOS app.

## App Store and one-time purchase

See [App Store preparation](AppStore/README.md) for the listing, review notes, support/privacy drafts, signing commands, and external submission requirements. Support: studio@unvalley.me.

vow is prepared as a free download with one non-consumable Vow Pro purchase (intended Japan price ¥900). Speaking and all five story scenes are free. Free catalog access includes 50 fixed phrases for browsing, spaced reviews and speaking practice, plus all core images. Pro unlocks the full 1200-expression catalog for browsing and meaning reviews. StoreKit provides the displayed price, verified entitlements, restoration and transaction updates.

Use scheme VowStore for local StoreKit integration tests and Vow for the production app. Local StoreKit success, signed export and App Store acceptance are separate validation boundaries; see AppStore/READINESS.md for current evidence.
