# Izzy

A native SwiftUI app for the gap between knowing a phrasal verb or idiom and being able to use it in conversation.

Previously named Verve, then vow. The Bundle ID, purchase product ID, App Store
SKU and learning-data location moved to `izzy` with the name, so this build is a
separate application from anything distributed earlier; see
[the rename record](docs/RENAME.md) for what that breaks. Version 1.0.0 (13) has
been uploaded to TestFlight. See [distribution status](AppStore/TESTFLIGHT.md)
for processing and installation verification boundaries.

Historical verification documents record the original checkout and local
artifacts. Those build products and private signing material are not in this repository.

**iOS 17 or later · Swift 6 · no server or API key**

## Open and run

Open `Izzy.xcodeproj`, select the **Izzy** scheme and an iPhone simulator, then Run. The generated project is included; XcodeGen is only needed if you change `project.yml`.

For your iPhone, choose your own development team in Signing & Capabilities, select your device, and Run. Device installation requires your signing identity; no distribution certificate is included. The **IzzyWidget** extension needs the `group.me.unvalley.izzy` App Group on both targets; with automatic signing Xcode registers it for your team the first time you build. Without it the app still runs and the widget shows its empty state.

```sh
# Regenerate the project after changing its manifest.
xcodegen generate

# Fast core tests on macOS, without booting a simulator.
swift test --scratch-path .build/SwiftPackage --jobs 2

# Full application and UI tests. Replace the ID with your available simulator.
xcodebuild -project Izzy.xcodeproj -scheme Izzy \
  -destination 'platform=iOS Simulator,id=YOUR-SIMULATOR-ID' \
  -derivedDataPath .build -parallel-testing-enabled NO -jobs 2 \
  CODE_SIGNING_ALLOWED=NO test
```

## Try it

The two tabs are **Today** and **Phrases**. Phrases offers **Scenes**, **Core images** and **Listen continuously** as three chips above the searchable phrase collection. **Stats** opens as a sheet from the flame at the top left of Today.

1. Switch between **Today’s learning** and **Explore** on **Today**. The small filter under the switch narrows both modes to phrasal verbs or idioms (the daily goal still counts every expression). Each mode keeps its own browsing position. Today’s learning contains due reviews and the remaining daily new-expression allowance; Explore shows all accessible expressions. Swipe horizontally or use the previous/next buttons; listen, save, or tap the info button to open the meaning and examples in a sheet from the bottom. Tap the phrase to open its details. The verb and particle chips in the detail screen link to related phrases and core images. In both modes the Again / Hard / Good / Easy ratings under the card can be tapped at any time. The settings button sets **Appearance → Accent color**, conversation focus, and **Learning → Explain phrases in → 日本語 / Easy English**. A fresh install starts from the device language (Japanese devices get 日本語, all others Easy English), and the first-launch introduction uses the same choice. The language choice is saved and shared by browsing, phrase notes, and practice hints/comparisons.
2. On first launch, a three-page introduction covers phrases, spaced reviews and Izzy Pro (**Explore Pro** is optional; **Get started** never buys anything). Then choose **5, 10, 20 or any number from 1 to 50 new expressions per day** in **Daily learning**. Home shows your new-expression progress beside compact page controls. Recall the meaning, open the meaning and examples from the info button in **Today's learning**, then choose Again / Hard / Good / Easy under the card. On the first-run goal sheet, **Decide later** keeps the default of five until you choose. Due cards come first; the chosen new-expression allowance persists across sessions and restarts. Change it anytime by tapping the progress count on Home. Each answer shows its next interval. Meaning recall uses a separate SM-2-derived schedule from speaking practice. See [daily learning](docs/daily-learning.md).

   Tap the waveform button at the top right for **Practice**: a list of questions, each with the phrase to use and an answer example that stays blurred until you tap it. Say your answer first, then tap to compare.
3. Compare the model, word order, and tone. Try the same meaning in a new situation.
4. Rate your initial recall. A phrase previewed on Today cannot be rated as unprompted recall in a practice session started from that screen. Reviews return after a gap; difficult phrases also get one immediate retry.
5. **Phrases** has four collections: **All**, **Phrasal verbs**, **Idioms** and **Saved**. Scenes and story practice are not linked from the current build.
6. In **Phrases**, open the filter next to the count and choose **Group by verb** to browse the available verb families (399 with Pro); the same menu narrows the list by level. With Pro, open **look** to compare 16 expressions, including **look for**, **look into**, and **look ahead**, with their meanings. Search works in the grouped view too, including alternative forms such as **drop in** for **drop by**.
7. Use the sort control beside the filter in **Phrases**, or the sort button in a verb family: **A–Z**, **Z–A**, **Unpracticed first**, or **Review date**. The shared choice persists across launches and applies to saved results too. Review date puts scheduled items first, earliest date first, followed by unpracticed items. Learning-sort ties use A–Z; groups use their first ordered member.
8. Save phrases and write personal examples in **Phrases**. **Stats** (the flame on Today) shows your current and best streak, a month calendar whose fill shows how much you practiced each day (tap a day to see what you practiced) and the next scheduled review. **Phrase notes** also offers the same rating row. Settings is the third tab. See [Stats](docs/stats.md) for counting rules and sources.

Settings and its daily-goal, background, difficulty, notification, privacy, and learning-approach screens support Japanese and English, following the iOS app language. This is independent of **Meaning language**, which controls lesson explanations. Translations live in `Izzy/Resources/Localizable.xcstrings`; learning content retains its existing language behavior.

**Settings → Contact support** includes the public help page, email/copy-email actions, offline purchase and microphone guidance, and app version. Privacy links to the public policy, and Terms of use is also available in Settings. Microphone permission has a Japanese purpose string; declining it leaves typed and unrecorded speaking available. See [App Review coverage](AppStore/APP-REVIEW-CHECKLIST.md) for the current implementation and submission boundaries.

The **Today** flame opens **Stats** as a sheet. For streaks, one completed phrase review or one completed three-take story qualifies; repeated practice on the same day counts once. Yesterday’s streak remains current until today ends. Missed days reset the current streak, while the best remains. Counts use the device’s current calendar/time zone, so travel can change day grouping. Historical phrase-review timestamps contribute; older story totals have no timestamps and are not backfilled.

The home screen offers two widgets. **Streak**, in the small and medium sizes, is a bold lowercase `i` that reports where today stands by how it stands: leaning in while you practise, thrown into a bounce when today's deck is empty, leaning off balance once the evening comes with the day still untouched, and toppled in grey once the streak has ended. It also shows the current streak and one line of text, and opens Home when tapped. It changes at 18:00 and at midnight without the app running. There is also an **Expression** widget (small, medium, and a Lock Screen size) that shows one expression to review with its meaning, and the example sentence where there is room. It follows your explanation language and phrase font, draws from what is closest to its next review, and changes every three hours for three days without the app being opened. See [the widgets](docs/widget.md).

The collection contains **3021 expressions**: 80 original meaning-specific lessons, 534 additions from the supplied 601-row CSV, 861 additional phrasal-verb lessons, and 1546 idiom lessons with two authored contexts each. The original lessons retain their 160 situations, IDs, explanations, and learning history. The 67 overlapping CSV rows appear under **More usage** in their existing phrase details. All CSV Japanese meanings, English meanings, and examples are retained; combined labels are normalized with searchable aliases. The 861 additional lessons cover everyday life, travel, digital tasks and work, with bilingual meanings, usage notes, editorial difficulty and dictionary references. See [the latest expansion record](docs/CATALOG-3021.md).

**Phrases → Idioms** shows 450 everyday idioms, including **break the ice**, **read between the lines** and **play it by ear**. Each includes two original conversation examples, bilingual meanings, a usage pattern, a note and a dictionary reference. Fifty fixed idioms are free. All 450 appear in Home, search, saved phrases, scenes, meaning reviews, continuous listening and speaking practice with Pro. They are learned as whole expressions, without verb-family or particle-image links. See [the idiom collection](docs/IDIOMS.md).

Every phrase has an editorial **A1–C1 difficulty estimate**. Today, details and rows display CEFR by default; **Settings → Difficulty display** can add IELTS, TOEFL iBT (1–6), or EIKEN CSE references independently of the meaning language. **Phrases → All levels** filters by difficulty, including saved results and verb families. Tap a phrase's difficulty label for the reference guide. These are learning estimates, not official exam ratings or score predictions; see [the rubric and sources](docs/phrase-difficulty.md).

CSV entries use **example recall**: complete a sentence with the phrase hidden, compare the supplied example, then make your own sentence and assess your first attempt. Inflected verbs and separated particles are hidden while objects remain visible. There is no invented second model answer or automatic correctness score. **Phrases → Scenes → Everyday English** opens this collection; scene sessions select up to six due/new entries. Meaning language, saving, sorting, spaced reviews, and streaks work for these entries too. Starting practice from a phrase detail counts as a preview, so unprompted-recall ratings are disabled for that session.

The lesson catalog is bundled for offline use. Every displayed example has its own meaning, listen/stop and slower controls. Every example ships with an authored Japanese meaning, shown under the sentence with 日本語 explanations; nothing is translated on the device. Settings → Reading voice selects and previews installed English voices, preferring Premium, then Enhanced, then Standard in automatic mode. See [example meanings and speech](docs/EXAMPLE-AUDIO.md) for OS support and verification boundaries. The CSV was supplied by the user, not independently dictionary-verified; dictionary links continue to support the original lesson senses. See [the import record](docs/COLLECTION-IMPORT.md) for the exact merge rules.

## Design and learning

**Meanings in Easy English** lead with a one-to-three-word gloss (look into → investigate, break the ice → ease the tension) before the plain-English explanation; Japanese explanations are short enough to stand alone. Glosses are authored in `scripts/data/glosses.json`, applied by `scripts/create_catalog.py`, and validated to exist for every lesson.

**Phrases → Core images** opens 36 consistent diagrams for prepositions and particles. Phrase details link directly to their component words, including both parts of combinations such as `put up with`. Compare pairs such as **in / into** or **out / off**, and scrub the movement slider to inspect a path. Image explanations follow the existing Japanese / Easy English setting. These are memory cues; the full phrase and example still determine the intended sense. See [Core images](docs/CORE-IMAGES.md).

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

- `Izzy/Core`: curriculum models, scheduler, queue, and local persistence; shared by the app and package tests.
- `Izzy/Views`: native Today, Scenes, Phrases, Practice, guided replies, and story rehearsal.
- `Izzy/Services`: temporary recording, playback, and system speech synthesis.
- `Izzy/Resources/phrases.json`: the editable curriculum.
- `scripts/create_catalog.py`: regenerates original lessons and merges the supplied CSV.
- `scripts/data/phrasal_verbs_complete_550.csv`: preserved source file; regeneration never depends on Downloads.
- `scripts/import_collection.py`: normalization, stable IDs, cloze generation, and import manifest.
- `scripts/test_collection.py`: checks all source rows, aliases, separated particles, inflections, and ID rules.
- `scripts/build_brand.mjs`: icon and web identity exports from the approved vector; `scripts/make_icon.swift` is a compatibility entry point.
- `IzzyTests`, `IzzyUITests`: core invariants and user flows.

## Data

Review history, settings, saved phrases, and notes live in `Application Support/Izzy/learning.json` in the app sandbox. Writes are atomic. Unreadable or unknown-schema files are preserved. Temporary takes are removed on exercise exit and abandoned takes are reclaimed on the next launch. No audio enters the progress file. There is no account, analytics SDK, cloud backend, or background recording.

This repository contains the standalone iOS app.

## App Store and one-time purchase

See [App Store preparation](AppStore/README.md) for the listing, review notes, support/privacy drafts, signing commands, and external submission requirements. Support: studio@unvalley.me.

Izzy is prepared as a free download with one non-consumable Izzy Pro purchase (intended Japan price ¥900). Speaking and all five story scenes are free. Free catalog access includes 50 fixed phrasal verbs and 50 fixed idioms for browsing, spaced reviews and speaking practice, plus all core images. Pro unlocks the full 3021-expression catalog for browsing and meaning reviews. StoreKit provides the displayed price, verified entitlements, restoration and transaction updates.

Use scheme IzzyStore for local StoreKit integration tests and Izzy for the production app. Local StoreKit success, signed export and App Store acceptance are separate validation boundaries; see AppStore/READINESS.md for current evidence.
