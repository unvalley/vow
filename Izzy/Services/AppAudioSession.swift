import AVFoundation

@MainActor final class AppAudioSession {
    static let shared = AppAudioSession()
    private let ownership = AudioOwnership()
    var isOccupied: Bool { ownership.owner != nil }

    func activate(owner: UUID, category: AVAudioSession.Category = .playback,
                  mode: AVAudioSession.Mode = .spokenAudio, options: AVAudioSession.CategoryOptions = [],
                  onReplacement: @escaping () -> Void) throws {
        ownership.claim(owner, onReplacement: onReplacement)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(category, mode: mode, options: options)
            try session.setActive(true)
        } catch {
            release(owner: owner)
            throw error
        }
    }

    func release(owner: UUID) {
        guard ownership.release(owner) else { return }
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }
}
