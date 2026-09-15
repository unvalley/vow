import AVFoundation
import Observation

@MainActor @Observable final class VoicePractice: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var isSpeaking = false
    @ObservationIgnored private var spokenUtterance: AVSpeechUtterance?
    var message: String?
    private let synthesizer = AVSpeechSynthesizer()
    private let audioOwner = UUID()

    func speak(_ text: String, slow: Bool = false, voiceIdentifier: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.delegate = self
        stopPlayback()
        do {
            try AppAudioSession.shared.activate(owner: audioOwner) { [weak self] in self?.stopPlayback() }
            let utterance = AVSpeechUtterance(string: text)
            guard let selectedVoice = SpeechVoices.resolve(preferredID: voiceIdentifier) else {
                message = String(localized: "No English voice is available. Add one in iOS Settings to listen.")
                releaseSession()
                return
            }
            message = nil
            utterance.voice = selectedVoice
            utterance.rate = slow ? 0.40 : AVSpeechUtteranceDefaultSpeechRate
            spokenUtterance = utterance
            isSpeaking = true
            synthesizer.speak(utterance)
        } catch {
            message = String(localized: "Audio is unavailable right now. The example is available as text.")
            releaseSession()
        }
    }

    func isSpeaking(_ text: String, slow: Bool = false) -> Bool {
        guard isSpeaking, let utterance = spokenUtterance else { return false }
        return utterance.speechString == text && utterance.rate == (slow ? 0.40 : AVSpeechUtteranceDefaultSpeechRate)
    }

    func stopPlayback() {
        isSpeaking = false
        spokenUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        releaseSession()
    }

    func clear() {
        stopPlayback()
        message = nil
    }

    private func releaseSession() { AppAudioSession.shared.release(owner: audioOwner) }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        speechEnded(utterance)
    }
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        speechEnded(utterance)
    }
    private nonisolated func speechEnded(_ utterance: AVSpeechUtterance) {
        let utteranceID = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, let current = self.spokenUtterance, ObjectIdentifier(current) == utteranceID else { return }
            self.spokenUtterance = nil
            self.isSpeaking = false
            self.releaseSession()
        }
    }
}
