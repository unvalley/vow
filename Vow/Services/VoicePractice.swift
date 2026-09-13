import AVFoundation
import Observation

@MainActor @Observable final class VoicePractice: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate, AVSpeechSynthesizerDelegate {
    private(set) var isRecording = false
    private(set) var isRequesting = false
    private(set) var hasRecording = false
    private(set) var isPlaying = false
    private(set) var isSpeaking = false
    private(set) var microphoneDenied = false
    @ObservationIgnored private var spokenUtterance: AVSpeechUtterance?
    private(set) var recordedSeconds: TimeInterval = 0
    var message: String?
    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private let synthesizer = AVSpeechSynthesizer()
    private let audioOwner = UUID()
    private var generation = 0
    private let url = FileManager.default.temporaryDirectory.appending(path: "verve-\(UUID().uuidString).m4a")

    static func reclaimAbandonedRecordings() {
        // Reclaim only Vow's abandoned temporary takes from a previous launch.
        if let files = try? FileManager.default.contentsOfDirectory(at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix("verve-") && file.pathExtension == "m4a" {
                try? FileManager.default.removeItem(at: file)
            }
        }
    }

    var elapsed: TimeInterval { recorder?.currentTime ?? recordedSeconds }
    var level: Double {
        guard let recorder, isRecording else { return 0 }
        recorder.updateMeters()
        return max(0, min(1, (Double(recorder.averagePower(forChannel: 0)) + 50) / 50))
    }

    func start() async {
        guard !isRecording, !isRequesting else { return }
        generation += 1
        let ticket = generation
        isRequesting = true
        message = nil
        microphoneDenied = false
        let granted = await AVAudioApplication.requestRecordPermission()
        guard ticket == generation else { return }
        guard !Task.isCancelled else { isRequesting = false; return }
        isRequesting = false
        guard granted else {
            microphoneDenied = true
            message = String(localized: "Microphone access is off. You can speak without recording or type a reply. To record, enable the microphone for vow in Settings.")
            return
        }
        do {
            stopPlayback()
            try AppAudioSession.shared.activate(owner: audioOwner, category: .playAndRecord, mode: .default, options: [.defaultToSpeaker]) { [weak self] in self?.suspend() }
            let recording = try AVAudioRecorder(url: url, settings: [AVFormatIDKey: kAudioFormatMPEG4AAC, AVSampleRateKey: 44100, AVNumberOfChannelsKey: 1, AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue])
            recording.delegate = self
            recording.isMeteringEnabled = true
            guard recording.record(forDuration: 180) else { throw CocoaError(.fileWriteUnknown) }
            recorder = recording
            hasRecording = false
            recordedSeconds = 0
            isRecording = true
        } catch {
            message = String(localized: "Recording couldn't start. Try again, or use a typed reply.")
            releaseSession()
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        recordedSeconds = recorder?.currentTime ?? 0
        recorder?.stop()
        recorder = nil
        isRecording = false
        hasRecording = recordedSeconds >= 0.5
        if !hasRecording { message = String(localized: "That recording was very short. Try a full reply, or type it instead.") }
        releaseSession()
    }

    func play() {
        guard hasRecording else { return }
        do {
            stopPlayback()
            try AppAudioSession.shared.activate(owner: audioOwner) { [weak self] in self?.suspend() }
            let playback = try AVAudioPlayer(contentsOf: url)
            playback.delegate = self
            player = playback
            isPlaying = playback.play()
            if !isPlaying {
                message = String(localized: "This recording couldn't be played. Try recording again.")
                releaseSession()
            }
        } catch { message = String(localized: "This recording couldn't be played. Try recording again."); releaseSession() }
    }

    func speak(_ text: String, slow: Bool = false, voiceIdentifier: String? = nil) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        synthesizer.delegate = self
        stopRecording()
        stopPlayback()
        do {
            try AppAudioSession.shared.activate(owner: audioOwner) { [weak self] in self?.suspend() }
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
        player?.stop()
        player = nil
        isPlaying = false
        isSpeaking = false
        spokenUtterance = nil
        synthesizer.stopSpeaking(at: .immediate)
        releaseSession()
    }

    func suspend() {
        generation += 1
        isRequesting = false
        stopRecording()
        stopPlayback()
    }

    func clear() {
        suspend()
        recorder = nil
        try? FileManager.default.removeItem(at: url)
        hasRecording = false
        recordedSeconds = 0
        message = nil
        microphoneDenied = false
    }

    private func releaseSession() { AppAudioSession.shared.release(owner: audioOwner) }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let recorderID = ObjectIdentifier(recorder)
        Task { @MainActor [weak self] in
            guard let self, self.isRecording, let current = self.recorder, ObjectIdentifier(current) == recorderID else { return }
            self.isRecording = false
            self.hasRecording = flag
            self.recordedSeconds = flag ? 180 : 0
            self.recorder = nil
            if !flag { self.message = String(localized: "Recording was interrupted. Please try again.") }
            self.releaseSession()
        }
    }
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
            guard !self.isRecording, !self.isPlaying, !self.synthesizer.isSpeaking else { return }
            self.releaseSession()
        }
    }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        let playerID = ObjectIdentifier(player)
        Task { @MainActor [weak self] in
            guard let self, let current = self.player, ObjectIdentifier(current) == playerID else { return }
            self.isPlaying = false
            self.releaseSession()
        }
    }
}
