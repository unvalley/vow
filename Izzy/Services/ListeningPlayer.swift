import AVFoundation
import MediaPlayer
import Observation

/// One app-scoped player keeps a bounded speech queue alive across navigation and locking.
@MainActor @Observable final class ListeningPlayer: NSObject, AVSpeechSynthesizerDelegate {
    private(set) var session: ListeningSession?
    private(set) var isPlaying = false
    private(set) var isFinished = false
    private(set) var message: String?
    private(set) var sleepDeadline: Date?
    @ObservationIgnored private var synthesizer = AVSpeechSynthesizer()
    @ObservationIgnored private var utterance: AVSpeechUtterance?
    @ObservationIgnored private let audioOwner = UUID()
    @ObservationIgnored private var voiceID: String?
    @ObservationIgnored private var sleepTask: Task<Void, Never>?
    @ObservationIgnored private var observers: [NSObjectProtocol] = []
    @ObservationIgnored private var commands: [(MPRemoteCommand, Any)] = []
    @ObservationIgnored private var resumeAfterInterruption = false

    var hasSession: Bool { session?.phrase != nil }

    override init() {
        super.init()
        synthesizer.delegate = self
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { [weak self] note in
            let type = (note.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber)?.uintValue
            let options = (note.userInfo?[AVAudioSessionInterruptionOptionKey] as? NSNumber)?.uintValue ?? 0
            Task { @MainActor [weak self] in self?.interrupted(type: type, options: options) }
        })
        observers.append(center.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] note in
            let reason = (note.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber)?.uintValue
            guard reason == AVAudioSession.RouteChangeReason.oldDeviceUnavailable.rawValue else { return }
            Task { @MainActor [weak self] in self?.pause() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.pause()
                self.utterance = nil
                self.synthesizer = AVSpeechSynthesizer()
                self.synthesizer.delegate = self
                if self.hasSession { self.message = String(localized: "Audio was interrupted. Tap play to continue.") }
            }
        })
    }

    func start(_ session: ListeningSession, voiceID: String?) {
        stop()
        guard session.phrase != nil else {
            message = String(localized: "No expressions in this playlist. Choose another collection or save some expressions.")
            return
        }
        self.session = session
        self.voiceID = voiceID
        Analytics.shared.record(.listeningStarted, ["scope": session.preferences.collection.rawValue])
        installCommands()
        if session.preferences.sleepMinutes > 0 {
            let seconds = min(session.preferences.sleepMinutes, 120) * 60
            sleepDeadline = Date.now.addingTimeInterval(Double(seconds))
            sleepTask = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(seconds)) } catch { return }
                self?.stop()
                self?.message = String(localized: "Sleep timer ended.")
            }
        }
        resume()
    }

    func resume() {
        guard hasSession else { return }
        if let sleepDeadline, sleepDeadline <= .now { stop(); return }
        do {
            try AppAudioSession.shared.activate(owner: audioOwner) { [weak self] in self?.pause() }
            message = nil
            resumeAfterInterruption = false
            if isFinished { session?.restart(); isFinished = false }
            isPlaying = true
            if utterance != nil, synthesizer.isPaused, synthesizer.continueSpeaking() {
                updateNowPlaying()
            } else {
                cancelUtterance()
                speakCurrentSegment()
            }
        } catch {
            fail(String(localized: "Audio is unavailable right now. Try playing again."))
        }
    }

    func pause() {
        resumeAfterInterruption = false
        isPlaying = false
        if utterance != nil, !synthesizer.pauseSpeaking(at: .immediate) { cancelUtterance() }
        AppAudioSession.shared.release(owner: audioOwner)
        updateNowPlaying()
    }

    func toggle() { if isPlaying { pause() } else { resume() } }

    func skip(_ offset: Int) {
        guard var next = session, next.skip(offset) else { return }
        cancelUtterance()
        session = next
        isFinished = false
        if isPlaying { speakCurrentSegment() } else { updateNowPlaying() }
    }

    func stop() {
        isPlaying = false
        isFinished = false
        resumeAfterInterruption = false
        cancelUtterance()
        session = nil
        message = nil
        sleepTask?.cancel()
        sleepTask = nil
        sleepDeadline = nil
        AppAudioSession.shared.release(owner: audioOwner)
        if !commands.isEmpty {
            for (command, target) in commands { command.removeTarget(target); command.isEnabled = false }
            commands.removeAll()
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
        }
    }

    func restrict(to allowedIDs: Set<String>) {
        guard var updated = session else { return }
        let currentID = updated.phrase?.id
        updated.restrict(to: allowedIDs)
        guard updated.phrase != nil else { stop(); return }
        session = updated
        if currentID != updated.phrase?.id {
            cancelUtterance()
            isFinished = false
            if isPlaying { speakCurrentSegment() }
        }
        updateNowPlaying()
    }

    private func speakCurrentSegment() {
        guard isPlaying, let session, let segment = session.segment else { return }
        if let sleepDeadline, sleepDeadline <= .now { stop(); return }
        let voice = segment.language.hasPrefix("en")
            ? SpeechVoices.resolve(preferredID: voiceID)
            : SpeechVoices.resolveJapanese()
        guard let voice else {
            fail(String(localized: "A voice for this language is unavailable. Add it in iOS Settings, or turn off spoken meanings."))
            return
        }
        let next = AVSpeechUtterance(string: segment.text)
        next.voice = voice
        next.rate = session.preferences.slower ? 0.40 : AVSpeechUtteranceDefaultSpeechRate
        next.postUtteranceDelay = session.segmentIndex == session.segments.count - 1 ? 1.2 : 0.6
        utterance = next
        synthesizer.speak(next)
        updateNowPlaying()
    }

    private func cancelUtterance() {
        // Old completion/cancellation callbacks cannot advance a replacement playlist.
        utterance = nil
        synthesizer.stopSpeaking(at: .immediate)
    }

    private func fail(_ text: String) {
        pause()
        cancelUtterance()
        message = text
    }

    private func interrupted(type: UInt?, options: UInt) {
        if type == AVAudioSession.InterruptionType.began.rawValue {
            let playing = isPlaying
            pause()
            resumeAfterInterruption = playing
        } else if type == AVAudioSession.InterruptionType.ended.rawValue {
            let resume = resumeAfterInterruption && AVAudioSession.InterruptionOptions(rawValue: options).contains(.shouldResume)
            resumeAfterInterruption = false
            if resume && !AppAudioSession.shared.isOccupied { self.resume() }
        }
    }

    private func installCommands() {
        let center = MPRemoteCommandCenter.shared()
        func add(_ command: MPRemoteCommand, action: @escaping @MainActor (ListeningPlayer) -> Void) {
            let target = command.addTarget { [weak self] _ in
                Task { @MainActor [weak self] in if let self { action(self) } }
                return .success
            }
            commands.append((command, target))
        }
        add(center.playCommand) { $0.resume() }
        add(center.pauseCommand) { $0.pause() }
        add(center.togglePlayPauseCommand) { $0.toggle() }
        add(center.nextTrackCommand) { $0.skip(1) }
        add(center.previousTrackCommand) { $0.skip(-1) }
    }

    private func updateNowPlaying() {
        guard let session, let phrase = session.phrase else { return }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: phrase.phrase,
            MPMediaItemPropertyArtist: "Izzy",
            MPNowPlayingInfoPropertyMediaType: MPNowPlayingInfoMediaType.audio.rawValue,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0,
            MPNowPlayingInfoPropertyPlaybackQueueIndex: session.index,
            MPNowPlayingInfoPropertyPlaybackQueueCount: session.phrases.count
        ]
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = !isPlaying
        center.pauseCommand.isEnabled = isPlaying
        center.togglePlayPauseCommand.isEnabled = true
        center.nextTrackCommand.isEnabled = session.canGoForward
        center.previousTrackCommand.isEnabled = session.canGoBack
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, let current = self.utterance, ObjectIdentifier(current) == id else { return }
            self.utterance = nil
            if self.session?.finishSegment() == true {
                if self.isPlaying { self.speakCurrentSegment() } else { self.updateNowPlaying() }
            } else {
                self.isPlaying = false
                self.isFinished = true
                AppAudioSession.shared.release(owner: self.audioOwner)
                self.updateNowPlaying()
            }
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        let id = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            guard let self, let current = self.utterance, ObjectIdentifier(current) == id else { return }
            self.utterance = nil
            self.fail(String(localized: "Audio was interrupted. Tap play to continue."))
        }
    }
}
