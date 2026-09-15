import Foundation

/// A projection of saved activity, not a prediction of recall or a mastery score.
struct LearningStats {
    struct ActivityDay: Identifiable {
        let date: Date
        var memoryAnswers = 0
        var speakingReplies = 0
        var stories = 0
        var id: Date { date }
        var total: Int { memoryAnswers + speakingReplies + stories }
    }

    struct ReviewDay: Identifiable {
        let date: Date
        var count = 0
        var id: Date { date }
    }

    let activity: [ActivityDay]
    let upcoming: [ReviewDay]
    let daily: DailyLearningProgress
    let streak: LearningStreak
    let totalPhrases: Int
    let started: Int
    let longerIntervals: Int
    let idiomsStarted: Int
    let overdue: Int
    let nextReview: Date?
    var learning: Int { started - longerIntervals }
    var unseen: Int { totalPhrases - started }
    var activeDays: Int { activity.filter { $0.total > 0 }.count }
    var memoryAnswers: Int { activity.reduce(0) { $0 + $1.memoryAnswers } }
    var speakingReplies: Int { activity.reduce(0) { $0 + $1.speakingReplies } }
    var stories: Int { activity.reduce(0) { $0 + $1.stories } }

    /// `phrases` is the currently accessible catalog. Activity preserves all past
    /// practice, even if access to a previously studied Pro phrase changes.
    init(data: LearningData, phrases: [Phrase], now: Date, calendar: Calendar = .autoupdatingCurrent) {
        let today = calendar.startOfDay(for: now)
        let states = data.memoryReviews ?? [:]
        let availableStates = phrases.compactMap { phrase -> (Phrase, MemoryReview)? in
            guard let state = states[phrase.id], state.introduced <= now, state.lastReviewed <= now else { return nil }
            return (phrase, state)
        }
        totalPhrases = phrases.count
        started = availableStates.count
        // Describes the current interval, never "mastered" or "permanently remembered".
        longerIntervals = availableStates.filter { $0.1.intervalDays >= 21 && $0.1.repetitions > 0 }.count
        idiomsStarted = availableStates.filter { $0.0.isIdiom }.count
        overdue = availableStates.filter { $0.1.due < today }.count
        nextReview = availableStates.map { $0.1.due }.filter { $0 > now }.min()
        daily = DailyLearningProgress(phrases: phrases, states: states, goal: data.newPhrasesPerDay, now: now, calendar: calendar)
        streak = LearningStreak.calculate(dates: data.events.map(\.date) + (data.rehearsalDates ?? []), now: now, calendar: calendar)

        let days = (-6...0).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        var byDay = Dictionary(uniqueKeysWithValues: days.map { ($0, ActivityDay(date: $0)) })
        for event in data.events where event.date <= now {
            let day = calendar.startOfDay(for: event.date)
            guard byDay[day] != nil else { continue }
            if event.mode == "memory" { byDay[day]?.memoryAnswers += 1 }
            else { byDay[day]?.speakingReplies += 1 }
        }
        // Older undated story totals cannot truthfully be assigned to specific days.
        for date in data.rehearsalDates ?? [] where date <= now {
            byDay[calendar.startOfDay(for: date)]?.stories += 1
        }
        activity = days.compactMap { byDay[$0] }

        let futureDays = (0...6).compactMap { calendar.date(byAdding: .day, value: $0, to: today) }
        var dueByDay = Dictionary(uniqueKeysWithValues: futureDays.map { ($0, ReviewDay(date: $0)) })
        for (_, state) in availableStates {
            // Overdue cards belong in today's work, not outside the displayed range.
            let day = max(today, calendar.startOfDay(for: state.due))
            dueByDay[day]?.count += 1
        }
        upcoming = futureDays.compactMap { dueByDay[$0] }
    }
}

/// A qualitative illustration only. These drawing values are not fitted to
/// user data and are intentionally never presented as recall percentages.
enum ForgettingIllustration {
    struct Point: Identifiable {
        let day: Double
        let recall: Double
        let segment: Int
        var id: String { "\(segment)-\(day)" }
    }

    static let reviewDays = [1.0, 7.0, 22.0]
    static let horizon = 30.0

    static func points(withReviews: Bool) -> [Point] {
        let starts = withReviews ? [0.0] + reviewDays : [0.0]
        return starts.enumerated().flatMap { index, start in
            let end = index + 1 < starts.count ? starts[index + 1] : horizon
            let steps = Int((end - start) * 8)
            let scale = 2.0 * pow(2.0, Double(index))
            return (0...steps).map { step in
                let day = start + Double(step) / 8
                return Point(day: day, recall: exp(-(day - start) / scale), segment: index)
            }
        }
    }
}

/// One month of practice for the Stats calendar: which days had activity, and what was
/// practiced on a chosen day, from the saved events.
struct LearningCalendar {
    let month: Date
    let days: [Date?]
    let activeDays: Set<Date>
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
        let practiced = events.filter { $0.date <= now }.map(\.date) + stories.filter { $0 <= now }
        activeDays = Set(practiced.map(calendar.startOfDay(for:)).filter { calendar.isDate($0, equalTo: start, toGranularity: .month) })
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

    var canGoForward: Bool { false }
    func isActive(_ day: Date) -> Bool { activeDays.contains(calendar.startOfDay(for: day)) }

    /// Phrase IDs practiced on `day`, first practice first, each once.
    static func phraseIDs(on day: Date, events: [PracticeEvent], calendar: Calendar = .autoupdatingCurrent) -> [String] {
        var seen = Set<String>()
        return events.filter { calendar.isDate($0.date, inSameDayAs: day) }.sorted { $0.date < $1.date }
            .compactMap { seen.insert($0.phraseID).inserted ? $0.phraseID : nil }
    }
}
