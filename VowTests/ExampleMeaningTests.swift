import XCTest
@testable import Vow

final class ExampleMeaningTests: XCTestCase {
    func testFreePhrasalVerbExamplesIncludeAuthoredOfflineSentenceMeanings() throws {
        let phrases = try Catalog.load()
        let free = phrases.filter { AccessPolicy.freePhraseIDs.contains($0.id) }
        XCTAssertEqual(free.count, 50)
        for phrase in free {
            let examples = phrase.examples + (phrase.referenceUsage.map { [$0.example] } ?? [])
            for example in examples {
                let meaning = try XCTUnwrap(phrase.exampleTranslations?[example], "Missing meaning for \(phrase.id): \(example)")
                XCTAssertFalse(meaning.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                XCTAssertNotEqual(meaning, example)
            }
        }
    }

    func testTranslationsStayBoundToExactSentencesIncludingSupplementalSenses() throws {
        for phrase in try Catalog.load() {
            let valid = Set(phrase.examples + (phrase.referenceUsage.map { [$0.example] } ?? []))
            XCTAssertTrue(Set(phrase.exampleTranslations?.keys.map { $0 } ?? []).isSubset(of: valid), phrase.id)
        }
        let phrase = try XCTUnwrap(Catalog.load().first { $0.id == "01-bring-up" })
        XCTAssertEqual(phrase.exampleTranslations?[phrase.reply], "終わる前に、締め切りについて話してもいいですか？")
        XCTAssertEqual(phrase.exampleTranslations?[phrase.transferReply], "少し話したいことがあります。会う時間は、今でも都合がいいですか？")
        XCTAssertNil(phrase.exampleTranslations?["A changed English example."])
    }
}
