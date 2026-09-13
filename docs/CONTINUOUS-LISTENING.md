# Continuous listening

Phrases → Listen continuously starts a playlist of the available expressions. Choose phrasal verbs, idioms, both, or saved expressions. Each entry plays its English expression, optionally its meaning in the configured meaning language, and optionally its first English example. Installed voices are used, with the same English voice selection as individual example playback.

The player supports pause/resume, previous/next, shuffle, repeat, slower speech and a 15/30/60-minute sleep timer. Closing the sheet leaves a mini-player above the tab bar. Playback is app-scoped and uses the audio background mode, with system play/pause/track commands and Now Playing metadata. Playback starts only through the user's action. The sleep timer counts wall-clock time, including pauses.

Individual speech and recording take ownership of audio and pause the playlist. A disappearing practice view cannot deactivate another player's audio. Disconnecting headphones pauses playback. An audio interruption resumes only if the system permits it and no other Vow audio operation has taken ownership. Media-service resets preserve the playlist for an explicit retry. A stopped/replaced utterance cannot advance the next playlist through a late completion callback.

Listening does not add learning events, mark an expression remembered, or change the daily goal or review schedule. Preferences persist; an active playlist does not automatically restart on app launch. Entitlement loss immediately removes paid expressions from an active queue.

## Free collection and related interface changes

- The original 50 phrasal verbs remain free, plus 50 fixed idioms. Access is based on stable IDs, including saved-expression playlists.
- Phrases places the Pro invitation after ten expression rows, or three verb groups. Smaller result sets show it at the end.
- Stats no longer repeats the “Your rhythm” heading.
- Practice uses a native alert for its exit confirmation. Cancel keeps the current practice; leaving dismisses it. Opening the alert stops active practice audio.

## Validation

`swift test --parallel` passes all 76 package tests, including nine tests for playlist filtering, segment progression, repeat/skip, empty and saved collections, entitlement loss, persisted preferences, unchanged learning history and audio ownership.

`ListeningUITests` covers automatic advancement, background/foreground continuation, audio handoff, the mini-player, free idioms, the scrolled Pro invitation, the native exit alert, Stats and Japanese at the largest accessibility text size. The iOS test targets compile. The September 13 run could not execute any UI test: Xcode failed before app launch with `Failed to prepare device 'iPhone 17 Pro'` / `Timed out trying to boot simulator after waiting 60.00s.` See `.build/listening/ui.log` and `Listening.xcresult`. No runtime playback or rendered-UI success is claimed for this change.

The built app's Info.plist contains `UIBackgroundModes = [audio]`, the expected app identity/version, and the microphone usage description. `scripts/check_submission.py` passes local consistency checks; the existing external review contact and rights fields still need completion before submission.

Before submission, verify audible playback on a physical iPhone while locked, lock-screen controls, Bluetooth/headphone disconnection and phone-call interruption. Simulator logic and screenshots do not establish these hardware behaviors. Voice quality depends on the installed system voices; this feature does not download voices or contact a speech service.

## Apple references

- [AVAudioSession](https://developer.apple.com/documentation/avfaudio/avaudiosession)
- [Speech synthesis and the application audio session](https://developer.apple.com/documentation/avfaudio/avspeechsynthesizer/usesapplicationaudiosession)
- [Handling audio interruptions](https://developer.apple.com/documentation/AVFAudio/handling-audio-interruptions)
