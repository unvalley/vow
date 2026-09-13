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
