# Example meanings and reading voices

Implemented in the working tree after the App Review preflight on 13 September
2026. These changes are not in build 11 or in the earlier unsigned review
archive; they are included in TestFlight build 12 (commit `85bfcc6`, uploaded
14 September 2026, see [TESTFLIGHT.md](../AppStore/TESTFLIGHT.md)).

Each example in Today, Phrase notes (including More usage), meaning reviews and
speaking comparisons has its own Listen/Stop and Slower/Stop controls. Since
2026-09-14 there is no Meaning button: with Japanese explanations the sentence's
Japanese meaning sits directly under it, and Easy English shows the sentence alone.
The first and transfer examples use the same component, so playback always uses
the text beside the pressed button. The owning screen shares one VoicePractice
instance; starting another example replaces speech rather than layering it.
Screen exit, card changes and background behavior retain the existing cleanup.

Authored meanings appear inline under the sentence.
There are 1,933 distinct catalog example strings. All 140 examples in the fixed
original 50-phrasal-verb free collection (including supplemental usage) have authored Japanese
meanings bundled from `scripts/data/example-translations.json`. The catalog
builder binds them to exact English text and rejects stale sources. Changing a
source sentence cannot silently reuse its old translation. These meanings work
on every supported iOS version without a model download.

For examples without an authored meaning (everything outside the free
collection), a small Show Japanese translation link under the sentence runs Apple
Translate in place on iOS 18+; older systems show the sentence alone. These
machine translations have not been reviewed for semantic accuracy.

| OS | Translation for an example without a bundled meaning |
| --- | --- |
| iOS 18+ | Show Japanese translation uses `TranslationSession` with explicit English → Japanese languages. iOS 26.4+ requests highFidelity (Apple Intelligence where enabled, traditional-model fallback otherwise). Download consent, loading, failure/retry and dismissal are handled. |
| iOS 17.4–17.x | Translate sentence opens Apple's translation overlay; the user selects Japanese. |
| iOS 17.0–17.3 | Select the English sentence and choose Translate from the system text-selection menu. |

The deployment target remains iOS 17. Translation is optional and needs a system
language download when its models are missing. Expression meanings and the
catalog remain available without translation. Downloaded TranslationSession
models run on-device; recordings, typed replies, notes and progress are never
passed to translation. Results are currently kept only while the sheet is open.
[Apple Translation API](https://developer.apple.com/videos/play/wwdc2024/10117/)

Settings → Reading voice lists installed English voices, supports preview and
persists a chosen identifier in the existing local learning JSON. Automatic
selection orders Premium → Enhanced → Standard, preferring en-US only when
quality is equal, then keeping the system-recommended voice ahead of legacy voice names. An explicit available voice always wins. A removed voice
falls back to automatic without deleting the preference, so reinstalling it
restores the choice. Novelty and Personal Voice are excluded. The list refreshes
when returning from iOS Settings, and playback resolves installed voices again.

Normal playback uses Apple's default speech rate; slower playback uses 0.40,
leaving pitch unchanged. Premium and Enhanced voices must be installed through
iOS Accessibility settings. An app cannot assume they exist on every device;
automatic selection alone does not upgrade a device with only Standard voices.
The settings screen explains this and links Apple's download instructions.
[Apple voice quality levels](https://developer.apple.com/documentation/avfaudio/avspeechsynthesisvoicequality)

Verification records are under `.build/example-audio/`. Voice selection and
persistence are unit-tested; UI coverage targets example identity, audio
controls, settings persistence and maximum Dynamic Type. Real iOS translation-model
downloads, translation correctness outside the authored set, audible Premium/Enhanced quality, Bluetooth
routes and background interruption need verification on a physical device.
No simulator button-state assertion is evidence that the audio sounds natural.

Before submission, rebuild and validate the final signed package and refresh
affected screenshots. The earlier App Review checklist's transaction/contact/
rights gates still apply.

A read-only Mac probe exercised actual installed English/Japanese translation
models, without requesting downloads. Both default and highFidelity requests
returned awkward and partly inaccurate translations for the initial bring-up
examples on this Mac; those outputs were not copied into the authored catalog.
`translation-probe.log` and `translation-high-fidelity-probe.log` retain this
quality evidence. This does not establish whether Apple Intelligence was enabled
or which model a different device will use. The resulting free-collection
translations were written separately and checked against their English sources.
Apple explicitly says the Translation APIs do not function in Simulator;
simulator UI checks therefore verify sentence identity and authored meanings,
not machine translation correctness.

The nine Python catalog tests include preservation of all original fields and
IDs using the original frozen digest, while checking additive translation
metadata separately. No existing lesson copy or order was changed.

Final focused checks: **72 iOS unit tests and 3 example/audio UI tests pass** in
`AuthoredMeanings.xcresult`. The Today reveal/layout regression also passed in
`ExampleAudio.xcresult` (4 UI scenarios total across those runs). The final UI
run verifies the authored Japanese text, distinct first/second sentence targets,
normal/slow playback controls, maximum Dynamic Type, and voice selection across
relaunch. Screenshots are exported in `authored-screenshots/`. Earlier screenshots
in `screenshots/` precede the authored meanings and system-voice tie-break fix.
The physical iPhone is currently unavailable, so audible Premium/Enhanced
quality, iOS model download/translation and device interruption tests are not
claimed as passed. No upload or App Store submission was performed.

The final unsigned arm64 Release build passes (`release-verified.log`).
`release-verification.json` records the executable hash, exact source/catalog
match, 140 packaged authored meanings, Japanese interface resources, absence of
test overrides/resources and weak links to both Translation frameworks for the
iOS 17 deployment target. This is a local build check, not Distribution signing
or a TestFlight upload. Final meaning and voice-settings screenshots were
visually inspected; automatic selection on this simulator resolves to the
system-recommended Samantha Standard voice, not an alphabetically earlier
legacy voice. No Premium/Enhanced voice was installed in this simulator.
