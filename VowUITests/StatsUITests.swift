import XCTest

@MainActor final class StatsUITests: XCTestCase {
    private var app: XCUIApplication!

    /// Stats open as a sheet from the flame on Home.
    private func launch(_ extra: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests"] + extra
        app.launch()
        app.buttons["streakSummary"].tap()
        XCTAssertTrue(app.navigationBars["Stats"].waitForExistence(timeout: 5))
    }

    private func reach(_ element: XCUIElement) {
        for _ in 0..<16 where !element.isHittable { app.swipeUp() }
        XCTAssertTrue(element.isHittable)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testEmptyStatsAndLearningEntry() {
        launch()
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "0 / 5 new expressions")
        XCTAssertEqual(app.staticTexts["statsDueNow"].label, "0 reviews due now")
        capture("stats-empty-top")
        let schedule = app.staticTexts["Study your first expression to start a review schedule."]
        reach(schedule)
        capture("stats-empty-schedule")
        for _ in 0..<12 where !app.buttons["statsReviewNow"].isHittable { app.swipeDown() }
        app.buttons["statsReviewNow"].tap()
        XCTAssertTrue(app.buttons["revealMemory"].waitForExistence(timeout: 3))
        app.buttons["revealMemory"].tap()
        // Home keeps its own (disabled) rating row behind the sheets; rate on the review screen.
        let good = app.buttons.matching(identifier: "memoryRate-good").allElementsBoundByIndex.first { $0.isHittable }
        XCTAssertNotNil(good)
        good?.tap()
        app.buttons["closeMemory"].tap()
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "1 / 5 new expressions")
        app.buttons["closeStats"].tap()
        XCTAssertTrue(app.buttons["todayLearningMode"].waitForExistence(timeout: 5))
    }

    func testRecordedStatsAndLargeText() {
        launch(["--stats-fixture", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "2 / 5 new expressions")
        capture("stats-large-top")
        let upcoming = app.descendants(matching: .any).matching(identifier: "statsUpcomingChart").firstMatch
        reach(upcoming)
        capture("stats-large-schedule")
        let overdue = app.staticTexts["statsOverdue"]
        reach(overdue)
        XCTAssertTrue(overdue.label.contains("5 overdue expressions"))
        XCTAssertTrue(app.staticTexts["statsNextReview"].exists)
    }
}
