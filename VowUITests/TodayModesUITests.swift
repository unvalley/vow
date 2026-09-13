import XCTest

@MainActor final class TodayModesUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(_ arguments: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests"] + arguments
        app.launch()
        if !arguments.contains("--choose-daily-goal") {
            XCTAssertTrue(app.buttons["todayLearningMode"].waitForExistence(timeout: 10))
        }
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private var phrase: String { app.buttons["featuredDetails"].label }
    private func assertPosition(_ position: Int, total: Int) {
        XCTAssertEqual(app.staticTexts["todayPosition"].label.replacingOccurrences(of: ",", with: ""), "Phrase \(position) of \(total)")
    }

    func testSwipeModesKeepPositionAndReviewSelectedExpression() {
        launch()
        assertPosition(1, total: 5)
        let first = phrase
        app.buttons["featuredDetails"].swipeLeft()
        assertPosition(2, total: 5)
        let selected = phrase
        XCTAssertNotEqual(selected, first)
        capture("today-learning-swipe")

        app.buttons["todayExploreMode"].tap()
        assertPosition(1, total: 1200)
        app.buttons["featuredDetails"].swipeLeft()
        assertPosition(2, total: 1200)
        let explored = phrase
        XCTAssertFalse(app.buttons["startMemoryReview"].exists)
        XCTAssertFalse(app.buttons["editDailyGoal"].exists)
        capture("today-explore-swipe")

        app.buttons["todayLearningMode"].tap()
        assertPosition(2, total: 5)
        XCTAssertEqual(phrase, selected)
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("0 / 5 new"))
        openLearning()
        XCTAssertTrue(app.staticTexts["memoryPhrase"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["memoryPhrase"].label, selected)
        app.buttons["revealMemory"].tap()
        XCTAssertTrue(app.buttons["memoryRate-good"].waitForExistence(timeout: 5))
        app.buttons["memoryRate-good"].tap()
        app.buttons["closeMemory"].tap()
        assertPosition(1, total: 4)
        XCTAssertNotEqual(phrase, selected)
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("1 / 5 new"))
        app.buttons["todayExploreMode"].tap()
        assertPosition(2, total: 1200)
        XCTAssertEqual(phrase, explored)
    }

    private func openLearning() {
        app.buttons["startMemoryReview"].tap()
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { [self] _, _ in
            let mode = app.buttons["todayLearningMode"]
            return app.buttons["revealMemory"].exists && (!mode.exists || !mode.isHittable)
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 10), .completed)
    }

    private func saveGoal() {
        let save = app.buttons["saveDailyGoal"]
        for _ in 0..<6 where !save.isHittable { app.swipeUp() }
        save.tap()
    }

    func testGoalAboveTwentyAndFreeExploreBoundary() {
        launch(["--choose-daily-goal", "--free-access"])
        app.buttons["dailyGoal-20"].tap()
        let increment = app.buttons["dailyGoalCount-Increment"]
        for _ in 0..<4 where !increment.isHittable { app.swipeUp() }
        increment.tap()
        increment.tap()
        saveGoal()
        assertPosition(1, total: 22)
        app.buttons["todayExploreMode"].tap()
        assertPosition(1, total: 50)
        app.buttons["Next phrase"].tap()
        assertPosition(2, total: 50)
        app.buttons["todayLearningMode"].tap()
        assertPosition(1, total: 22)
        XCTAssertTrue(app.buttons["editDailyGoal"].label.contains("0 / 22 new"))
        capture("today-free-goal-22")
    }

    func testCompletionOffersExploreAndIncreasingGoalRefillsLearning() {
        launch(["--choose-daily-goal"])
        app.buttons["dailyGoal-3"].tap()
        saveGoal()
        openLearning()
        for _ in 0..<3 {
            app.buttons["revealMemory"].tap()
            XCTAssertTrue(app.buttons["memoryRate-good"].waitForExistence(timeout: 5))
        app.buttons["memoryRate-good"].tap()
        }
        app.buttons["finishMemory"].tap()
        XCTAssertTrue(app.buttons["exploreAfterLearning"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["todayPosition"].exists)
        capture("today-learning-complete")
        app.buttons["exploreAfterLearning"].tap()
        assertPosition(1, total: 1200)
        app.buttons["todayLearningMode"].tap()
        app.buttons["editDailyGoal"].tap()
        app.buttons["dailyGoal-10"].tap()
        saveGoal()
        assertPosition(1, total: 7)
    }

    func testModesAndPagingAtLargestTypeWithReducedMotion() {
        launch(["--design-dark", "--design-reduce-motion", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.buttons["todayLearningMode"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["todayExploreMode"].frame.minY,
                                    app.buttons["todayLearningMode"].frame.maxY)
        app.buttons["todayExploreMode"].tap()
        capture("today-modes-largest-type")
        let next = app.buttons["Next phrase"]
        for _ in 0..<12 where !next.isHittable { app.swipeUp() }
        XCTAssertTrue(next.isHittable)
        next.tap()
        assertPosition(2, total: 1200)
        for _ in 0..<12 where !app.buttons["todayLearningMode"].isHittable { app.swipeDown() }
        app.buttons["todayLearningMode"].tap()
        let start = app.buttons["startMemoryReview"]
        for _ in 0..<12 where !start.isHittable { app.swipeUp() }
        XCTAssertTrue(start.isHittable)
        capture("today-learning-largest-type")
    }
}
