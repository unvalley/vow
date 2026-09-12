import XCTest
@testable import Vow

final class LibraryResultsTests: XCTestCase {
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
                    let result = LibraryResults(phrases: phrases, collection: collection, query: query,
                                                sort: sort, reviews: reviews, saved: saved)
                    let expectedPhrases = sort.ordered(phrases.filter {
                        (collection != .saved || saved.contains($0.id)) && $0.matches(query)
                    }, reviews: reviews)
                    XCTAssertEqual(result.isEmpty, expectedPhrases.isEmpty, "\(collection) \(sort) \(query)")
                    if collection == .verbs {
                        let expectedGroups = sort.ordered(VerbGroup.groups(for: phrases).filter {
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
        let group = LibraryResults(phrases: phrases, collection: .verbs, query: "look into", sort: .alphabetical, reviews: [:], saved: [])
        XCTAssertTrue(group.groups.first { $0.verb == "look" }?.phrases.contains { $0.phrase == "look for" } == true)
    }

    func testLibraryResultsPerformance() throws {
        let phrases = try Catalog.load()
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()]) {
            for collection in LibraryCollection.allCases {
                let result = LibraryResults(phrases: phrases, collection: collection, query: "look", sort: .alphabetical,
                                            reviews: [:], saved: [])
                XCTAssertEqual(result.isEmpty, collection == .saved)
            }
        }
    }
}
