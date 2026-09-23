import XCTest
@testable import Izzy

final class LearningMergeTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    private func synced() -> LearningData {
        var data = LearningData()
        data.onboardingDone = true
        data.dailyNewGoal = 10
        data.saved = ["look-into", "break-the-ice"]
        data.reviews["look-into"] = ReviewState(intervalDays: 1, due: now, reviews: 1, naturalRecalls: 0, lastReviewed: now)
        data.events = [PracticeEvent(phraseID: "look-into", date: now, rating: .effort, mode: "memory")]
        return data
    }

    func testASideLeftAsTheBaseTakesTheOtherSideWhole() {
        let base = synced()
        var changed = base
        changed.saved.insert("give-up")
        changed.theme = .dark
        XCTAssertEqual(LearningMerge.merge(base: base, local: base, remote: changed), changed)
        XCTAssertEqual(LearningMerge.merge(base: base, local: changed, remote: base), changed)
    }

    func testReviewsOnTwoDevicesBothSurviveAndTheLaterReviewOfOnePhraseWins() {
        let base = synced()
        var phone = base, tablet = base
        phone.reviews["give-up"] = ReviewState(intervalDays: 1, due: now, reviews: 1, lastReviewed: now.addingTimeInterval(60))
        phone.reviews["look-into"] = ReviewState(intervalDays: 2.5, due: now, reviews: 2, lastReviewed: now.addingTimeInterval(120))
        tablet.reviews["look-into"] = ReviewState(intervalDays: 0, due: now, reviews: 2, lastReviewed: now.addingTimeInterval(600))
        tablet.memoryReviews = ["break-the-ice": MemoryReview(due: now, introduced: now, lastReviewed: now)]
        let merged = LearningMerge.merge(base: base, local: phone, remote: tablet)
        XCTAssertNotNil(merged.reviews["give-up"])
        XCTAssertEqual(merged.reviews["look-into"]?.lastReviewed, now.addingTimeInterval(600))
        XCTAssertNotNil(merged.memoryReviews?["break-the-ice"])
    }

    func testEventsMergeByIDAndAChangedAnswerKeepsTheLaterTime() throws {
        let base = synced()
        let shared = try XCTUnwrap(base.events.first)
        var phone = base, tablet = base
        phone.events.append(PracticeEvent(phraseID: "give-up", date: now.addingTimeInterval(30), rating: .ready, mode: "memory"))
        // The same day's answer changed on the tablet: same ID, later time.
        tablet.events[0] = PracticeEvent(id: shared.id, phraseID: shared.phraseID, date: now.addingTimeInterval(90), rating: .ready, mode: "memory", memoryRating: .easy)
        let merged = LearningMerge.merge(base: base, local: phone, remote: tablet)
        XCTAssertEqual(merged.events.count, 2)
        XCTAssertEqual(merged.events.first { $0.id == shared.id }?.memoryRating, .easy)
        XCTAssertEqual(merged.events.map(\.date), merged.events.map(\.date).sorted())
    }

    func testSavedPhrasesKeepARemovalOnOneSideAndAnAdditionOnTheOther() {
        let base = synced()
        var phone = base, tablet = base
        phone.saved.remove("look-into")
        tablet.saved.insert("give-up")
        XCTAssertEqual(LearningMerge.merge(base: base, local: phone, remote: tablet).saved, ["break-the-ice", "give-up"])
    }

    func testASettingChangedOnBothSidesKeepsThisDevicesChoice() {
        let base = synced()
        var phone = base, tablet = base
        phone.theme = .dark
        tablet.theme = .light
        tablet.accent = .blue
        let merged = LearningMerge.merge(base: base, local: phone, remote: tablet)
        XCTAssertEqual(merged.theme, .dark)
        XCTAssertEqual(merged.accent, .blue, "changed on one side only")
    }

    func testAFreshInstallTakesTheHistoryAndTheSettingsFromICloud() {
        let remote = synced()
        var fresh = LearningData()
        fresh.japaneseHints = false // the device language, set before the first sync
        fresh.dailyNewGoal = 5
        let merged = LearningMerge.merge(base: nil, local: fresh, remote: remote)
        XCTAssertEqual(merged.dailyNewGoal, 10)
        XCTAssertTrue(merged.japaneseHints)
        XCTAssertTrue(merged.onboardingDone)
        XCTAssertEqual(merged.saved, remote.saved)
        XCTAssertEqual(merged.events, remote.events)
    }

    func testTwoHistoriesMeetingForTheFirstTimeKeepEverythingFromBoth() {
        var phone = synced()
        phone.rehearsalCount = 2
        phone.rehearsalDates = [now]
        var tablet = LearningData()
        tablet.saved = ["give-up"]
        tablet.events = [PracticeEvent(phraseID: "give-up", date: now.addingTimeInterval(-60), rating: .ready, mode: "memory")]
        tablet.rehearsalCount = 3
        tablet.rehearsalDates = [now.addingTimeInterval(-86_400)]
        let merged = LearningMerge.merge(base: nil, local: phone, remote: tablet)
        XCTAssertEqual(merged.saved, ["look-into", "break-the-ice", "give-up"])
        XCTAssertEqual(merged.events.count, 2)
        XCTAssertEqual(merged.rehearsalDates?.count, 2)
        XCTAssertEqual(merged.rehearsalCount, 3, "without a base the same stories may be on both sides")
    }

    func testStoriesFinishedOnBothDevicesAddUpAgainstTheBase() {
        var base = synced()
        base.rehearsalCount = 2
        var phone = base, tablet = base
        phone.rehearsalCount = 3
        tablet.rehearsalCount = 4
        XCTAssertEqual(LearningMerge.merge(base: base, local: phone, remote: tablet).rehearsalCount, 5)
    }

    func testNotesWrittenOnBothDevicesAreBothKept() {
        let base = synced()
        var phone = base, tablet = base
        phone.notes["look-into"] = "I'll look into it."
        tablet.notes["look-into"] = "Let me look into the delay."
        tablet.notes["give-up"] = "Never give up."
        let merged = LearningMerge.merge(base: base, local: phone, remote: tablet)
        XCTAssertEqual(merged.notes["look-into"], "I'll look into it.\n\nLet me look into the delay.")
        XCTAssertEqual(merged.notes["give-up"], "Never give up.")
    }

    func testTheReadingVoiceStaysWithTheDevice() {
        let base = synced()
        var phone = base, tablet = base
        phone.speechVoiceID = "phone-voice"
        tablet.speechVoiceID = "tablet-voice"
        tablet.theme = .dark
        XCTAssertEqual(LearningMerge.merge(base: base, local: phone, remote: tablet).speechVoiceID, "phone-voice")
        XCTAssertEqual(LearningMerge.merge(base: base, local: base, remote: tablet).speechVoiceID, nil)
    }

    /// The device that loses the race to upload merges; the other then takes the result unchanged.
    func testTheOtherDeviceTakesTheMergeUnchanged() {
        let base = synced()
        var phone = base, tablet = base
        phone.saved.insert("give-up")
        phone.theme = .dark
        tablet.saved.remove("break-the-ice")
        tablet.theme = .light
        let merged = LearningMerge.merge(base: base, local: tablet, remote: phone)
        XCTAssertEqual(LearningMerge.merge(base: phone, local: phone, remote: merged), merged)
    }

    /// Every stored field, so a new one can't be added without deciding how two devices merge it.
    func testEveryStoredFieldIsHandledByTheMerge() throws {
        var data = synced()
        data.memoryReviews = [:]
        data.reviewReminders = .init()
        data.notes = ["look-into": "note"]
        data.theme = .dark
        data.accent = .blue
        data.todayBackground = TodayBackground.allCases.first
        data.phraseTypeface = .sfPro
        data.dailyGoalSkipped = false
        data.difficultyScale = .cefr
        data.phraseSort = .alphabetical
        data.homeKind = .all
        data.speechVoiceID = "voice"
        data.listeningPreferences = .init()
        data.rehearsalDates = []
        let keys = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(data)) as? [String: Any]).keys
        XCTAssertEqual(Set(keys), [
            "schema", "reviews", "memoryReviews", "reviewReminders", "saved", "notes", "events", "focus", "japaneseHints",
            "theme", "accent", "todayBackground", "phraseTypeface", "dailyNewGoal", "dailyGoalSkipped", "difficultyScale",
            "phraseSort", "homeKind", "speechVoiceID", "listeningPreferences", "onboardingDone", "rehearsalCount", "rehearsalDates"
        ], "A new field needs a rule in LearningMerge and a new LearningMerge.format")
    }
}
