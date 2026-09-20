import XCTest

@MainActor final class ListeningUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(japanese: Bool = false, large: Bool = false) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--free-access", "-AppleLanguages", japanese ? "(ja)" : "(en)", "-AppleLocale", japanese ? "ja_JP" : "en_US"]
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
    }

    private func reach(_ element: XCUIElement, down: Bool = false) {
        for _ in 0..<15 {
            if element.exists, app.frame.insetBy(dx: 0, dy: 100).contains(CGPoint(x: element.frame.midX, y: element.frame.midY)), element.isHittable { return }
            if down { app.swipeDown() } else { app.swipeUp() }
        }
        XCTFail("Unreachable control: \(element.identifier)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testAutomaticPlaybackBackgroundAndAudioHandoff() async throws {
        executionTimeAllowance = 180
        launch()
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["openListening"].tap()
        XCTAssertTrue(app.staticTexts["listeningCount"].label.contains("100"))
        for identifier in ["listeningMeanings", "listeningExamples"] {
            let toggle = app.switches[identifier]
            reach(toggle)
            toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        }
        reach(app.buttons["startListening"])
        app.buttons["startListening"].tap()
        let phrase = app.staticTexts["listeningPhrase"]
        XCTAssertTrue(phrase.waitForExistence(timeout: 10))
        let first = phrase.label
        let advanced = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in phrase.exists && phrase.label != first }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [advanced], timeout: 25), .completed)
        app.buttons["listeningPlayPause"].tap()
        XCTAssertEqual(app.buttons["listeningPlayPause"].label, "Play")
        let paused = phrase.label
        app.buttons["listeningNext"].tap()
        XCTAssertNotEqual(phrase.label, paused)
        XCTAssertEqual(app.buttons["listeningPlayPause"].label, "Play")
        capture("listening-player-paused")
        app.buttons["listeningPlayPause"].tap()
        let beforeBackground = app.staticTexts["listeningPosition"].label
        XCUIDevice.shared.press(.home)
        try await Task.sleep(for: .seconds(8))
        app.activate()
        XCTAssertNotEqual(app.staticTexts["listeningPosition"].label, beforeBackground)
        XCTAssertEqual(app.buttons["listeningPlayPause"].label, "Pause")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["listeningMiniPlayer"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Home"].tap()
        XCTAssertEqual(app.buttons["miniListeningPlayPause"].label, "Pause")
        XCTAssertTrue(((app.buttons["todayPhrases"].value as? String) ?? "").contains("0 / 5 new"))
        app.buttons["Hear phrase"].tap()
        XCTAssertEqual(app.buttons["miniListeningPlayPause"].label, "Play")
        capture("listening-mini-player-handoff")
        app.buttons["miniStopListening"].tap()
        XCTAssertFalse(app.buttons["listeningMiniPlayer"].exists)
    }

    func testFreeIdiomsAndProPromptAppearAfterExpressions() {
        launch()
        app.tabBars.buttons["Phrases"].tap()
        XCTAssertTrue(app.staticTexts["100 phrases"].exists)
        XCTAssertFalse(app.buttons["unlockPro"].isHittable)
        app.buttons["Idioms"].tap()
        XCTAssertTrue(app.staticTexts["50 idioms"].exists)
        XCTAssertFalse(app.buttons["unlockPro"].isHittable)
        let rows = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'phraseRow-idiom-'")).allElementsBoundByIndex
        XCTAssertFalse(rows.isEmpty)
        capture("phrases-free-idioms-before-pro")
        reach(app.buttons["unlockPro"])
        capture("phrases-pro-between-rows")
        app.buttons["unlockPro"].tap()
        XCTAssertTrue(app.staticTexts["Izzy Pro"].waitForExistence(timeout: 5))
    }

    func testPracticeExitUsesAlertAndStatsHasNoExtraHeading() {
        launch()
        app.buttons["streakSummary"].tap()
        XCTAssertFalse(app.staticTexts["Your rhythm"].exists)
        capture("stats-without-extra-heading")
        app.buttons["closeStats"].tap()
        app.buttons["dailyPractice"].tap()
        // Nothing done yet: closing leaves at once, without the alert.
        app.buttons["Close practice"].tap()
        XCTAssertTrue(app.buttons["todayLearningMode"].waitForExistence(timeout: 5))
        app.buttons["dailyPractice"].tap()
        // A typed reply is progress worth confirming before leaving.
        reach(app.buttons["replyMode"])
        app.buttons["replyMode"].tap()
        let reply = app.descendants(matching: .any).matching(identifier: "replyField").firstMatch
        reply.tap()
        reply.typeText("I will bring it up.")
        app.buttons["Close practice"].tap()
        let alert = app.alerts["Leave this practice?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        capture("practice-exit-alert")
        alert.buttons["Keep practicing"].tap()
        XCTAssertTrue(app.buttons["Close practice"].exists)
        app.buttons["Close practice"].tap()
        alert.buttons["Leave practice"].tap()
        XCTAssertTrue(app.buttons["todayLearningMode"].waitForExistence(timeout: 5))
    }

    func testJapaneseListeningOptionsAtLargestTextSize() {
        executionTimeAllowance = 180
        launch(japanese: true, large: true)
        app.tabBars.buttons["Phrases"].tap()
        reach(app.buttons["openListening"])
        app.buttons["openListening"].tap()
        XCTAssertTrue(app.navigationBars["聞き流し"].waitForExistence(timeout: 5))
        capture("listening-japanese-large-options")
        reach(app.buttons["startListening"])
        XCTAssertEqual(app.buttons["startListening"].label, "聞き流しを開始")
        XCTAssertTrue(app.buttons["startListening"].isEnabled)
        capture("listening-japanese-large-start")
    }
}
