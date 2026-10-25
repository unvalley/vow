import XCTest
@testable import Izzy

final class CompletionNextStepTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)
    private typealias Step = CompletionNextStep

    func testAFirstFinishedDayAsksForTheReminderBeforeTheTrial() {
        let state = Step.State(trialOffered: true)
        XCTAssertEqual(Step.choose(state, now: now), .reminder, "coming back comes before paying")
        var reminded = state
        reminded.remindersOn = true
        XCTAssertEqual(Step.choose(reminded, now: now), .trial)
        var denied = state
        denied.notificationsDenied = true
        XCTAssertEqual(Step.choose(denied, now: now), .trial, "a refusal in iOS Settings is not asked about again")
    }

    func testNotNowWaitsAWeek() {
        var state = Step.State(reminderSnoozed: now.addingTimeInterval(-Step.snooze + 60), trialOffered: true,
                               trialSnoozed: now.addingTimeInterval(-60))
        XCTAssertNil(Step.choose(state, now: now))
        state.reminderSnoozed = now.addingTimeInterval(-Step.snooze)
        XCTAssertEqual(Step.choose(state, now: now), .reminder)
    }

    func testTheEndOfTheFreePlanComesFirstAndOnlyOnTheFreePlan() {
        let finished = Step.State(freePlanFinished: true, trialOffered: true)
        XCTAssertEqual(Step.choose(finished, now: now), .freePlanFinished)
        XCTAssertEqual(Step.choose(Step.State(pausedProReviews: 3), now: now), .proReviewsWaiting)
        var pro = finished
        pro.hasFullAccess = true
        pro.trialOffered = false
        XCTAssertEqual(Step.choose(pro, now: now), .reminder, "Pro learners still get the reminder")
        pro.remindersOn = true
        XCTAssertNil(Step.choose(pro, now: now))
    }

    func testTheReminderComesBackTheNextDayAtTheHourTheDayWasFinished() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        for (hour, minute, expected) in [(21, 38, (21, 40)), (22, 55, (23, 0)), (23, 57, (23, 59)), (7, 0, (7, 5))] {
            let finished = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: hour, minute: minute, second: 30)))
            let time = Step.reminderTime(for: finished, calendar: calendar)
            XCTAssertEqual(time.hour, expected.0)
            XCTAssertEqual(time.minute, expected.1)
            // The day's last answer, rated Good as the day finished, falls due a day later; the reminder must not skip that day.
            let review = MemoryScheduler.review(nil, rating: .good, now: finished)
            let input = ReviewReminderInput(preferences: .init(enabled: true, hour: time.hour, minute: time.minute),
                                            reviews: ["p": review], allowedIDs: ["p"], japanese: true)
            let first = try XCTUnwrap(ReviewReminderPlan.make(input, now: finished, calendar: calendar).first)
            XCTAssertTrue(calendar.isDate(first.date, inSameDayAs: review.due), "finished at \(hour):\(minute)")
        }
    }
}
