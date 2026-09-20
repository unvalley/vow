import XCTest

@MainActor final class BrandScreenshotsUITests: XCTestCase {
    private var app: XCUIApplication!

    /// Runs as a Japanese or an English device, so the interface and the meaning language match the
    /// store and website listings: a fresh install takes its meaning language from the device.
    private func launch(_ language: String, _ arguments: [String] = []) {
        app = XCUIApplication()
        let locale = language == "ja"
            ? ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
            : ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--locale-language"] + locale + arguments
        app.launch()
        XCTAssertTrue(app.buttons["todayLearningMode"].waitForExistence(timeout: 10))
    }

    /// Tab labels are localized, so the tabs are addressed by their symbol identifiers:
    /// `house`, `rectangle.stack`, `slider.horizontal.3`.
    private func selectTab(_ symbol: String) {
        let tab = app.tabBars.buttons[symbol]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testCurrentStoreScreenshots() {
        continueAfterFailure = false
        for language in ["ja", "en"] {
            launch(language, ["--free-access"])
            capture("brand-\(language)-01-today")
            app.buttons["toggleAnswer"].tap()
            XCTAssertTrue(app.staticTexts["featuredMeaning"].waitForExistence(timeout: 3))
            capture("brand-\(language)-04-review")
            app.buttons["closeAnswer"].tap()
            app.buttons["todayPhrases"].tap()
            XCTAssertTrue(app.buttons["changeDailyGoal"].waitForExistence(timeout: 3))
            app.buttons["changeDailyGoal"].tap()
            XCTAssertTrue(app.buttons["dailyGoal-5"].waitForExistence(timeout: 3))
            capture("brand-\(language)-05-goal")

            launch(language)
            selectTab("rectangle.stack")
            // Collection segments are localized: All, Phrasal verbs, Idioms, Saved.
            app.buttons.matching(identifier: "libraryCollection").element(boundBy: 2).tap()
            let idiomRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "phraseRow-idiom-")).firstMatch
            XCTAssertTrue(idiomRow.waitForExistence(timeout: 5))
            capture("brand-\(language)-02-idioms")
            app.searchFields.firstMatch.tap()
            app.searchFields.firstMatch.typeText("a clean slate")
            let lesson = app.buttons["phraseRow-idiom-a-clean-slate"]
            XCTAssertTrue(lesson.waitForExistence(timeout: 3))
            lesson.tap()
            XCTAssertTrue(app.staticTexts["a clean slate"].waitForExistence(timeout: 3))
            capture("brand-\(language)-03-lesson")

            launch(language, ["--free-access"])
            selectTab("rectangle.stack")
            app.buttons["coreImages"].tap()
            XCTAssertTrue(app.buttons["particle-in"].waitForExistence(timeout: 3))
            capture("brand-\(language)-06-core")

            // Stats is a sheet from the streak on Home, holding the streaks and the month calendar.
            launch(language, ["--stats-fixture"])
            app.buttons["streakSummary"].tap()
            XCTAssertTrue(app.descendants(matching: .any)["currentStreak"].waitForExistence(timeout: 5))
            capture("brand-\(language)-07-stats")
        }
    }
}
