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
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        XCTAssertFalse(app.buttons["startMemoryReview"].exists)
        XCTAssertFalse(app.buttons["featuredScene"].exists)
        XCTAssertTrue(app.buttons["memoryRate-good"].isEnabled, "ratings are available without opening the answer")
        let first = phrase
        app.buttons["featuredDetails"].swipeLeft()
        assertPosition(2, total: 5)
        let selected = phrase
        XCTAssertNotEqual(selected, first)
        capture("today-learning-swipe")

        app.buttons["todayExploreMode"].tap()
        assertPosition(1, total: 1370)
        app.buttons["featuredDetails"].swipeLeft()
        assertPosition(2, total: 1370)
        let explored = phrase
        XCTAssertFalse(app.buttons["featuredScene"].exists)
        XCTAssertTrue(app.buttons["memoryRate-good"].isEnabled, "ratings are available without opening the answer")
        XCTAssertFalse(app.buttons["startMemoryReview"].exists)
        XCTAssertFalse(app.buttons["todayPhrases"].exists)
        capture("today-explore-swipe")

        app.buttons["todayLearningMode"].tap()
        assertPosition(2, total: 5)
        XCTAssertEqual(phrase, selected)
        XCTAssertTrue(((app.buttons["todayPhrases"].value as? String) ?? "").contains("0 / 5 new"))
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        XCTAssertTrue(app.buttons["memoryRate-good"].waitForExistence(timeout: 5))
        app.buttons["memoryRate-good"].tap()
        app.waitForFeaturedPhrase(toChangeFrom: selected)
        // The answered card stays in today's deck; the next card is the one after it.
        assertPosition(3, total: 5)
        XCTAssertNotEqual(phrase, selected)
        XCTAssertTrue(((app.buttons["todayPhrases"].value as? String) ?? "").contains("1 / 5 new"))
        app.buttons["todayExploreMode"].tap()
        assertPosition(2, total: 1370)
        XCTAssertEqual(phrase, explored)
    }

    private func saveGoal() {
        let save = app.buttons["saveDailyGoal"]
        for _ in 0..<6 where !save.isHittable { app.swipeUp() }
        save.tap()
    }

    func testGoalOfTwentyAndFreeExploreBoundary() {
        launch(["--choose-daily-goal", "--free-access"])
        app.buttons["dailyGoal-20"].tap()
        saveGoal()
        assertPosition(1, total: 20)
        app.buttons["todayExploreMode"].tap()
        // Explore counts the whole collection on the free plan too.
        assertPosition(1, total: 1370)
        app.buttons["Next phrase"].tap()
        assertPosition(2, total: 1370)
        app.buttons["todayLearningMode"].tap()
        assertPosition(1, total: 20)
        XCTAssertTrue(((app.buttons["todayPhrases"].value as? String) ?? "").contains("0 / 20 new"))
        capture("today-free-goal-20")
    }

    func testCompletionOffersExploreAndIncreasingGoalRefillsLearning() {
        launch(["--choose-daily-goal"])
        app.buttons["dailyGoal-5"].tap()
        saveGoal()
        for _ in 0..<5 {
            app.buttons["toggleAnswer"].tap()
            XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
            app.buttons["closeAnswer"].tap()
            XCTAssertTrue(app.buttons["memoryRate-good"].waitForExistence(timeout: 5))
            let shown = app.buttons["featuredDetails"].label
            app.buttons["memoryRate-good"].tap()
            let moved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@ OR exists == false", shown), object: app.buttons["featuredDetails"])
            XCTAssertEqual(XCTWaiter.wait(for: [moved], timeout: 5), .completed)
        }
        XCTAssertTrue(app.buttons["exploreAfterLearning"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["todayPosition"].label, "Today's learning complete")
        capture("today-learning-complete")
        app.buttons["exploreAfterLearning"].tap()
        assertPosition(1, total: 1370)
        app.buttons["todayLearningMode"].tap()
        app.buttons["todayPhrases"].tap()
        app.buttons["changeDailyGoal"].tap()
        app.buttons["dailyGoal-10"].tap()
        saveGoal()
        app.buttons["closeTodayPhrases"].tap()
        // Five answered cards stay; learning resumes at the first of the five new ones.
        assertPosition(6, total: 10)
    }

    func testModesAndPagingAtLargestTypeWithReducedMotion() {
        executionTimeAllowance = 240
        launch(["--design-dark", "--design-reduce-motion", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.buttons["todayLearningMode"].isHittable)
        XCTAssertGreaterThanOrEqual(app.buttons["todayExploreMode"].frame.minY,
                                    app.buttons["todayLearningMode"].frame.maxY)
        app.buttons["todayExploreMode"].tap()
        capture("today-modes-largest-type")
        let next = app.buttons["Next phrase"]
        for _ in 0..<12 {
            if next.exists && next.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(next.isHittable)
        next.tap()
        assertPosition(2, total: 1370)
        for _ in 0..<12 {
            if app.buttons["todayLearningMode"].isHittable { break }
            app.swipeDown()
        }
        app.buttons["todayLearningMode"].tap()
        let reveal = app.buttons["toggleAnswer"]
        for _ in 0..<12 {
            if reveal.exists && reveal.isHittable { break }
            app.swipeUp()
        }
        reveal.tap()
        XCTAssertTrue(app.buttons["closeAnswer"].waitForExistence(timeout: 5))
        app.buttons["closeAnswer"].tap()
        let rating = app.buttons["memoryRate-easy"]
        for _ in 0..<12 {
            if rating.exists && rating.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(rating.isHittable)
        capture("today-learning-largest-type")
        rating.tap()
        // The answer sheet closes before the next card is ready to tap.
        let nextCard = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: app.buttons["featuredDetails"])
        XCTAssertEqual(XCTWaiter.wait(for: [nextCard], timeout: 5), .completed)
        XCTAssertFalse(app.staticTexts["featuredMeaning"].exists)
    }
}
