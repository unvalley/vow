import Foundation

enum MemoryRating: String, Codable, CaseIterable, Sendable {
    case again, hard, good, easy
    var title: String { rawValue.capitalized }
    var quality: Double {
        switch self { case .again: 2; case .hard: 3; case .good: 4; case .easy: 5 }
    }
    var eventRating: RecallRating {
        switch self { case .again: .again; case .hard: .effort; case .good, .easy: .ready }
    }
}

/// Meaning recall is tracked separately from producing a reply in speaking practice.
struct MemoryReview: Codable, Equatable, Sendable {
    var due: Date
    var intervalDays: Double = 0
    var ease: Double = 2.5
    var repetitions: Int = 0
    var lapses: Int = 0
    var introduced: Date
    var lastReviewed: Date
    /// The schedule before the day's first rating, so a change of answer that day replaces it instead of stacking.
    var dayBaseline: DayBaseline?

    indirect enum DayBaseline: Codable, Equatable, Sendable {
        case new
        case scheduled(MemoryReview)
    }
}

/// SM-2-derived intervals with four answer buttons and a ten-minute relearning step.
/// This is not Anki's FSRS model or a fitted prediction of an individual's forgetting curve.
enum MemoryScheduler {
    static let dailyNewLimit = 5

    /// Rates a phrase as the learner sees it: a second answer on the same day, before that answer's due time,
    /// corrects the first one and is scheduled from where the day started. Once the phrase is due again (after
    /// Again's ten minutes) the next answer is a new review. Rating controls preview intervals with this too,
    /// so the labels don't shift when an answer is tapped.
    static func rate(_ state: MemoryReview?, rating: MemoryRating, now: Date,
                     calendar: Calendar = .autoupdatingCurrent) -> MemoryReview {
        let baseline: MemoryReview.DayBaseline
        if let state, let saved = state.dayBaseline, state.due > now, calendar.isDate(state.lastReviewed, inSameDayAs: now) {
            baseline = saved
        } else if var state {
            state.dayBaseline = nil
            baseline = .scheduled(state)
        } else {
            baseline = .new
        }
        let start: MemoryReview? = if case .scheduled(let old) = baseline { old } else { nil }
        var next = review(start, rating: rating, now: now)
        if let state { next.introduced = state.introduced }
        next.dayBaseline = baseline
        return next
    }

    static func review(_ old: MemoryReview?, rating: MemoryRating, now: Date) -> MemoryReview {
        var state = old ?? MemoryReview(due: now, introduced: now, lastReviewed: now)
        state.lastReviewed = now
        // Re-reading before the due date must not inflate the spacing interval.
        if let old, old.due > now, rating != .again { return state }
        let quality = rating.quality
        let oldEase = state.ease
        state.ease = max(1.3, min(3.0, oldEase + 0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02)))
        if rating == .again {
            state.lapses += 1
            state.repetitions = 0
            state.intervalDays = 0
            state.due = now.addingTimeInterval(600)
            return state
        }
        let interval: Double
        if state.repetitions == 0 {
            interval = rating == .easy ? 4 : 1
        } else if rating == .hard {
            interval = max(state.intervalDays + 1, state.intervalDays * 1.2)
        } else if state.repetitions == 1 {
            interval = max(6, state.intervalDays * (rating == .easy ? oldEase * 1.3 : 1))
        } else {
            interval = state.intervalDays * oldEase * (rating == .easy ? 1.3 : 1)
        }
        state.repetitions += 1
        state.intervalDays = min(36_500, ceil(interval))
        state.due = now.addingTimeInterval(state.intervalDays * 86_400)
        return state
    }

    /// Today's learning as a deck that keeps what was already answered today. It holds the remaining
    /// `queue` plus every phrase answered today, ordered by where each stood at the start of the day
    /// (`dayBaseline`): due reviews by that due date, then new phrases in queue order. Answering a card
    /// never moves any card, so paging stays put through the day.
    static func todayDeck(phrases: [Phrase], states: [String: MemoryReview], focus: String, now: Date,
                          calendar: Calendar = .autoupdatingCurrent,
                          dailyNewLimit: Int = MemoryScheduler.dailyNewLimit) -> (deck: [Phrase], remaining: [Phrase]) {
        let remaining = queue(phrases: phrases, states: states, focus: focus, now: now, calendar: calendar,
                              limit: phrases.count, dailyNewLimit: dailyNewLimit)
        let remainingIDs = Set(remaining.map(\.id))
        let answered = phrases.filter {
            guard !remainingIDs.contains($0.id), let state = states[$0.id] else { return false }
            return state.lastReviewed <= now && calendar.isDate(state.lastReviewed, inSameDayAs: now)
        }
        /// (group, due, focus rank, id): due reviews first by due date, then new phrases as the queue orders them.
        func key(_ phrase: Phrase) -> (Int, Date, Int, String) {
            let focusRank = phrase.scene == focus ? 0 : 1
            guard let state = states[phrase.id] else { return (1, .distantPast, focusRank, phrase.id) }
            let answeredToday = calendar.isDate(state.lastReviewed, inSameDayAs: now)
            switch answeredToday ? state.dayBaseline : nil {
            case .new?: return (1, .distantPast, focusRank, phrase.id)
            case .scheduled(let start)?: return (0, start.due, 0, phrase.id)
            // Answered before day baselines existed, or not answered today: its current schedule is the best record.
            case nil: return (0, answeredToday ? state.lastReviewed : state.due, 0, phrase.id)
            }
        }
        let deck = (remaining + answered).sorted { key($0) < key($1) }
        return (deck, remaining)
    }

    /// Whether a phrase is one of today's new phrases rather than a review: never rated, or first rated today.
    /// The same test counts introductions toward the daily goal, so the label and the count agree.
    static func isNewToday(_ state: MemoryReview?, now: Date, calendar: Calendar = .autoupdatingCurrent) -> Bool {
        guard let state else { return true }
        return state.introduced <= now && calendar.isDate(state.introduced, inSameDayAs: now)
    }

    static func intervalLabel(until due: Date, now: Date) -> String {
        let seconds = max(0, due.timeIntervalSince(now))
        if seconds < 3_600 { return "\(max(1, Int(ceil(seconds / 60))))m" }
        if seconds < 86_400 { return "\(Int(ceil(seconds / 3_600)))h" }
        return "\(Int(ceil(seconds / 86_400)))d"
    }

    static func queue(phrases: [Phrase], states: [String: MemoryReview], focus: String,
                      now: Date, calendar: Calendar = .autoupdatingCurrent, limit: Int = 20,
                      dailyNewLimit: Int = MemoryScheduler.dailyNewLimit) -> [Phrase] {
        let due = phrases.filter { states[$0.id].map { $0.due <= now } ?? false }
            .sorted {
                let a = states[$0.id]!.due, b = states[$1.id]!.due
                return a == b ? $0.id < $1.id : a < b
            }
        // Count all introductions, including phrases whose Pro access was later revoked.
        let introducedToday = states.values.filter { $0.introduced <= now && calendar.isDate($0.introduced, inSameDayAs: now) }.count
        // Only a handful of new phrases are needed; pick them without sorting every unseen phrase.
        let fresh = phrases.filter { states[$0.id] == nil }
            .smallest(max(0, dailyNewLimit - introducedToday)) {
                if ($0.scene == focus) != ($1.scene == focus) { return $0.scene == focus }
                return $0.id < $1.id
            }
        return Array((due + fresh).prefix(max(0, limit)))
    }
}

extension Array {
    /// The `count` smallest elements in order, by insertion into a bounded buffer: O(n·count)
    /// instead of sorting everything when `count` is small next to `self.count`.
    func smallest(_ count: Int, by precedes: (Element, Element) -> Bool) -> [Element] {
        guard count > 0 else { return [] }
        if count * 8 >= self.count { return Array(sorted(by: precedes).prefix(count)) }
        var best: [Element] = []
        best.reserveCapacity(count + 1)
        for element in self {
            if best.count == count, let last = best.last, !precedes(element, last) { continue }
            let index = best.firstIndex { precedes(element, $0) } ?? best.count
            best.insert(element, at: index)
            if best.count > count { best.removeLast() }
        }
        return best
    }
}

/// Counts introductions, not reveals or repeated ratings of the same phrase.
struct DailyLearningProgress {
    let goal: Int
    let introduced: Int
    let remainingNew: Int
    let dueReviews: Int
    var target: Int { min(goal, introduced + remainingNew) }

    init(phrases: [Phrase], states: [String: MemoryReview], goal: Int, now: Date,
         calendar: Calendar = .autoupdatingCurrent) {
        self.goal = min(50, max(1, goal))
        introduced = states.values.filter {
            $0.introduced <= now && calendar.isDate($0.introduced, inSameDayAs: now)
        }.count
        let unseen = phrases.filter { states[$0.id] == nil }.count
        remainingNew = min(unseen, max(0, self.goal - introduced))
        dueReviews = phrases.filter { states[$0.id].map { $0.due <= now } ?? false }.count
    }
}
