import XCTest

@MainActor final class AppReviewReadinessUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(resetMicrophone: Bool = false) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--reset-ui-tests", "--free-access", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        if resetMicrophone { app.resetAuthorizationStatus(for: .microphone) }
        app.launch()
    }

    private func reach(_ element: XCUIElement) {
        let viewport = app.frame.insetBy(dx: 0, dy: 100)
        for _ in 0..<12 {
            if element.exists, viewport.contains(CGPoint(x: element.frame.midX, y: element.frame.midY)), element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Could not scroll to \(element)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testSupportAndPrivacyAreAvailableWithoutPurchasing() {
        launch()
        app.buttons["practiceSettings"].tap()
        let terms = app.descendants(matching: .any).matching(identifier: "settingsTerms").firstMatch
        reach(terms)
        XCTAssertEqual(terms.label, "利用規約")
        let contact = app.buttons["contactSupport"]
        reach(contact)
        contact.tap()
        XCTAssertTrue(app.navigationBars["ヘルプ・お問い合わせ"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "supportWebsite").firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(identifier: "supportEmail").firstMatch.exists)
        app.buttons["copySupportEmail"].tap()
        XCTAssertTrue(app.buttons["copySupportEmail"].label.contains("コピーしました"))
        capture("review-support-japanese-free")
        reach(app.buttons["プライバシーポリシー"])
        app.buttons["プライバシーポリシー"].tap()
        let policy = app.descendants(matching: .any).matching(identifier: "onlinePrivacyPolicy").firstMatch
        reach(policy)
        XCTAssertEqual(policy.label, "公開プライバシーポリシーを読む")
        capture("review-privacy-japanese-free")
    }

    func testJapaneseMicrophoneDenialKeepsTypedAndSpokenPracticeAvailable() {
        launch(resetMicrophone: true)
        app.buttons["dailyPractice"].tap()
        let record = app.buttons["recordReply"]
        reach(record)
        record.tap()
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        // SpringBoard resolves this string using the device language, not the
        // app-only AppleLanguages launch argument. Run on a Japanese device to
        // also verify the Japanese system dialog (see App Review checklist).
        let japaneseSystem = Locale.preferredLanguages.first?.hasPrefix("ja") == true
        let purpose = japaneseSystem ? "練習の回答を録音し" : "Record a practice reply and listen back."
        capture("review-microphone-permission")
        XCTAssertTrue(alert.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", purpose)).firstMatch.exists,
                      "The system permission dialog must use its bundled localized purpose string.")
        let deny = alert.buttons.matching(NSPredicate(format: "label IN %@", ["Don’t Allow", "Don't Allow", "許可しない"])).firstMatch
        XCTAssertTrue(deny.exists)
        deny.tap()
        let settings = app.buttons["microphoneSettings"]
        reach(settings)
        XCTAssertTrue(app.staticTexts["voiceMessage"].label.contains("マイクの使用が許可されていません"))
        capture("review-microphone-denied")
        // A permission refusal must not gate either alternative or the lesson.
        app.swipeDown()
        let spoken = app.switches["spokenWithoutRecording"]
        reach(spoken)
        spoken.tap()
        XCTAssertTrue(app.buttons["advanceReply"].isEnabled)
        let mode = app.buttons["replyMode"]
        reach(mode)
        mode.tap()
        let reply = app.descendants(matching: .any).matching(identifier: "replyField").firstMatch
        reply.tap()
        reply.typeText("I want to get my idea across.")
        app.toolbars.buttons["完了"].tap()
        let advance = app.buttons["advanceReply"]
        reach(advance)
        XCTAssertTrue(advance.isEnabled)
        advance.tap()
        XCTAssertTrue(app.staticTexts["revealedPhrase"].waitForExistence(timeout: 3))
        capture("review-denied-microphone-typed-comparison")
    }
}
