import XCTest

@MainActor final class SettingsLocalizationUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(language: String = "ja", reset: Bool = true, largeType: Bool = false) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "-AppleLanguages", "(\(language))", "-AppleLocale", language == "ja" ? "ja_JP" : "en_US"]
        if reset { app.launchArguments.append("--reset-ui-tests") }
        if largeType { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
        app.buttons["practiceSettings"].tap()
    }

    private func reach(_ element: XCUIElement) {
        let viewport = app.frame.insetBy(dx: 0, dy: 100)
        for _ in 0..<12 {
            // Offscreen rows in a large-type Form can have no activation point.
            // Scroll them into view before asking XCTest for hittability.
            if element.exists, viewport.contains(CGPoint(x: element.frame.midX, y: element.frame.midY)), element.isHittable {
                return
            }
            // A row left above the viewport by an earlier scroll needs the opposite direction.
            if element.exists, !element.frame.isEmpty, element.frame.midY < viewport.minY { app.swipeDown() } else { app.swipeUp() }
        }
        XCTFail("Could not scroll to \(element)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testJapaneseSettingsAndSavedChoicesAcrossLanguages() {
        launch()
        XCTAssertTrue(app.navigationBars["設定"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["completeSettings"].label, "購入済み")
        XCTAssertTrue(app.buttons["todayBackground"].label.contains("山"))
        capture("settings-japanese")
        app.buttons["todayBackground"].tap()
        XCTAssertTrue(app.buttons["background-ocean"].label.contains("海"))
        app.buttons["background-ocean"].tap()
        capture("settings-japanese-background")
        app.navigationBars.buttons["設定"].tap()
        app.buttons["dailyGoalSettings"].tap()
        XCTAssertTrue(app.navigationBars["1日で学習するフレーズ数"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.buttons["dailyGoal-10"].label, "1日10表現")
        app.buttons["dailyGoal-10"].tap()
        reach(app.buttons["saveDailyGoal"])
        XCTAssertEqual(app.buttons["saveDailyGoal"].label, "学習量を保存")
        capture("settings-japanese-daily-goal")
        app.buttons["saveDailyGoal"].tap()
        XCTAssertTrue(app.buttons["dailyGoalSettings"].label.contains("1日10表現"))
        reach(app.buttons["やさしい英語"])
        app.buttons["やさしい英語"].tap()
        XCTAssertTrue(app.navigationBars["設定"].exists)
        app.buttons["完了"].tap()
        app.terminate()

        launch(reset: false)
        XCTAssertTrue(app.buttons["todayBackground"].label.contains("海"))
        XCTAssertTrue(app.buttons["dailyGoalSettings"].label.contains("1日10表現"))
        app.terminate()

        launch(language: "en", reset: false)
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["todayBackground"].label.contains("Ocean"))
        XCTAssertTrue(app.buttons["dailyGoalSettings"].label.contains("10 new / day"))
        capture("settings-english")
    }

    func testJapaneseDetailsAndLargeType() {
        launch(largeType: true)
        // Rows are visited in layout order: Learning, then Notifications, then About.
        reach(app.buttons["difficultySettings"])
        app.buttons["difficultySettings"].tap()
        XCTAssertTrue(app.navigationBars["難易度の表示"].waitForExistence(timeout: 3))
        reach(app.buttons["difficultyScale-eiken"])
        XCTAssertTrue(app.buttons["difficultyScale-eiken"].label.contains("英検"))
        reach(app.buttons["難易度について"])
        app.buttons["難易度について"].tap()
        XCTAssertTrue(app.navigationBars["難易度の目安"].waitForExistence(timeout: 3))
        capture("settings-japanese-difficulty-large")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reach(app.switches["reviewReminders"])
        XCTAssertEqual(app.switches["reviewReminders"].label, "復習のリマインダー")
        capture("settings-japanese-notifications-large")
        reach(app.buttons["プライバシーポリシー"])
        app.buttons["プライバシーポリシー"].tap()
        XCTAssertTrue(app.staticTexts["プライバシー"].waitForExistence(timeout: 3))
        capture("settings-japanese-privacy-large")
        app.navigationBars.buttons.element(boundBy: 0).tap()
        reach(app.buttons["学習の進め方"])
        app.buttons["学習の進め方"].tap()
        XCTAssertTrue(app.staticTexts["答えを見る前に思い出す"].waitForExistence(timeout: 3))
        capture("settings-japanese-method-large")
    }
}
