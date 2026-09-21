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

    /// iPhone shows a tab bar, where the tabs are taken by position — Home, Phrases, Settings —
    /// because their labels are localized and SwiftUI does not always carry the symbol identifier
    /// onto the button. iPad puts the same tabs in its toolbar, where the symbol does identify them.
    private func selectTab(_ index: Int, _ symbol: String) {
        let tabs = app.tabBars.firstMatch
        if tabs.waitForExistence(timeout: 5) {
            var tab = tabs.buttons.element(boundBy: index)
            for _ in 0..<10 where !tab.exists || !tab.isHittable {
                _ = tabs.waitForExistence(timeout: 1)
                tab = tabs.buttons.element(boundBy: index)
            }
            XCTAssertTrue(tab.exists, "No tab at position \(index)")
            tab.tap()
            return
        }
        let toolbarTab = app.buttons[symbol].firstMatch
        XCTAssertTrue(toolbarTab.waitForExistence(timeout: 10), "No tab for \(symbol)")
        toolbarTab.tap()
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

            // The idioms list as a free learner sees it, so a store image never features Pro-only
            // rows without saying so; the lesson below is the Pro page and stays marked as such.
            launch(language, ["--free-access"])
            selectTab(1, "rectangle.stack")
            // Collection segments are localized: All, Phrasal verbs, Idioms, Saved.
            app.buttons.matching(identifier: "libraryCollection").element(boundBy: 2).tap()
            let idiomRow = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "phraseRow-idiom-")).firstMatch
            XCTAssertTrue(idiomRow.waitForExistence(timeout: 5))
            capture("brand-\(language)-02-idioms")

            launch(language)
            selectTab(1, "rectangle.stack")
            app.searchFields.firstMatch.tap()
            app.searchFields.firstMatch.typeText("a clean slate")
            let lesson = app.buttons["phraseRow-idiom-a-clean-slate"]
            XCTAssertTrue(lesson.waitForExistence(timeout: 3))
            lesson.tap()
            XCTAssertTrue(app.staticTexts["a clean slate"].waitForExistence(timeout: 3))
            capture("brand-\(language)-03-lesson")

            // A phrasal verb's own page: its meaning, the core image of its particle, then examples.
            launch(language, ["--free-access"])
            selectTab(1, "rectangle.stack")
            app.searchFields.firstMatch.tap()
            app.searchFields.firstMatch.typeText("bring up")
            let phrase = app.buttons["phraseRow-01-bring-up"]
            XCTAssertTrue(phrase.waitForExistence(timeout: 3))
            phrase.tap()
            XCTAssertTrue(app.staticTexts["bring up"].waitForExistence(timeout: 3))
            capture("brand-\(language)-08-phrase")

            launch(language, ["--free-access"])
            selectTab(1, "rectangle.stack")
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
