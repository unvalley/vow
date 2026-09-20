import XCTest
@testable import Izzy

final class LearningStatsTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return result
    }
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))! }

    func testEventsAloneDoNotStartPhrases() throws {
        let phrases = Array(try Catalog.load().prefix(3))
        var data = LearningData()
        data.events = [
            .init(phraseID: phrases[0].id, date: now, rating: .ready, mode: "memory"),
            .init(phraseID: phrases[1].id, date: now, rating: .ready, mode: "spoken")
        ]
        let stats = LearningStats(data: data, phrases: phrases, now: now, calendar: calendar)
        XCTAssertEqual(stats.started, 0, "Events alone must not invent memory-review states.")
    }

    func testStreakSurvivesADaylightSavingDayThatStartsAtOneAM() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "America/Santiago"))
        // 6 Sep 2026 has no midnight in Santiago: the day starts at 01:00.
        let dates = try (3...9).map { day in
            try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: 12)))
        }
        let streak = LearningStreak.calculate(dates: dates, now: dates.last!, calendar: calendar)
        XCTAssertEqual(streak.current, 7)
        XCTAssertEqual(streak.longest, 7)
    }

    func testHomeProgressCountsWhatTheFilterLeavesButIntroductionsEverywhere() throws {
        let phrases = try Catalog.load().filter { AccessPolicy.allows($0, purchased: false) }
        let now = Date.now
        var memory: [String: MemoryReview] = [:]
        for phrase in phrases where phrase.isIdiom {
            memory[phrase.id] = MemoryReview(due: now.addingTimeInterval(86_400), introduced: now.addingTimeInterval(-86_400 * 3),
                                             lastReviewed: now.addingTimeInterval(-86_400))
        }
        let verb = try XCTUnwrap(phrases.first { !$0.isIdiom })
        memory[verb.id] = MemoryReview(due: now.addingTimeInterval(-60), introduced: now, lastReviewed: now)
        let d = HomeDerivation(phrases: phrases, purchased: false, kind: .idioms, memory: memory, reviews: [:], focus: "work",
                               dailyNew: 5, now: now, mode: .learning, selectedID: "")
        XCTAssertTrue(d.learning.isEmpty)
        XCTAssertEqual(d.progress.introduced, 1, "the phrasal verb introduced today still counts toward the goal")
        XCTAssertEqual(d.progress.target, 1)
        XCTAssertEqual(d.progress.dueReviews, 0, "a due phrasal verb is hidden by the Idioms filter")
    }

    func testHomeSeparatesTodaysNewPhrasesFromReviews() throws {
        let phrases = try Catalog.load().filter { AccessPolicy.allows($0, purchased: false) }
        let now = Date.now
        var memory: [String: MemoryReview] = [:]
        let review = phrases[0]
        memory[review.id] = MemoryReview(due: now.addingTimeInterval(-60), introduced: now.addingTimeInterval(-86_400 * 3),
                                         lastReviewed: now.addingTimeInterval(-86_400))
        let learned = phrases[1]
        memory[learned.id] = MemoryScheduler.rate(nil, rating: .good, now: now)
        let d = HomeDerivation(phrases: phrases, purchased: false, kind: .all, memory: memory, reviews: [:], focus: "work",
                               dailyNew: 3, now: now, mode: .learning, selectedID: "")
        XCTAssertTrue(d.isReview(review.id))
        XCTAssertFalse(d.isReview(learned.id))
        XCTAssertEqual(d.learnedToday.map(\.id), [learned.id])
        XCTAssertEqual(d.upcomingNew.count, 2, "the goal of three minus the one already introduced")
        XCTAssertTrue(d.upcomingNew.allSatisfy { memory[$0.id] == nil && !d.isReview($0.id) })
        XCTAssertTrue(d.learning.contains { $0.id == review.id }, "the due review stays in the deck")
        XCTAssertEqual(d.upcomingReviews.map(\.id), [review.id])
        XCTAssertTrue(d.reviewedToday.isEmpty)
        memory[review.id] = MemoryScheduler.rate(memory[review.id], rating: .good, now: now)
        let after = HomeDerivation(phrases: phrases, purchased: false, kind: .all, memory: memory, reviews: [:], focus: "work",
                                   dailyNew: 3, now: now, mode: .learning, selectedID: "")
        XCTAssertEqual(after.reviewedToday.map(\.id), [review.id], "an answered review moves to reviewed, not to new")
        XCTAssertTrue(after.upcomingReviews.isEmpty)
        XCTAssertEqual(after.learnedToday.map(\.id), [learned.id])
    }

    func testNextReviewIsTheFirstFutureDueDateOfAnAccessiblePhrase() throws {
        let phrases = Array(try Catalog.load().prefix(7))
        let today = calendar.startOfDay(for: now)
        let dueDates = [today.addingTimeInterval(-1), now, now.addingTimeInterval(60),
                        calendar.date(byAdding: .day, value: 6, to: today)!,
                        calendar.date(byAdding: .day, value: 7, to: today)!, now]
        var data = LearningData()
        data.memoryReviews = Dictionary(uniqueKeysWithValues: zip(phrases, dueDates).map { phrase, due in
            (phrase.id, MemoryReview(due: due, introduced: today.addingTimeInterval(-86400), lastReviewed: today.addingTimeInterval(-86400)))
        })
        let stats = LearningStats(data: data, phrases: Array(phrases.prefix(5)), now: now, calendar: calendar)
        XCTAssertEqual(stats.nextReview, now.addingTimeInterval(60))
    }

    func testStartedCountsAccessibleStatesOnce() throws {
        let catalog = try Catalog.load()
        let phrases = Array(catalog.prefix(3)) + [try XCTUnwrap(catalog.first(where: \.isIdiom))]
        var data = LearningData()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        data.memoryReviews = [
            phrases[0].id: .init(due: now, intervalDays: 20, repetitions: 3, introduced: yesterday, lastReviewed: yesterday),
            phrases[1].id: .init(due: now, intervalDays: 21, repetitions: 3, introduced: yesterday, lastReviewed: yesterday),
            phrases[3].id: .init(due: now, intervalDays: 0, repetitions: 0, lapses: 1, introduced: now, lastReviewed: now),
            "locked": .init(due: now, intervalDays: 30, repetitions: 4, introduced: now, lastReviewed: now)
        ]
        let stats = LearningStats(data: data, phrases: phrases, now: now, calendar: calendar)
        XCTAssertEqual(stats.started, 3)
        let daily = DailyLearningProgress(phrases: phrases, states: data.memoryReviews ?? [:], goal: 5, now: now, calendar: calendar)
        XCTAssertEqual(daily.introduced, 2, "Daily goal keeps introductions made before access changed.")
    }

    func testEmptyLegacyProgressDoesNotInventActivity() throws {
        let stats = LearningStats(data: LearningData(), phrases: try Catalog.load(), now: now, calendar: calendar)
        XCTAssertEqual(stats.started, 0)
        XCTAssertNil(stats.nextReview)
        XCTAssertEqual(stats.streak.current, 0)
    }
}
