import XCTest
@testable import Izzy

final class ProOfferTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_790_000_000)
    private func met(_ phrases: [Phrase]) -> [String: MemoryReview] {
        Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, MemoryReview(due: now, introduced: now, lastReviewed: now)) })
    }

    func testCountsTheFreePlanInTheLearnersOwnNumbers() throws {
        let phrases = try Catalog.load()
        let free = phrases.filter { AccessPolicy.allows($0, purchased: false) }
        let offer = ProOffer(phrases: phrases, memory: met(Array(free.prefix(7))), kind: .all)
        XCTAssertEqual(offer.freeLearned, 7)
        XCTAssertEqual(offer.freeTotal, AccessPolicy.freeIDs.count)
        XCTAssertEqual(offer.lockedCount, phrases.count - free.count, "every Pro expression is still to come")
    }

    func testNextIsWhatHomeWouldIntroduceWithPro() throws {
        let phrases = try Catalog.load()
        let offer = ProOffer(phrases: phrases, memory: [:], kind: .idioms, levels: PhraseLevelFilter(levels: [.a2]), count: 3)
        XCTAssertEqual(offer.next.count, 3)
        for phrase in offer.next {
            XCTAssertFalse(AccessPolicy.allows(phrase, purchased: false), "only Pro expressions are offered")
            XCTAssertTrue(phrase.isIdiom)
            XCTAssertEqual(phrase.difficulty, .a2, "a level the free plan lacks is still the learner's choice")
        }
        // The daily queue's order with Pro open and nothing met yet.
        let visible = HomeDerivation.visible(phrases, purchased: true, kind: .idioms, levels: PhraseLevelFilter(levels: [.a2]))
        let queue = MemoryScheduler.queue(phrases: visible, states: [:], focus: "", now: now, dailyNewLimit: 3)
        XCTAssertEqual(offer.next.map(\.id), queue.map(\.id))
    }

    func testMetProExpressionsAreNotOfferedAgain() throws {
        let phrases = try Catalog.load()
        let first = ProOffer(phrases: phrases, memory: [:], kind: .phrasalVerbs, count: 1).next
        let after = ProOffer(phrases: phrases, memory: met(first), kind: .phrasalVerbs, count: 1).next
        XCTAssertNotEqual(first.map(\.id), after.map(\.id), "a phrase met during a trial or before a refund is not news")
        XCTAssertEqual(ProOffer(phrases: phrases, memory: met(first), kind: .phrasalVerbs).paused, 1, "its reviews wait for Pro")
    }

    func testEveryLevelFromA2HasFreeExpressionsToTry() throws {
        let free = try Catalog.load().filter { AccessPolicy.allows($0, purchased: false) }
        for level in [PhraseDifficulty.a2, .b1, .b2, .c1] {
            XCTAssertGreaterThanOrEqual(free.filter { $0.difficulty == level }.count, 5, "\(level.rawValue) has too little to try for free")
        }
    }

    func testTheTrialLastsTheDaysItStates() {
        XCTAssertEqual(AccessPolicy.trialEnd(startedAt: now).timeIntervalSince(now), TimeInterval(AccessPolicy.trialDays) * 86_400)
    }

    func testTheTrialNoticeComesTheDayBeforeAtTheReminderTime() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "Asia/Tokyo"))
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 8)))
        let end = AccessPolicy.trialEnd(startedAt: start)
        let notice = try XCTUnwrap(AccessPolicy.trialNotice(endingAt: end, hour: 21, minute: 0, now: start, calendar: calendar))
        XCTAssertEqual(calendar.dateComponents([.month, .day, .hour], from: notice), DateComponents(month: 10, day: 30, hour: 21))
        XCTAssertNil(AccessPolicy.trialNotice(endingAt: end, hour: 21, minute: 0, now: notice, calendar: calendar), "never in the past")
    }

    func testTheFreePlanFinishesOnlyWhenNothingNewIsLeft() throws {
        let phrases = try Catalog.load()
        let visible = HomeDerivation.visible(phrases, purchased: false, kind: .all)
        XCTAssertFalse(ProOffer.freePlanFinished(visible: visible, memory: met(Array(visible.dropLast())), purchased: false))
        XCTAssertTrue(ProOffer.freePlanFinished(visible: visible, memory: met(visible), purchased: false))
        XCTAssertFalse(ProOffer.freePlanFinished(visible: visible, memory: met(visible), purchased: true), "Pro has more to learn")
        XCTAssertFalse(ProOffer.freePlanFinished(visible: [], memory: [:], purchased: false), "an empty filter is not a finished plan")
    }
}
