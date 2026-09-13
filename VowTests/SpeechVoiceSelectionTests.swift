import XCTest
@testable import Vow

final class SpeechVoiceSelectionTests: XCTestCase {
    private let standard = SpeechVoiceOption(id: "us-basic", name: "Basic", language: "en-US", quality: 1)
    private let enhanced = SpeechVoiceOption(id: "us-enhanced", name: "Enhanced", language: "en-US", quality: 2)
    private let premium = SpeechVoiceOption(id: "gb-premium", name: "Premium", language: "en-GB", quality: 3)

    func testAutomaticPrefersQualityBeforeAccentAndHandlesNoEnglishVoice() {
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [standard, enhanced, premium], preferredID: nil), premium)
        let japanese = SpeechVoiceOption(id: "ja", name: "Japanese", language: "ja-JP", quality: 3)
        XCTAssertNil(SpeechVoiceSelection.selected(in: [japanese], preferredID: nil))
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [japanese, standard], preferredID: "ja"), standard)
    }

    func testExplicitChoiceWinsAndRemovedChoiceFallsBack() {
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [standard, premium], preferredID: standard.id), standard)
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [enhanced, premium], preferredID: "removed"), premium)
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [standard, enhanced], preferredID: nil), enhanced)
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [standard], preferredID: nil), standard)
    }

    func testEqualQualityUsesSystemRecommendationBeforeLegacyVoiceNames() {
        let legacy = SpeechVoiceOption(id: "a-fred", name: "Fred", language: "en-US", quality: 1)
        let recommended = SpeechVoiceOption(id: "samantha", name: "Samantha", language: "en-US", quality: 1, isSystemPreferred: true)
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [legacy, recommended], preferredID: nil), recommended)
        XCTAssertEqual(SpeechVoiceSelection.selected(in: [recommended, premium], preferredID: nil), premium)
    }

    func testEqualQualityPrefersUSAndDoesNotDependOnEnumerationOrder() {
        let us = SpeechVoiceOption(id: "us-premium", name: "US", language: "en-US", quality: 3)
        let otherUS = SpeechVoiceOption(id: "us-premium-b", name: "US B", language: "en-US", quality: 3)
        XCTAssertEqual(SpeechVoiceSelection.ordered([premium, us, otherUS]), [us, otherUS, premium])
        XCTAssertEqual(SpeechVoiceSelection.ordered([otherUS, us, premium]), [us, otherUS, premium])
    }

    @MainActor func testVoiceChoicePersistsWithoutChangingLearningHistory() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let store = LearningStore(file: file)
        store.toggleSaved("01-bring-up")
        store.note("My own example.", for: "01-bring-up")
        store.configureSpeechVoice(premium.id)
        let reopened = LearningStore(file: file)
        XCTAssertEqual(reopened.data.speechVoiceID, premium.id)
        XCTAssertTrue(reopened.data.saved.contains("01-bring-up"))
        XCTAssertEqual(reopened.data.notes["01-bring-up"], "My own example.")
        reopened.configureSpeechVoice(nil)
        XCTAssertNil(LearningStore(file: file).data.speechVoiceID)
    }

    func testOldLearningDataWithoutVoiceStillDecodes() throws {
        let data = try JSONEncoder().encode(LearningData())
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        object.removeValue(forKey: "speechVoiceID")
        let decoded = try JSONDecoder().decode(LearningData.self, from: JSONSerialization.data(withJSONObject: object))
        XCTAssertNil(decoded.speechVoiceID)
        XCTAssertEqual(decoded.schema, 1)
    }
}
