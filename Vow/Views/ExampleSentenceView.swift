import SwiftUI
import Translation

/// The same sentence owns its audio controls on every learning surface. With Japanese explanations
/// the sentence's meaning sits right under it; Easy English shows the sentence alone.
struct ExampleSentenceView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    let text: String
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    var identifier = "exampleSentence"

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            PhraseExampleText(text: "“\(text)”", phrase: phrase)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier)
            if store.data.meaningLanguage == .japanese {
                if let authored = phrase.exampleTranslations?[text] {
                    Text(authored).font(.subheadline).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("\(identifier)-translation")
                } else if #available(iOS 18.0, *) {
                    InlineJapaneseTranslation(text: text, identifier: identifier).id(text)
                }
            }
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.md) { controls }
                VStack(alignment: .leading, spacing: Spacing.xxs) { controls }
            }.font(.subheadline).buttonStyle(PressStyle())
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder private var controls: some View {
        audioButton(slow: false)
        audioButton(slow: true)
    }

    private func audioButton(slow: Bool) -> some View {
        let playing = voice.isSpeaking(text, slow: slow)
        return Button {
            if playing { voice.stopPlayback() }
            else { voice.speak(text, slow: slow, voiceIdentifier: store.data.speechVoiceID) }
        } label: {
            Label {
                Text(playing ? LocalizedStringKey("Stop") : slow ? LocalizedStringKey("Slower") : LocalizedStringKey("Listen"))
            } icon: {
                // The filled stop reports playback; it swaps in place of the outline icon.
                Image(systemName: playing ? "stop.fill" : slow ? "tortoise" : "speaker.wave.2")
                    .contentTransition(.symbolEffect(.replace))
            }
        }.foregroundStyle(playing ? accent.color : Palette.ink).frame(minHeight: 44)
            .animation(Motion.snappy, value: playing)
            .accessibilityIdentifier("\(identifier)-\(slow ? "slow" : "listen")")
            .accessibilityValue(playing ? Text("Playing") : Text(""))
    }
}

/// Examples without an authored Japanese meaning translate in place on request. Translation may
/// download language data, so it never starts on its own.
@available(iOS 18.0, *)
private struct InlineJapaneseTranslation: View {
    let text: String
    let identifier: String
    @State private var configuration: TranslationSession.Configuration?
    @State private var translation: String?
    @State private var isLoading = false
    @State private var failed = false

    var body: some View {
        Group {
            if let translation {
                Text(translation).font(.subheadline).foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(identifier)-translation")
                    .transition(.opacity.combined(with: BlurTransition.soft))
            } else if isLoading {
                ProgressView("Translating…").font(.caption).accessibilityIdentifier("\(identifier)-translating")
                    .transition(.opacity)
            } else {
                Button(failed ? LocalizedStringKey("Try translation again") : LocalizedStringKey("Show Japanese translation"), systemImage: "translate") {
                    failed = false
                    isLoading = true
                    if configuration != nil { configuration?.invalidate() }
                    else if #available(iOS 26.4, *) {
                        configuration = .init(source: .init(identifier: "en"), target: .init(identifier: "ja"), preferredStrategy: .highFidelity)
                    } else {
                        configuration = .init(source: .init(identifier: "en"), target: .init(identifier: "ja"))
                    }
                }.font(.caption.weight(.medium)).buttonStyle(PressStyle()).frame(minHeight: 32)
                    .hitArea(6) // 32 pt drawn, 44 pt to touch
                    .accessibilityIdentifier("\(identifier)-translate")
            }
        }.translationTask(configuration, action: translate)
    }

    nonisolated private func translate(using session: TranslationSession) async {
        do {
            try await session.prepareTranslation()
            let response = try await session.translate(text)
            guard !Task.isCancelled else { return }
            await MainActor.run { withAnimation(Motion.snappy) { translation = response.targetText; isLoading = false } }
        } catch {
            guard !Task.isCancelled else { return }
            await MainActor.run { failed = true; isLoading = false }
        }
    }
}
