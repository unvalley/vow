import SwiftUI

struct PracticeView: View {
    @Environment(\.appAccent) private var accent
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    let phrases: [Phrase]
    var primedIDs: Set<String> = []
    @State private var index = 0
    @State private var phase = 0 // recall, compare, transfer, reflect
    @State private var reply = ""
    @State private var firstReply = ""
    /// How the first attempt was given; the rating asks about that attempt, not the transfer reply.
    @State private var firstTyped = false
    @State private var typed = false
    @State private var voice = VoicePractice()
    @State private var retry: [Phrase] = []
    @State private var ratings: [RecallRating] = []
    @State private var showExit = false
    /// Nothing to lose yet: first prompt, no reply, no recording, no rating.
    private var hasProgress: Bool {
        index > 0 || phase > 0 || !reply.isEmpty || !ratings.isEmpty || voice.isRecording || voice.hasRecording
    }
    private var queue: [Phrase] { phrases + retry }
    private var complete: Bool { index >= queue.count }
    private var phrase: Phrase? { complete ? nil : queue[index] }

    var body: some View {
        NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if let phrase {
                        stepHeader
                        if phase == 0 || phase == 2 { prompt(phrase) }
                        if phase == 1 { comparison(phrase) }
                        if phase == 3 { reflection(phrase) }
                    } else { completion }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .id("\(index)-\(phase)")
            .navigationTitle("Practice speaking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button { if complete || !hasProgress { voice.stopPlayback(); dismiss() } else { voice.stopRecording(); voice.stopPlayback(); showExit = true } } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }.accessibilityLabel("Close practice") }
            }
            .alert("Leave this practice?", isPresented: $showExit) {
                Button("Leave practice", role: .destructive) { dismiss() }
                Button("Keep practicing", role: .cancel) { }
            } message: { Text("Completed reviews are saved. Your current reply and recording will be discarded.") }
        }.interactiveDismissDisabled(!complete)
            .onDisappear { voice.clear() }
            .onChange(of: scenePhase) { _, value in if value == .background { voice.suspend() } else if value == .inactive { voice.stopRecording(); voice.stopPlayback() } }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { _ in voice.stopRecording(); voice.stopPlayback() }
    }

    /// Every phrase goes through the same four steps. Plain names and one instruction replace the former
    /// "Retrieve / Notice / Transfer / Reflect" eyebrow, which said nothing about what to do.
    private static let steps: [(title: LocalizedStringKey, instruction: LocalizedStringKey)] = [
        ("Say it", "Read the situation and answer out loud using the phrase."),
        ("Check the model", "Compare your answer with the model answer."),
        ("New situation", "Use the same phrase in a different situation."),
        ("Rate", "How easily did the phrase come to you the first time?")
    ]

    private var stepHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Expression \(index + 1) of \(queue.count)")
                .font(Typography.metadata.monospacedDigit()).foregroundStyle(Palette.secondary)
            HStack(alignment: .top, spacing: Spacing.xs) {
                ForEach(Self.steps.indices, id: \.self) { step in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        Capsule().fill(step < phase ? accent.color.opacity(0.4) : step == phase ? accent.color : Palette.secondary.opacity(0.16))
                            .frame(height: 4)
                        Text(Self.steps[step].title).font(.caption2.weight(step == phase ? .semibold : .regular))
                            .foregroundStyle(step == phase ? Palette.ink : Palette.secondary)
                            .lineLimit(1).minimumScaleFactor(0.8)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }.padding(.bottom, Spacing.xs)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Step \(phase + 1) of 4"))
                .accessibilityValue(Text(Self.steps[phase].title))
            Text(Self.steps[phase].instruction).font(.subheadline).foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder private func prompt(_ phrase: Phrase) -> some View {
        if phase == 0 && phrase.usesExampleRecall {
            Text("Complete the sentence.").font(.headline)
            PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .subheadline, color: Palette.secondary)
        }
        Text(phase == 0 ? phrase.cue : phrase.transferCue).font(Typography.meaning).fixedSize(horizontal: false, vertical: true)
            .padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
        if phase == 2 && !phrase.usesExampleRecall { Text("Use the same phrase in this situation.").font(.subheadline).foregroundStyle(Palette.secondary) }
        if phase == 0 {
            // The target phrase always sits under the situation: the exercise is to use it, not to guess it.
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Use this phrase").font(Typography.metadata).foregroundStyle(Palette.secondary)
                Text(phrase.phrase).font(Typography.phraseRow)
                PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .subheadline, color: Palette.secondary)
            }.accessibilityElement(children: .combine).accessibilityIdentifier("practicePhrase")
        }
        // Saying the reply aloud without recording needs no confirmation: comparing is always available.
        VoiceReplyPanel(voice: voice, typed: $typed, reply: $reply)
        let step = phase // the step this page shows, not whatever the state is when a late tap lands
        PrimaryButton(title: String(localized: step == 0 ? "Compare reply" : "Review reply"), symbol: "arrow.right") {
            guard step == phase else { return }
            voice.stopRecording(); voice.stopPlayback()
            if step == 0 { firstReply = reply; firstTyped = typed }
            move(to: step + 1)
        }.disabled(voice.isRecording || voice.isRequesting).accessibilityIdentifier("advanceReply")
    }

    @ViewBuilder private func comparison(_ phrase: Phrase) -> some View {
        Text(phrase.phrase).font(Typography.phrase).accessibilityIdentifier("revealedPhrase")
        PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .title3, detailFont: .body)
        VStack(alignment: .leading, spacing: Spacing.md) {
            ExampleSentenceView(text: phrase.reply, phrase: phrase, voice: voice, identifier: "comparisonExample")
            if voice.hasRecording { Button("My take", systemImage: "play.circle") { voice.play() }.frame(minHeight: 44) }
            if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
        }.padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
        if !firstReply.isEmpty { VStack(alignment: .leading, spacing: Spacing.xs) { Eyebrow(text: "Your reply"); Text(firstReply).font(.body) } }
        if !phrase.frame.isEmpty || !phrase.nuance.isEmpty || !phrase.contrast.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if !phrase.frame.isEmpty { PhraseExampleText(text: phrase.pattern, phrase: phrase, font: .headline) }
                if !phrase.nuance.isEmpty { Text(phrase.nuance(in: store.data.meaningLanguage)).font(.subheadline).foregroundStyle(Palette.secondary) }
                if !phrase.contrast.isEmpty { Text(phrase.contrast(in: store.data.meaningLanguage)).font(.subheadline) }
            }
        }
        PrimaryButton(title: String(localized: phrase.usesExampleRecall ? "Make your own sentence" : "Try a new situation")) {
            guard phase == 1 else { return }
            voice.clear(); reply = ""
            move(to: 2)
        }.accessibilityIdentifier("tryTransfer")
    }

    @ViewBuilder private func reflection(_ phrase: Phrase) -> some View {
        Text(phrase.phrase).font(Typography.phraseRow) // phrases are serif on every screen
        if !phrase.transferReply.isEmpty {
            DisclosureGroup("Compare the new situation") {
                ExampleSentenceView(text: phrase.transferReply, phrase: phrase, voice: voice, identifier: "transferExample").padding(.vertical, Spacing.sm)
            }
        } else {
            PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .subheadline, color: Palette.secondary)
            DisclosureGroup("Check your sentence") {
                Text("Does it keep the intended meaning? Check the verb form and word order against the example.").font(.body).padding(.vertical, Spacing.sm)
                ExampleSentenceView(text: phrase.reply, phrase: phrase, voice: voice, identifier: "reflectionExample")
            }
        }
        if !reply.isEmpty { Text(reply).padding(Spacing.md).frame(maxWidth: .infinity, alignment: .leading).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium)) }
        if voice.hasRecording { Button("Listen to my reply", systemImage: "play.circle") { voice.play() }.frame(minHeight: 44) }
        Text(primedIDs.contains(phrase.id) ? "You previewed this phrase. Try unprompted recall after a gap." : "Rate your first attempt.")
            .font(.subheadline).foregroundStyle(Palette.secondary)
        ForEach(RecallRating.allCases, id: \.self) { rating in
            Button { save(rating, phrase: phrase) } label: {
                HStack(spacing: Spacing.sm) {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(rating.title).font(Typography.control)
                        Text(rating == .again ? "Another try, then revisit in 10 minutes" : (rating == .effort ? "I found it, but had to search" : "I used it right away")).font(.caption).foregroundStyle(Palette.secondary)
                    }
                    Spacer(); Image(systemName: "arrow.right")
                }.padding(Spacing.lg).foregroundStyle(Palette.ink).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            }.buttonStyle(PressStyle()).disabled(primedIDs.contains(phrase.id) && rating == .ready).accessibilityIdentifier("rate-\(rating.rawValue)")
        }
    }

    private var completion: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            CompletionMark()
            Text(phrases.isEmpty ? "No reviews due" : "Practice complete").font(Typography.phraseRow).staggeredEntrance(1)
            Text(phrases.isEmpty ? "You're up to date. Explore a scene, or come back when your next review is ready." : "You practiced \(ratings.count) replies across \(phrases.count) phrases. Your next reviews are scheduled.").font(.body.monospacedDigit()).foregroundStyle(Palette.secondary).staggeredEntrance(2)
            PrimaryButton(title: String(localized: "Done"), symbol: "checkmark") { dismiss() }.accessibilityIdentifier("finishPractice").staggeredEntrance(3)
        }
    }

    private func save(_ rating: RecallRating, phrase: Phrase) {
        // A second tap on the page fading out must not rate again or skip the next phrase.
        guard phase == 3, self.phrase?.id == phrase.id else { return }
        guard rating != .ready || !primedIDs.contains(phrase.id) else { return }
        let wasRetry = index >= phrases.count
        // Immediate retries are practice, never a second spaced-repetition success.
        if !wasRetry { store.rate(phrase, rating, mode: firstTyped ? "typed" : "spoken") }
        if rating == .again, !wasRetry { retry.append(phrase) }
        ratings.append(rating)
        voice.clear(); reply = ""; firstReply = ""
        // The next phrase replaces the page the same way the steps do, rather than snapping in.
        withAnimation(reduceMotion ? Motion.reducedFade : Motion.snappy) { phase = 0; index += 1 }
    }
    private func move(to phase: Int) {
        // Steps only go forward one at a time; a double tap during the page transition is ignored.
        guard phase == self.phase + 1, phase <= 3 else { return }
        withAnimation(reduceMotion ? Motion.reducedFade : Motion.snappy) { self.phase = phase }
    }
}

import AVFoundation

/// Recording is a supporting action, not the step's main one ("Compare reply" is): a surface button like the
/// rest of the secondary level, tinted with the recording color only while it records.
struct VoiceReplyPanel: View {
    @Environment(\.appAccent) private var accent
    @Bindable var voice: VoicePractice
    @Binding var typed: Bool
    @Binding var reply: String
    @State private var requestTask: Task<Void, Never>?
    @FocusState private var typing: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            if typed {
                TextField("Your reply…", text: $reply, axis: .vertical)
                    .lineLimit(3...6).focused($typing).padding(Spacing.md).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium)).accessibilityIdentifier("replyField")
                    .toolbar { ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { typing = false } } }
            } else {
                Button {
                    if voice.isRecording { voice.stopRecording() }
                    else { requestTask = Task { await voice.start() } }
                } label: {
                    HStack(spacing: Spacing.sm) {
                        // Outline mic at rest; the filled stop reports the recording state. The symbol swaps in place.
                        Image(systemName: voice.isRecording ? "stop.fill" : "mic")
                            .contentTransition(.symbolEffect(.replace))
                            .accessibilityHidden(true)
                        Text(LocalizedStringKey(voice.isRecording ? "Stop recording" : (voice.hasRecording ? "Record again" : "Record a reply")))
                        Spacer(minLength: 0)
                        if voice.isRecording {
                            TimelineView(.periodic(from: .now, by: 0.2)) { _ in
                                HStack(spacing: Spacing.xs) {
                                    Capsule().fill(Palette.recording).frame(width: max(4, voice.level * 48), height: 4)
                                    Text("\(Int(voice.elapsed))s / 180s").monospacedDigit()
                                }.font(.caption).accessibilityLabel("Recording")
                            }
                        }
                    }
                    .font(Typography.control).frame(maxWidth: .infinity, minHeight: 44)
                    .padding(.horizontal, Spacing.md)
                    .foregroundStyle(voice.isRecording ? Palette.recording : Palette.ink)
                    .background(voice.isRecording ? Palette.recording.opacity(0.12) : Palette.surface,
                                in: RoundedRectangle(cornerRadius: Radius.medium))
                    .animation(Motion.snappy, value: voice.isRecording)
                }.buttonStyle(PressStyle()).disabled(voice.isRequesting)
                    .sensoryFeedback(trigger: voice.isRecording) { _, recording in recording ? .start : .stop }
                    .accessibilityLabel(Text(voice.isRecording ? LocalizedStringKey("Stop recording") : LocalizedStringKey("Record my reply")))
                    .accessibilityIdentifier("recordReply")
                if voice.isRequesting {
                    Text("Allow the microphone to record").font(.caption).foregroundStyle(Palette.secondary)
                }
                if voice.hasRecording && !voice.isRecording {
                    Button {
                        if voice.isPlaying { voice.stopPlayback() } else { voice.play() }
                    } label: {
                        Label {
                            Text(voice.isPlaying ? LocalizedStringKey("Stop playback") : LocalizedStringKey("Listen to my take"))
                        } icon: {
                            Image(systemName: voice.isPlaying ? "stop.fill" : "play").contentTransition(.symbolEffect(.replace))
                        }
                    }.font(.subheadline).frame(minHeight: 44).buttonStyle(PressStyle())
                }
            }
            Button(typed ? LocalizedStringKey("Speak instead") : LocalizedStringKey("Type a reply"), systemImage: typed ? "mic" : "keyboard") {
                voice.clear(); reply = ""; typed.toggle()
            }.font(.subheadline).frame(minHeight: 44).buttonStyle(PressStyle()).accessibilityIdentifier("replyMode")
            if let message = voice.message {
                Text(message).font(.caption).foregroundStyle(Palette.secondary).accessibilityIdentifier("voiceMessage")
            }
            if voice.microphoneDenied {
                Button("Open microphone settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }.font(.subheadline).frame(minHeight: 44).accessibilityIdentifier("microphoneSettings")
            }
        }.onDisappear { requestTask?.cancel() }
    }
}
