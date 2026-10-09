import Foundation

/// Everything Home derives from the catalog for one render, computed once per body evaluation.
/// Before this, each read of the learning queue, speaking queue or daily progress re-filtered and
/// re-sorted the whole catalog; a single render did that around eighteen times.
struct HomeDerivation {
    enum Mode { case learning, explore }
    static let lockID = "izzy-pro-locked"
    /// The page after the last card of Today's learning once nothing is left to do.
    static let completeID = "izzy-learning-complete"

    /// Everything the plan allows.
    let accessible: [Phrase]
    /// Accessible and matching the kind and level filters: what both modes show.
    let visible: [Phrase]
    /// Today's learning: the remaining queue plus what was answered today, in a stable order.
    let learning: [Phrase]
    /// What is still to do today; empty means today's learning is complete.
    let remaining: [Phrase]
    let browsing: [Phrase]
    let showsLock: Bool
    let showsComplete: Bool
    let pageIDs: [String]
    let position: Int
    /// Explore counts the whole collection for the filter, including Pro phrases a free plan can't open yet.
    let collectionCount: Int
    let speaking: [Phrase]
    let progress: DailyLearningProgress
    /// Today's new phrases in the deck: first rated today, then the unseen ones still to come. Everything
    /// else in the deck is a review.
    let learnedToday: [Phrase]
    let upcomingNew: [Phrase]
    /// Today's reviews in the deck: answered today, then still due.
    let reviewedToday: [Phrase]
    let upcomingReviews: [Phrase]
    private let newIDs: Set<String>
    /// Whether a card in Today's learning is a review rather than one of today's new phrases.
    func isReview(_ id: String) -> Bool { !newIDs.contains(id) }

    /// Everything the plan allows, narrowed to the chosen kind and levels: what Home shows, and what
    /// anything reporting on Home has to count.
    static func visible(_ phrases: [Phrase], purchased: Bool, kind: PhraseKindFilter,
                        levels: PhraseLevelFilter = .all) -> [Phrase] {
        let levels = levels.applied(phrases: phrases, purchased: purchased, kind: kind)
        return phrases.filter { AccessPolicy.allows($0, purchased: purchased) && kind.allows($0) && levels.allows($0) }
    }

    init(phrases: [Phrase], purchased: Bool, kind: PhraseKindFilter, levels: PhraseLevelFilter = .all,
         memory: [String: MemoryReview], reviews: [String: ReviewState], focus: String, dailyNew: Int, now: Date,
         mode: Mode, selectedID: String) {
        accessible = phrases.filter { AccessPolicy.allows($0, purchased: purchased) }
        // Levels the plan or kind no longer offers are set aside here, so `visible` is never emptied by a stale choice.
        let levels = levels.applied(phrases: phrases, purchased: purchased, kind: kind)
        visible = phrases.filter { AccessPolicy.allows($0, purchased: purchased) && kind.allows($0) && levels.allows($0) }
        let today = MemoryScheduler.todayDeck(phrases: visible, states: memory, focus: focus, now: now, dailyNewLimit: dailyNew)
        learning = today.deck
        remaining = today.remaining
        browsing = mode == .learning ? learning : visible
        showsLock = mode == .explore && !purchased
        showsComplete = mode == .learning && remaining.isEmpty && !learning.isEmpty
        pageIDs = browsing.map(\.id) + (showsLock ? [Self.lockID] : []) + (showsComplete ? [Self.completeID] : [])
        position = pageIDs.firstIndex(of: selectedID) ?? 0
        collectionCount = purchased ? visible.count : phrases.filter { kind.allows($0) && levels.allows($0) }.count
        speaking = mode == .learning
            ? SessionPlanner.queue(phrases: visible, states: reviews, focus: focus, now: now)
            : visible.filter { $0.id == selectedID }
        // Introductions count across every phrase; what is left (new and due) matches the filtered queue.
        progress = DailyLearningProgress(phrases: visible, states: memory, goal: dailyNew, now: now)
        let new = learning.filter { MemoryScheduler.isNewToday(memory[$0.id], now: now) }
        learnedToday = new.filter { memory[$0.id] != nil }
        upcomingNew = new.filter { memory[$0.id] == nil }
        newIDs = Set(new.map(\.id))
        let remainingIDs = Set(remaining.map(\.id)), ids = newIDs
        let due = learning.filter { !ids.contains($0.id) }
        reviewedToday = due.filter { !remainingIDs.contains($0.id) }
        upcomingReviews = due.filter { remainingIDs.contains($0.id) }
    }

    /// Home as the store has it set up: its filters, focus, daily goal and schedules.
    @MainActor init(store: LearningStore, purchased: Bool, now: Date, mode: Mode = .learning, selectedID: String = "") {
        self.init(phrases: store.phrases, purchased: purchased, kind: store.data.homeKindFilter,
                  levels: store.data.homeLevelFilter, memory: store.data.memoryReviews ?? [:],
                  reviews: store.data.reviews, focus: store.data.focus, dailyNew: store.data.newPhrasesPerDay,
                  now: now, mode: mode, selectedID: selectedID)
    }
}
