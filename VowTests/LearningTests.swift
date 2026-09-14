import XCTest
@testable import Vow

final class LearningTests: XCTestCase {
    let now = Date(timeIntervalSince1970: 1_800_000_000)

    func testFreeAccessIsStableAndPurchasedAccessCoversCatalog() throws {
        let phrases = try Catalog.load()
        let free = phrases.filter { AccessPolicy.allows($0, purchased: false) }
        XCTAssertEqual(free.count, 100)
        XCTAssertEqual(free.filter(\.isIdiom).count, 50)
        XCTAssertEqual(free.filter { !$0.isIdiom }.count, 50)
        XCTAssertEqual(Set(free.map(\.id)), AccessPolicy.freeIDs)
        XCTAssertEqual(Set(free.filter { !$0.isIdiom }.map(\.scene)), Set(["work", "connect", "plans", "perspective"]))
        XCTAssertTrue(phrases.allSatisfy { AccessPolicy.allows($0, purchased: true) })
        XCTAssertEqual(phrases.reversed().filter { AccessPolicy.allows($0, purchased: false) }.count, 100)
    }

    func testEditorialLessonsParticipateInSearchAndBothReviewSchedulers() throws {
        let phrases = try Catalog.load()
        let additions = phrases.filter { $0.id.hasPrefix("editorial-") || $0.isIdiom }
        XCTAssertEqual(additions.count, 686)
        for phrase in additions {
            XCTAssertTrue(phrase.matches(phrase.phrase))
            XCTAssertTrue(phrase.matches(phrase.japanese))
            XCTAssertTrue(phrase.matches(phrase.easyEnglish))
            XCTAssertEqual(phrase.examples.count, 2)
            XCTAssertEqual(AccessPolicy.allows(phrase, purchased: false), AccessPolicy.freeIdiomIDs.contains(phrase.id))
            XCTAssertTrue(AccessPolicy.allows(phrase, purchased: true))
            XCTAssertEqual(phrase.particleConcepts.isEmpty, phrase.isIdiom)
            XCTAssertNotNil(phrase.difficulty)
            let memory = MemoryScheduler.review(nil, rating: .good, now: now)
            let queue = MemoryScheduler.queue(phrases: [phrase], states: [phrase.id: memory], focus: phrase.scene, now: memory.due)
            XCTAssertEqual(queue.map(\.id), [phrase.id])
            let speaking = Scheduler.review(ReviewState(), rating: .ready, now: now)
            XCTAssertEqual(SessionPlanner.queue(phrases: [phrase], states: [phrase.id: speaking], focus: phrase.scene, now: speaking.due).map(\.id), [phrase.id])
        }
    }

    func testCoreImagesCoverCatalogAndHaveBilingualComparisons() throws {
        XCTAssertEqual(ParticleConcept.all.count, 35)
        XCTAssertEqual(Set(ParticleConcept.all.map(\.id)).count, ParticleConcept.all.count)
        for concept in ParticleConcept.all {
            XCTAssertFalse(concept.title(in: .japanese).isEmpty)
            XCTAssertFalse(concept.title(in: .easyEnglish).isEmpty)
            XCTAssertFalse(concept.extensionText(in: .japanese).isEmpty)
            XCTAssertFalse(concept.extensionText(in: .easyEnglish).isEmpty)
            XCTAssertNotNil(ParticleConcept.find(concept.comparison))
            XCTAssertNotEqual(concept.comparison, concept.id)
        }
        for phrase in try Catalog.load().filter({ !$0.isIdiom }) {
            XCTAssertFalse(phrase.particleConcepts.isEmpty, phrase.phrase)
        }
    }

    func testParticleMatchingUsesWordsAndPreservesCompoundOrder() {
        XCTAssertEqual(ParticleConcept.concepts(in: "look into").map(\.id), ["into"])
        XCTAssertEqual(ParticleConcept.concepts(in: "put up with").map(\.id), ["up", "with"])
        XCTAssertEqual(ParticleConcept.concepts(in: "run out of").map(\.id), ["out", "of"])
        XCTAssertEqual(ParticleConcept.concepts(in: "hit it off").map(\.id), ["off"])
        XCTAssertEqual(ParticleConcept.concepts(in: "fend for oneself").map(\.id), ["for"])
        XCTAssertEqual(ParticleConcept.concepts(in: "GET ROUND TO").map(\.id), ["around", "to"])
        XCTAssertEqual(ParticleConcept.concepts(in: "touch upon").map(\.id), ["on"])
        XCTAssertTrue(ParticleConcept.concepts(in: "invent").isEmpty)
    }

    func testForgottenPhraseReturnsSoonAndResetsInterval() {
        let old = ReviewState(intervalDays: 15, due: .distantPast, reviews: 5, naturalRecalls: 3)
        let next = Scheduler.review(old, rating: .again, now: now)
        XCTAssertEqual(next.due.timeIntervalSince(now), 600)
        XCTAssertEqual(next.intervalDays, 0)
        XCTAssertEqual(next.naturalRecalls, 0)
        XCTAssertEqual(next.reviews, 6)
    }

    func testSuccessfulRecallExpandsIntervalsWithACap() {
        var state = ReviewState()
        state = Scheduler.review(state, rating: .ready, now: now)
        XCTAssertEqual(state.intervalDays, 1)
        state = Scheduler.review(state, rating: .ready, now: state.due)
        XCTAssertEqual(state.intervalDays, 2.5)
        for _ in 0..<15 { state = Scheduler.review(state, rating: .ready, now: state.due) }
        XCTAssertEqual(state.intervalDays, 60)
        XCTAssertEqual(state.due.timeIntervalSince(state.lastReviewed ?? now), 60 * 86400)
    }

    func testEarlyPracticeDoesNotPostponeAnExistingReview() {
        let old = ReviewState(intervalDays: 10, due: now.addingTimeInterval(86400), reviews: 4, naturalRecalls: 2)
        for rating in [RecallRating.ready, .effort] {
            let next = Scheduler.review(old, rating: rating, now: now)
            XCTAssertEqual(next.due, old.due)
            XCTAssertEqual(next.intervalDays, old.intervalDays)
            XCTAssertEqual(next.naturalRecalls, old.naturalRecalls)
            XCTAssertEqual(next.reviews, old.reviews + 1)
        }
        XCTAssertEqual(Scheduler.review(old, rating: .again, now: now).due, now.addingTimeInterval(600))
    }

    func testEffortIsNotCountedAsNaturalRecall() {
        let next = Scheduler.review(ReviewState(), rating: .effort, now: now)
        XCTAssertEqual(next.intervalDays, 1)
        XCTAssertEqual(next.naturalRecalls, 0)
    }

    func testDueReviewsPrecedeNewPhrasesAndFutureReviewsAreExcluded() throws {
        let phrases = try Catalog.load()
        let first = phrases[0], second = phrases[1], third = phrases[2]
        let states: [String: ReviewState] = [
            first.id: .init(due: now.addingTimeInterval(100)),
            second.id: .init(due: now.addingTimeInterval(-100)),
            third.id: .init(due: now.addingTimeInterval(-200))
        ]
        let queue = SessionPlanner.queue(phrases: phrases, states: states, focus: "connect", now: now)
        XCTAssertEqual(queue.count, 3)
        XCTAssertEqual(queue[0].id, third.id)
        XCTAssertEqual(queue[1].id, second.id)
        XCTAssertEqual(queue[2].scene, "connect")
        XCTAssertFalse(queue.contains { $0.id == first.id })
    }

    func testAllFutureMeansEmptyQueue() throws {
        let phrases = try Catalog.load()
        let states = Dictionary(uniqueKeysWithValues: phrases.map { ($0.id, ReviewState(due: now.addingTimeInterval(1000))) })
        XCTAssertTrue(SessionPlanner.queue(phrases: phrases, states: states, focus: "work", now: now).isEmpty)
    }

    func testCatalogHasCompleteDistinctContextsAndKnownScenes() throws {
        let phrases = try Catalog.load()
        XCTAssertEqual(phrases.count, 1300)
        XCTAssertEqual(Set(phrases.map(\.id)).count, 1300)
        XCTAssertEqual(Set(phrases.map(\.phrase)).count, 1300)
        let original = Array(phrases.prefix(80))
        XCTAssertEqual(original.count, 80)
        XCTAssertEqual(phrases.filter { !$0.usesExampleRecall }.count, 766)
        XCTAssertEqual(Set(original.flatMap { [$0.cue, $0.transferCue] }).count, 160)
        XCTAssertEqual(phrases.filter { $0.referenceUsage != nil }.count, 67)
        for phrase in phrases {
            XCTAssertTrue(Scene.all.contains { $0.id == phrase.scene })
            XCTAssertNotEqual(phrase.cue, phrase.transferCue)
            XCTAssertNotEqual(phrase.reply, phrase.transferReply)
            if phrase.usesExampleRecall {
                XCTAssertTrue(phrase.cue.contains("____"))
                XCTAssertFalse(phrase.reply.isEmpty)
                XCTAssertTrue(phrase.transferReply.isEmpty)
                XCTAssertTrue(phrase.source.isEmpty)
            } else {
                XCTAssertFalse(phrase.nuance.isEmpty)
                XCTAssertFalse(phrase.frame.isEmpty)
                XCTAssertEqual(URL(string: phrase.source)?.scheme, "https")
            }
            XCTAssertFalse(phrase.japanese.isEmpty)
            XCTAssertFalse(phrase.easyEnglish.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            XCTAssertEqual(phrase.explanation(in: .easyEnglish), phrase.easyEnglish)
            XCTAssertEqual(phrase.explanation(in: .japanese), phrase.japanese)
        }
        for scene in Scene.all { XCTAssertGreaterThanOrEqual(phrases.filter { $0.scene == scene.id }.count, 6) }
    }

    func testVerbFamiliesPreserveMembershipAndOldLessonIDs() throws {
        let phrases = try Catalog.load().filter { !$0.isIdiom }
        let groups = VerbGroup.groups(for: phrases)
        let look = try XCTUnwrap(groups.first { $0.verb == "look" })
        XCTAssertEqual(look.phrases.count, 17)
        XCTAssertEqual(groups.count, 370)
        XCTAssertTrue(look.phrases.contains { $0.phrase == "look for" })
        XCTAssertTrue(look.phrases.contains { $0.phrase == "look into" })
        XCTAssertTrue(look.phrases.allSatisfy { $0.baseVerb == "look" })
        XCTAssertEqual(groups.map(\.verb), groups.map(\.verb).sorted())
        XCTAssertEqual(groups.flatMap(\.phrases).count, phrases.count)
        XCTAssertEqual(Set(groups.flatMap(\.phrases).map(\.id)), Set(phrases.map(\.id)))
        let original = ["bring up", "get across", "follow up", "push back", "talk through", "wrap up", "catch up", "open up", "reach out", "drift apart", "let down", "bring out", "put off", "work out", "fall through", "turn down", "come up", "rule out", "come across", "figure out", "back up", "go over", "think through", "point out"]
        for (index, phrase) in original.enumerated() {
            let id = String(format: "%02d-", index + 1) + phrase.replacingOccurrences(of: " ", with: "-")
            XCTAssertEqual(phrases.first { $0.id == id }?.phrase, phrase)
        }
    }

    func testImportedSearchAndLegacyLessonDecoding() throws {
        let phrases = try Catalog.load()
        let drop = try XCTUnwrap(phrases.first { $0.phrase == "drop by" })
        XCTAssertTrue(drop.matches(" DROP IN "))
        XCTAssertTrue(drop.matches("ふらり"))
        XCTAssertTrue(drop.matches("visit informally"))
        let original = try XCTUnwrap(phrases.first { $0.id == "21-back-up" })
        XCTAssertTrue(original.matches("copy data"))
        XCTAssertEqual(original.referenceUsage?.example, "Make sure you back up your files.")
        XCTAssertEqual(original.reply, "Do we have any data to back that up?")
        var json = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(original)) as? [String: Any])
        for key in ["aliases", "referenceUsage", "exampleRecall"] { json.removeValue(forKey: key) }
        let legacy = try JSONDecoder().decode(Phrase.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(legacy.usesExampleRecall)
        XCTAssertNil(legacy.referenceUsage)
        XCTAssertEqual(legacy.id, original.id)
    }

    @MainActor func testImportedReviewPersistsAlongsideOriginalProgress() throws {
        let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".json")
        defer { try? FileManager.default.removeItem(at: file) }
        let store = LearningStore(file: file)
        let old = try XCTUnwrap(store.phrases.first { $0.id == "76-run-out-of" })
        store.rate(old, .effort, mode: "spoken", now: now)
        store.note("We have run out of time.", for: old.id)
        store.toggleSaved(old.id)
        let imported = try XCTUnwrap(store.phrases.first { $0.id == "collection-zoom-in" })
        store.rate(imported, .effort, mode: "typed", now: now)
        store.toggleSaved(imported.id)
        store.configure(meaningLanguage: .easyEnglish)
        let reopened = LearningStore(file: file)
        XCTAssertEqual(reopened.data.events.map(\.phraseID), [old.id, imported.id])
        XCTAssertEqual(reopened.data.saved, Set([old.id, imported.id]))
        XCTAssertEqual(reopened.data.notes[old.id], "We have run out of time.")
        XCTAssertEqual(reopened.data.meaningLanguage, .easyEnglish)
        XCTAssertEqual(reopened.streak(now: now).current, 1)
        XCTAssertEqual(reopened.data.reviews[imported.id]?.reviews, 1)
        let everyday = reopened.phrases.filter { $0.scene == "everyday" }
        let queue = SessionPlanner.queue(phrases: everyday, states: reopened.data.reviews, focus: "everyday", now: now, limit: 6)
        XCTAssertEqual(queue.count, 6)
        XCTAssertFalse(queue.contains { $0.id == imported.id })
    }

    @MainActor func testProgressBookmarksAndNotesSurviveRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let first = LearningStore(file: file)
        let phrase = try XCTUnwrap(first.phrases.first)
        first.toggleSaved(phrase.id)
        first.note("Can I bring up the timeline?", for: phrase.id)
        first.configure(focus: "connect", japanese: false, gentle: true, sort: .reviewDate, accent: .purple, theme: .dark, background: .waterLilies, showAnswerByDefault: true)
        first.rate(phrase, .effort, mode: "typed", now: now)
        first.finishRehearsal()
        let reopened = LearningStore(file: file)
        XCTAssertNil(reopened.errorMessage)
        XCTAssertTrue(reopened.data.saved.contains(phrase.id))
        XCTAssertEqual(reopened.data.notes[phrase.id], "Can I bring up the timeline?")
        XCTAssertEqual(reopened.data.events.count, 1)
        XCTAssertEqual(reopened.data.events.first?.mode, "typed")
        XCTAssertEqual(reopened.data.reviews[phrase.id]?.due, now.addingTimeInterval(86400))
        XCTAssertEqual(reopened.data.focus, "connect")
        XCTAssertEqual(reopened.data.sortOrder, .reviewDate)
        XCTAssertEqual(reopened.data.accentColor, .purple)
        XCTAssertEqual(reopened.data.backgroundChoice, .waterLilies)
        XCTAssertEqual(reopened.data.themeChoice, .dark)
        XCTAssertTrue(reopened.data.showsAnswerByDefault)
        XCTAssertFalse(reopened.data.japaneseHints)
        XCTAssertEqual(reopened.data.meaningLanguage, .easyEnglish)
        reopened.configure(meaningLanguage: .japanese, showAnswerByDefault: false)
        let japanese = LearningStore(file: file)
        XCTAssertEqual(japanese.data.meaningLanguage, .japanese)
        XCTAssertFalse(japanese.data.showsAnswerByDefault)
        XCTAssertEqual(japanese.data.events.count, 1)
        XCTAssertTrue(japanese.data.saved.contains(phrase.id))
        for theme in AppTheme.allCases {
            japanese.configure(theme: theme, background: .clouds)
            let restored = LearningStore(file: file)
            XCTAssertEqual(restored.data.themeChoice, theme)
            XCTAssertEqual(restored.data.backgroundChoice, .clouds)
            XCTAssertEqual(restored.data.events.count, 1)
            XCTAssertTrue(restored.data.saved.contains(phrase.id))
        }
        XCTAssertTrue(reopened.data.gentleMode)
        XCTAssertEqual(reopened.data.rehearsalCount, 1)
    }

    @MainActor func testIntroductionShowsOnceForFreshInstallsOnly() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let fresh = LearningStore(file: file)
        XCTAssertTrue(fresh.isFreshInstall)
        XCTAssertTrue(fresh.data.needsOnboarding)
        XCTAssertEqual(fresh.data.meaningLanguage, .japanese)
        fresh.configureDefaultLanguage(japanese: false)
        XCTAssertEqual(fresh.data.meaningLanguage, .easyEnglish)
        fresh.finishOnboarding()
        XCTAssertFalse(fresh.data.needsOnboarding)
        // Finishing the introduction leaves the daily pace for the learner to confirm.
        XCTAssertNil(fresh.data.dailyNewGoal)
        let reopened = LearningStore(file: file)
        XCTAssertNil(reopened.errorMessage)
        XCTAssertTrue(reopened.data.onboardingDone)
        XCTAssertFalse(reopened.data.needsOnboarding)
        XCTAssertFalse(reopened.isFreshInstall)
        XCTAssertEqual(reopened.data.meaningLanguage, .easyEnglish)
        // A later device-language change never overrides the saved choice.
        reopened.configureDefaultLanguage(japanese: true)
        XCTAssertEqual(reopened.data.meaningLanguage, .easyEnglish)
        // Installs that chose a goal before the introduction existed never see it.
        var upgraded = LearningData()
        upgraded.dailyNewGoal = 10
        XCTAssertFalse(upgraded.needsOnboarding)
        var legacy = LearningData()
        legacy.onboardingDone = true
        XCTAssertFalse(legacy.needsOnboarding)
    }

    @MainActor func testDailyGoalCanBeDeclinedOnceAndStillChangedLater() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let store = LearningStore(file: file)
        XCTAssertTrue(store.data.needsDailyGoal)
        store.skipDailyGoal()
        XCTAssertFalse(store.data.needsDailyGoal)
        XCTAssertNil(store.data.dailyNewGoal)
        XCTAssertEqual(store.data.newPhrasesPerDay, 5)
        let reopened = LearningStore(file: file)
        XCTAssertFalse(reopened.data.needsDailyGoal)
        reopened.configureDailyGoal(10)
        XCTAssertEqual(reopened.data.newPhrasesPerDay, 10)
        XCTAssertFalse(LearningStore(file: file).data.needsDailyGoal)
    }

    @MainActor func testCorruptProgressIsNeverSilentlyOverwritten() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appending(path: "learning.json")
        let original = Data("preserve this broken file".utf8)
        try original.write(to: file)
        let store = LearningStore(file: file)
        XCTAssertNotNil(store.errorMessage)
        store.configure(focus: "plans")
        XCTAssertEqual(try Data(contentsOf: file), original)
    }

    func testOriginalSettingsDecodeWithoutANewLanguageKey() throws {
        let legacy = Data(#"{"schema":1,"reviews":{},"saved":["01-bring-up"],"notes":{},"events":[],"focus":"work","japaneseHints":false,"gentleMode":false,"onboardingDone":true,"rehearsalCount":2}"#.utf8)
        let decoded = try JSONDecoder().decode(LearningData.self, from: legacy)
        XCTAssertEqual(decoded.meaningLanguage, .easyEnglish)
        XCTAssertTrue(decoded.saved.contains("01-bring-up"))
        XCTAssertEqual(decoded.rehearsalCount, 2)
        XCTAssertNil(decoded.rehearsalDates)
        XCTAssertEqual(decoded.accentColor, .blue)
        XCTAssertEqual(decoded.backgroundChoice, .mountains)
        XCTAssertEqual(decoded.themeChoice, .system)
        XCTAssertFalse(decoded.showsAnswerByDefault)
        XCTAssertEqual(decoded.sortOrder, .alphabetical)
    }

    func testExamplesKeepDistinctLessonContexts() throws {
        let phrases = try Catalog.load()
        let bringUp = try XCTUnwrap(phrases.first { $0.id == "01-bring-up" })
        XCTAssertEqual(bringUp.examples, [bringUp.reply, bringUp.transferReply])
        for phrase in phrases {
            XCTAssertFalse(phrase.examples.isEmpty)
            XCTAssertEqual(Set(phrase.examples).count, phrase.examples.count)
            XCTAssertFalse(phrase.examples.contains(""))
        }
    }

    func testAlphabeticalSortBothDirectionsPreservesAllPhrases() throws {
        let phrases = try Catalog.load()
        let ascending = PhraseSort.alphabetical.ordered(phrases.reversed(), reviews: [:])
        XCTAssertEqual(ascending.first?.phrase, "a ballpark figure")
        XCTAssertEqual(ascending.last?.phrase, "zoom out")
        let descending = PhraseSort.reverseAlphabetical.ordered(phrases, reviews: [:])
        XCTAssertEqual(descending.map(\.id), ascending.reversed().map(\.id))
        XCTAssertEqual(Set(descending.map(\.id)), Set(phrases.map(\.id)))
        XCTAssertTrue(PhraseSort.reviewDate.ordered([Phrase](), reviews: [:]).isEmpty)
    }

    func testLearningSortUsesReviewDatesAndDeterministicTies() throws {
        let all = try Catalog.load()
        let names = ["wrap up", "bring up", "get across", "follow up"]
        let phrases = names.compactMap { name in all.first { $0.phrase == name } }
        let states: [String: ReviewState] = [
            phrases[0].id: .init(due: now.addingTimeInterval(100), reviews: 1),
            phrases[1].id: .init(due: now.addingTimeInterval(100), reviews: 2),
            phrases[2].id: .init(due: now.addingTimeInterval(-100), reviews: 1)
        ]
        XCTAssertEqual(PhraseSort.reviewDate.ordered(phrases, reviews: states).map(\.phrase), ["get across", "bring up", "wrap up", "follow up"])
        XCTAssertEqual(PhraseSort.unpracticed.ordered(phrases, reviews: states).map(\.phrase), ["follow up", "bring up", "get across", "wrap up"])
        let subset = phrases.filter { ["bring up", "follow up"].contains($0.phrase) }
        XCTAssertEqual(PhraseSort.reviewDate.ordered(subset, reviews: states).map(\.phrase), ["bring up", "follow up"])
    }

    func testGroupSortingKeepsMembershipAndUsesEarliestReview() throws {
        let phrases = try Catalog.load().filter { !$0.isIdiom }
        let groups = VerbGroup.groups(for: phrases)
        let into = try XCTUnwrap(phrases.first { $0.phrase == "look into" })
        let states = [into.id: ReviewState(due: now, reviews: 1)]
        let sorted = PhraseSort.reviewDate.ordered(groups, reviews: states)
        XCTAssertEqual(sorted.first?.verb, "look")
        XCTAssertEqual(sorted.first?.phrases.first?.id, into.id)
        XCTAssertEqual(Set(sorted.flatMap(\.phrases).map(\.id)), Set(phrases.map(\.id)))
        XCTAssertEqual(PhraseSort.reverseAlphabetical.ordered(groups, reviews: [:]).map(\.verb), groups.reversed().map(\.verb))
    }
    private func instant(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
    private func calendar(_ zone: String) -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(identifier: zone)!
        return result
    }

    func testStreakCountsCalendarDaysAndKeepsYesterdayUntilTodayEnds() {
        let cal = calendar("Asia/Tokyo")
        let dates = [instant("2026-09-10T23:30:00+09:00"), instant("2026-09-11T00:30:00+09:00"), instant("2026-09-11T20:00:00+09:00")]
        let today = instant("2026-09-12T12:00:00+09:00")
        let waiting = LearningStreak.calculate(dates: dates, now: today, calendar: cal)
        XCTAssertEqual(waiting.current, 2)
        XCTAssertEqual(waiting.longest, 2)
        XCTAssertEqual(waiting.activeDays.count, 2)
        let done = LearningStreak.calculate(dates: dates + [today, today], now: today, calendar: cal)
        XCTAssertEqual(done.current, 3)
        XCTAssertEqual(done.longest, 3)
        let missed = LearningStreak.calculate(dates: dates, now: instant("2026-09-13T00:00:00+09:00"), calendar: cal)
        XCTAssertEqual(missed.current, 0)
        XCTAssertEqual(missed.longest, 2)
    }

    func testBestStreakSurvivesGapsAndLeapDay() {
        let dates = ["2024-02-27", "2024-02-28", "2024-02-29", "2024-03-01", "2024-03-04", "2024-03-05"].map { instant($0 + "T12:00:00Z") }
        let result = LearningStreak.calculate(dates: dates.reversed(), now: instant("2024-03-05T13:00:00Z"), calendar: calendar("UTC"))
        XCTAssertEqual(result.current, 2)
        XCTAssertEqual(result.longest, 4)
    }

    func testStreakHandlesDSTAndTheCurrentTimeZone() {
        let cal = calendar("America/Los_Angeles")
        for values in [
            ["2026-03-07T12:00:00-08:00", "2026-03-08T12:00:00-07:00", "2026-03-09T12:00:00-07:00"],
            ["2025-11-01T12:00:00-07:00", "2025-11-02T12:00:00-08:00", "2025-11-03T12:00:00-08:00"]
        ] {
            let dates = values.map(instant)
            XCTAssertEqual(LearningStreak.calculate(dates: dates, now: dates.last!, calendar: cal).current, 3)
        }
        let dates = [instant("2026-09-11T23:30:00Z"), instant("2026-09-12T00:30:00Z")]
        XCTAssertEqual(LearningStreak.calculate(dates: dates, now: dates.last!, calendar: calendar("UTC")).current, 2)
        XCTAssertEqual(LearningStreak.calculate(dates: dates, now: dates.last!, calendar: calendar("Asia/Tokyo")).current, 1)
    }

    func testEmptyAndFutureActivityDoesNotCreateAStreak() {
        let cal = calendar("UTC")
        let empty = LearningStreak.calculate(dates: [], now: now, calendar: cal)
        XCTAssertEqual(empty.current, 0)
        XCTAssertEqual(empty.longest, 0)
        let future = LearningStreak.calculate(dates: [now.addingTimeInterval(60)], now: now, calendar: cal)
        XCTAssertEqual(future.current, 0)
        XCTAssertTrue(future.activeDays.isEmpty)
    }

    @MainActor func testStreakCombinesReviewsAndStoriesAndSurvivesRelaunch() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = directory.appending(path: "learning.json")
        let store = LearningStore(file: file)
        let phrase = try XCTUnwrap(store.phrases.first)
        let today = instant("2026-09-12T12:00:00Z")
        let cal = calendar("UTC")
        store.toggleSaved(phrase.id)
        store.note("My example", for: phrase.id)
        XCTAssertEqual(store.streak(now: today, calendar: cal).current, 0)
        store.rate(phrase, .again, mode: "typed", now: instant("2026-09-10T12:00:00Z"))
        store.finishRehearsal(now: instant("2026-09-11T12:00:00Z"))
        store.finishRehearsal(now: instant("2026-09-11T13:00:00Z"))
        let reopened = LearningStore(file: file)
        XCTAssertNil(reopened.errorMessage)
        XCTAssertEqual(reopened.streak(now: today, calendar: cal).current, 2)
        XCTAssertEqual(reopened.data.rehearsalCount, 2)
        XCTAssertEqual(reopened.data.rehearsalDates?.count, 2)
        reopened.rate(phrase, .effort, mode: "spoken", now: today)
        XCTAssertEqual(LearningStore(file: file).streak(now: today, calendar: cal).current, 3)
    }

}
