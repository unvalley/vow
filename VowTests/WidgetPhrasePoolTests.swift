import XCTest
@testable import Vow

final class WidgetPhrasePoolTests: XCTestCase {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        return result
    }
    private func date(_ day: Int, _ hour: Int = 12) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 9, day: day, hour: hour))!
    }
    private func review(due: Int) -> MemoryReview {
        MemoryReview(due: date(due), introduced: date(1), lastReviewed: date(1))
    }

    func testTheSoonestReviewComesFirstAndUnseenPhrasesFollow() throws {
        let phrases = Array(try Catalog.load().prefix(6))
        var data = LearningData()
        data.memoryReviews = [
            phrases[3].id: review(due: 20),
            phrases[1].id: review(due: 11),
            phrases[5].id: review(due: 14)
        ]
        let pool = WidgetPhrasePool(data: data, phrases: phrases, typeface: .newYork)
        let ids = pool.phrases.map(\.id)
        XCTAssertEqual(Array(ids.prefix(3)), [phrases[1].id, phrases[5].id, phrases[3].id])
        XCTAssertEqual(Set(ids.dropFirst(3)), Set([phrases[0], phrases[2], phrases[4]].map(\.id)))
    }

    func testThePoolIsCappedAndCarriesTheLearnersFaceAndLanguage() throws {
        let phrases = try Catalog.load()
        var data = LearningData()
        data.japaneseHints = true
        let pool = WidgetPhrasePool(data: data, phrases: phrases, typeface: .georgia)
        XCTAssertEqual(pool.phrases.count, WidgetPhrasePool.size)
        XCTAssertEqual(pool.typeface, .georgia)
        let first = try XCTUnwrap(pool.phrases.first)
        let source = try XCTUnwrap(phrases.first { $0.id == first.id })
        XCTAssertEqual(first.meaning, source.japanese)
        XCTAssertNil(first.lead, "A Japanese explanation is already terse and leads with nothing.")
    }

    func testAnEnglishExplanationKeepsItsShortEquivalent() throws {
        let phrases = try Catalog.load()
        var data = LearningData()
        data.japaneseHints = false
        let pool = WidgetPhrasePool(data: data, phrases: phrases, typeface: .newYork)
        let withGloss = try XCTUnwrap(pool.phrases.first { $0.lead != nil })
        let source = try XCTUnwrap(phrases.first { $0.id == withGloss.id })
        XCTAssertEqual(withGloss.lead, source.gloss)
        XCTAssertEqual(withGloss.meaning, source.easyEnglish)
    }

    func testTheExpressionTurnsOnAFixedClockAndWrapsAround() throws {
        let phrases = Array(try Catalog.load().prefix(3))
        let pool = WidgetPhrasePool(data: LearningData(), phrases: phrases, typeface: .newYork)
        let start = Date(timeIntervalSince1970: 0)
        let step = WidgetPhrasePool.interval
        let shown = (0..<6).map { pool.phrase(at: start.addingTimeInterval(step * Double($0)))?.id }
        XCTAssertEqual(Array(shown.prefix(3)), Array(shown.suffix(3)), "The pool repeats once it runs out.")
        XCTAssertEqual(Set(shown.compactMap { $0 }).count, 3, "Every expression gets its turn.")
        // Within one interval nothing changes, so a reload part-way through shows the same expression.
        XCTAssertEqual(pool.phrase(at: start)?.id, pool.phrase(at: start.addingTimeInterval(step - 1))?.id)
    }

    func testTurnDatesLandOnTheIntervalAndCoverThePool() throws {
        let phrases = Array(try Catalog.load().prefix(4))
        let pool = WidgetPhrasePool(data: LearningData(), phrases: phrases, typeface: .newYork)
        let now = date(10, 13)
        let dates = pool.turnDates(from: now)
        XCTAssertEqual(dates.count, 4)
        XCTAssertTrue(dates.allSatisfy { $0 > now })
        XCTAssertEqual(dates, dates.sorted())
        for turn in dates {
            XCTAssertEqual(turn.timeIntervalSince1970
                .truncatingRemainder(dividingBy: WidgetPhrasePool.interval), 0, accuracy: 0.001)
        }
        // Each entry is the moment its expression takes over.
        XCTAssertNotEqual(pool.phrase(at: dates[0])?.id, pool.phrase(at: now)?.id)
    }

    func testAnEmptyPoolShowsNothingRatherThanCrashing() {
        let pool = WidgetPhrasePool()
        XCTAssertNil(pool.phrase(at: date(10)))
        XCTAssertTrue(pool.turnDates(from: date(10)).isEmpty)
    }

    func testThePoolSurvivesTheSharedFileRoundTrip() throws {
        let url = URL.temporaryDirectory.appending(path: "phrases-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let pool = WidgetPhrasePool(data: LearningData(), phrases: try Catalog.load(), typeface: .charter)
        try WidgetSharing.write(pool, to: url)
        XCTAssertEqual(WidgetSharing.read(WidgetPhrasePool.self, from: url), pool)
        XCTAssertNotEqual(WidgetPhrasePool.fileName, CompanionSnapshot.fileName,
                          "Each widget keeps its own file so one reload never spends the other's budget.")
    }
}
