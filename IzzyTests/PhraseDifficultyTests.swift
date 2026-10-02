import XCTest
@testable import Izzy

final class PhraseDifficultyTests: XCTestCase {
    func testCatalogHasAnExplicitLevelForEveryEntryAndStableSenseAnchors() throws {
        let phrases = try Catalog.load()
        XCTAssertEqual(phrases.count, 3020)
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

    func testLevelsToLearnNarrowHomeAndDefaultToEveryLevel() throws {
        let phrases = try Catalog.load()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertEqual(LearningData().homeLevelFilter, .all)
        // Older learning files without the key still decode and show every level.
        var record = try JSONSerialization.jsonObject(with: JSONEncoder().encode(LearningData())) as! [String: Any]
        record.removeValue(forKey: "homeLevels")
        let legacy = try JSONDecoder().decode(LearningData.self, from: JSONSerialization.data(withJSONObject: record))
        XCTAssertEqual(legacy.homeLevelFilter, .all)

        XCTAssertEqual(HomeDerivation.visible(phrases, purchased: true, kind: .all, levels: .all).count, phrases.count)
        let b1 = PhraseLevelFilter(levels: [.b1])
        let visible = HomeDerivation.visible(phrases, purchased: true, kind: .all, levels: b1)
        XCTAssertEqual(visible.count, phrases.filter { $0.difficulty == .b1 }.count)
        XCTAssertTrue(visible.allSatisfy { $0.difficulty == .b1 })
        let mixed = HomeDerivation.visible(phrases, purchased: true, kind: .idioms, levels: PhraseLevelFilter(levels: [.a2, .b1]))
        XCTAssertFalse(mixed.isEmpty)
        XCTAssertTrue(mixed.allSatisfy { $0.isIdiom && ($0.difficulty == .a2 || $0.difficulty == .b1) })

        // Today's learning introduces only the chosen level, and a due review from another level waits.
        let other = try XCTUnwrap(phrases.first { $0.difficulty == .b2 })
        let memory = [other.id: MemoryReview(due: now.addingTimeInterval(-60), introduced: now.addingTimeInterval(-86_400 * 3),
                                             lastReviewed: now.addingTimeInterval(-86_400 * 3))]
        let d = HomeDerivation(phrases: phrases, purchased: true, kind: .all, levels: b1, memory: memory, reviews: [:],
                               focus: "work", dailyNew: 5, now: now, mode: .learning, selectedID: "")
        XCTAssertEqual(d.learning.count, 5)
        XCTAssertTrue(d.learning.allSatisfy { $0.difficulty == .b1 })
        XCTAssertEqual(d.progress.dueReviews, 0)
        let everything = HomeDerivation(phrases: phrases, purchased: true, kind: .all, memory: memory, reviews: [:],
                                        focus: "work", dailyNew: 5, now: now, mode: .learning, selectedID: "")
        XCTAssertEqual(everything.progress.dueReviews, 1)
        XCTAssertTrue(everything.learning.contains { $0.id == other.id })

        // Explore on the free plan counts the chosen level across the whole collection, Pro included.
        let free = HomeDerivation(phrases: phrases, purchased: false, kind: .all, levels: b1, memory: [:], reviews: [:],
                                  focus: "work", dailyNew: 5, now: now, mode: .explore, selectedID: "")
        XCTAssertEqual(free.collectionCount, phrases.filter { $0.difficulty == .b1 }.count)
        XCTAssertTrue(free.visible.allSatisfy { $0.difficulty == .b1 && AccessPolicy.freeIDs.contains($0.id) })
    }

    func testAChosenLevelThePlanOrKindDoesNotOfferShowsEveryLevelInstead() throws {
        let phrases = try Catalog.load()
        let free = phrases.filter { AccessPolicy.allows($0, purchased: false) }
        let offered = Set(free.compactMap(\.difficulty))
        let absent = try XCTUnwrap(PhraseDifficulty.allCases.first { !offered.contains($0) }, "C2 has no lessons")
        let stale = PhraseLevelFilter(levels: [absent])
        XCTAssertEqual(stale.applied(to: offered), .all)
        XCTAssertEqual(HomeDerivation.visible(phrases, purchased: false, kind: .all, levels: stale).count, free.count)
        // A level still on offer keeps narrowing; one that is not on offer is set aside without clearing the rest.
        let level = try XCTUnwrap(offered.sorted().first)
        XCTAssertEqual(PhraseLevelFilter(levels: [level, absent]).applied(to: offered), PhraseLevelFilter(levels: [level]))
        XCTAssertEqual(PhraseLevelFilter(levels: offered).applied(to: offered), .all)
        XCTAssertEqual(stale.applied(phrases: phrases, purchased: false, kind: .all), .all)
        XCTAssertEqual(PhraseLevelFilter.all.applied(phrases: phrases, purchased: false, kind: .idioms), .all)
    }

    func testTogglingLevelsTreatsEveryLevelOnOfferAsNoChoice() {
        let offered: Set<PhraseDifficulty> = [.a2, .b1, .b2]
        let one = PhraseLevelFilter.all.toggling(.b1, among: offered)
        XCTAssertEqual(one, PhraseLevelFilter(levels: [.b1]))
        XCTAssertEqual(one.summary, "B1")
        let two = one.toggling(.a2, among: offered)
        XCTAssertEqual(two.ordered, [.a2, .b1])
        XCTAssertEqual(two.summary, "A2 · B1")
        XCTAssertEqual(two.toggling(.b2, among: offered), .all, "all three is the same as no choice")
        XCTAssertEqual(one.toggling(.b1, among: offered), .all, "removing the last level shows everything")
        XCTAssertNil(PhraseLevelFilter.all.summary)
        XCTAssertTrue(PhraseDifficulty.a1 < .a2 && PhraseDifficulty.b2 < .c1)
    }

    func testLevelProgressCountsWhatThePlanOpensAndWhatWasLearned() throws {
        let phrases = try Catalog.load()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let learned = try XCTUnwrap(phrases.first { AccessPolicy.allows($0, purchased: false) })
        let locked = try XCTUnwrap(phrases.first { !AccessPolicy.allows($0, purchased: false) })
        let memory = [learned.id: MemoryScheduler.rate(nil, rating: .good, now: now),
                      locked.id: MemoryScheduler.rate(nil, rating: .good, now: now)]
        let free = LevelProgress.levels(phrases: phrases, purchased: false, kind: .all, memory: memory)
        XCTAssertEqual(free.map(\.level), free.map(\.level).sorted())
        XCTAssertEqual(free.reduce(0) { $0 + $1.total }, phrases.count)
        XCTAssertEqual(free.reduce(0) { $0 + $1.available }, AccessPolicy.freeIDs.count)
        XCTAssertEqual(free.reduce(0) { $0 + $1.learned }, 1, "a lesson the plan no longer opens is not counted")
        XCTAssertEqual(free.first { $0.level == learned.difficulty }?.learned, 1)
        let pro = LevelProgress.levels(phrases: phrases, purchased: true, kind: .all, memory: memory)
        XCTAssertTrue(pro.allSatisfy { $0.available == $0.total })
        XCTAssertEqual(pro.reduce(0) { $0 + $1.learned }, 2)
        let idioms = LevelProgress.levels(phrases: phrases, purchased: true, kind: .idioms, memory: [:])
        XCTAssertEqual(idioms.reduce(0) { $0 + $1.total }, phrases.filter(\.isIdiom).count)
        XCTAssertFalse(idioms.contains { $0.total == 0 }, "a level with nothing in the chosen kind is not listed")
    }

    @MainActor func testLevelsToLearnPersistInLevelOrder() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appending(path: "learning.json")
        let store = LearningStore(file: file)
        store.configure(homeLevels: PhraseLevelFilter(levels: [.b2, .a2]))
        XCTAssertEqual(store.data.homeLevels, [.a2, .b2])
        XCTAssertEqual(LearningStore(file: file).data.homeLevelFilter, PhraseLevelFilter(levels: [.a2, .b2]))
        store.configure(homeLevels: .all)
        XCTAssertNil(store.data.homeLevels)
        XCTAssertEqual(LearningStore(file: file).data.homeLevelFilter, .all)
    }

    func testScoreReferencesDoNotInventUnsupportedBands() {
        XCTAssertEqual(PhraseDifficulty.b1.examReferences, "TOEIC 550–780 · 英検 2級 · IELTS 4.0–5.0 · TOEFL 3–3.5")
        XCTAssertEqual(PhraseDifficulty.a1.examReferences, "TOEIC 120–220 · 英検 3級 · TOEFL 1–1.5")
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
        XCTAssertEqual(PhraseDifficulty.b1.label(for: .toeic), "B1 · TOEIC ≈550–780")
        XCTAssertEqual(PhraseDifficulty.c1.reference(for: .toeic), "945–990")
        XCTAssertNil(PhraseDifficulty.c2.reference(for: .toeic))
    }
}
