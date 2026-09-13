import XCTest
@testable import Vow

final class ReviewReminderPlanTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return result
    }
    private func date(_ value: String) -> Date { ISO8601DateFormatter().date(from: value)! }
    private func input(_ dues: [String: Date], enabled: Bool = true) -> ReviewReminderInput {
        .init(preferences: .init(enabled: enabled),
              reviews: dues.mapValues { MemoryReview(due: $0, introduced: $0, lastReviewed: $0) },
              allowedIDs: Set(dues.keys), japanese: false)
    }

    func testUsesSM2DeadlinesWithoutNotifyingEarly() {
        let now = date("2026-09-13T10:00:00+09:00")
        for rating in MemoryRating.allCases {
            let review = MemoryScheduler.review(nil, rating: rating, now: now)
            let plan = ReviewReminderPlan.make(input(["a": review.due]), now: now, calendar: calendar)
            XCTAssertEqual(plan.count, 1)
            XCTAssertGreaterThanOrEqual(plan[0].date, review.due)
            XCTAssertEqual(calendar.component(.hour, from: plan[0].date), 19)
            XCTAssertLessThan(plan[0].date.timeIntervalSince(review.due), 86_400)
        }
    }

    func testGroupsDueCardsAndCarriesUnreviewedCount() {
        let now = date("2026-09-13T10:00:00+09:00")
        let plan = ReviewReminderPlan.make(input([
            "overdue": now.addingTimeInterval(-86_400),
            "today": date("2026-09-13T18:30:00+09:00"),
            "late": date("2026-09-13T20:00:00+09:00"),
            "tomorrow": date("2026-09-14T14:00:00+09:00")
        ]), now: now, calendar: calendar)
        XCTAssertEqual(plan, [
            .init(date: date("2026-09-13T19:00:00+09:00"), count: 2),
            .init(date: date("2026-09-14T19:00:00+09:00"), count: 4)
        ])
    }

    func testPastTimeOffEmptyAndRevokedAccess() {
        let now = date("2026-09-13T21:00:00+09:00")
        var state = input(["free": now.addingTimeInterval(-3600), "pro": now])
        state.allowedIDs = ["free"]
        XCTAssertEqual(ReviewReminderPlan.make(state, now: now, calendar: calendar), [
            .init(date: date("2026-09-14T19:00:00+09:00"), count: 1)
        ])
        state.preferences.enabled = false
        XCTAssertTrue(ReviewReminderPlan.make(state, now: now).isEmpty)
        XCTAssertTrue(ReviewReminderPlan.make(input([:]), now: now).isEmpty)
        state.preferences.enabled = true
        state.allowedIDs = []
        XCTAssertTrue(ReviewReminderPlan.make(state, now: now).isEmpty)
    }

    func testDSTGapTimezoneAndQueueLimit() {
        var ny = Calendar(identifier: .gregorian)
        ny.timeZone = TimeZone(identifier: "America/New_York")!
        let now = date("2026-03-08T00:00:00-05:00")
        var state = input(["a": now])
        state.preferences.hour = 2
        state.preferences.minute = 30
        let spring = ReviewReminderPlan.make(state, now: now, calendar: ny)
        XCTAssertEqual(spring.first?.date, date("2026-03-08T03:00:00-04:00"))
        var autumn = input(["a": date("2026-11-01T01:40:00-04:00")])
        autumn.preferences.hour = 1
        autumn.preferences.minute = 30
        let fall = ReviewReminderPlan.make(autumn, now: date("2026-11-01T00:00:00-04:00"), calendar: ny)
        XCTAssertEqual(fall[0].date, date("2026-11-02T01:30:00-05:00"))
        let many = input(Dictionary(uniqueKeysWithValues: (0..<100).map { (String($0), now.addingTimeInterval(Double($0) * 86_400)) }))
        let plan = ReviewReminderPlan.make(many, now: now, calendar: calendar)
        XCTAssertEqual(plan.count, 32)
        XCTAssertEqual(Set(plan.map { calendar.startOfDay(for: $0.date) }).count, 32)
        XCTAssertNotEqual(ReviewReminderPlan.make(state, now: now, calendar: calendar)[0].date, spring[0].date)
    }

    @MainActor func testPreferencesPersistAndLegacyFilesDefaultOff() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let store = LearningStore(file: file)
        XCTAssertFalse(store.data.reminderPreferences.enabled)
        store.configureReminders(enabled: true, hour: 8, minute: 45)
        let reopened = LearningStore(file: file)
        XCTAssertEqual(reopened.data.reminderPreferences, .init(enabled: true, hour: 8, minute: 45))
        var legacy = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(reopened.data)) as? [String: Any])
        legacy.removeValue(forKey: "reviewReminders")
        let decoded = try JSONDecoder().decode(LearningData.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(decoded.reminderPreferences, .init())
        store.configureReminders(enabled: false)
        XCTAssertFalse(LearningStore(file: file).data.reminderPreferences.enabled)
        XCTAssertEqual(store.data.reminderPreferences.hour, 8)
    }
}
