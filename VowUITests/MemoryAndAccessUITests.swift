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
        let first = app.buttons["featuredDetails"].label
        capture("design-review-prompt")
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.staticTexts["featuredMeaning"].exists)
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        XCTAssertTrue(app.buttons["memoryRate-good"].isHittable)
        capture("design-review-answer")
        app.buttons["memoryRate-good"].tap()
        XCTAssertNotEqual(app.buttons["featuredDetails"].label, first)
        XCTAssertFalse(app.staticTexts["featuredMeaning"].exists)
        XCTAssertFalse(app.buttons["memoryRate-good"].isEnabled)
        XCTAssertTrue(app.buttons["toggleAnswer"].isHittable)
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("1 / 5 new"))
        capture("design-review-next")
    }

    func testDesignDarkReducedMotionAndLargeReview() {
        launch(["--design-dark", "--design-reduce-motion", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        capture("design-dark-large-today")
        let reveal = app.buttons["toggleAnswer"]
        for _ in 0..<12 where !reveal.isHittable { app.swipeUp() }
        capture("design-dark-large-prompt")
        reveal.tap()
        XCTAssertTrue(app.staticTexts["featuredMeaning"].exists)
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        let rating = app.buttons["memoryRate-good"]
        for _ in 0..<12 where !rating.isHittable { app.swipeUp() }
        XCTAssertTrue(rating.isHittable)
        capture("design-dark-large-rating")
        rating.tap()
        // The answer sheet closes before the next card is ready to tap.
        let nextCard = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["featuredDetails"])
        XCTAssertEqual(XCTWaiter.wait(for: [nextCard], timeout: 5), .completed)
        XCTAssertFalse(app.staticTexts["featuredMeaning"].exists)
        capture("design-dark-large-next")
        app.tabBars.buttons["Phrases"].tap()
        let collection = app.buttons["libraryCollection"]
        for _ in 0..<6 where !collection.isHittable { app.swipeUp() }
        collection.tap()
        app.buttons["Idioms"].tap()
        XCTAssertTrue(app.staticTexts["500 idioms"].exists)
        capture("design-dark-large-library")
    }

    func testDailyGoalSetupResumeCompletionAndChange() {
        launch(["--choose-daily-goal", "--free-access"])
        XCTAssertTrue(app.buttons["dailyGoal-5"].waitForExistence(timeout: 5))
        app.buttons["dailyGoal-5"].tap()
        capture("daily-goal-setup")
        let save = app.buttons["saveDailyGoal"]
        for _ in 0..<4 where !save.isHittable { app.swipeUp() }
        save.tap()
        XCTAssertTrue(app.buttons["editDailyGoal"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("0 / 5 new"))
        let first = app.buttons["featuredDetails"].label
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.staticTexts["featuredMeaning"].exists)
        XCTAssertTrue(app.staticTexts["featuredExample"].exists)
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        app.buttons["memoryRate-good"].tap()
        app.terminate()
        app.launchArguments = ["--ui-tests", "--free-access"]
        app.launch()
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("1 / 5 new"))
        XCTAssertNotEqual(app.buttons["featuredDetails"].label, first)
        for _ in 0..<4 {
            app.buttons["toggleAnswer"].tap()
            XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
            app.buttons["closeAnswer"].tap()
            let rating = app.buttons["memoryRate-good"]
            if !rating.isHittable { app.swipeUp() }
            rating.tap()
        }
        XCTAssertTrue(app.buttons["exploreAfterLearning"].waitForExistence(timeout: 3))
        capture("daily-goal-complete")
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("5 / 5 new"))
        app.buttons["editDailyGoal"].tap()
        app.buttons["dailyGoal-10"].tap()
        let update = app.buttons["saveDailyGoal"]
        for _ in 0..<4 where !update.isHittable { app.swipeUp() }
        update.tap()
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("5 / 10 new"))
        capture("daily-goal-updated")
    }

    func testDailyGoalAndUnifiedAnswerAtLargestType() {
        launch(["--choose-daily-goal", "--free-access", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let choice = app.buttons["dailyGoal-5"]
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
        XCTAssertTrue(app.buttons["featuredDetails"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.staticTexts["featuredMeaning"].exists)
        XCTAssertFalse(app.buttons["memoryRate-good"].isEnabled)
        capture("memory-question")
        for index in 0..<5 {
            app.buttons["toggleAnswer"].tap()
            XCTAssertTrue(app.staticTexts["featuredMeaning"].exists)
            XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
            app.buttons["closeAnswer"].tap()
            if index == 0 {
                XCTAssertTrue(app.buttons["memoryRate-again"].label.contains("10m"))
                XCTAssertTrue(app.buttons["memoryRate-easy"].label.contains("4d"))
                capture("memory-answer")
            }
            let rating = app.buttons[index == 0 ? "memoryRate-again" : "memoryRate-good"]
            if !rating.isHittable { app.swipeUp() }
            rating.tap()
        }
        XCTAssertTrue(app.buttons["exploreAfterLearning"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["nextMemoryReview"].exists)
        capture("memory-complete")
        app.terminate()
        app.launchArguments = ["--ui-tests", "--free-access"]
        app.launch()
        XCTAssertTrue(app.buttons["exploreAfterLearning"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["featuredDetails"].exists)
        app.buttons["streakSummary"].tap()
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
        XCTAssertTrue(app.staticTexts["100 phrases"].waitForExistence(timeout: 5))
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
        XCTAssertTrue(app.staticTexts["100 phrases"].waitForExistence(timeout: 3))
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
        XCTAssertTrue(app.staticTexts["1,300 phrases"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["unlockPro"].exists)
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("flesh out")
        app.buttons["phraseRow-collection-flesh-out"].tap()
        XCTAssertTrue(app.staticTexts["flesh out"].waitForExistence(timeout: 3))
    }

    func testTodayFreeBoundary() {
        launch(["--free-access"])
        app.buttons["todayExploreMode"].tap()
        XCTAssertTrue(app.staticTexts["Phrase 1 of 100"].waitForExistence(timeout: 3))
        for _ in 0..<99 { app.buttons["Next phrase"].tap() }
        XCTAssertTrue(app.staticTexts["Phrase 100 of 100"].waitForExistence(timeout: 3))
        app.buttons["Next phrase"].tap()
        XCTAssertTrue(app.buttons["unlockPro"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["Next phrase"].isEnabled)
        XCTAssertFalse(app.buttons["toggleAnswer"].isHittable)
        capture("today-pro-lock")
        // The footer regains its rating row when a phrase returns; let the layout settle around the tap.
        let previous = app.buttons["Previous phrase"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: previous)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        previous.tap()
        XCTAssertTrue(app.staticTexts["Phrase 100 of 100"].waitForExistence(timeout: 5))
    }

    func testMemoryReviewAtLargestType() {
        launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        let reveal = app.buttons["toggleAnswer"]
        for _ in 0..<12 where !reveal.isHittable { app.swipeUp() }
        reveal.tap()
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        let easy = app.buttons["memoryRate-easy"]
        for _ in 0..<8 { if easy.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(easy.isHittable)
        capture("memory-large-type")
        easy.tap()
        XCTAssertTrue(app.buttons["toggleAnswer"].waitForExistence(timeout: 3))
    }
}


extension MemoryAndAccessUITests {
    func testReviewRemindersOptInPersistAndTurnOff() {
        launch(["--free-access"])
        XCTAssertTrue(app.buttons["toggleAnswer"].waitForExistence(timeout: 5))
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        let good = app.buttons["memoryRate-good"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: good)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed)
        good.tap()

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
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == '1'"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 10), .completed)
        // Notifications sit low in Settings now; the next-reminder row is below the toggle.
        let nextRow = app.otherElements["nextReviewReminder"]
        for _ in 0..<3 where !nextRow.exists && !app.staticTexts["Next reminder"].exists { app.swipeUp() }
        XCTAssertTrue(nextRow.exists || app.staticTexts["Next reminder"].exists)
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
