import Foundation

/// What the home-screen widget shows, written by the app into the shared App Group container.
///
/// It records dates and counts rather than an already-decided mood: the widget re-derives
/// where today stands for each timeline entry, so it changes at the evening mark and at midnight
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
    /// Starts of the days practised in the fortnight up to `day`, for the widget's row of days.
    /// Optional so a file written before it existed still decodes; the row then falls back to the streak.
    var practiceDays: [Date]?
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
        // Two weeks, so the row stays right through the days the widget's timeline runs ahead.
        let horizon = calendar.date(byAdding: .day, value: -(Self.practiceHorizon - 1), to: day) ?? day
        practiceDays = Set(practiceDates.lazy.filter { $0 <= now }.map(calendar.startOfDay).filter { $0 >= horizon })
            .sorted()
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

/// Where today stands, which picks the widget's line under the streak.
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
    /// The last `CompanionSnapshot.weekLength` days, oldest first and ending today: whether each was practised.
    let week: [Bool]
}

extension CompanionSnapshot {
    /// When a day with no practice starts reading as running out. Before it the widget says today
    /// is unpracticed; after it, that the day is almost over.
    static let eveningHour = 18
    static let weekLength = 7
    static let practiceHorizon = 14

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
                               target: isCurrentDay ? target : nil, remaining: remainingToday,
                               week: week(endingOn: today, calendar: calendar))
    }

    private func week(endingOn today: Date, calendar: Calendar) -> [Bool] {
        let practised: (Date) -> Bool
        if let practiceDays {
            let days = Set(practiceDays.map(calendar.startOfDay))
            practised = { days.contains($0) }
        } else if let lastPracticeDay, streak > 0 {
            // An older file knows only the streak: its run of days is certain, anything before it is not shown.
            let first = calendar.date(byAdding: .day, value: -(streak - 1), to: lastPracticeDay) ?? lastPracticeDay
            practised = { $0 >= first && $0 <= lastPracticeDay }
        } else {
            practised = { _ in false }
        }
        return (0..<Self.weekLength).reversed().map { offset in
            calendar.date(byAdding: .day, value: -offset, to: today).map { practised(calendar.startOfDay(for: $0)) } ?? false
        }
    }

    /// The moments the line can change on its own: this evening's mark, then each following midnight
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
