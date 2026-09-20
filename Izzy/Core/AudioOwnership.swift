import Foundation

/// Prevents a disappearing practice view from deactivating another player's audio.
@MainActor final class AudioOwnership {
    private(set) var owner: UUID?
    private var onReplacement: (() -> Void)?

    func claim(_ id: UUID, onReplacement: @escaping () -> Void) {
        if owner != id {
            let previous = self.onReplacement
            owner = nil
            self.onReplacement = nil
            previous?()
        }
        owner = id
        self.onReplacement = onReplacement
    }

    @discardableResult func release(_ id: UUID) -> Bool {
        guard owner == id else { return false }
        owner = nil
        onReplacement = nil
        return true
    }
}
