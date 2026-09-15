import SwiftUI

/// Practice is a list: for each situation, the question, the phrase to use, and an answer example that
/// stays blurred until tapped. Say your answer, then tap to compare. There are no steps to page through.
struct PracticeView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    let phrases: [Phrase]
    var primedIDs: Set<String> = []
    @State private var revealed: Set<String> = []
    @State private var practiced: Set<String> = []
    @State private var voice = VoicePractice()

    private struct Item: Identifiable {
        let id: String
        let phrase: Phrase
        let question: String
        let answer: String
    }

    /// Both situations of each phrase, in session order.
    private var items: [Item] {
        phrases.flatMap { phrase in
            [(phrase.cue, phrase.reply, "a"), (phrase.transferCue, phrase.transferReply, "b")]
                .filter { !$0.0.isEmpty && !$0.1.isEmpty }
                .map { Item(id: "\(phrase.id)-\($0.2)", phrase: phrase, question: $0.0, answer: $0.1) }
        }
    }

    var body: some View {
        NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    if items.isEmpty {
                        ContentUnavailableView("No reviews due", systemImage: "checkmark.circle",
                                               description: Text("You're up to date. Come back when your next review is ready."))
                    }
                    ForEach(items) { item in card(item) }
                }.frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Practice").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { voice.stopPlayback(); dismiss() } label: { Image(systemName: "xmark").frame(width: 44, height: 44) }
                        .accessibilityLabel("Close practice")
                }
            }
        }
        .onDisappear { voice.clear() }
    }

    private func card(_ item: Item) -> some View {
        let isRevealed = revealed.contains(item.id)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text(verbatim: "Q.").font(Typography.section).foregroundStyle(Palette.secondary)
                Text(item.question).font(Typography.meaning).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Use this phrase").font(Typography.metadata).foregroundStyle(Palette.secondary)
                Text(item.phrase.phrase).font(Typography.phraseRow)
            }
            Divider()
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text("Answer example").font(Typography.metadata).foregroundStyle(Palette.secondary)
                Button { reveal(item) } label: {
                    HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                        Text(verbatim: "A.").font(Typography.section).foregroundStyle(Palette.secondary)
                        PhraseExampleText(text: item.answer, phrase: item.phrase)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            // Blurred until tapped, so the answer can be thought through before it's seen.
                            .blur(radius: isRevealed ? 0 : 7)
                            .overlay {
                                if !isRevealed {
                                    Label("Tap to show", systemImage: "eye").font(.caption.weight(.medium))
                                        .foregroundStyle(Palette.ink)
                                        .padding(.horizontal, Spacing.sm).padding(.vertical, Spacing.xxs)
                                        .background(Palette.paper, in: Capsule())
                                }
                            }
                    }.contentShape(Rectangle())
                }.buttonStyle(.plain) // never disabled: a disabled label would dim the revealed answer
                    .accessibilityLabel(isRevealed ? Text(item.answer) : Text("Answer example, hidden"))
                    .accessibilityHint(isRevealed ? Text("") : Text("Shows the answer example"))
                if isRevealed {
                    ExampleSentenceControls(text: item.answer, voice: voice)
                        .transition(.opacity)
                }
            }
        }.padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            .accessibilityIdentifier("practiceItem-\(item.id)")
    }

    /// Revealing an answer counts as practicing that phrase once, so the speaking schedule moves on.
    private func reveal(_ item: Item) {
        guard !revealed.contains(item.id) else { return }
        withAnimation(reduceMotion ? Motion.reducedFade : Motion.snappy) { _ = revealed.insert(item.id) }
        guard !practiced.contains(item.phrase.id) else { return }
        practiced.insert(item.phrase.id)
        store.rate(item.phrase, .effort, mode: "spoken")
    }
}

/// Listen and Slower for a revealed answer, without the translation shown in the notes.
private struct ExampleSentenceControls: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    let text: String
    @Bindable var voice: VoicePractice
    var body: some View {
        HStack(spacing: Spacing.md) {
            button(slow: false)
            button(slow: true)
        }.font(.subheadline).buttonStyle(PressStyle())
    }
    private func button(slow: Bool) -> some View {
        let playing = voice.isSpeaking(text, slow: slow)
        return Button {
            if playing { voice.stopPlayback() } else { voice.speak(text, slow: slow, voiceIdentifier: store.data.speechVoiceID) }
        } label: {
            Label {
                Text(playing ? LocalizedStringKey("Stop") : slow ? LocalizedStringKey("Slower") : LocalizedStringKey("Listen"))
            } icon: {
                Image(systemName: playing ? "stop.fill" : slow ? "tortoise" : "speaker.wave.2").contentTransition(.symbolEffect(.replace))
            }
        }.foregroundStyle(playing ? accent.color : Palette.ink).frame(minHeight: 44)
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
