# vow

A native SwiftUI app for the gap between knowing a phrasal verb and being able to use it in conversation.

Previously named Verve. This is the standalone repository for vow. The Bundle
ID, purchase product ID, and existing learning-data location are retained to
preserve updates, purchases, and history. The next build is 1.0.0 (2); the
existing TestFlight build 1 still displays the previous name.

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

The three tabs are **Today**, **Phrases**, and **Practice**. Phrases includes **Scenes** and **Core images**, alongside the searchable phrase collection.

1. Explore one phrase at a time on **Today**. Swipe horizontally or use the previous/next buttons; listen, save, open details, or reveal an example. Tap the phrase to open its details. The verb and particle chips link to related phrases and core images. Examples reveal in a reserved area, keeping the controls in place. The settings button sets **Appearance → Accent color**, conversation focus, and **Meaning language → 日本語 / Easy English**. The language choice is saved and shared by browsing, phrase notes, and practice hints/comparisons.
2. Tap **Practice speaking** at the bottom. Produce a reply before revealing the example. You can record, speak without recording, or type.
3. Compare the model, word order, and tone. Try the same meaning in a new situation.
4. Rate your initial recall. A phrase previewed on Today cannot be rated as unprompted recall in a practice session started from that screen. Reviews return after a gap; difficult phrases also get one immediate retry.
5. Browse **Phrases → Scenes** for a specific conversation, or try **Story practice** to retell the same message.
6. Choose **Phrases → By verb** to browse 310 verb families. Open **look** to compare 16 expressions, including **look for**, **look into**, and **look ahead**, with their meanings. Search works in the grouped view too, including alternative forms such as **drop in** for **drop by**.
7. Use the sort button in **Phrases** or a verb family: **A–Z**, **Z–A**, **Unpracticed first**, or **Review date**. The shared choice persists across launches and applies to saved results too. Review date puts scheduled items first, earliest date first, followed by unpracticed items. Learning-sort ties use A–Z; groups use their first ordered member.
8. Save phrases and write personal examples in **Phrases**. **Practice** shows your actual history and next review dates.

The **Today** flame links to **Practice**, which shows the current streak, best streak, and the last seven calendar days. One completed phrase review or one completed three-take story qualifies; repeated practice on the same day counts once. Yesterday’s streak remains current until today ends. Missed days reset the current streak, while the best remains. Counts use the device’s current calendar/time zone, so travel can change day grouping. Historical phrase-review timestamps contribute; older story totals have no timestamps and are not backfilled.

The collection contains **614 expressions**: 80 original meaning-specific lessons and 534 additions from the supplied 601-row CSV. The original lessons retain their 160 situations, IDs, explanations, and learning history. The 67 overlapping CSV rows appear under **More usage** in their existing phrase details. All CSV Japanese meanings, English meanings, and examples are retained; combined labels are normalized with searchable aliases.

New entries use **example recall**: complete a sentence with the phrase hidden, compare the supplied example, then make your own sentence and assess your first attempt. Inflected verbs and separated particles are hidden while objects remain visible. There is no invented second model answer or automatic correctness score. **Phrases → Scenes → Everyday English** opens this collection; scene sessions select up to six due/new entries. Meaning language, saving, sorting, spaced reviews, and streaks work for these entries too. Starting practice from a phrase detail counts as a preview, so unprompted-recall ratings are disabled for that session.

All teaching copy is bundled for offline use. System speech voices provide model audio. The CSV was supplied by the user, not independently dictionary-verified; dictionary links continue to support the original lesson senses. See [the import record](docs/COLLECTION-IMPORT.md) for the exact merge rules.

## Design and learning

**Phrases → Core images** opens 35 consistent diagrams for prepositions and particles. Phrase details link directly to their component words, including both parts of combinations such as `put up with`. Compare pairs such as **in / into** or **out / off**, and scrub the movement slider to inspect a path. Image explanations follow the existing Japanese / Easy English setting. These are memory cues; the full phrase and example still determine the intended sense. See [Core images](docs/CORE-IMAGES.md).

The interface uses near-white centers, static ice-blue edge gradients, black text, and blue actions. The color direction follows the user’s reference and subsequent ice-blue choice; Apple and Distinction informed the earlier palette. The current one-phrase reading surface takes cues from Vocabulary by Monkey Taps. Collections and microphone interaction retain elements of the earlier references. The app icon is original vector artwork. Native navigation, Dynamic Type, adaptive color definitions, and Reduce Motion are implemented. See the verification record for the visual checks completed on the simulator.

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
- `scripts/make_icon.swift`: reproducible original icon drawing.
- `VowTests`, `VowUITests`: core invariants and user flows.

## Data

Review history, settings, saved phrases, and notes live in `Application Support/Verve/learning.json` in the app sandbox. Writes are atomic. Unreadable or unknown-schema files are preserved. Temporary takes are removed on exercise exit and abandoned takes are reclaimed on the next launch. No audio enters the progress file. There is no account, analytics SDK, cloud backend, or background recording.

This repository contains the standalone iOS app.

## App Store and one-time purchase

See [App Store preparation](AppStore/README.md) for the listing, review notes, support/privacy drafts, signing commands, and external submission requirements. Support: studio@unvalley.me.

vow is prepared as a free download with one non-consumable vow Complete purchase (intended Japan price ¥900). All expressions and core images remain browsable; 20 stable expressions and one story scene can be practiced free. The purchase unlocks all speaking and story practice. StoreKit provides the displayed price, verified entitlements, restoration and transaction updates.

Use scheme VowStore for local StoreKit integration tests and Vow for the production app. Local StoreKit success, signed export and App Store acceptance are separate validation boundaries; see AppStore/READINESS.md for current evidence.
