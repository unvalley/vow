import XCTest
@testable import Vow

final class LearningStatsTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "America/Los_Angeles")!
        return result
    }
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 3, day: 10, hour: 12))! }

    func testActivityUsesLocalDaysAcrossDSTAndExcludesFutureAndUndatedStories() throws {
        let phrases = Array(try Catalog.load().prefix(3))
        let today = calendar.startOfDay(for: now)
        let firstDay = calendar.date(byAdding: .day, value: -6, to: today)!
        var data = LearningData()
        data.events = [
            .init(phraseID: phrases[0].id, date: firstDay, rating: .ready, mode: "memory"),
            .init(phraseID: phrases[0].id, date: now, rating: .again, mode: "memory"),
            .init(phraseID: phrases[0].id, date: now, rating: .effort, mode: "memory"),
            .init(phraseID: "previous-pro-phrase", date: now, rating: .ready, mode: "typed"),
            .init(phraseID: phrases[1].id, date: firstDay.addingTimeInterval(-1), rating: .ready, mode: "spoken"),
            .init(phraseID: phrases[1].id, date: now.addingTimeInterval(1), rating: .ready, mode: "memory")
        ]
        data.rehearsalCount = 99
        data.rehearsalDates = [today, now.addingTimeInterval(1)]
        let stats = LearningStats(data: data, phrases: phrases, now: now, calendar: calendar)
        XCTAssertEqual(stats.activity.count, 7)
        XCTAssertEqual(stats.activity.first?.date, firstDay)
        XCTAssertEqual(stats.memoryAnswers, 3)
        XCTAssertEqual(stats.speakingReplies, 1)
        XCTAssertEqual(stats.stories, 1)
        XCTAssertEqual(stats.activeDays, 2)
        XCTAssertEqual(stats.activity.last?.total, 4)
        XCTAssertEqual(stats.started, 0, "Events alone must not invent memory-review states.")
        XCTAssertTrue(zip(stats.activity, stats.activity.dropFirst()).contains { $1.date.timeIntervalSince($0.date) == 23 * 3600 })
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

    func testScheduleIncludesOverdueTodayButNotLockedOrOutOfWindowCards() throws {
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
        XCTAssertEqual(stats.overdue, 1)
        XCTAssertEqual(stats.daily.dueReviews, 2)
        XCTAssertEqual(stats.upcoming.first?.count, 3, "Later today belongs in today's bar but isn't due now.")
        XCTAssertEqual(stats.upcoming.last?.count, 1)
        XCTAssertEqual(stats.upcoming.reduce(0) { $0 + $1.count }, 4)
        XCTAssertEqual(stats.nextReview, now.addingTimeInterval(60))
    }

    func testCollectionCountsStatesOnceAndDescribesIntervalsWithoutInferringMastery() throws {
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
        XCTAssertEqual(stats.learning, 2)
        XCTAssertEqual(stats.longerIntervals, 1)
        XCTAssertEqual(stats.unseen, 1)
        XCTAssertEqual(stats.idiomsStarted, 1)
        XCTAssertEqual(stats.daily.introduced, 2, "Daily goal keeps introductions made before access changed.")
        XCTAssertEqual(stats.unseen + stats.learning + stats.longerIntervals, stats.totalPhrases)
    }

    func testEmptyLegacyProgressDoesNotInventActivityOrRetention() throws {
        let stats = LearningStats(data: LearningData(), phrases: try Catalog.load(), now: now, calendar: calendar)
        XCTAssertEqual(stats.activity.map(\.total), Array(repeating: 0, count: 7))
        XCTAssertEqual(stats.upcoming.map(\.count), Array(repeating: 0, count: 7))
        XCTAssertEqual(stats.started, 0)
        XCTAssertEqual(stats.unseen, 1300)
        XCTAssertNil(stats.nextReview)
        XCTAssertEqual(stats.streak.current, 0)
    }

    func testIllustrationHasSeparateDecliningSegmentsAndExplicitReviewResets() {
        let baseline = ForgettingIllustration.points(withReviews: false)
        let reviewed = ForgettingIllustration.points(withReviews: true)
        XCTAssertEqual(Set(baseline.map(\.segment)), [0])
        XCTAssertEqual(Set(reviewed.map(\.segment)), [0, 1, 2, 3])
        XCTAssertEqual(reviewed.first?.day, 0)
        XCTAssertEqual(reviewed.last?.day, 30)
        XCTAssertTrue(reviewed.allSatisfy { (0...1).contains($0.recall) && $0.recall.isFinite })
        for index in 0...3 {
            let segment = reviewed.filter { $0.segment == index }
            XCTAssertEqual(segment.first?.recall, 1)
            XCTAssertTrue(zip(segment, segment.dropFirst()).allSatisfy { $0.day < $1.day && $0.recall > $1.recall })
        }
        XCTAssertGreaterThan(reviewed.last!.recall, baseline.last!.recall)
        XCTAssertEqual(reviewed.filter { $0.recall == 1 }.map(\.day), [0] + ForgettingIllustration.reviewDays)
    }
}
