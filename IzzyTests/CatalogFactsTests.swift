import XCTest
@testable import Izzy

final class CatalogFactsTests: XCTestCase {
    func testFreeFiguresComeFromTheFreeLists() throws {
        let facts = CatalogFacts(phrases: try Catalog.load())
        XCTAssertEqual(facts.freePhrasalVerbs, AccessPolicy.freePhraseIDs.count, "every free phrasal verb is in the catalog")
        XCTAssertEqual(facts.freeIdioms, AccessPolicy.freeIdiomIDs.count, "every free idiom is in the catalog")
        XCTAssertEqual(facts.freeExpressions, AccessPolicy.freeIDs.count)
        XCTAssertLessThan(facts.freeExamples, facts.examples)
    }

    func testOpenEndedClaimsNeverOverstate() throws {
        XCTAssertEqual(CatalogFacts.openEnded(3_020), 3_000)
        XCTAssertEqual(CatalogFacts.openEnded(5_573), 5_000)
        XCTAssertEqual(CatalogFacts.openEnded(240), 200)
        XCTAssertEqual(CatalogFacts.openEnded(36), 36)
        let facts = CatalogFacts(phrases: try Catalog.load())
        for count in [facts.expressions, facts.examples] {
            let claim = CatalogFacts.openEnded(count)
            XCTAssertLessThanOrEqual(claim, count)
            XCTAssertGreaterThan(claim + 1_000, count, "the claim rises with the catalog")
        }
    }

    func testTheFreePlanKeepsTenSavedPhrasesAndTenNotes() {
        let ten = Set((1...10).map { "p\($0)" })
        XCTAssertTrue(AccessPolicy.canSave("new", saved: Set(ten.prefix(9)), purchased: false))
        XCTAssertFalse(AccessPolicy.canSave("new", saved: ten, purchased: false))
        XCTAssertTrue(AccessPolicy.canSave("p1", saved: ten, purchased: false), "unsaving always works")
        XCTAssertTrue(AccessPolicy.canSave("new", saved: ten, purchased: true))

        var notes = Dictionary(uniqueKeysWithValues: ten.map { ($0, "text") })
        XCTAssertFalse(AccessPolicy.canWriteNote(for: "new", notes: notes, purchased: false))
        XCTAssertTrue(AccessPolicy.canWriteNote(for: "p1", notes: notes, purchased: false), "existing notes stay editable")
        XCTAssertTrue(AccessPolicy.canWriteNote(for: "new", notes: notes, purchased: true))
        notes["p1"] = " "
        XCTAssertTrue(AccessPolicy.canWriteNote(for: "new", notes: notes, purchased: false), "a cleared note frees its place")
    }

    /// Copy states catalog and plan figures through `CatalogFacts`, never as typed numbers that go stale.
    func testViewCopyTypesNoCounts() throws {
        let root = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let units = #"(表現|個|種|件| ?expressions| ?phrasal verbs| ?idioms| ?core images| ?backgrounds| ?fonts| ?saved phrases| ?notes)"#
        let typed = try NSRegularExpression(pattern: #""[^"\n]*(?<![\\(\w.])\d[\d,]*\+?(以上)?"# + units)
        var found: [String] = []
        for folder in ["Izzy/Views", "IzzyWidget"] {
            let files = try FileManager.default.contentsOfDirectory(at: root.appending(path: folder), includingPropertiesForKeys: nil)
            for file in files where file.pathExtension == "swift" {
                for (index, line) in try String(contentsOf: file, encoding: .utf8).components(separatedBy: .newlines).enumerated() {
                    let range = NSRange(line.startIndex..., in: line)
                    if typed.firstMatch(in: line, range: range) != nil { found.append("\(file.lastPathComponent):\(index + 1)") }
                }
            }
        }
        XCTAssertEqual(found, [], "use CatalogFacts or AccessPolicy for these counts")
    }
}
