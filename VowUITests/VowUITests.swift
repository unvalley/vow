import XCTest
import StoreKitTest

@MainActor final class VowUITests: XCTestCase {
    var app: XCUIApplication!
    func launchFresh(_ extra: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests"] + extra
        app.launch()
    }

    func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCoreImageGalleryMovementComparisonAndPhraseLinks() {
        launchFresh()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["coreImages"].tap()
        XCTAssertTrue(app.navigationBars["Core images"].waitForExistence(timeout: 3))
        capture("32-core-images")
        let into = app.buttons["particle-into"]
        if !into.isHittable { app.swipeUp() }
        into.tap()
        XCTAssertEqual(app.staticTexts["coreImageTitle"].label, "外から内側へ")
        let slider = app.sliders["diagramMovement"]
        XCTAssertTrue(slider.waitForExistence(timeout: 3))
        slider.adjust(toNormalizedSliderPosition: 0.25)
        capture("33-into-movement")
        let compare = app.buttons["compareParticle"]
        if !compare.isHittable { app.swipeUp() }
        compare.tap()
        XCTAssertTrue(app.navigationBars["into / in"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["境界の内側にある"].exists)
        capture("34-image-comparison")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.buttons["Practice settings"].tap()
        app.buttons["Easy English"].tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("put up with")
        app.buttons["phraseRow-48-put-up-with"].tap()
        XCTAssertTrue(app.buttons["phraseImage-up"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["phraseImage-with"].exists)
        app.buttons["phraseImage-with"].tap()
        XCTAssertTrue(app.staticTexts["Together; in connection"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.sliders["diagramMovement"].exists)
        capture("35-with-image")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        XCTAssertEqual(app.buttons["streakSummary"].label, "0-day streak")
    }

    func testCoreImageLargeTypeAndAliasSearch() {
        launchFresh(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["coreImages"].tap()
        XCTAssertTrue(app.navigationBars["Core images"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("upon")
        app.buttons["particle-on"].tap()
        XCTAssertTrue(app.staticTexts["coreImageTitle"].waitForExistence(timeout: 3))
        capture("36-core-image-large-type")
        let compare = app.buttons["compareParticle"]
        for _ in 0..<5 { if compare.isHittable { break }; app.swipeUp() }
        compare.tap()
        XCTAssertTrue(app.navigationBars["on / off"].waitForExistence(timeout: 3))
        capture("37-core-compare-large-type")
    }

    func testFreeAccessPurchaseScreenAndTrialPractice() throws {
        let config = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Vow", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: config)
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.clearTransactions() }
        launchFresh(["--free-access", "--store-tests"])
        app.buttons["Practice settings"].tap()
        app.buttons["completeSettings"].tap()
        XCTAssertTrue(app.buttons["buyComplete"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["buyComplete"].label.contains("900"))
        XCTAssertTrue(app.buttons["restorePurchases"].exists)
        capture("38-purchase-japanese")
        app.buttons["閉じる"].tap()
        app.buttons["Easy English"].tap()
        app.buttons["completeSettings"].tap()
        XCTAssertTrue(app.staticTexts["One purchase. No subscription."].waitForExistence(timeout: 3))
        capture("39-purchase-english")
        app.navigationBars.buttons["Done"].tap()
        app.navigationBars.buttons["Done"].tap()
        app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.navigationBars["Practice"].waitForExistence(timeout: 3))
        revealBySpeaking()
        XCTAssertTrue(app.staticTexts["revealedPhrase"].waitForExistence(timeout: 3))
        app.buttons["Close practice"].tap()
        app.buttons["Leave practice"].tap()
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh out")
        let row = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "phraseRow-")).firstMatch
        row.tap()
        let practice = app.buttons["practicePhrase"]
        for _ in 0..<5 { if practice.isHittable { break }; app.swipeUp() }
        XCTAssertEqual(practice.label, "Unlock speaking practice")
        practice.tap()
        XCTAssertTrue(app.buttons["buyComplete"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["revealedPhrase"].exists)
    }

    func testUnavailableStoreKeepsTrialUsableAndPaidPracticeLocked() {
        launchFresh(["--free-access"])
        app.buttons["Practice settings"].tap()
        app.buttons["completeSettings"].tap()
        XCTAssertTrue(app.buttons["reloadPrice"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.buttons["buyComplete"].exists)
        XCTAssertTrue(app.staticTexts["purchaseNotice"].exists)
        capture("40-purchase-unavailable")
        app.buttons["閉じる"].tap()
        app.buttons["Done"].tap()
        app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.navigationBars["Practice"].waitForExistence(timeout: 3))
        revealBySpeaking()
        XCTAssertTrue(app.staticTexts["revealedPhrase"].waitForExistence(timeout: 3))
        app.buttons["Close practice"].tap()
        app.buttons["Leave practice"].tap()
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh out")
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "phraseRow-")).firstMatch.tap()
        let practice = app.buttons["practicePhrase"]
        for _ in 0..<5 { if practice.isHittable { break }; app.swipeUp() }
        XCTAssertEqual(practice.label, "Unlock speaking practice")
        practice.tap()
        XCTAssertTrue(app.buttons["reloadPrice"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["revealedPhrase"].exists)
    }

    // iPadOS 18+ presents a floating tab control outside XCUIElementTypeTabBar.
    func selectTab(_ title: String) {
        let phoneTab = app.tabBars.buttons[title]
        if phoneTab.exists {
            phoneTab.tap()
        } else {
            let tabletTab = app.buttons[title].firstMatch
            XCTAssertTrue(tabletTab.waitForExistence(timeout: 5))
            tabletTab.tap()
        }
    }

    func testAppStoreScreenshots() {
        for language in ["ja", "en"] {
            launchFresh(["--free-access"])
            if language == "en" {
                app.buttons["Practice settings"].tap()
                app.buttons["Easy English"].tap()
                app.buttons["Done"].tap()
            }
            XCTAssertTrue(app.staticTexts["featuredPhrase"].waitForExistence(timeout: 5))
            capture("app-store-\(language)-01-today")
            selectTab("Phrases")
            XCTAssertTrue(app.buttons["coreImages"].waitForExistence(timeout: 3))
            capture("app-store-\(language)-02-phrases")
            app.buttons["coreImages"].tap()
            XCTAssertTrue(app.buttons["particle-in"].waitForExistence(timeout: 3))
            capture("app-store-\(language)-03-core-images")
            let into = app.buttons["particle-into"]
            if !into.isHittable { app.swipeUp() }
            into.tap()
            let compare = app.buttons["compareParticle"]
            if !compare.isHittable { app.swipeUp() }
            compare.tap()
            XCTAssertTrue(app.navigationBars["into / in"].waitForExistence(timeout: 3))
            capture("app-store-\(language)-04-comparison")
            selectTab("Today")
            app.buttons["dailyPractice"].tap()
            XCTAssertTrue(app.navigationBars["Practice"].waitForExistence(timeout: 3))
            capture("app-store-\(language)-05-practice")
        }
    }

    func revealBySpeaking() {
        let toggle = app.switches["I said my reply without recording"]
        if !toggle.isHittable { app.swipeUp() }
        toggle.tap()
        let advance = app.buttons["advanceReply"]
        if !advance.isHittable { app.swipeUp() }
        advance.tap()
    }

    func testDailyPracticeCompletesAndPersists() {
        launchFresh()
        XCTAssertEqual(app.buttons["streakSummary"].label, "0-day streak")
        capture("01-today")
        app.buttons["dailyPractice"].tap()
        XCTAssertTrue(app.navigationBars["Practice"].waitForExistence(timeout: 5))
        capture("02-retrieve")
        for index in 0..<3 {
            revealBySpeaking()
            XCTAssertTrue(app.staticTexts["revealedPhrase"].waitForExistence(timeout: 3))
            if index == 0 { capture("03-notice") }
            let transfer = app.buttons["tryTransfer"]
            if !transfer.isHittable { app.swipeUp() }
            transfer.tap()
            revealBySpeaking()
            let rating = app.buttons["rate-effort"]
            if !rating.isHittable { app.swipeUp() }
            rating.tap()
        }
        XCTAssertTrue(app.buttons["finishPractice"].waitForExistence(timeout: 3))
        capture("04-complete")
        app.buttons["finishPractice"].tap()
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(app.staticTexts["3"].firstMatch.waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.label, "Current streak, 1 day")
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "bestStreak").firstMatch.label, "Best streak, 1 day")
        capture("23-streak")
    }

    func testLibrarySearchSaveAndPersonalNote() {
        launchFresh()
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("get across")
        app.staticTexts["get across"].firstMatch.tap()
        app.buttons["Save phrase"].tap()
        XCTAssertTrue(app.buttons["Unsave phrase"].exists)
        capture("06-phrase")
        app.swipeUp()
        let field = app.descendants(matching: .any).matching(identifier: "personalNote").firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        field.tap()
        field.typeText("I want to get my idea across clearly.")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["get across"].exists)
        app.staticTexts["get across"].tap()
        app.swipeUp()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "personalNote").firstMatch.value as? String == "I want to get my idea across clearly.")
    }

    func testScenesAndSettings() {
        launchFresh()
        app.buttons["Practice settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        app.buttons["Easy English"].tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Scenes"].tap()
        capture("07-scenes")
        app.staticTexts["Friends & connection"].tap()
        XCTAssertTrue(app.buttons["Practice this scene"].waitForExistence(timeout: 3))
        capture("08-scene-detail")
    }

    func testTypedFallbackAndHintRating() {
        launchFresh()
        app.buttons["dailyPractice"].tap()
        app.buttons["Hint"].tap()
        app.buttons["Type a reply"].tap()
        let field = app.descendants(matching: .any).matching(identifier: "replyField").firstMatch
        field.tap()
        field.typeText("Can I bring up the deadline?")
        app.buttons["Done"].tap()
        app.buttons["advanceReply"].tap()
        let transfer = app.buttons["tryTransfer"]
        if !transfer.isHittable { app.swipeUp() }
        transfer.tap()
        let second = app.descendants(matching: .any).matching(identifier: "replyField").firstMatch
        second.tap()
        second.typeText("There is something I would like to bring up.")
        app.buttons["Done"].tap()
        app.buttons["advanceReply"].tap()
        app.swipeUp()
        XCTAssertFalse(app.buttons["rate-ready"].isEnabled)
        capture("09-hinted-reflection")
        app.buttons["rate-effort"].tap()
    }

    func testLargeTypeLayout() {
        launchFresh(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        capture("10-large-type")
        app.buttons["streakSummary"].tap()
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.exists)
        capture("25-streak-large-type")
        app.navigationBars.buttons.firstMatch.tap()
        app.tabBars.buttons["Scenes"].tap()
        capture("11-scenes-large-type")
        XCTAssertTrue(app.staticTexts["Meetings & ideas"].exists)
        app.tabBars.buttons["Today"].tap()
        let start = app.buttons["dailyPractice"]
        if !start.isHittable { app.swipeUp() }
        start.tap()
        capture("12-retrieve-large-type")
        XCTAssertTrue(app.buttons["Close practice"].exists)
    }


    func testFeaturedBrowsingSavesWithoutCreatingReviews() {
        launchFresh()
        XCTAssertTrue(app.staticTexts["bring up"].waitForExistence(timeout: 3))
        app.buttons["Next phrase"].tap()
        XCTAssertTrue(app.staticTexts["get across"].waitForExistence(timeout: 3))
        app.buttons["Save featured phrase"].tap()
        XCTAssertTrue(app.buttons["Unsave featured phrase"].exists)
        app.buttons["Show example"].tap()
        XCTAssertTrue(app.staticTexts["featuredExample"].waitForExistence(timeout: 3))
        capture("17-word-focus")
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["follow up"].waitForExistence(timeout: 3))
        app.buttons["Previous phrase"].tap()
        XCTAssertTrue(app.staticTexts["get across"].waitForExistence(timeout: 3))
        app.buttons["Phrase details"].tap()
        XCTAssertTrue(app.navigationBars["Phrase notes"].waitForExistence(timeout: 3))
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(app.staticTexts["No reviews yet."].exists)
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.label, "Current streak, 0 days")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["get across"].exists)
    }

    func testPreviewedPhraseIsNotRatedAsUnpromptedRecall() {
        launchFresh()
        XCTAssertTrue(app.staticTexts["bring up"].waitForExistence(timeout: 3))
        app.buttons["dailyPractice"].tap()
        revealBySpeaking()
        let transfer = app.buttons["tryTransfer"]
        if !transfer.isHittable { app.swipeUp() }
        transfer.tap()
        revealBySpeaking()
        app.swipeUp()
        XCTAssertFalse(app.buttons["rate-ready"].isEnabled)
        XCTAssertTrue(app.buttons["rate-effort"].isEnabled)
    }

    func testMeaningLanguageChangesAcrossScreensAndPersists() {
        launchFresh()
        let japanese = "話題を切り出す。"
        let english = "Start talking about a topic."
        XCTAssertTrue(app.staticTexts[japanese].waitForExistence(timeout: 3))
        app.buttons["Practice settings"].tap()
        app.buttons["Easy English"].tap()
        capture("18-language-settings")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts[english].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts[japanese].exists)
        capture("19-easy-english")
        app.buttons["Phrase details"].tap()
        XCTAssertTrue(app.staticTexts[english].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts[japanese].exists)
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        XCTAssertTrue(app.staticTexts[english].waitForExistence(timeout: 3))
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("Start talking about a topic")
        XCTAssertTrue(app.staticTexts["bring up"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts[english].exists)
        app.buttons["Close"].tap() // Dismiss native search and its keyboard before changing tabs.
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["dailyPractice"].waitForExistence(timeout: 3))
        app.buttons["dailyPractice"].tap()
        app.buttons["Hint"].tap()
        XCTAssertTrue(app.staticTexts[english].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts[japanese].exists)
        revealBySpeaking()
        XCTAssertTrue(app.staticTexts[english].waitForExistence(timeout: 3))
        capture("20-easy-english-practice")
        app.buttons["Close practice"].tap()
        XCTAssertTrue(app.buttons["Leave practice"].waitForExistence(timeout: 3))
        app.buttons["Leave practice"].tap()
        let settings = app.buttons["Practice settings"]
        let canOpenSettings = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: settings)
        XCTAssertEqual(XCTWaiter.wait(for: [canOpenSettings], timeout: 5), .completed)
        settings.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        app.buttons["日本語"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts[japanese].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts[english].exists)
    }

    func testVerbFamilyBrowsingAndPhraseNavigation() {
        launchFresh()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["By verb"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("look")
        let group = app.buttons["verbGroup-look"]
        XCTAssertTrue(group.waitForExistence(timeout: 3))
        capture("15-verbs")
        group.tap()
        XCTAssertTrue(app.navigationBars["look"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["16 phrases"].exists)
        if !app.staticTexts["look for"].isHittable { app.swipeUp() }
        XCTAssertTrue(app.staticTexts["look for"].exists)
        let phrase = app.staticTexts["look into"]
        if !phrase.isHittable { app.swipeUp() }
        XCTAssertTrue(phrase.isHittable)
        capture("16-look-family")
        phrase.tap()
        XCTAssertTrue(app.staticTexts["問題や可能性を調べる。"].waitForExistence(timeout: 3))
        app.buttons["Save phrase"].tap()
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["look into"].exists)
        XCTAssertFalse(app.staticTexts["look for"].exists)
    }

    func testStoryPracticeCompletesThreeTakes() {
        launchFresh()
        app.tabBars.buttons["Scenes"].tap()
        app.staticTexts["Friends & connection"].tap()
        let story = app.buttons["Story practice"]
        if !story.isHittable { app.swipeUp() }
        story.tap()
        capture("13-story-practice")
        for take in 0..<3 {
            let said = app.switches["I said my reply without recording"]
            if !said.isHittable { app.swipeUp() }
            said.tap()
            let next = app.buttons[take == 2 ? "Finish" : "Start take \(take + 2)"]
            if !next.isHittable { app.swipeUp() }
            next.tap()
        }
        XCTAssertTrue(app.staticTexts["rehearsalComplete"].waitForExistence(timeout: 3))
        capture("14-story-complete")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Practice"].tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.label, "Current streak, 1 day")
        capture("24-story-streak")
    }

    func testSortingAcrossCollectionsAndRelaunch() {
        launchFresh()
        app.buttons["Save featured phrase"].tap()
        app.buttons["Next phrase"].tap()
        let nextPhrase = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "get across"), object: app.staticTexts["featuredPhrase"])
        XCTAssertEqual(XCTWaiter.wait(for: [nextPhrase], timeout: 5), .completed)
        app.buttons["Save featured phrase"].tap()
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertFalse(app.staticTexts["Your words"].exists)
        XCTAssertTrue(app.buttons["phraseRow-collection-abide-by"].waitForExistence(timeout: 3))
        capture("21-phrases")
        app.buttons["Saved"].tap()
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'phraseRow-'"))
        XCTAssertEqual(rows.element(boundBy: 0).identifier, "phraseRow-01-bring-up")
        app.buttons["Sort phrases"].tap()
        capture("22-sort-menu")
        app.buttons["Z–A"].tap()
        XCTAssertEqual(rows.element(boundBy: 0).identifier, "phraseRow-02-get-across")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["Saved"].tap()
        XCTAssertEqual(rows.element(boundBy: 0).identifier, "phraseRow-02-get-across")
        app.buttons["By verb"].tap()
        XCTAssertTrue(app.buttons["verbGroup-zoom"].waitForExistence(timeout: 3))
        app.buttons["Sort phrases"].tap()
        app.buttons["A–Z"].tap()
        XCTAssertTrue(app.buttons["verbGroup-abide"].waitForExistence(timeout: 3))
        app.buttons["verbGroup-abide"].tap()
        app.buttons["Sort phrases"].tap()
        app.buttons["Review date"].tap()
        XCTAssertEqual(app.buttons["Sort phrases"].value as? String, "Review date")
        XCTAssertTrue(app.staticTexts["abide by"].exists)
    }

    func testImportedPhrasePracticeLanguageAndPersistence() {
        launchFresh()
        app.buttons["Practice settings"].tap()
        app.buttons["Easy English"].tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertTrue(app.staticTexts["614 phrases"].waitForExistence(timeout: 3))
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("zoom in")
        let row = app.buttons["phraseRow-collection-zoom-in"]
        XCTAssertTrue(row.waitForExistence(timeout: 3))
        row.tap()
        XCTAssertTrue(app.staticTexts["to focus more closely"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["“Can you zoom in on the picture?”"].exists)
        app.buttons["Save phrase"].tap()
        capture("26-imported-phrase")
        let practice = app.buttons["practicePhrase"]
        if !practice.isHittable { app.swipeUp() }
        practice.tap()
        XCTAssertTrue(app.staticTexts["Can you ____ ____ on the picture?"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["revealedPhrase"].exists)
        capture("27-imported-recall")
        revealBySpeaking()
        XCTAssertEqual(app.staticTexts["revealedPhrase"].label, "zoom in")
        let transfer = app.buttons["tryTransfer"]
        if !transfer.isHittable { app.swipeUp() }
        transfer.tap()
        XCTAssertTrue(app.staticTexts["Use the phrase in a different sentence about a real or imagined situation."].waitForExistence(timeout: 3))
        revealBySpeaking()
        XCTAssertTrue(app.buttons["Check your sentence"].exists)
        XCTAssertFalse(app.buttons["Compare the new situation"].exists)
        app.swipeUp()
        XCTAssertFalse(app.buttons["rate-ready"].isEnabled)
        app.buttons["rate-effort"].tap()
        XCTAssertTrue(app.buttons["finishPractice"].waitForExistence(timeout: 3))
        app.buttons["finishPractice"].tap()
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Practice"].tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.label, "Current streak, 1 day")
        app.tabBars.buttons["Today"].tap()
        app.buttons["Practice settings"].tap()
        app.buttons["日本語"].tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["zoom in"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["拡大する"].exists)
    }

    func testImportedAliasesSupplementAndEverydayScene() {
        launchFresh()
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("drop in")
        app.buttons["phraseRow-collection-drop-by"].tap()
        XCTAssertTrue(app.staticTexts["drop in"].waitForExistence(timeout: 3))
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Phrases"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("copy data")
        app.buttons["phraseRow-21-back-up"].tap()
        let more = app.buttons["More usage"]
        if !more.isHittable { app.swipeUp() }
        more.tap()
        XCTAssertTrue(app.staticTexts["“Make sure you back up your files.”"].waitForExistence(timeout: 3))
        capture("28-supplemental-usage")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Scenes"].tap()
        let everyday = app.staticTexts["Everyday English"]
        if !everyday.isHittable { app.swipeUp() }
        everyday.tap()
        XCTAssertTrue(app.staticTexts["534 phrases"].waitForExistence(timeout: 3))
        app.buttons["Practice this scene"].tap()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "1 of 6")).firstMatch.waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Complete the sentence."].exists)
    }

    func testCompleteCollectionNewEntriesAndAliases() {
        launchFresh()
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertTrue(app.staticTexts["614 phrases"].waitForExistence(timeout: 3))
        capture("29-complete-collection")
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("log out")
        app.buttons["phraseRow-collection-log-off"].tap()
        XCTAssertTrue(app.staticTexts["log out"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["ログアウトする"].exists)
        app.buttons["Save phrase"].tap()
        capture("30-complete-alias")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.buttons["Practice settings"].tap()
        app.buttons["Easy English"].tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["By verb"].tap()
        XCTAssertTrue(app.staticTexts["310 verbs"].waitForExistence(timeout: 3))
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh")
        app.buttons["verbGroup-flesh"].tap()
        app.buttons["phraseRow-collection-flesh-out"].tap()
        XCTAssertTrue(app.staticTexts["to add more details"].waitForExistence(timeout: 3))
        capture("31-complete-phrase")
        let practice = app.buttons["practicePhrase"]
        if !practice.isHittable { app.swipeUp() }
        practice.tap()
        XCTAssertTrue(app.staticTexts["We need to ____ ____ this plan before presenting it."].waitForExistence(timeout: 3))
        revealBySpeaking()
        XCTAssertEqual(app.staticTexts["revealedPhrase"].label, "flesh out")
        let transfer = app.buttons["tryTransfer"]
        if !transfer.isHittable { app.swipeUp() }
        transfer.tap()
        revealBySpeaking()
        app.swipeUp()
        app.buttons["rate-effort"].tap()
        XCTAssertTrue(app.buttons["finishPractice"].waitForExistence(timeout: 3))
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Practice"].tap()
        XCTAssertTrue(app.staticTexts["flesh out"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.label, "Current streak, 1 day")
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["Saved"].tap()
        XCTAssertTrue(app.staticTexts["log off"].waitForExistence(timeout: 3))
    }

}
