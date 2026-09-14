import Foundation

/// Everything Home derives from the catalog for one render, computed once per body evaluation.
/// Before this, each read of the learning queue, speaking queue or daily progress re-filtered and
/// re-sorted the whole catalog; a single render did that around eighteen times.
struct HomeDerivation {
    enum Mode { case learning, explore }
    static let lockID = "vow-pro-locked"

    /// Everything the plan allows; the daily goal counts against this set.
    let accessible: [Phrase]
    /// Accessible and matching the kind filter: what both modes show.
    let visible: [Phrase]
    let learning: [Phrase]
    let browsing: [Phrase]
    let showsLock: Bool
    let pageIDs: [String]
    let position: Int
    let speaking: [Phrase]
    let progress: DailyLearningProgress

    /// `pinned` keeps a phrase that was just rated at its place in the learning queue for the
    /// moment its chosen answer is shown; the rating itself is already recorded.
    init(phrases: [Phrase], purchased: Bool, kind: PhraseKindFilter, memory: [String: MemoryReview],
         reviews: [String: ReviewState], focus: String, dailyNew: Int, now: Date, mode: Mode, selectedID: String,
         pinned: (id: String, index: Int)? = nil) {
        accessible = phrases.filter { AccessPolicy.allows($0, purchased: purchased) }
        visible = accessible.filter(kind.allows)
        var queue = MemoryScheduler.queue(phrases: visible, states: memory, focus: focus, now: now,
                                          limit: visible.count, dailyNewLimit: dailyNew)
        if let pinned, mode == .learning, !queue.contains(where: { $0.id == pinned.id }),
           let phrase = visible.first(where: { $0.id == pinned.id }) {
            queue.insert(phrase, at: min(max(0, pinned.index), queue.count))
        }
        learning = queue
        browsing = mode == .learning ? learning : visible
        showsLock = mode == .explore && !purchased
        pageIDs = browsing.map(\.id) + (showsLock ? [Self.lockID] : [])
        position = pageIDs.firstIndex(of: selectedID) ?? 0
        speaking = mode == .learning
            ? SessionPlanner.queue(phrases: visible, states: reviews, focus: focus, now: now)
            : visible.filter { $0.id == selectedID }
        progress = DailyLearningProgress(phrases: accessible, states: memory, goal: dailyNew, now: now)
    }
}
