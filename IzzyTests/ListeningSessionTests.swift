import XCTest
@testable import Izzy

final class ListeningSessionTests: XCTestCase {
    private func session(_ preferences: ListeningPreferences = .init(), purchased: Bool = false, saved: Set<String> = [], language: MeaningLanguage = .japanese) throws -> ListeningSession {
        .init(phrases: try Catalog.load(), purchased: purchased, saved: saved, preferences: preferences, meaningLanguage: language)
    }

    func testCollectionsKeepBothFreeSelectionsStableAndExcludePaidContent() throws {
        XCTAssertEqual(try session().phrases.count, 100)
        XCTAssertEqual(try session(purchased: true).phrases.count, 2206)
        for collection in [ListeningCollection.phrasalVerbs, .idioms] {
            var options = ListeningPreferences()
            options.collection = collection
            let free = try session(options).phrases
            XCTAssertEqual(free.count, 50)
            XCTAssertTrue(free.allSatisfy { $0.isIdiom == (collection == .idioms) })
            XCTAssertEqual(Set(free.map(\.id)), collection == .idioms ? AccessPolicy.freeIdiomIDs : AccessPolicy.freePhraseIDs)
        }
    }

    func testSavedPlaylistDoesNotBypassPurchases() throws {
        let paid = try XCTUnwrap(Catalog.load().first { !AccessPolicy.allows($0, purchased: false) })
        var options = ListeningPreferences()
        options.collection = .saved
        let saved: Set<String> = ["01-bring-up", paid.id]
        XCTAssertEqual(try session(options, saved: saved).phrases.map(\.id), ["01-bring-up"])
        XCTAssertEqual(try session(options, purchased: true, saved: saved).phrases.count, 2)
        XCTAssertTrue(try session(options).phrases.isEmpty)
    }

    func testSpeechSequenceUsesCorrectLanguageAndAdvancesOnlyAfterExample() throws {
        var queue = try session()
        let first = try XCTUnwrap(queue.phrase)
        XCTAssertEqual(queue.segment, .init(text: first.phrase, language: "en-US"))
        XCTAssertTrue(queue.finishSegment())
        XCTAssertEqual(queue.segment, .init(text: first.japanese, language: "ja-JP"))
        XCTAssertEqual(queue.index, 0)
        XCTAssertTrue(queue.finishSegment())
        XCTAssertEqual(queue.segment, .init(text: first.examples[0], language: "en-US"))
        XCTAssertTrue(queue.finishSegment())
        XCTAssertEqual(queue.index, 1)
        XCTAssertEqual(queue.segmentIndex, 0)
        XCTAssertEqual(try session(language: .easyEnglish).segments[1].language, "en-US")
    }

    func testSkippingResetsSegmentAndNonRepeatingPlaylistFinishes() throws {
        var options = ListeningPreferences()
        options.repeats = false
        options.collection = .saved
        var queue = try session(options, saved: ["01-bring-up", "02-get-across"])
        XCTAssertFalse(queue.skip(-1))
        XCTAssertTrue(queue.finishSegment())
        XCTAssertTrue(queue.skip(1))
        XCTAssertEqual(queue.segmentIndex, 0)
        XCTAssertTrue(queue.finishSegment())
        XCTAssertTrue(queue.finishSegment())
        XCTAssertFalse(queue.finishSegment())
        XCTAssertFalse(queue.canGoForward)
        queue.restart()
        XCTAssertEqual(queue.index, 0)
        XCTAssertEqual(queue.segmentIndex, 0)
    }

    func testRepeatAndExpressionOnlyPlaybackWrapWithoutEmptyUtterances() throws {
        var options = ListeningPreferences()
        options.collection = .saved
        options.includesMeaning = false
        options.includesExample = false
        var queue = try session(options, saved: ["01-bring-up", "02-get-across"])
        XCTAssertEqual(queue.segments.count, 1)
        XCTAssertTrue(queue.skip(-1))
        XCTAssertEqual(queue.index, 1)
        XCTAssertTrue(queue.finishSegment())
        XCTAssertEqual(queue.index, 0)
        var empty = try session(options)
        XCTAssertNil(empty.segment)
        XCTAssertFalse(empty.finishSegment())
        XCTAssertFalse(empty.skip(1))
    }

    func testRefundRemovesQueuedPaidExpressionsAndResetsRevokedCurrentItem() throws {
        var queue = try session(purchased: true)
        let paidIndex = try XCTUnwrap(queue.phrases.firstIndex { !AccessPolicy.freeIDs.contains($0.id) })
        XCTAssertTrue(queue.skip(paidIndex))
        XCTAssertTrue(queue.finishSegment())
        queue.restrict(to: AccessPolicy.freeIDs)
        XCTAssertEqual(queue.phrases.count, 100)
        XCTAssertEqual(queue.index, 0)
        XCTAssertEqual(queue.segmentIndex, 0)
        XCTAssertTrue(AccessPolicy.freeIDs.contains(try XCTUnwrap(queue.phrase).id))
        queue.restrict(to: [])
        XCTAssertNil(queue.segment)
    }

    func testShuffleRetainsExactlyTheAccessibleExpressions() throws {
        var options = ListeningPreferences()
        options.shuffled = true
        let queue = try session(options)
        XCTAssertEqual(Set(queue.phrases.map(\.id)), AccessPolicy.freeIDs)
        XCTAssertEqual(queue.phrases.count, 100)
    }

    @MainActor func testPreferencesPersistWithoutConsumingLearningQuota() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let store = LearningStore(file: file)
        var preferences = ListeningPreferences()
        preferences.collection = .idioms
        preferences.sleepMinutes = 15
        preferences.slower = true
        store.configureListening(preferences)
        let restored = LearningStore(file: file)
        XCTAssertEqual(restored.data.listeningPreferences, preferences)
        XCTAssertTrue(restored.data.events.isEmpty)
        XCTAssertTrue(restored.data.memoryReviews?.isEmpty ?? true)
        var legacy = try JSONSerialization.jsonObject(with: Data(contentsOf: file)) as! [String: Any]
        legacy.removeValue(forKey: "listeningPreferences")
        XCTAssertNil(try JSONDecoder().decode(LearningData.self, from: JSONSerialization.data(withJSONObject: legacy)).listeningPreferences)
    }

    @MainActor func testAudioReplacementStopsPreviousOwnerAndIgnoresStaleRelease() {
        let ownership = AudioOwnership()
        let practice = UUID(), listening = UUID()
        var stopped = 0
        ownership.claim(practice) {
            stopped += 1
            XCTAssertFalse(ownership.release(practice))
        }
        ownership.claim(listening) {}
        XCTAssertEqual(stopped, 1)
        XCTAssertEqual(ownership.owner, listening)
        XCTAssertFalse(ownership.release(practice))
        ownership.claim(listening) { XCTFail("Reclaiming the same owner must not interrupt it") }
        XCTAssertTrue(ownership.release(listening))
        XCTAssertNil(ownership.owner)
    }
}
