import SwiftUI

struct SpeechSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var voices: [SpeechVoiceOption] = []
    @State private var voice = VoicePractice()
    private let sample = "Before we finish, can I bring up the deadline?"

    private var selected: SpeechVoiceOption? {
        SpeechVoiceSelection.selected(in: voices, preferredID: store.data.speechVoiceID)
    }

    var body: some View {
        List {
            Section {
                Button {
                    voice.stopPlayback()
                    store.configureSpeechVoice(nil)
                } label: {
                    HStack {
                        Text("Automatic · best available")
                        Spacer()
                        if store.data.speechVoiceID == nil { Image(systemName: "checkmark") }
                    }
                }.accessibilityIdentifier("speechVoice-automatic")
                    .accessibilityValue(store.data.speechVoiceID == nil ? Text("Selected") : Text(""))
                if let selected {
                    LabeledContent("Current voice", value: label(selected))
                        .accessibilityIdentifier("currentSpeechVoice")
                }
                if let saved = store.data.speechVoiceID, !voices.contains(where: { $0.id == saved }) {
                    Text("Your selected voice is no longer installed. Automatic selection is being used until it is available again.")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                }
                Button(voice.isSpeaking ? LocalizedStringKey("Stop preview") : LocalizedStringKey("Preview voice"),
                       systemImage: voice.isSpeaking ? "stop.fill" : "speaker.wave.2") {
                    if voice.isSpeaking { voice.stopPlayback() }
                    else { voice.speak(sample, voiceIdentifier: store.data.speechVoiceID) }
                }.accessibilityIdentifier("previewSpeechVoice")
                if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
            } footer: {
                Text("Automatic chooses an installed Premium voice first, then Enhanced, then Standard. English (US) is preferred when quality is equal. You can choose a different accent below.")
            }
            Section("Installed English voices") {
                ForEach(voices) { option in
                    Button {
                        voice.stopPlayback()
                        store.configureSpeechVoice(option.id)
                    } label: {
                        HStack {
                            Text(label(option))
                            Spacer()
                            if store.data.speechVoiceID == option.id { Image(systemName: "checkmark") }
                        }
                    }.accessibilityIdentifier("speechVoice-\(option.id)")
                        .accessibilityValue(store.data.speechVoiceID == option.id ? Text("Selected") : Text(""))
                }
            }
            Section("More natural voices") {
                if !voices.contains(where: { $0.quality >= 2 }) {
                    Text("Only standard English voices are installed.")
                }
                Text("In iOS Settings, open Accessibility → Read & Speak (Spoken Content on earlier iOS versions) → Voices → English. Download an Enhanced or Premium voice, then return to vow. Downloads may require Wi-Fi and storage space.")
                Text("Installed voices work offline. Voice availability and how natural they sound depend on your device and the voice you choose.")
                Link("Apple's voice download guide", destination: URL(string: "https://support.apple.com/111798")!)
            }
        }.scrollContentBackground(.hidden).background { ReadingBackground() }
            .foregroundStyle(Palette.ink).tint(Palette.ink)
            .navigationTitle("Reading voice").navigationBarTitleDisplayMode(.inline)
            .onAppear { voices = SpeechVoices.available() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { voices = SpeechVoices.available() }
                else { voice.stopPlayback() }
            }
            .onDisappear { voice.clear() }
    }

    private func label(_ option: SpeechVoiceOption) -> String {
        let quality = option.quality >= 3 ? String(localized: "Premium") :
            option.quality == 2 ? String(localized: "Enhanced") : String(localized: "Standard")
        let language = Locale.current.localizedString(forIdentifier: option.language) ?? option.language
        return "\(option.name) · \(language) · \(quality)"
    }
}
