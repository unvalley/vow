import AVFoundation

enum SpeechVoices {
    static func available() -> [SpeechVoiceOption] {
        let systemID = AVSpeechSynthesisVoice(language: "en-US")?.identifier
        return SpeechVoiceSelection.ordered(AVSpeechSynthesisVoice.speechVoices().filter {
            !$0.voiceTraits.contains(.isNoveltyVoice) && !$0.voiceTraits.contains(.isPersonalVoice)
        }.map { .init(id: $0.identifier, name: $0.name, language: $0.language,
                      quality: $0.quality.rawValue, isSystemPreferred: $0.identifier == systemID) })
    }

    static func resolveJapanese() -> AVSpeechSynthesisVoice? {
        let system = AVSpeechSynthesisVoice(language: "ja-JP")
        return AVSpeechSynthesisVoice.speechVoices().filter {
            $0.language.hasPrefix("ja") && !$0.voiceTraits.contains(.isNoveltyVoice) && !$0.voiceTraits.contains(.isPersonalVoice)
        }.sorted {
            if $0.quality != $1.quality { return $0.quality.rawValue > $1.quality.rawValue }
            if ($0.identifier == system?.identifier) != ($1.identifier == system?.identifier) { return $0.identifier == system?.identifier }
            return $0.identifier < $1.identifier
        }.first ?? system
    }

    static func resolve(preferredID: String?) -> AVSpeechSynthesisVoice? {
        // Refresh on playback so downloaded or removed voices take effect immediately.
        if let option = SpeechVoiceSelection.selected(in: available(), preferredID: preferredID),
           let voice = AVSpeechSynthesisVoice(identifier: option.id) { return voice }
        guard let fallback = AVSpeechSynthesisVoice(language: "en-US"),
              !fallback.voiceTraits.contains(.isNoveltyVoice),
              !fallback.voiceTraits.contains(.isPersonalVoice) else { return nil }
        return fallback
    }
}
