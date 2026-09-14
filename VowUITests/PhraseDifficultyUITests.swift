import XCTest

@MainActor final class PhraseDifficultyUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(_ extra: [String] = []) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--free-access"] + extra
        app.launch()
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testDifficultyDisplayPersistsAndFilterCarriesIntoVerbFamily() {
        launch()
        XCTAssertTrue(app.buttons["phraseDifficulty"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["phraseDifficulty"].label.contains("B1"))
        capture("difficulty-today-cefr")
        app.buttons["phraseDifficulty"].tap()
        XCTAssertTrue(app.navigationBars["Difficulty guide"].waitForExistence(timeout: 3))
        capture("difficulty-guide")
        app.buttons["Done"].tap()
        app.buttons["Practice settings"].tap()
        let settings = app.buttons["difficultySettings"]
        for _ in 0..<3 where !settings.isHittable { app.swipeUp() }
        settings.tap()
        app.buttons["difficultyScale-ielts"].tap()
        capture("difficulty-scale-settings")
        app.navigationBars.buttons["Settings"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["phraseDifficulty"].label.contains("IELTS"))
        capture("difficulty-today-ielts")
        app.terminate()
        app.launchArguments = ["--ui-tests", "--free-access"]
        app.launch()
        XCTAssertTrue(app.buttons["phraseDifficulty"].label.contains("IELTS"))
        app.tabBars.buttons["Phrases"].tap()
        app.buttons["difficultyFilter"].tap()
        app.buttons["A2 · Elementary"].tap()
        XCTAssertEqual(app.buttons["difficultyFilter"].value as? String, "A2")
        capture("difficulty-library-a2")
        app.buttons["By verb"].tap()
        let look = app.buttons["verbGroup-look"]
        for _ in 0..<3 where !look.isHittable { app.swipeUp() }
        look.tap()
        XCTAssertTrue(app.buttons["phraseRow-25-look-for"].exists)
        XCTAssertFalse(app.buttons["phraseRow-26-look-into"].exists)
        XCTAssertFalse(app.buttons["phraseRow-collection-look-at"].exists)
        capture("difficulty-verb-family-a2")
        app.buttons["phraseRow-25-look-for"].tap()
        XCTAssertTrue(app.buttons["phraseDifficulty"].label.contains("A2"))
        capture("difficulty-detail")
    }

    func testDifficultyIsReadableAtLargestDynamicType() {
        launch(["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.buttons["phraseDifficulty"].waitForExistence(timeout: 5))
        capture("difficulty-today-largest-type")
        app.buttons["phraseDifficulty"].tap()
        XCTAssertTrue(app.navigationBars["Difficulty guide"].waitForExistence(timeout: 3))
        capture("difficulty-guide-largest-type")
    }

    func testEikenUsesGradesAndPersistsOnHome() {
        launch()
        app.buttons["practiceSettings"].tap()
        let settings = app.buttons["difficultySettings"]
        for _ in 0..<5 where !settings.isHittable { app.swipeUp() }
        settings.tap()
        app.buttons["difficultyScale-eiken"].tap()
        app.navigationBars.buttons["Settings"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["phraseDifficulty"].label.contains("英検 ≈2級"))
        app.buttons["phraseDifficulty"].tap()
        XCTAssertTrue(app.staticTexts["difficultyIntroduction"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["≈3級"].exists)
        capture("home-eiken-guide")
        app.buttons["Done"].tap()
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.buttons["memoryRate-easy"].isEnabled)
        capture("home-inline-ratings-eiken")
        app.terminate()
        app.launchArguments = ["--ui-tests", "--free-access"]
        app.launch()
        XCTAssertTrue(app.buttons["phraseDifficulty"].label.contains("英検 ≈2級"))
    }

    func testJapaneseHomeRatingsAndGradeGuide() {
        launch(["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"])
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
        app.buttons["practiceSettings"].tap()
        let settings = app.buttons["difficultySettings"]
        for _ in 0..<5 where !settings.isHittable { app.swipeUp() }
        settings.tap()
        app.buttons["difficultyScale-eiken"].tap()
        app.navigationBars.buttons["設定"].tap()
        app.buttons["完了"].tap()
        app.buttons["toggleAnswer"].tap()
        XCTAssertTrue(app.staticTexts["意味を思い出せた？"].exists)
        XCTAssertTrue(app.buttons["memoryRate-easy"].label.contains("簡単"))
        XCTAssertTrue(app.buttons["memoryRate-easy"].isHittable)
        capture("home-japanese-inline-ratings")
        app.buttons["phraseDifficulty"].tap()
        XCTAssertTrue(app.navigationBars["難易度の目安"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["≈3級"].exists)
        capture("home-japanese-grade-guide")
    }
}
