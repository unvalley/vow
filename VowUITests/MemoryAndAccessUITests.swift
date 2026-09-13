import XCTest
import StoreKitTest

@MainActor final class MemoryAndAccessUITests: XCTestCase {
    private var app: XCUIApplication!
    private func launch(_ arguments: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests"] + arguments
        app.launch()
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testReviewCardResetsAnswerAndKeepsControlsReachable() {
        launch()
        capture("design-today")
        app.buttons["Save featured phrase"].tap()
        XCTAssertTrue(app.buttons["Unsave featured phrase"].exists)
        capture("design-saved-feedback")
        app.buttons["startMemoryReview"].tap()
        let first = app.staticTexts["memoryPhrase"].label
        let headerBefore = app.staticTexts["sessionDailyProgress"].frame
        capture("design-review-prompt")
        app.buttons["revealMemory"].tap()
        XCTAssertTrue(app.staticTexts["memoryMeaning"].exists)
        XCTAssertTrue(app.buttons["memoryRate-good"].isHittable)
        XCTAssertEqual(app.staticTexts["sessionDailyProgress"].frame.minY, headerBefore.minY, accuracy: 1)
        capture("design-review-answer")
        app.buttons["memoryRate-good"].tap()
        XCTAssertNotEqual(app.staticTexts["memoryPhrase"].label, first)
        XCTAssertFalse(app.staticTexts["memoryMeaning"].exists)
        XCTAssertFalse(app.buttons["memoryRate-good"].exists)
        XCTAssertTrue(app.buttons["revealMemory"].isHittable)
        XCTAssertTrue(app.staticTexts["sessionDailyProgress"].label.contains("1 / 5 new"))
        capture("design-review-next")
    }

    func testDesignDarkReducedMotionAndLargeReview() {
        launch(["--design-dark", "--design-reduce-motion", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let start = app.buttons["startMemoryReview"]
        for _ in 0..<12 where !start.isHittable { app.swipeUp() }
        capture("design-dark-large-today")
        start.tap()
        let reveal = app.buttons["revealMemory"]
        for _ in 0..<12 where !reveal.isHittable { app.swipeUp() }
        capture("design-dark-large-prompt")
        reveal.tap()
        XCTAssertTrue(app.staticTexts["memoryMeaning"].exists)
        let rating = app.buttons["memoryRate-good"]
        for _ in 0..<12 where !rating.isHittable { app.swipeUp() }
        XCTAssertTrue(rating.isHittable)
        capture("design-dark-large-rating")
        rating.tap()
        XCTAssertTrue(app.staticTexts["memoryPhrase"].isHittable)
        XCTAssertFalse(app.staticTexts["memoryMeaning"].exists)
        capture("design-dark-large-next")
        app.buttons["closeMemory"].tap()
        app.tabBars.buttons["Phrases"].tap()
        let collection = app.buttons["libraryCollection"]
        for _ in 0..<6 where !collection.isHittable { app.swipeUp() }
        collection.tap()
        app.buttons["Idioms"].tap()
        XCTAssertTrue(app.staticTexts["450 idioms"].exists)
        capture("design-dark-large-library")
    }

    func testTodayAnswerDefaultIsUnifiedAndPersists() {
        launch()
        func changeDefault() {
            app.buttons["Practice settings"].tap()
            let toggle = app.switches["defaultAnswer"]
            for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            app.buttons["Done"].tap()
        }
        func assertVisibility(_ shown: Bool) {
            XCTAssertEqual(app.buttons["toggleAnswer"].value as? String, shown ? "Shown" : "Hidden")
            XCTAssertEqual(app.staticTexts["featuredMeaning"].exists, shown)
            XCTAssertEqual(app.staticTexts["featuredExample"].exists, shown)
        }
        assertVisibility(false)
        app.buttons["toggleAnswer"].tap()
        assertVisibility(true)
        app.buttons["Next phrase"].tap()
        assertVisibility(false)
        changeDefault()
        assertVisibility(true)
        app.buttons["toggleAnswer"].tap()
        assertVisibility(false)
        app.buttons["Previous phrase"].tap()
        assertVisibility(true)
        capture("today-unified-answer")
        app.terminate()
        app.launchArguments = ["--ui-tests"]
        app.launch()
        assertVisibility(true)
        changeDefault()
        assertVisibility(false)
    }

    func testDailyGoalSetupResumeCompletionAndChange() {
        launch(["--choose-daily-goal", "--free-access"])
        XCTAssertTrue(app.buttons["dailyGoal-3"].waitForExistence(timeout: 5))
        app.buttons["dailyGoal-3"].tap()
        capture("daily-goal-setup")
        let save = app.buttons["saveDailyGoal"]
        for _ in 0..<4 where !save.isHittable { app.swipeUp() }
        save.tap()
        XCTAssertTrue(app.buttons["editDailyGoal"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("0 / 3 new"))
        app.buttons["startMemoryReview"].tap()
        let first = app.staticTexts["memoryPhrase"].label
        app.buttons["revealMemory"].tap()
        XCTAssertTrue(app.staticTexts["memoryMeaning"].exists)
        XCTAssertTrue(app.staticTexts["featuredExample"].exists)
        app.buttons["memoryRate-good"].tap()
        app.buttons["closeMemory"].tap()
        app.terminate()
        app.launchArguments = ["--ui-tests", "--free-access"]
        app.launch()
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("1 / 3 new"))
        app.buttons["startMemoryReview"].tap()
        XCTAssertNotEqual(app.staticTexts["memoryPhrase"].label, first)
        for _ in 0..<2 {
            app.buttons["revealMemory"].tap()
            let rating = app.buttons["memoryRate-good"]
            if !rating.isHittable { app.swipeUp() }
            rating.tap()
        }
        XCTAssertTrue(app.buttons["finishMemory"].waitForExistence(timeout: 3))
        capture("daily-goal-complete")
        app.buttons["finishMemory"].tap()
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("3 / 3 new"))
        app.buttons["editDailyGoal"].tap()
        app.buttons["dailyGoal-10"].tap()
        let update = app.buttons["saveDailyGoal"]
        for _ in 0..<4 where !update.isHittable { app.swipeUp() }
        update.tap()
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("3 / 10 new"))
        capture("daily-goal-updated")
    }

    func testDailyGoalAndUnifiedAnswerAtLargestType() {
        launch(["--choose-daily-goal", "--free-access", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let choice = app.buttons["dailyGoal-3"]
        XCTAssertTrue(app.navigationBars["Daily learning"].waitForExistence(timeout: 5))
        for _ in 0..<4 where !choice.isHittable { app.swipeUp() }
        XCTAssertTrue(choice.isHittable)
        choice.tap()
        capture("daily-goal-largest-type")
        let save = app.buttons["saveDailyGoal"]
        for _ in 0..<8 where !save.isHittable { app.swipeUp() }
        save.tap()
        let answer = app.buttons["toggleAnswer"]
        for _ in 0..<8 where !answer.isHittable { app.swipeUp() }
        answer.tap()
        XCTAssertTrue(app.staticTexts["featuredMeaning"].exists)
        let meaning = app.staticTexts["featuredMeaning"]
        for _ in 0..<8 where !meaning.isHittable { app.swipeUp() }
        XCTAssertTrue(meaning.isHittable)
        capture("unified-answer-largest-type")
        let example = app.staticTexts["featuredExample"]
        for _ in 0..<8 where !example.isHittable { app.swipeUp() }
        XCTAssertTrue(example.isHittable)
        capture("unified-examples-largest-type")
    }

    func testSpacedReviewRevealsRatesAndPersistsDailyLimit() {
        launch(["--free-access"])
        app.buttons["startMemoryReview"].tap()
        XCTAssertTrue(app.staticTexts["memoryPhrase"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["memoryMeaning"].exists)
        XCTAssertFalse(app.buttons["memoryRate-good"].exists)
        capture("memory-question")
        for index in 0..<5 {
            app.buttons["revealMemory"].tap()
            XCTAssertTrue(app.staticTexts["memoryMeaning"].exists)
            if index == 0 {
                XCTAssertTrue(app.buttons["memoryRate-again"].label.contains("10m"))
                XCTAssertTrue(app.buttons["memoryRate-easy"].label.contains("4d"))
                capture("memory-answer")
            }
            let rating = app.buttons[index == 0 ? "memoryRate-again" : "memoryRate-good"]
            if !rating.isHittable { app.swipeUp() }
            rating.tap()
        }
        XCTAssertTrue(app.buttons["finishMemory"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["nextMemoryReview"].exists)
        capture("memory-complete")
        app.terminate()
        app.launchArguments = ["--ui-tests", "--free-access"]
        app.launch()
        app.buttons["startMemoryReview"].tap()
        XCTAssertTrue(app.buttons["finishMemory"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["memoryPhrase"].exists)
        app.buttons["finishMemory"].tap()
        app.tabBars.buttons["Stats"].tap()
        XCTAssertEqual(app.descendants(matching: .any).matching(identifier: "currentStreak").firstMatch.label, "Current streak, 1 day")
    }

    func testFreeCatalogUnlockAndRefundHidePaidContent() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Vow", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        defer { session.clearTransactions() }
        launch(["--free-access", "--store-tests"])
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertTrue(app.staticTexts["50 phrases"].waitForExistence(timeout: 5))
        capture("free-phrases-lock")
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh out")
        XCTAssertFalse(app.buttons["phraseRow-collection-flesh-out"].exists)
        XCTAssertTrue(app.buttons["unlockPro"].exists)
        app.buttons["unlockPro"].tap()
        XCTAssertTrue(app.staticTexts["Vow Pro"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["buyComplete"].waitForExistence(timeout: 10))
        app.buttons["buyComplete"].tap()
        XCTAssertTrue(app.staticTexts["purchaseUnlocked"].waitForExistence(timeout: 10))
        app.buttons["閉じる"].tap()
        let paidRow = app.buttons["phraseRow-collection-flesh-out"]
        XCTAssertTrue(paidRow.waitForExistence(timeout: 5))
        paidRow.tap()
        XCTAssertTrue(app.staticTexts["flesh out"].waitForExistence(timeout: 3))
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        XCTAssertTrue(app.buttons["unlockPro"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["flesh out"].exists)
        XCTAssertFalse(app.buttons["practicePhrase"].exists)
        capture("refund-locks-open-detail")
    }

    func testFreeSearchAndProCatalog() {
        launch(["--free-access"])
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertTrue(app.staticTexts["50 phrases"].waitForExistence(timeout: 3))
        capture("free-50-phrases")
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh out")
        XCTAssertFalse(app.buttons["phraseRow-collection-flesh-out"].exists)
        XCTAssertTrue(app.buttons["unlockPro"].exists)
        app.terminate()
        // Existing Debug-only entitlement fixture verifies Pro rendering, not a purchase.
        app.launchArguments = ["--ui-tests"]
        app.launch()
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertTrue(app.staticTexts["1,200 phrases"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["unlockPro"].exists)
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh out")
        app.buttons["phraseRow-collection-flesh-out"].tap()
        XCTAssertTrue(app.staticTexts["flesh out"].waitForExistence(timeout: 3))
    }

    func testTodayFreeBoundary() {
        launch(["--free-access"])
        XCTAssertTrue(app.staticTexts["Phrase 1 of 50"].waitForExistence(timeout: 3))
        for _ in 0..<49 { app.buttons["Next phrase"].tap() }
        XCTAssertTrue(app.staticTexts["Phrase 50 of 50"].waitForExistence(timeout: 3))
        app.buttons["Next phrase"].tap()
        XCTAssertTrue(app.buttons["unlockPro"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Next phrase"].isEnabled)
        XCTAssertFalse(app.buttons["toggleAnswer"].isHittable)
        capture("today-pro-lock")
        app.buttons["Previous phrase"].tap()
        XCTAssertTrue(app.staticTexts["Phrase 50 of 50"].waitForExistence(timeout: 3))
    }

    func testMemoryReviewAtLargestType() {
        launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        app.buttons["startMemoryReview"].tap()
        app.buttons["revealMemory"].tap()
        let easy = app.buttons["memoryRate-easy"]
        for _ in 0..<8 { if easy.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(easy.isHittable)
        capture("memory-large-type")
        easy.tap()
        XCTAssertTrue(app.buttons["revealMemory"].waitForExistence(timeout: 3))
    }
}


extension MemoryAndAccessUITests {
    func testReviewRemindersOptInPersistAndTurnOff() {
        launch(["--free-access"])
        app.buttons["startMemoryReview"].tap()
        XCTAssertTrue(app.buttons["revealMemory"].waitForExistence(timeout: 5))
        app.buttons["revealMemory"].tap()
        app.buttons["memoryRate-good"].tap()
        app.buttons["closeMemory"].tap()

        func openReminders() -> XCUIElement {
            app.buttons["Practice settings"].tap()
            let toggle = app.switches["reviewReminders"]
            for _ in 0..<4 where !toggle.isHittable { app.swipeUp() }
            XCTAssertTrue(toggle.isHittable)
            return toggle
        }
        let toggle = openReminders()
        XCTAssertEqual(toggle.value as? String, "0")
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allow = springboard.buttons["Allow"]
        if allow.waitForExistence(timeout: 3) { allow.tap() }
        XCTAssertTrue(app.otherElements["nextReviewReminder"].waitForExistence(timeout: 8)
                      || app.staticTexts["Next reminder"].waitForExistence(timeout: 3))
        XCTAssertEqual(toggle.value as? String, "1")
        capture("Review reminders enabled with next due notification")
        app.buttons["Done"].tap()
        app.terminate()
        app.launchArguments.removeAll { $0 == "--reset-ui-tests" }
        app.launch()
        let restored = openReminders()
        XCTAssertEqual(restored.value as? String, "1")
        restored.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        XCTAssertEqual(restored.value as? String, "0")
        XCTAssertFalse(app.datePickers["reviewReminderTime"].exists)
        capture("Review reminders disabled")
    }
}
