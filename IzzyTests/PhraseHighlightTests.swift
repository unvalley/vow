import XCTest
@testable import Izzy

final class PhraseHighlightTests: XCTestCase {
    func testIdiomsMatchWholeChunksWithoutPairingUnrelatedWords() throws {
        let phrases = try Catalog.load()
        let ice = try XCTUnwrap(phrases.first { $0.phrase == "break the ice" })
        let example = "Her joke broke the ice."
        XCTAssertEqual(PhraseHighlight.ranges(in: example, phrase: ice).map { String(example[$0]) }, ["broke the ice"])
        XCTAssertTrue(PhraseHighlight.ranges(in: "Break time is over and the ice is melting.", phrase: ice).isEmpty)
        let run = try XCTUnwrap(phrases.first { $0.phrase == "in the long run" })
        XCTAssertTrue(PhraseHighlight.ranges(in: "In the garden we took a long run.", phrase: run).isEmpty)
    }

    private func highlighted(_ example: String, _ expressions: String...) -> [String] {
        PhraseHighlight.ranges(in: example, expressions: expressions).map { String(example[$0]) }
    }

    func testHyphenatedIdiomsAndTrailingPossessivesKeepTheirPunctuation() throws {
        let phrases = try Catalog.load()
        for (name, example, expected) in [
            ("a double-edged sword", "This flexibility is a double-edged sword.", "a double-edged sword"),
            ("caught red-handed", "He was caught red-handed taking the cake.", "caught red-handed"),
            ("at your wits' end", "Are you at your wits' end with that repair?", "at your wits' end")
        ] {
            let phrase = try XCTUnwrap(phrases.first { $0.phrase == name })
            XCTAssertEqual(PhraseHighlight.ranges(in: example, phrase: phrase).map { String(example[$0]) }, [expected])
        }
        let phrase = try XCTUnwrap(phrases.first { $0.phrase == "a double-edged sword" })
        XCTAssertTrue(PhraseHighlight.ranges(in: "A double bed stood beside the edged sword.", phrase: phrase).isEmpty)
    }

    func testInflectionCaseAndWordBoundaries() {
        XCTAssertEqual(highlighted("The deadline crept up on us.", "creep up on"), ["crept up on"])
        XCTAssertEqual(highlighted("The teacher won me over.", "win over"), ["won", "over"])
        XCTAssertEqual(highlighted("She BROUGHT up a concern.", "bring up"), ["BROUGHT up"])
        XCTAssertEqual(highlighted("He's taking off now.", "take off"), ["taking off"])
        XCTAssertEqual(highlighted("She tries out new ideas.", "try out"), ["tries out"])
        XCTAssertEqual(highlighted("They're tying up the boat.", "tie up"), ["tying up"])
        XCTAssertEqual(highlighted("She was lying down.", "lie down"), ["lying down"])
        XCTAssertTrue(highlighted("The setup is outside.", "set up").isEmpty)
    }

    func testSeparatedObjectsStayPlainAndOccurrencesAreIndependent() {
        XCTAssertEqual(highlighted("She brought the issue up, then brought it up again.", "bring up"), ["brought", "up", "brought", "up"])
        XCTAssertEqual(highlighted("We chalked the error up to inexperience.", "chalk up to"), ["chalked", "up to"])
        XCTAssertEqual(highlighted("That shirt goes perfectly with those pants.", "go with"), ["goes", "with"])
        XCTAssertEqual(highlighted("Look at him looking up.", "look up"), ["looking up"])
    }

    func testAliasesReflexivesAndUnicodePreserveOriginalRanges() {
        XCTAssertEqual(highlighted("Please log out, then log off.", "log off", "log out"), ["log out", "log off"])
        XCTAssertEqual(highlighted("彼は “fended for himself.” 🌿", "fend for oneself"), ["fended for himself"])
        XCTAssertEqual(highlighted("I’ll bring it up.", "bring up"), ["bring", "up"])
    }

    func testNeverMatchesAcrossClausesOrRevealsMaskedAnswers() {
        for text in ["Look at me. We need to go up.", "Look here; lift it up.", "Look over there, then go up.", "Look here! Go up."] {
            XCTAssertTrue(highlighted(text, "look up").isEmpty, text)
        }
        XCTAssertTrue(highlighted("Can I ____ ____ one thing?", "point out").isEmpty)
    }

    func testEveryCatalogExampleContainsItsPhrase() throws {
        var count = 0
        for phrase in try Catalog.load() {
            let examples = phrase.examples + (phrase.referenceUsage.map { [$0.example] } ?? [])
            for example in examples {
                count += 1
                let ranges = PhraseHighlight.ranges(in: example, phrase: phrase)
                XCTAssertFalse(ranges.isEmpty, "\(phrase.phrase): \(example)")
                for (a, b) in zip(ranges, ranges.dropFirst()) { XCTAssertLessThanOrEqual(a.upperBound, b.lowerBound) }
            }
        }
        XCTAssertEqual(count, 5573)
    }

    func testPatternsHighlightThePhraseAndStartLowercase() throws {
        let phrases = try Catalog.load()
        let dozen = try XCTUnwrap(phrases.first { $0.phrase == "a dime a dozen" })
        XCTAssertEqual(dozen.pattern, "something is a dime a dozen")
        let range = try XCTUnwrap(PhraseHighlight.ranges(in: dozen.pattern, phrase: dozen).first)
        XCTAssertEqual(String(dozen.pattern[range]), "a dime a dozen")
        let bringUp = try XCTUnwrap(phrases.first { $0.phrase == "bring up" })
        XCTAssertEqual(bringUp.pattern, "can I bring something up?")
        XCTAssertFalse(PhraseHighlight.ranges(in: bringUp.pattern, phrase: bringUp).isEmpty)
        // A frame that starts with "I" keeps its capital.
        let getAcross = try XCTUnwrap(phrases.first { $0.phrase == "get across" })
        XCTAssertEqual(getAcross.pattern.first, "w")
        // Every pattern keeps its text apart from the first letter, and none starts with a lowercase "i" pronoun.
        for phrase in phrases where !phrase.frame.isEmpty {
            XCTAssertEqual(phrase.pattern.dropFirst(), phrase.frame.dropFirst(), phrase.id)
            XCTAssertFalse(phrase.pattern.hasPrefix("i ") || phrase.pattern.hasPrefix("i'") || phrase.pattern.hasPrefix("i’"), phrase.id)
        }
    }

}
