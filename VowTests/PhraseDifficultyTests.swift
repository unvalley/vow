import XCTest
@testable import Vow

final class PhraseDifficultyTests: XCTestCase {
    func testCatalogHasAnExplicitLevelForEveryEntryAndStableSenseAnchors() throws {
        let phrases = try Catalog.load()
        XCTAssertEqual(phrases.count, 1300)
        XCTAssertTrue(phrases.allSatisfy { $0.difficulty != nil })
        for (phrase, level) in [("get up", PhraseDifficulty.a1), ("look for", .a2), ("bring up", .b1), ("rule out", .b2), ("gloss over", .c1)] {
            XCTAssertEqual(phrases.first { $0.phrase == phrase }?.difficulty, level, phrase)
        }
        XCTAssertEqual(Set(phrases.compactMap(\.difficulty)), Set([.a1, .a2, .b1, .b2, .c1]))
        XCTAssertEqual(phrases.first { $0.phrase == "stand up" }?.difficulty, .b2)
        XCTAssertEqual(phrases.first { $0.phrase == "pay for" }?.difficulty, .b2)
        var legacy = try JSONSerialization.jsonObject(with: JSONEncoder().encode(phrases[0])) as! [String: Any]
        legacy.removeValue(forKey: "difficulty")
        XCTAssertNil(try JSONDecoder().decode(Phrase.self, from: JSONSerialization.data(withJSONObject: legacy)).difficulty)
    }

    func testDifficultyIntersectsSearchSavedAndFreeAccessIncludingVerbFamilies() throws {
        let available = try Catalog.load().filter { AccessPolicy.allows($0, purchased: false) }
        let saved = Set(available.prefix(30).map(\.id))
        for level in PhraseDifficulty.allCases {
            for collection in LibraryCollection.allCases {
                for groupByVerb in [false, true] {
                let grouped = groupByVerb && collection != .idioms
                let results = LibraryResults(phrases: available, collection: collection, query: "look", sort: .alphabetical,
                                             reviews: [:], saved: saved, difficulty: level, groupByVerb: groupByVerb)
                let actual = grouped ? results.groups.flatMap(\.phrases) : results.phrases
                let expected = available.filter {
                    $0.difficulty == level && $0.matches("look") && (!grouped || !$0.isIdiom) && (collection != .phrasalVerbs || !$0.isIdiom) && (collection != .idioms || $0.isIdiom) && (collection != .saved || saved.contains($0.id))
                }
                XCTAssertEqual(Set(actual.map(\.id)), Set(expected.map(\.id)))
                XCTAssertTrue(actual.allSatisfy { $0.difficulty == level && AccessPolicy.freeIDs.contains($0.id) })
                }
            }
        }
    }

    @MainActor func testDisplayPreferencePersistsIndependentlyOfMeaningAndProgress() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "learning.json")
        let store = LearningStore(file: file)
        XCTAssertEqual(store.data.difficultyDisplay, .cefr)
        let phrase = try XCTUnwrap(store.phrases.first)
        store.toggleSaved(phrase.id)
        store.rateMemory(phrase, .good)
        for scale in DifficultyScale.allCases {
            store.configure(difficultyScale: scale)
            store.configure(meaningLanguage: .easyEnglish)
            let reloaded = LearningStore(file: file)
            XCTAssertEqual(reloaded.data.difficultyDisplay, scale)
            XCTAssertEqual(reloaded.data.meaningLanguage, .easyEnglish)
            XCTAssertTrue(reloaded.data.saved.contains(phrase.id))
            XCTAssertNotNil(reloaded.data.memoryReviews?[phrase.id])
        }
        var legacy = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        legacy.removeValue(forKey: "difficultyScale")
        let old = try JSONDecoder().decode(LearningData.self, from: JSONSerialization.data(withJSONObject: legacy))
        XCTAssertEqual(old.difficultyDisplay, .cefr)
        XCTAssertTrue(old.saved.contains(phrase.id))
    }

    func testScoreReferencesDoNotInventUnsupportedBands() {
        XCTAssertNil(PhraseDifficulty.a1.reference(for: .ielts))
        XCTAssertNil(PhraseDifficulty.a2.reference(for: .ielts))
        XCTAssertNil(PhraseDifficulty.c2.reference(for: .eiken))
        XCTAssertEqual(PhraseDifficulty.a2.label(for: .ielts), "A2 · Elementary")
        XCTAssertEqual(PhraseDifficulty.b2.reference(for: .toefl), "4–4.5")
        XCTAssertEqual(PhraseDifficulty.b1.reference(for: .eiken), "2級")
        XCTAssertEqual(PhraseDifficulty.a1.reference(for: .eiken), "3級")
        XCTAssertEqual(PhraseDifficulty.a2.reference(for: .eiken), "準2級・準2級プラス")
        XCTAssertEqual(PhraseDifficulty.b2.reference(for: .eiken), "準1級")
        XCTAssertEqual(PhraseDifficulty.c1.label(for: .eiken), "C1 · 英検 ≈1級")
    }
}
