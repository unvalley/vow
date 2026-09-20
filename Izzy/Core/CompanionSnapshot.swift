import Foundation

/// What the home-screen widget shows, written by the app into the shared App Group container.
///
/// It records dates and counts rather than an already-decided mood: the widget re-derives the
/// figure's pose for each timeline entry, so it changes at the evening mark and at midnight
/// without the app having run since.
struct CompanionSnapshot: Codable, Sendable, Equatable {
    var schema = 1
    /// Start of the most recent day with a qualifying practice; nil before the first one.
    var lastPracticeDay: Date?
    /// The streak as of `lastPracticeDay`. It is still current today when that day was yesterday.
    var streak: Int = 0
    /// The day the counts below describe. They are dropped once the widget's own day moves past it.
    var day: Date = .distantPast
    /// New expressions introduced on `day`, and the day's reachable goal, as Home counts them.
    var introduced: Int = 0
    var target: Int = 0
    /// Cards still to do on `day`: nothing left means today's learning is complete.
    var remaining: Int = 0
    var accent: AppAccent = .black

}

extension CompanionSnapshot {
    /// The projection of saved progress the widget needs, from the same records Stats reads.
    /// `phrases` is the currently accessible catalog, as the daily deck and Stats both use.
    init(data: LearningData, phrases: [Phrase], now: Date, calendar: Calendar = .autoupdatingCurrent) {
        self.init()
        let practiceDates = data.practiceDates
        streak = LearningStreak.calculate(dates: practiceDates, now: now, calendar: calendar).current
        lastPracticeDay = practiceDates.lazy.filter { $0 <= now }.max().map(calendar.startOfDay)
        day = calendar.startOfDay(for: now)
        accent = data.accentColor
        let goal = data.newPhrasesPerDay
        let states = data.memoryReviews ?? [:]
        // The same two counts Home shows, so the widget never disagrees with the screen behind it.
        let progress = DailyLearningProgress(phrases: phrases, states: states, goal: goal, now: now, calendar: calendar)
        introduced = progress.introduced
        target = progress.target
        // `queue` is what todayDeck's `remaining` already is; the deck it builds around it is discarded here.
        remaining = MemoryScheduler.queue(phrases: phrases, states: states, focus: data.focus, now: now,
                                          calendar: calendar, limit: phrases.count, dailyNewLimit: goal).count
    }
}

/// The figure's pose. Personality comes from how the letterform leans and bounces, so each case
/// is a posture rather than an expression.
enum CompanionMood: String, Sendable, CaseIterable {
    /// Today's learning is finished.
    case celebrating
    /// Practiced today, with cards still to go.
    case working
    /// Nothing practiced today, and the day still has room.
    case resting
    /// Nothing practiced today, the evening has come, and a live streak lapses at midnight.
    case urging
    /// The streak has already lapsed.
    case lapsed
    /// Nothing has been practiced yet at all.
    case fresh
}

/// A snapshot read for one moment in time.
struct CompanionStatus: Sendable, Equatable {
    let mood: CompanionMood
    /// The streak the learner still holds now: yesterday's streak stays current until today ends.
    let streak: Int
    /// Today's counts, or nil when the snapshot describes an earlier day and the app hasn't run since.
    let introduced: Int?
    let target: Int?
    let remaining: Int?
}

extension CompanionSnapshot {
    /// When a day with no practice starts reading as running out. Before it the figure waits; after
    /// it, it leans as though about to fall.
    static let eveningHour = 18

    func status(now: Date, calendar: Calendar = .autoupdatingCurrent) -> CompanionStatus {
        let today = calendar.startOfDay(for: now)
        // Days since the last practice: nil before the first one, 0 today, 1 yesterday. A streak
        // practised yesterday is still current, because today has not ended yet.
        let gap = lastPracticeDay.flatMap { calendar.dateComponents([.day], from: $0, to: today).day }
        let current = gap == 0 || gap == 1 ? streak : 0
        // Counts belong to the day they were written on. After midnight the app hasn't run yet, so
        // the widget reports the new day as empty rather than repeating yesterday's numbers.
        let isCurrentDay = calendar.isDate(day, inSameDayAs: today)
        let remainingToday = isCurrentDay ? remaining : nil
        let mood: CompanionMood
        switch gap {
        case nil: mood = .fresh
        case 0: mood = remainingToday == 0 ? .celebrating : .working
        case 1 where current > 0: mood = calendar.component(.hour, from: now) >= Self.eveningHour ? .urging : .resting
        default: mood = .lapsed
        }
        return CompanionStatus(mood: mood, streak: current,
                               introduced: isCurrentDay ? introduced : nil,
                               target: isCurrentDay ? target : nil, remaining: remainingToday)
    }

    /// The moments the pose can change on its own: this evening's mark, then each following midnight
    /// and evening mark. The widget asks for an entry at each so it stays right while the app is closed.
    func refreshDates(from now: Date, calendar: Calendar = .autoupdatingCurrent) -> [Date] {
        let today = calendar.startOfDay(for: now)
        return (0...2).flatMap { offset -> [Date] in
            guard let start = calendar.date(byAdding: .day, value: offset, to: today).map(calendar.startOfDay) else { return [] }
            let evening = calendar.date(byAdding: .hour, value: Self.eveningHour, to: start)
            return [start, evening].compactMap { $0 }
        }.filter { $0 > now }
    }
}

extension CompanionSnapshot: WidgetShared {
    static let fileName = "companion.json"
    static let widgetKind = "CompanionWidget"
}
