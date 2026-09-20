import Foundation

struct SpeechVoiceOption: Identifiable, Equatable, Sendable {
    let id: String
    let name: String
    let language: String
    /// AVSpeechSynthesisVoiceQuality: default = 1, enhanced = 2, premium = 3.
    let quality: Int
    var isSystemPreferred = false
}

enum SpeechVoiceSelection {
    static func ordered(_ voices: [SpeechVoiceOption]) -> [SpeechVoiceOption] {
        voices.filter { $0.language.lowercased().hasPrefix("en-") || $0.language == "en" }
            .sorted {
                if $0.quality != $1.quality { return $0.quality > $1.quality }
                if ($0.language == "en-US") != ($1.language == "en-US") { return $0.language == "en-US" }
                if $0.isSystemPreferred != $1.isSystemPreferred { return $0.isSystemPreferred }
                if $0.language != $1.language { return $0.language < $1.language }
                return $0.id < $1.id
            }
    }

    static func selected(in voices: [SpeechVoiceOption], preferredID: String?) -> SpeechVoiceOption? {
        let available = ordered(voices)
        if let preferredID, let preferred = available.first(where: { $0.id == preferredID }) { return preferred }
        return available.first
    }
}
