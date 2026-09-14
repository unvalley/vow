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
        // Stats no longer starts a review; rate on Home and come back to see the count move.
        app.buttons["closeStats"].tap()
        XCTAssertTrue(app.buttons["todayLearningMode"].waitForExistence(timeout: 5))
        let first = app.buttons["featuredDetails"].label
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        app.buttons["memoryRate-good"].tap()
        app.waitForFeaturedPhrase(toChangeFrom: first)
        app.buttons["streakSummary"].tap()
        XCTAssertTrue(app.navigationBars["Stats"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "1 / 5 new expressions")
        let today = Date.now.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
        reach(app.buttons["calendarDay-\(today)"])
        XCTAssertEqual(app.buttons["calendarDay-\(today)"].value as? String, "practiced")
        app.buttons["closeStats"].tap()
    }

    func testRecordedStatsAndLargeText() {
        launch(["--stats-fixture", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "2 / 5 new expressions")
        capture("stats-large-top")
        // The calendar shows today's due count (overdue included) and the next scheduled review.
        let today = Date.now.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
        let todayCell = app.buttons["calendarDay-\(today)"]
        reach(todayCell)
        capture("stats-large-schedule")
        XCTAssertTrue((todayCell.value as? String)?.contains("reviews due") == true)
        XCTAssertTrue(app.staticTexts["statsNextReview"].exists)
    }
}
