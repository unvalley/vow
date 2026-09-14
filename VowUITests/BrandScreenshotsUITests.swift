import XCTest

@MainActor final class BrandScreenshotsUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(_ language: String, _ arguments: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests"] + arguments
        app.launch()
        XCTAssertTrue(app.buttons["Practice settings"].waitForExistence(timeout: 5))
        if language == "en" {
            app.buttons["Practice settings"].tap()
            let english = app.buttons["Easy English"]
            XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
            func isVisible() -> Bool {
                guard english.exists else { return false }
                let frame = english.frame
                return !frame.isEmpty && frame.minY > app.frame.minY + 80 && frame.maxY < app.frame.maxY - 60
            }
            for _ in 0..<8 {
                if isVisible() { break }
                app.swipeUp()
            }
            XCTAssertTrue(isVisible())
            english.tap()
            app.buttons["Done"].tap()
        }
    }

    private func selectTab(_ title: String) {
        let phone = app.tabBars.buttons[title]
        if phone.exists {
            phone.tap()
        } else {
            let tablet = app.buttons[title].firstMatch
            XCTAssertTrue(tablet.waitForExistence(timeout: 5))
            tablet.tap()
        }
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
            app.buttons["editDailyGoal"].tap()
            XCTAssertTrue(app.buttons["dailyGoal-5"].waitForExistence(timeout: 3))
            capture("brand-\(language)-05-goal")

            launch(language)
            selectTab("Phrases")
            app.buttons["Idioms"].tap()
            XCTAssertTrue(app.staticTexts["500 idioms"].waitForExistence(timeout: 3))
            capture("brand-\(language)-02-idioms")
            app.searchFields.firstMatch.tap()
            app.searchFields.firstMatch.typeText("a clean slate")
            let lesson = app.buttons["phraseRow-idiom-a-clean-slate"]
            XCTAssertTrue(lesson.waitForExistence(timeout: 3))
            lesson.tap()
            XCTAssertTrue(app.staticTexts["a clean slate"].waitForExistence(timeout: 3))
            capture("brand-\(language)-03-lesson")

            launch(language, ["--free-access"])
            selectTab("Phrases")
            app.buttons["coreImages"].tap()
            XCTAssertTrue(app.buttons["particle-in"].waitForExistence(timeout: 3))
            capture("brand-\(language)-06-core")

            launch(language, ["--stats-fixture"])
            selectTab("Stats")
            XCTAssertTrue(app.staticTexts["statsDailyProgress"].waitForExistence(timeout: 3))
            if app.tabBars.firstMatch.exists {
                let axis = app.staticTexts["Days since first study →"]
                let bottom = app.tabBars.firstMatch.frame.minY - 24
                for _ in 0..<4 {
                    if axis.exists && axis.frame.maxY < bottom { break }
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.72))
                        .press(forDuration: 0.1, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.50)))
                }
                XCTAssertTrue(axis.exists)
                XCTAssertLessThan(axis.frame.maxY, bottom)
                XCTAssertGreaterThan(app.staticTexts["forgettingIllustrationNote"].frame.minY, app.frame.minY + 60)
            }
            capture("brand-\(language)-07-stats")
        }
    }
}
