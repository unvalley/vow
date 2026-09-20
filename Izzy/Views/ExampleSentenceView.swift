import SwiftUI

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
            // Every example has an authored Japanese meaning in the catalog; nothing is translated on device.
            if store.data.meaningLanguage == .japanese, let japanese = phrase.exampleTranslations?[text] {
                Text(japanese).font(.subheadline).foregroundStyle(Palette.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(identifier)-translation")
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
