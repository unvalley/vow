import Foundation

/// A projection of saved activity, not a prediction of recall or a mastery score.
struct LearningStats {
    let streak: LearningStreak
    let started: Int
    let nextReview: Date?

    /// `phrases` is the currently accessible catalog.
    init(data: LearningData, phrases: [Phrase], now: Date, calendar: Calendar = .autoupdatingCurrent) {
        let states = data.memoryReviews ?? [:]
        let availableStates = phrases.compactMap { phrase -> MemoryReview? in
            guard let state = states[phrase.id], state.introduced <= now, state.lastReviewed <= now else { return nil }
            return state
        }
        started = availableStates.count
        nextReview = availableStates.map(\.due).filter { $0 > now }.min()
        streak = LearningStreak.calculate(dates: data.events.map(\.date) + (data.rehearsalDates ?? []), now: now, calendar: calendar)
    }
}

/// One month of practice for the Stats calendar: which days had activity, and what was
/// practiced on a chosen day, from the saved events.
struct LearningCalendar {
    let month: Date
    let days: [Date?]
    /// Meaning reviews scheduled per day in this month; anything overdue counts on today.
    let dueCounts: [Date: Int]
    /// Expressions practiced per day this month (each expression once) plus completed stories: the fill's intensity.
    let practiceCounts: [Date: Int]
    let calendar: Calendar

    /// `month` is any date in the month; the grid starts on the calendar's first weekday and
    /// pads with nil so weekdays line up. `reviews` are the states of the accessible phrases.
    init(month: Date, events: [PracticeEvent], stories: [Date], reviews: [MemoryReview] = [], now: Date, calendar: Calendar = .autoupdatingCurrent) {
        self.calendar = calendar
        let start = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
        self.month = start
        let count = calendar.range(of: .day, in: .month, for: start)?.count ?? 30
        let dates = (0..<count).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }
        let leading = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        days = Array(repeating: nil, count: leading) + dates
        var practicedPhrases: [Date: Set<String>] = [:]
        for event in events where event.date <= now {
            practicedPhrases[calendar.startOfDay(for: event.date), default: []].insert(event.phraseID)
        }
        var counts = practicedPhrases.mapValues(\.count)
        for story in stories where story <= now { counts[calendar.startOfDay(for: story), default: 0] += 1 }
        practiceCounts = counts.filter { calendar.isDate($0.key, equalTo: start, toGranularity: .month) }
        let today = calendar.startOfDay(for: now)
        var due: [Date: Int] = [:]
        for review in reviews {
            let day = max(today, calendar.startOfDay(for: review.due))
            if calendar.isDate(day, equalTo: start, toGranularity: .month) { due[day, default: 0] += 1 }
        }
        dueCounts = due
    }

    func dueCount(on day: Date) -> Int { dueCounts[calendar.startOfDay(for: day)] ?? 0 }
    func practiceCount(on day: Date) -> Int { practiceCounts[calendar.startOfDay(for: day)] ?? 0 }

    /// Phrase IDs practiced on `day`, first practice first, each once.
    static func phraseIDs(on day: Date, events: [PracticeEvent], calendar: Calendar = .autoupdatingCurrent) -> [String] {
        var seen = Set<String>()
        return events.filter { calendar.isDate($0.date, inSameDayAs: day) }.sorted { $0.date < $1.date }
            .compactMap { seen.insert($0.phraseID).inserted ? $0.phraseID : nil }
    }
}
