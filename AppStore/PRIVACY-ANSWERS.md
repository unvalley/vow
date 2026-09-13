# Privacy and rating preparation

Inspected app implementation: no URLSession, analytics, ad SDK, account backend, or speech-recognition upload. Apple StoreKit handles purchases; local verified transactions control access. AVAudioRecorder writes short-lived audio in the app's temporary directory. LearningStore writes progress, notes and saved IDs in Application Support. AVSpeechSynthesizer uses the system voice. External source links open third-party sites.

Proposed App Privacy answer: **Data Not Collected** by the developer. Apple distinguishes data processed only on the device from collected data. Revisit this answer before adding analytics, cloud sync, remote speech, or a purchase backend. [Apple privacy definitions](https://developer.apple.com/app-store/app-privacy-details/)

PrivacyInfo.xcprivacy declares no tracking, tracking domains, collected data, or required-reason API categories. The current source does not use UserDefaults, file timestamps, system boot time, disk-capacity APIs, or active-keyboard APIs; ordinary app-container file reading/writing alone is not a reason to add an invented declaration. Re-audit each added SDK and the exported privacy report. [Apple privacy manifests](https://developer.apple.com/documentation/bundleresources/privacy_manifest_files)

Rating questionnaire draft: no advertising, public user-generated content, messaging between users, gambling, medical treatment guidance, contests, or unrestricted embedded web browser. Personal text replies are stored locally and are not published. A targeted scan found non-graphic murder-investigation examples in the supplied supplemental usage for rule out and look into. Inspect these educational references against the current violence questionnaire; this scan is not a complete content-rating audit. Do not claim a final age rating before App Store Connect calculates it.

The user supplied the two imported CSVs. Their availability on disk is not evidence of commercial redistribution rights. Confirm the origin and rights before public distribution. Original diagrams and original app-authored examples are separate from supplied material; row provenance remains in docs/COLLECTION-IMPORT.md.

Apple's system-only encryption / StoreKit HTTPS use is the current basis for `ITSAppUsesNonExemptEncryption = false`. No custom cryptography was added. Reassess if that implementation changes. The account holder must verify any export-compliance and legal declarations during submission.

September 13 re-audit: review reminders use local UserNotifications requests based
on on-device review dates and preferences. No remote notification provider or
learning-data upload was added. Public privacy copy now describes reminders.
The current native-source scan still found no network client, analytics SDK,
UserDefaults or speech-recognition service. Final Apple declarations remain
unsubmitted and require the account holder’s confirmation.

The later review-preparation changes add a user-initiated copy-email button,
public support/privacy links and localized microphone purpose/error strings.
The clipboard is written only when Copy email address is tapped; the app does
not read clipboard contents or send support messages automatically. The native
policy now also describes optional local notifications. No new collection,
tracking, backend or required-reason API category was introduced.

Example/audio additions: the chosen system voice identifier is saved in the
existing local learning file. English example speech uses installed Apple
voices. Explicit sentence-translation actions pass only the bundled example
text to Apple Translate; no recording, typed reply, note or learning history is
sent. TranslationSession uses on-device language models and Apple's own consent
flow for language downloads. Results are held in the sheet's memory, not sent
to the developer or added to analytics. On older iOS, the system translation
overlay or text-selection menu handles translation. [Apple Translation behavior](https://developer.apple.com/videos/play/wwdc2024/10117/)
