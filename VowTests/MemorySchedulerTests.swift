import XCTest
@testable import Vow

final class MemorySchedulerTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    @MainActor func testDailyGoalPersistsResumesAndDoesNotCountRepeatedRatings() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "learning.json")
        let store = LearningStore(file: file)
        XCTAssertNil(store.data.dailyNewGoal)
        store.configureDailyGoal(3)
        let phrases = store.phrases.filter { AccessPolicy.allows($0, purchased: false) }
        let first = try XCTUnwrap(phrases.first)
        store.rateMemory(first, .again, now: now)
        store.rateMemory(first, .good, now: now)
        let reopened = LearningStore(file: file)
        XCTAssertEqual(reopened.data.newPhrasesPerDay, 3)
        let states = reopened.data.memoryReviews ?? [:]
        let progress = DailyLearningProgress(phrases: phrases, states: states, goal: 3, now: now)
        XCTAssertEqual(progress.introduced, 1)
        XCTAssertEqual(progress.remainingNew, 2)
        let queue = MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: now, dailyNewLimit: 3)
        XCTAssertEqual(queue.count, 2)
        XCTAssertFalse(queue.contains(first))
        XCTAssertEqual(DailyLearningProgress(phrases: phrases, states: states, goal: 1, now: now).remainingNew, 0)
        XCTAssertEqual(DailyLearningProgress(phrases: phrases, states: states, goal: 10, now: now).remainingNew, 9)
        reopened.configureDailyGoal(0)
        XCTAssertEqual(reopened.data.newPhrasesPerDay, 1)
        reopened.configureDailyGoal(100)
        XCTAssertEqual(reopened.data.newPhrasesPerDay, 50)
    }

    func testDailyGoalSeparatesDueReviewsAndHandlesMidnightAndCollectionEnd() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let phrases = Array(try Catalog.load().prefix(4))
        let start = calendar.startOfDay(for: now).addingTimeInterval(86_390)
        let states = [phrases[0].id: MemoryReview(due: start, introduced: start.addingTimeInterval(-86_400), lastReviewed: start)]
        let queue = MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: start,
                                          calendar: calendar, dailyNewLimit: 2)
        XCTAssertEqual(queue.count, 3)
        XCTAssertEqual(queue.first?.id, phrases[0].id)
        var next = states
        for phrase in queue { next[phrase.id] = MemoryScheduler.review(next[phrase.id], rating: .good, now: start) }
        let complete = DailyLearningProgress(phrases: phrases, states: next, goal: 2, now: start, calendar: calendar)
        XCTAssertEqual(complete.introduced, 2)
        XCTAssertTrue(complete.isComplete)
        let tomorrow = DailyLearningProgress(phrases: phrases, states: next, goal: 2, now: start.addingTimeInterval(20), calendar: calendar)
        XCTAssertEqual(tomorrow.introduced, 0)
        XCTAssertEqual(tomorrow.remainingNew, 1)
        XCTAssertEqual(tomorrow.target, 1)
        // Losing access cannot grant another set of new introductions today.
        let restricted = DailyLearningProgress(phrases: [phrases[3]], states: next, goal: 2, now: start, calendar: calendar)
        XCTAssertEqual(restricted.remainingNew, 0)
        XCTAssertTrue(MemoryScheduler.queue(phrases: [phrases[3]], states: next, focus: "work", now: start,
                                            calendar: calendar, dailyNewLimit: 2).isEmpty)
    }

    func testUnifiedAnswerDefaultsMigrateOldIndependentPreferences() throws {
        for (meaning, examples) in [(false, false), (false, true), (true, false), (true, true)] {
            var data = LearningData()
            data.todayShowsMeaning = meaning
            data.todayShowsExamples = examples
            let decoded = try JSONDecoder().decode(LearningData.self, from: JSONEncoder().encode(data))
            XCTAssertEqual(decoded.showsAnswerByDefault, meaning || examples)
            XCTAssertNil(decoded.dailyNewGoal)
            XCTAssertEqual(decoded.newPhrasesPerDay, 5)
            data.todayShowsAnswer = false
            XCTAssertFalse(try JSONDecoder().decode(LearningData.self, from: JSONEncoder().encode(data)).showsAnswerByDefault)
        }
    }

    func testGoodRecallExpandsFromOneToSixDaysThenUsesEase() {
        var state = MemoryScheduler.review(nil, rating: .good, now: now)
        XCTAssertEqual(state.intervalDays, 1)
        state = MemoryScheduler.review(state, rating: .good, now: state.due)
        XCTAssertEqual(state.intervalDays, 6)
        state = MemoryScheduler.review(state, rating: .good, now: state.due)
        XCTAssertEqual(state.intervalDays, 15)
        XCTAssertEqual(state.repetitions, 3)
    }

    func testDifficultyChangesFutureSpacingAndAgainRelearns() {
        let old = MemoryReview(due: now, intervalDays: 10, repetitions: 3, introduced: now, lastReviewed: now)
        let hard = MemoryScheduler.review(old, rating: .hard, now: now)
        let good = MemoryScheduler.review(old, rating: .good, now: now)
        let easy = MemoryScheduler.review(old, rating: .easy, now: now)
        XCTAssertLessThan(hard.intervalDays, good.intervalDays)
        XCTAssertLessThan(good.intervalDays, easy.intervalDays)
        XCTAssertLessThan(hard.ease, good.ease)
        XCTAssertGreaterThan(easy.ease, good.ease)
        let again = MemoryScheduler.review(old, rating: .again, now: now)
        XCTAssertEqual(again.due.timeIntervalSince(now), 600)
        XCTAssertEqual(again.repetitions, 0)
        XCTAssertEqual(again.lapses, 1)
        let relearned = MemoryScheduler.review(again, rating: .good, now: again.due)
        XCTAssertEqual(relearned.intervalDays, 1)
        XCTAssertEqual(relearned.introduced, old.introduced)
    }

    func testEarlyPracticeDoesNotExtendDueDateAndIntervalsRemainBounded() {
        let old = MemoryScheduler.review(nil, rating: .easy, now: now)
        let early = MemoryScheduler.review(old, rating: .easy, now: now.addingTimeInterval(60))
        XCTAssertEqual(early.due, old.due)
        XCTAssertEqual(early.intervalDays, old.intervalDays)
        XCTAssertEqual(early.repetitions, old.repetitions)
        var hard = old, easy = old
        for _ in 0..<100 {
            hard = MemoryScheduler.review(hard, rating: .hard, now: hard.due)
            easy = MemoryScheduler.review(easy, rating: .easy, now: easy.due)
        }
        XCTAssertEqual(hard.ease, 1.3)
        XCTAssertEqual(easy.ease, 3)
        XCTAssertEqual(easy.intervalDays, 36_500)
    }

    func testDueQueueDailyLimitMidnightAndAccessBoundary() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let phrases = try Catalog.load().filter { AccessPolicy.allows($0, purchased: false) }
        var states: [String: MemoryReview] = [:]
        let start = MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: now, calendar: calendar)
        XCTAssertEqual(start.count, 5)
        for phrase in start { states[phrase.id] = MemoryScheduler.review(nil, rating: .good, now: now) }
        XCTAssertTrue(MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: now, calendar: calendar).isEmpty)
        states[start[0].id] = MemoryScheduler.review(states[start[0].id], rating: .again, now: now)
        let due = MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: now.addingTimeInterval(600), calendar: calendar)
        XCTAssertEqual(due.map(\.id), [start[0].id])
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
        let next = MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: tomorrow, calendar: calendar)
        XCTAssertEqual(next.count, 10)
        XCTAssertEqual(Set(next.prefix(5).map(\.id)), Set(start.map(\.id)))
        let paid = try XCTUnwrap(Catalog.load().first { !AccessPolicy.allows($0, purchased: false) })
        states[paid.id] = MemoryReview(due: .distantPast, introduced: now, lastReviewed: now)
        XCTAssertFalse(MemoryScheduler.queue(phrases: phrases, states: states, focus: "work", now: tomorrow).contains { $0.id == paid.id })
    }

    @MainActor func testMemoryPersistenceIsSeparateFromSpeakingAndLegacyDataDecodes() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let store = LearningStore(file: file)
        let phrase = try XCTUnwrap(store.phrases.first)
        store.rate(phrase, .effort, mode: "spoken", now: now)
        let speakingDue = store.data.reviews[phrase.id]?.due
        store.rateMemory(phrase, .easy, now: now)
        let reopened = LearningStore(file: file)
        XCTAssertEqual(reopened.data.memoryReviews?[phrase.id]?.intervalDays, 4)
        XCTAssertEqual(reopened.data.reviews[phrase.id]?.due, speakingDue)
        XCTAssertEqual(reopened.data.events.last?.mode, "memory")
        XCTAssertEqual(reopened.streak(now: now).current, 1)
        let encoded = try JSONEncoder().encode(reopened.data)
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        legacy.removeValue(forKey: "memoryReviews")
        let decoded = try JSONDecoder().decode(LearningData.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertNil(decoded.memoryReviews)
        XCTAssertEqual(decoded.reviews[phrase.id]?.due, speakingDue)
    }
}
