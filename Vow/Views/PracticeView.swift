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
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    if items.isEmpty {
                        ContentUnavailableView("No reviews due", systemImage: "checkmark.circle",
                                               description: Text("You're up to date. Come back when your next review is ready."))
                    } else {
                        Text("\(phrases.count) phrases · \(items.count) questions")
                            .font(Typography.metadata.monospacedDigit()).foregroundStyle(Palette.secondary)
                    }
                    ForEach(phrases) { phrase in
                        let questions = items.filter { $0.phrase.id == phrase.id }
                        if !questions.isEmpty { section(phrase, questions) }
                    }
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

    /// The phrase once, as the heading its questions share, then one card per question.
    private func section(_ phrase: Phrase, _ questions: [Item]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Use this phrase").font(Typography.metadata).foregroundStyle(Palette.secondary)
                Text(phrase.phrase).phraseFont(.title2).accessibilityAddTraits(.isHeader)
                PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, font: .subheadline, leadOnly: true, color: Palette.secondary)
            }
            ForEach(questions) { item in card(item) }
        }
    }

    private func card(_ item: Item) -> some View {
        let isRevealed = revealed.contains(item.id)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                marker("Q")
                Text(item.question).font(Typography.meaning).fixedSize(horizontal: false, vertical: true)
            }
            // The answer lives in its own inset: blurred with a quiet prompt, then the sentence and its audio.
            Button { reveal(item) } label: {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                    marker("A")
                    Group {
                        if isRevealed {
                            PhraseExampleText(text: item.answer, phrase: item.phrase)
                        } else {
                            // Plain text under the blur, so the phrase highlight doesn't show through as a colored smear.
                            Text(item.answer).font(Typography.example).foregroundStyle(Palette.secondary)
                                .blur(radius: 7)
                                .overlay {
                                    Text("Tap to show the answer example").font(.subheadline.weight(.medium))
                                        .foregroundStyle(Palette.ink)
                                }
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(Spacing.md).frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: Radius.medium))
                .contentShape(RoundedRectangle(cornerRadius: Radius.medium))
            }.buttonStyle(.plain) // never disabled: a disabled label would dim the revealed answer
                .accessibilityLabel(isRevealed ? Text(item.answer) : Text("Answer example, hidden"))
                .accessibilityHint(isRevealed ? Text("") : Text("Shows the answer example"))
            if isRevealed {
                ExampleSentenceControls(text: item.answer, voice: voice)
                    .padding(.leading, Spacing.md)
                    .transition(.opacity)
            }
        }.padding(Spacing.md).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            .accessibilityIdentifier("practiceItem-\(item.id)")
    }

    /// Q and A as small fixed-width marks, so both texts start on the same line.
    private func marker(_ letter: String) -> some View {
        Text(verbatim: letter).font(.caption.weight(.semibold).monospaced())
            .foregroundStyle(Palette.secondary)
            .frame(width: 14, alignment: .leading)
            .accessibilityHidden(true)
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
