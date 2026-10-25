import XCTest

/// Where the free plan meets Izzy Pro: the end of the free deck on Home, a search that finds a Pro
/// expression, a verb family with more in Pro, and the purchase screen each of them opens.
@MainActor final class ProConversionUITests: XCTestCase {
    private var app: XCUIApplication!
    private func launch(_ arguments: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--free-access", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"] + arguments
        app.launch()
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testTheLevelCheckSetsHomesLevelsAndLeadsIntoPro() {
        launch(["--show-onboarding", "--locale-language"])
        for _ in 0..<2 { app.buttons["onboardingContinue"].tap() }
        XCTAssertTrue(app.staticTexts["レベルを確かめる。"].waitForExistence(timeout: 5))
        capture("level-check-invitation")
        app.buttons["levelCheckStart"].tap()
        XCTAssertTrue(app.staticTexts["levelCheckPhrase"].waitForExistence(timeout: 5))
        capture("level-check-question")
        // Not knowing any of them recommends the easiest band.
        for _ in 0..<8 {
            let notSure = app.buttons["levelCheckNotSure"]
            let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: notSure)
            XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 5), .completed)
            notSure.tap()
        }
        XCTAssertTrue(app.staticTexts["おすすめはA1・A2。"].waitForExistence(timeout: 5))
        capture("level-check-result")
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.staticTexts["もっと学ぶなら、Pro。"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'A1・A2'")).firstMatch.exists,
                      "the Pro page speaks of the learner's own levels")
        capture("level-check-pro")
    }

    func testHomeSaysWhenTheFreePlanIsFinished() {
        launch(["--free-finished-fixture"])
        let pro = app.buttons["completionPro"]
        XCTAssertTrue(pro.waitForExistence(timeout: 5), "the free deck's end names Pro on Home")
        capture("pro-home-free-finished")
        pro.tap()
        XCTAssertTrue(app.descendants(matching: .any)["purchaseProgress"].waitForExistence(timeout: 5),
                      "the purchase screen shows the learner's own progress")
        XCTAssertTrue(app.descendants(matching: .any)["purchaseNextUp"].exists, "and the Pro expressions Home would bring next")
        XCTAssertTrue(app.buttons["buyComplete"].waitForExistence(timeout: 10) || app.buttons["startTrial"].exists
                      || app.buttons["reloadPrice"].exists, "the way forward is pinned in reach")
        capture("pro-purchase-from-home")
    }

    func testTheFirstFinishedDayOffersAReminderThatCanWait() {
        launch(["--completion-steps"])
        // Today's five new phrases; the last answer moves on to the completion.
        for index in 0..<5 {
            let rating = app.buttons["memoryRate-good"]
            XCTAssertTrue(rating.waitForExistence(timeout: 5))
            let card = app.buttons["featuredDetails"].label
            rating.tap()
            if index < 4 { app.waitForFeaturedPhrase(toChangeFrom: card) }
        }
        let remind = app.buttons["completionReminder"]
        XCTAssertTrue(remind.waitForExistence(timeout: 5), "a finished day asks what will bring the learner back")
        capture("completion-reminder")
        app.buttons["completionReminderLater"].tap()
        XCTAssertFalse(remind.waitForExistence(timeout: 2), "not now puts it off")
        capture("completion-after-not-now")
    }

    func testSearchFindsProExpressionsInsteadOfNothing() {
        launch()
        app.tabBars.buttons.element(boundBy: 1).tap() // Phrases, named in Japanese here
        let search = app.descendants(matching: .any)["librarySearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("give up")
        let locked = app.buttons["lockedRow-69-give-up"]
        XCTAssertTrue(locked.waitForExistence(timeout: 5), "a Pro match is listed, not hidden")
        capture("pro-search-locked")
        locked.tap()
        XCTAssertTrue(app.staticTexts["purchasePhrase"].waitForExistence(timeout: 5), "the purchase screen leads with the phrase")
        capture("pro-purchase-from-search")
    }

    func testVerbFamilySaysHowManyMoreProHolds() {
        launch()
        app.tabBars.buttons.element(boundBy: 1).tap() // Phrases, named in Japanese here
        let search = app.descendants(matching: .any)["librarySearch"]
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("look")
        app.buttons["libraryFilter"].tap()
        app.buttons["動詞でまとめる"].tap()
        let family = app.buttons["verbGroup-look"]
        XCTAssertTrue(family.waitForExistence(timeout: 5))
        family.tap()
        let more = app.buttons["verbGroupUnlockPro"]
        for _ in 0..<8 where !more.isHittable { app.swipeUp() }
        XCTAssertTrue(more.isHittable)
        capture("pro-verb-family")
    }
}
