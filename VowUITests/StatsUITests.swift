import XCTest

@MainActor final class StatsUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(_ extra: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests"] + extra
        app.launch()
        app.tabBars.buttons["Stats"].tap()
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

    func testEmptyStatsCurveComparisonAndLearningEntry() {
        launch()
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "0 / 5 new expressions")
        XCTAssertEqual(app.staticTexts["statsDueNow"].label, "0 reviews due now")
        capture("stats-empty-top")
        let toggle = app.switches["compareSpacedReviews"]
        reach(toggle)
        let curve = app.descendants(matching: .any).matching(identifier: "forgettingCurve").firstMatch
        reach(curve)
        toggle.tap()
        XCTAssertTrue(String(describing: curve.value).contains("declines over 30 days"))
        toggle.tap()
        XCTAssertTrue(String(describing: curve.value).contains("days 1, 7 and 22"))
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.75)).press(forDuration: 0.05,
            thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)))
        capture("stats-forgetting-comparison")
        let upcoming = app.descendants(matching: .any).matching(identifier: "statsUpcomingChart").firstMatch
        reach(upcoming)
        XCTAssertTrue(app.staticTexts["Study your first expression to start a review schedule."].exists)
        capture("stats-empty-schedule")
        for _ in 0..<12 where !app.buttons["statsReviewNow"].isHittable { app.swipeDown() }
        app.buttons["statsReviewNow"].tap()
        XCTAssertTrue(app.buttons["revealMemory"].waitForExistence(timeout: 3))
        app.buttons["revealMemory"].tap()
        app.buttons["memoryRate-good"].tap()
        app.buttons["closeMemory"].tap()
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "1 / 5 new expressions")
    }

    func testRecordedStatsAndLargeText() {
        launch(["--stats-fixture", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertEqual(app.staticTexts["statsDailyProgress"].label, "2 / 5 new expressions")
        capture("stats-large-top")
        let toggle = app.switches["compareSpacedReviews"]
        reach(toggle)
        capture("stats-large-curve-intro")
        toggle.tap()
        let curve = app.descendants(matching: .any).matching(identifier: "forgettingCurve").firstMatch
        reach(curve)
        capture("stats-large-curve")
        let activity = app.descendants(matching: .any).matching(identifier: "statsActivityChart").firstMatch
        reach(activity)
        capture("stats-large-activity")
        let upcoming = app.descendants(matching: .any).matching(identifier: "statsUpcomingChart").firstMatch
        reach(upcoming)
        capture("stats-large-schedule")
        let overdue = app.staticTexts["statsOverdue"]
        reach(overdue)
        XCTAssertTrue(overdue.label.contains("5 overdue expressions"))
        XCTAssertTrue(app.staticTexts["statsNextReview"].exists)
    }
}
