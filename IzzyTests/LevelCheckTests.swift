import XCTest
@testable import Izzy

final class LevelCheckTests: XCTestCase {
    /// A fixed sequence, so a failure can be replayed.
    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }

    func testAsksAPhrasalVerbAndAnIdiomAtEachLevelEasiestFirst() throws {
        let phrases = try Catalog.load()
        for language in MeaningLanguage.allCases {
            for seed in 1...20 {
                var generator = Seeded(state: UInt64(seed))
                let check = LevelCheck(phrases: phrases, language: language, using: &generator)
                XCTAssertEqual(check.questions.count, 8)
                XCTAssertEqual(check.questions.map(\.level), [.a2, .a2, .b1, .b1, .b2, .b2, .c1, .c1])
                XCTAssertEqual(check.questions.map(\.phrase.isIdiom), [false, true, false, true, false, true, false, true])
                for question in check.questions {
                    XCTAssertEqual(Set(question.choices).count, 4, "four different meanings")
                    XCTAssertEqual(question.phrase.difficulty, question.level)
                    let own = language == .japanese ? question.phrase.japanese
                        : (question.phrase.lead(in: .easyEnglish) ?? question.phrase.easyEnglish)
                    XCTAssertEqual(question.choices[question.answer], own)
                }
            }
        }
    }

    func testRecommendsTheFirstLevelWithAMissAndTheOneAbove() {
        let asked: [PhraseDifficulty: Int] = [.a2: 2, .b1: 2, .b2: 2, .c1: 2]
        XCTAssertEqual(LevelCheck.recommendation(correct: [.a2: 2, .b1: 1], asked: asked), [.b1, .b2])
        XCTAssertEqual(LevelCheck.recommendation(correct: [.a2: 2, .b1: 2, .b2: 2, .c1: 1], asked: asked), [.b2, .c1])
        XCTAssertEqual(LevelCheck.recommendation(correct: [.a2: 2, .b1: 2, .b2: 2, .c1: 2], asked: asked), [.b2, .c1])
        XCTAssertEqual(LevelCheck.recommendation(correct: [.a2: 1], asked: asked), [.a2, .b1])
        XCTAssertEqual(LevelCheck.recommendation(correct: [:], asked: asked), [.a1, .a2], "knowing none of the easiest starts at A1")
    }
}
