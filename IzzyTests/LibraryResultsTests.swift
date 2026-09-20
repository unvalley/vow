import XCTest
@testable import Izzy

final class LibraryResultsTests: XCTestCase {
    func testIdiomsAreSearchableSavedAndExcludedFromVerbFamilies() throws {
        let phrases = try Catalog.load()
        let idioms = phrases.filter(\.isIdiom)
        XCTAssertEqual(idioms.count, 1559)
        // Every lesson leads its English meaning with a one-to-three-word gloss that is not the phrase itself.
        XCTAssertTrue(phrases.allSatisfy { phrase in
            let gloss = phrase.gloss ?? ""
            return (1...3).contains(gloss.split(separator: " ").count) && gloss.lowercased() != phrase.phrase.lowercased()
        })
        XCTAssertEqual(phrases.first { $0.phrase == "look into" }?.lead(in: .easyEnglish), "investigate")
        XCTAssertNil(phrases.first { $0.phrase == "look into" }?.lead(in: .japanese))
        XCTAssertEqual(phrases.filter { !$0.isIdiom }.count, 1449)
        let phrase = try XCTUnwrap(idioms.first { $0.phrase == "break the ice" })
        for query in ["break", "緊張", "comfortable"] {
            let result = LibraryResults(phrases: phrases, collection: .idioms, query: query,
                                        sort: .alphabetical, reviews: [:], saved: [], difficulty: .b1)
            XCTAssertTrue(result.phrases.contains(phrase))
            XCTAssertTrue(result.phrases.allSatisfy { $0.isIdiom && $0.difficulty == .b1 })
        }
        let saved = LibraryResults(phrases: phrases, collection: .saved, query: "", sort: .alphabetical,
                                   reviews: [:], saved: [phrase.id])
        XCTAssertEqual(saved.phrases, [phrase])
        XCTAssertFalse(VerbGroup.groups(for: phrases).flatMap(\.phrases).contains(where: \.isIdiom))
        let verbs = LibraryResults(phrases: phrases, collection: .all, query: phrase.phrase,
                                   sort: .alphabetical, reviews: [:], saved: [], groupByVerb: true)
        XCTAssertTrue(verbs.isEmpty)
        let idiomsGrouped = LibraryResults(phrases: phrases, collection: .idioms, query: "",
                                           sort: .alphabetical, reviews: [:], saved: [], groupByVerb: true)
        XCTAssertTrue(idiomsGrouped.groups.isEmpty)
        XCTAssertEqual(idiomsGrouped.phrases.count, 1559)
        let decoded = try JSONDecoder().decode(Phrase.self, from: JSONEncoder().encode(phrase))
        XCTAssertEqual(decoded.kind, .idiom)
        let original = try XCTUnwrap(phrases.first)
        XCTAssertNil(original.kind)
        XCTAssertFalse(try JSONDecoder().decode(Phrase.self, from: JSONEncoder().encode(original)).isIdiom)
    }

    func testResultsPreserveSearchGroupsAndEverySortOrder() throws {
        let phrases = try Catalog.load()
        let saved = Set(phrases.enumerated().filter { $0.offset.isMultiple(of: 5) }.map { $0.element.id })
        let reviews = Dictionary(uniqueKeysWithValues: phrases.enumerated().compactMap { index, phrase in
            index.isMultiple(of: 3) ? (phrase.id, ReviewState(due: Date(timeIntervalSince1970: Double(index)), reviews: 2)) : nil
        })
        let queries = ["", " \n ", "look", " LOOK INTO ", "調べ", "round", "zzzz-no-match"]
        for collection in LibraryCollection.allCases {
            for sort in PhraseSort.allCases {
                for query in queries {
                    for groupByVerb in [false, true] {
                        let result = LibraryResults(phrases: phrases, collection: collection, query: query,
                                                    sort: sort, reviews: reviews, saved: saved, groupByVerb: groupByVerb)
                        let grouped = groupByVerb && collection != .idioms
                        let members = phrases.filter {
                            (collection != .saved || saved.contains($0.id)) && (collection != .idioms || $0.isIdiom) &&
                            (collection != .phrasalVerbs || !$0.isIdiom) && (!grouped || !$0.isIdiom)
                        }
                        let expectedPhrases = sort.ordered(members.filter { $0.matches(query) }, reviews: reviews)
                        XCTAssertEqual(result.isEmpty, expectedPhrases.isEmpty, "\(collection) \(sort) \(query) \(groupByVerb)")
                        if grouped {
                            let expectedGroups = sort.ordered(VerbGroup.groups(for: members).filter {
                                $0.phrases.contains { $0.matches(query) }
                            }, reviews: reviews)
                            XCTAssertEqual(result.groups.map(\.verb), expectedGroups.map(\.verb))
                            XCTAssertEqual(result.groups.map { $0.phrases.map(\.id) }, expectedGroups.map { $0.phrases.map(\.id) })
                            XCTAssertTrue(result.phrases.isEmpty)
                        } else {
                            XCTAssertEqual(result.phrases.map(\.id), expectedPhrases.map(\.id))
                            XCTAssertTrue(result.groups.isEmpty)
                        }
                    }
                }
            }
        }
    }

    func testSavedChangesAndReviewChangesAreVisibleOnNextProjection() throws {
        let phrases = try Catalog.load()
        let phrase = try XCTUnwrap(phrases.first { $0.phrase == "look into" })
        let empty = LibraryResults(phrases: phrases, collection: .saved, query: "", sort: .alphabetical, reviews: [:], saved: [])
        XCTAssertTrue(empty.isEmpty)
        let saved = LibraryResults(phrases: phrases, collection: .saved, query: "", sort: .alphabetical, reviews: [:], saved: [phrase.id])
        XCTAssertEqual(saved.phrases.map(\.id), [phrase.id])
        let reviewed = LibraryResults(phrases: phrases, collection: .all, query: "", sort: .reviewDate,
                                      reviews: [phrase.id: ReviewState(due: .distantPast, reviews: 1)], saved: [])
        XCTAssertEqual(reviewed.phrases.first?.id, phrase.id)
        let group = LibraryResults(phrases: phrases, collection: .all, query: "look into", sort: .alphabetical, reviews: [:], saved: [], groupByVerb: true)
        XCTAssertTrue(group.groups.first { $0.verb == "look" }?.phrases.contains { $0.phrase == "look for" } == true)
    }

    func testLibraryResultsPerformance() throws {
        let phrases = try Catalog.load()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            for collection in LibraryCollection.allCases {
                for groupByVerb in [false, true] {
                    let result = LibraryResults(phrases: phrases, collection: collection, query: "look", sort: .alphabetical,
                                                reviews: [:], saved: [], groupByVerb: groupByVerb)
                    XCTAssertEqual(result.isEmpty, collection == .saved)
                }
            }
        }
    }
}
