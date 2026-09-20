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
        // Today's goal lives on Home; Stats keeps streaks, the month and the next review.
        XCTAssertEqual(app.descendants(matching: .any)["currentStreak"].label, "Current streak, 0 days")
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
        XCTAssertEqual(app.descendants(matching: .any)["currentStreak"].label, "Current streak, 1 day")
        let today = Date.now.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
        reach(app.buttons["calendarDay-\(today)"])
        XCTAssertTrue(app.buttons["calendarDay-\(today)"].label.contains("1 expressions practiced"))
        app.buttons["closeStats"].tap()
    }

    func testRecordedStatsAndLargeText() {
        launch(["--stats-fixture", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertEqual(app.descendants(matching: .any)["currentStreak"].label, "Current streak, 7 days")
        capture("stats-large-top")
        // The calendar shows today's due count (overdue included) and the next scheduled review.
        let today = Date.now.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits))
        let todayCell = app.buttons["calendarDay-\(today)"]
        reach(todayCell)
        capture("stats-large-schedule")
        XCTAssertTrue(todayCell.label.contains("reviews due"))
        XCTAssertTrue(app.staticTexts["statsNextReview"].exists)
    }
}
