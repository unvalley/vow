import XCTest
@testable import Izzy

final class RatingPromptTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)

    func testAsksOnlyAfterAStreakAndEnoughLearning() {
        XCTAssertTrue(RatingPrompt.shouldAsk(streak: 3, learned: 15, lastAsked: nil, now: now))
        XCTAssertFalse(RatingPrompt.shouldAsk(streak: 2, learned: 40, lastAsked: nil, now: now), "a first day is too early to judge")
        XCTAssertFalse(RatingPrompt.shouldAsk(streak: 10, learned: 14, lastAsked: nil, now: now))
    }

    func testAsksAgainOnlyAfterTheInterval() {
        let recent = now.addingTimeInterval(-RatingPrompt.interval + 60)
        let old = now.addingTimeInterval(-RatingPrompt.interval)
        XCTAssertFalse(RatingPrompt.shouldAsk(streak: 30, learned: 300, lastAsked: recent, now: now))
        XCTAssertTrue(RatingPrompt.shouldAsk(streak: 30, learned: 300, lastAsked: old, now: now))
    }
}
