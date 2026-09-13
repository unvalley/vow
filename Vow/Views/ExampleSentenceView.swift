import SwiftUI

/// The same sentence owns its meaning and audio controls on every learning surface.
struct ExampleSentenceView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    let text: String
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    var identifier = "exampleSentence"
    var expressionMeaning: String? = nil
    @State private var showsMeaning = false

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            PhraseExampleText(text: "“\(text)”", phrase: phrase)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(identifier)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Spacing.md) { controls }
                VStack(alignment: .leading, spacing: Spacing.xxs) { controls }
            }.font(.subheadline).buttonStyle(.plain)
        }.frame(maxWidth: .infinity, alignment: .leading)
            .sheet(isPresented: $showsMeaning) {
                SentenceMeaningView(text: text, phrase: phrase, expressionMeaning: expressionMeaning)
            }
    }

    @ViewBuilder private var controls: some View {
        Button("Meaning", systemImage: "character.book.closed") {
            voice.stopPlayback()
            showsMeaning = true
        }.frame(minHeight: 44).accessibilityIdentifier("\(identifier)-meaning")
        audioButton(slow: false)
        audioButton(slow: true)
    }

    private func audioButton(slow: Bool) -> some View {
        let playing = voice.isSpeaking(text, slow: slow)
        return Button(playing ? LocalizedStringKey("Stop") : slow ? LocalizedStringKey("Slower") : LocalizedStringKey("Listen"),
                      systemImage: playing ? "stop.fill" : slow ? "tortoise" : "speaker.wave.2") {
            if playing { voice.stopPlayback() }
            else { voice.speak(text, slow: slow, voiceIdentifier: store.data.speechVoiceID) }
        }.foregroundStyle(playing ? accent.color : Palette.ink).frame(minHeight: 44)
            .accessibilityIdentifier("\(identifier)-\(slow ? "slow" : "listen")")
            .accessibilityValue(playing ? Text("Playing") : Text(""))
    }
}
