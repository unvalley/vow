import XCTest

@MainActor final class OnboardingUITests: XCTestCase {
    func testIntroductionAndCompletionPersist() {
        let app = XCUIApplication()
        // A fresh install has no purchase, so the last page invites rather than confirms.
        // --locale-language applies the production default: an English device starts in Easy English.
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--show-onboarding", "--free-access", "--locale-language", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        let titles = ["Learn real English.", "Remember for good.", "More with Izzy Pro."]
        for (index, title) in titles.enumerated() {
            XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10))
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "onboarding-\(index + 1)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
            if index == 2 {
                app.buttons["onboardingPro"].tap()
                XCTAssertTrue(app.buttons["restorePurchases"].waitForExistence(timeout: 5))
                // The purchase screen follows the same language as the introduction.
                app.buttons["Done"].tap()
                XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
            }
            app.buttons["onboardingContinue"].tap()
        }
        // The introduction hands over to the daily goal sheet; the pace is never confirmed silently.
        let save = app.buttons["saveDailyGoal"]
        XCTAssertTrue(save.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboardingContinue"].exists)
        let goalScreenshot = XCTAttachment(screenshot: app.screenshot())
        goalScreenshot.name = "onboarding-4-daily-goal"
        goalScreenshot.lifetime = .keepAlways
        add(goalScreenshot)
        for _ in 0..<4 where !save.isHittable { app.swipeUp() }
        save.tap()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["todayPhrases"].waitForExistence(timeout: 10))
        XCTAssertTrue(((app.buttons["todayPhrases"].value as? String) ?? "").contains("0 / 5 new"))
        app.terminate()
        app.launchArguments = ["--ui-tests", "--show-onboarding", "--free-access", "--locale-language", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboardingContinue"].exists)
        XCTAssertFalse(app.buttons["saveDailyGoal"].exists)
        XCTAssertTrue(app.buttons["todayPhrases"].waitForExistence(timeout: 10))
        XCTAssertTrue(((app.buttons["todayPhrases"].value as? String) ?? "").contains("0 / 5 new"))
    }

    func testJapaneseDevicesStartInJapanese() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--show-onboarding", "--free-access", "--locale-language", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        XCTAssertTrue(app.staticTexts["使える英語を、毎日。"].waitForExistence(timeout: 10))
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.staticTexts["復習で、身につく。"].waitForExistence(timeout: 5))
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.staticTexts["もっと学ぶなら、Pro。"].waitForExistence(timeout: 5))
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "onboarding-ja-3"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        app.buttons["onboardingPro"].tap()
        XCTAssertTrue(app.buttons["閉じる"].waitForExistence(timeout: 5))
    }

    func testPurchasedLearnersSeeAnActiveProPage() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--show-onboarding", "--locale-language", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.buttons["onboardingContinue"].waitForExistence(timeout: 10))
        app.buttons["onboardingContinue"].tap()
        app.buttons["onboardingContinue"].tap()
        XCTAssertTrue(app.staticTexts["Izzy Pro is ready."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["onboardingPro"].exists)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "onboarding-3-purchased"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }

    func testExistingLearnersWithADailyGoalSkipTheIntroduction() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["onboardingContinue"].exists)
        XCTAssertFalse(app.buttons["saveDailyGoal"].exists)
    }
}


























