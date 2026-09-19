import XCTest
@testable import Vow

final class CompanionSnapshotTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return result
    }
    private func date(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }
    private var now: Date { date(10) }
    /// A snapshot written on `day` after practising that day.
    private func snapshot(writtenOn day: Int, streak: Int = 4, remaining: Int) -> CompanionSnapshot {
        let start = calendar.startOfDay(for: date(day))
        return CompanionSnapshot(lastPracticeDay: start, streak: streak, day: start,
                                 introduced: 3, target: 5, remaining: remaining, accent: .blue)
    }

    func testFinishingTheDayCelebratesAndLeavingCardsKeepsWorking() {
        let done = snapshot(writtenOn: 10, remaining: 0).status(now: date(10, 20), calendar: calendar)
        XCTAssertEqual(done.mood, .celebrating)
        let partway = snapshot(writtenOn: 10, remaining: 4).status(now: date(10, 20), calendar: calendar)
        XCTAssertEqual(partway.mood, .working)
        XCTAssertEqual(partway.remaining, 4)
    }

    func testAnUntouchedDayOnlyUrgesOnceTheEveningMarkPasses() {
        // Practised yesterday, nothing today: the streak is still current and lapses at midnight.
        let waiting = snapshot(writtenOn: 9, remaining: 2).status(now: date(10, 9), calendar: calendar)
        XCTAssertEqual(waiting.mood, .resting)
        XCTAssertEqual(waiting.streak, 4, "Yesterday's streak stays current until today ends.")
        let evening = snapshot(writtenOn: 9, remaining: 2)
            .status(now: date(10, CompanionSnapshot.eveningHour), calendar: calendar)
        XCTAssertEqual(evening.mood, .urging)
    }

    func testAMissedDayLapsesAndDropsTheStreakToZero() {
        let status = snapshot(writtenOn: 8, remaining: 2).status(now: date(10, 9), calendar: calendar)
        XCTAssertEqual(status.mood, .lapsed)
        XCTAssertEqual(status.streak, 0)
    }

    func testNothingPracticedYetReadsAsFreshRatherThanLapsed() {
        let status = CompanionSnapshot().status(now: date(10), calendar: calendar)
        XCTAssertEqual(status.mood, .fresh)
        XCTAssertEqual(status.streak, 0)
    }

    func testCountsFromAnEarlierDayAreDroppedRatherThanRepeated() {
        // The widget crosses midnight without the app running: yesterday's 3 of 5 is not today's.
        let status = snapshot(writtenOn: 9, remaining: 2).status(now: date(10, 9), calendar: calendar)
        XCTAssertNil(status.introduced)
        XCTAssertNil(status.target)
        XCTAssertNil(status.remaining)
    }

    func testYesterdaysFinishedDayDoesNotStillReadAsComplete() {
        // remaining 0 from yesterday must not celebrate today, which has not been started.
        let status = snapshot(writtenOn: 9, remaining: 0).status(now: date(10, 9), calendar: calendar)
        XCTAssertEqual(status.mood, .resting)
    }

    func testRefreshDatesCoverTheEveningMarkAndTheNextMidnight() {
        let now = date(10, 9)
        let dates = snapshot(writtenOn: 10, remaining: 2).refreshDates(from: now, calendar: calendar)
        XCTAssertEqual(dates.first, date(10, CompanionSnapshot.eveningHour))
        XCTAssertTrue(dates.contains(calendar.startOfDay(for: date(11))))
        XCTAssertTrue(dates.allSatisfy { $0 > now })
        XCTAssertEqual(dates, dates.sorted())
    }

    func testTheSnapshotReportsTheSameStreakAsStats() throws {
        let phrases = Array(try Catalog.load().prefix(20))
        var data = LearningData()
        data.dailyNewGoal = 5
        let days = [8, 9, 10]
        data.events = days.map { .init(phraseID: phrases[0].id, date: date($0), rating: .ready, mode: "memory") }
        data.memoryReviews = [phrases[0].id: MemoryReview(due: date(12), introduced: date(10), lastReviewed: date(10))]
        let now = date(10, 21)
        let snapshot = CompanionSnapshot(data: data, phrases: phrases, now: now, calendar: calendar)
        let stats = LearningStats(data: data, phrases: phrases, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.streak, stats.streak.current)
        XCTAssertEqual(snapshot.lastPracticeDay, calendar.startOfDay(for: date(10)))
        XCTAssertEqual(snapshot.introduced, 1, "One phrase was introduced today.")
        XCTAssertEqual(snapshot.status(now: now, calendar: calendar).mood, .working)
    }

    /// Rating the same phrase twice in a day replaces its event in place, so the event count, the
    /// review count and the last event's date are all unchanged. A watcher listing those fields
    /// would miss the change; the revision cannot.
    @MainActor func testASameDayReRatingStillMovesTheRevision() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = LearningStore(file: directory.appending(path: "learning.json"))
        let phrase = try XCTUnwrap(store.phrases.first)
        store.rateMemory(phrase, .good, now: now)
        let afterFirst = (revision: store.revision, events: store.data.events.count,
                          last: store.data.events.last?.date)
        store.rateMemory(phrase, .again, now: now)
        XCTAssertEqual(store.data.events.count, afterFirst.events, "The same day's answer is replaced, not appended.")
        XCTAssertEqual(store.data.events.last?.date, afterFirst.last)
        XCTAssertGreaterThan(store.revision, afterFirst.revision)
    }

    func testTheSharedFileSurvivesARoundTrip() throws {
        let url = URL.temporaryDirectory.appending(path: "companion-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let original = snapshot(writtenOn: 10, remaining: 2)
        try WidgetSharing.write(original, to: url)
        XCTAssertEqual(WidgetSharing.read(CompanionSnapshot.self, from: url), original)
    }

    func testAnUnreadableFileFallsBackToNoSnapshot() throws {
        let url = URL.temporaryDirectory.appending(path: "companion-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        try Data("not json".utf8).write(to: url)
        XCTAssertNil(WidgetSharing.read(CompanionSnapshot.self, from: url))
        XCTAssertNil(WidgetSharing.read(CompanionSnapshot.self, from: URL.temporaryDirectory.appending(path: "absent.json")))
    }
}
