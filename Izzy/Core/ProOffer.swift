import Foundation

/// What the free plan has given a learner so far and what Izzy Pro would give them next, worked out
/// from the catalog and their own reviews. Every Pro invitation speaks in these numbers and phrases
/// rather than in general claims, so the offer is the learner's next step, not an advertisement.
struct ProOffer: Sendable {
    /// Free expressions already met in meaning recall.
    let freeLearned: Int
    /// Expressions the free plan opens in this catalog.
    let freeTotal: Int
    /// Pro expressions for the learner's kind and levels not met yet: what Pro adds to Home.
    let lockedCount: Int
    /// Pro expressions already met, during a trial or before a refund: their reviews wait for Pro.
    let paused: Int
    /// The first Pro expressions Home would introduce, in the order it would introduce them.
    let next: [Phrase]

    init(phrases: [Phrase], memory: [String: MemoryReview], kind: PhraseKindFilter,
         levels: PhraseLevelFilter = .all, focus: String = "", count: Int = 3) {
        var freeLearned = 0, freeTotal = 0, paused = 0
        var locked: [Phrase] = []
        // The level choice as Pro would apply it: a level the free plan has nothing in is still the learner's choice.
        let levels = levels.applied(phrases: phrases, purchased: true, kind: kind)
        for phrase in phrases {
            if AccessPolicy.allows(phrase, purchased: false) {
                freeTotal += 1
                if memory[phrase.id] != nil { freeLearned += 1 }
            } else if memory[phrase.id] != nil {
                paused += 1
            } else if kind.allows(phrase), levels.allows(phrase) {
                locked.append(phrase)
            }
        }
        self.freeLearned = freeLearned
        self.freeTotal = freeTotal
        self.paused = paused
        lockedCount = locked.count
        // The same order the daily queue picks new phrases in: the conversation focus first, then by ID.
        next = locked.smallest(count) {
            if ($0.scene == focus) != ($1.scene == focus) { return $0.scene == focus }
            return $0.id < $1.id
        }
    }

    /// Whether Home's free deck has nothing new left: every free expression the filters show has been met.
    /// Reviews continue; only new expressions have run out, which is the moment Pro is worth mentioning.
    static func freePlanFinished(visible: [Phrase], memory: [String: MemoryReview], purchased: Bool) -> Bool {
        !purchased && !visible.isEmpty && visible.allSatisfy { memory[$0.id] != nil }
    }
}
