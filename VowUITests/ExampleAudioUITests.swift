import XCTest

@MainActor final class ExampleAudioUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(reset: Bool = true, large: Bool = false) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "--free-access", "-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        if reset { app.launchArguments.append("--reset-ui-tests") }
        if large { app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"] }
        app.launch()
    }

    private func reach(_ element: XCUIElement) {
        let bounds = app.frame.insetBy(dx: 0, dy: 100)
        for _ in 0..<12 {
            if element.exists, bounds.contains(CGPoint(x: element.frame.midX, y: element.frame.midY)), element.isHittable { return }
            app.swipeUp()
        }
        XCTFail("Element is not reachable: \(element)")
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    func testBothExamplesHaveTheirOwnMeaningAndAudio() {
        launch()
        app.buttons["featuredDetails"].tap()
        let firstMeaning = app.buttons["featuredExample-meaning"]
        reach(firstMeaning)
        XCTAssertTrue(app.buttons["featuredExample-listen"].exists)
        XCTAssertTrue(app.buttons["featuredExample-slow"].exists)
        firstMeaning.tap()
        XCTAssertTrue(app.navigationBars["例文の意味"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["meaningSourceSentence"].label.contains("Before we finish"))
        XCTAssertEqual(app.staticTexts["sentenceTranslation"].label, "終わる前に、締め切りについて話してもいいですか？")
        XCTAssertFalse(app.buttons["translateSentence"].exists)
        capture("example-first-meaning")
        // Do not consent to language-model downloads from a UI test.
        app.buttons["closeSentenceMeaning"].tap()
        let secondMeaning = app.buttons["featuredExample-1-meaning"]
        reach(secondMeaning)
        secondMeaning.tap()
        XCTAssertTrue(app.staticTexts["meaningSourceSentence"].label.contains("There's something"))
        XCTAssertEqual(app.staticTexts["sentenceTranslation"].label, "少し話したいことがあります。会う時間は、今でも都合がいいですか？")
        capture("example-second-meaning")
        app.buttons["closeSentenceMeaning"].tap()
        let listen = app.buttons["featuredExample-1-listen"]
        reach(listen)
        listen.tap()
        XCTAssertEqual(listen.label, "停止")
        XCTAssertEqual(app.buttons["featuredExample-listen"].label, "聞く")
        listen.tap()
        XCTAssertEqual(listen.label, "聞く")
        let slow = app.buttons["featuredExample-1-slow"]
        slow.tap()
        XCTAssertEqual(slow.label, "停止")
        slow.tap()
        capture("example-individual-controls")
    }

    func testVoiceChoicePersistsAndCanReturnToAutomatic() {
        launch()
        app.buttons["practiceSettings"].tap()
        reach(app.buttons["speechSettings"])
        app.buttons["speechSettings"].tap()
        XCTAssertTrue(app.navigationBars["読み上げ音声"].waitForExistence(timeout: 3))
        let choices = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'speechVoice-' AND identifier != 'speechVoice-automatic'"))
        XCTAssertGreaterThan(choices.count, 0)
        let choice = choices.firstMatch
        let identifier = choice.identifier
        reach(choice)
        choice.tap()
        XCTAssertEqual(choice.value as? String, "選択中")
        app.terminate()
        launch(reset: false)
        app.buttons["practiceSettings"].tap()
        reach(app.buttons["speechSettings"])
        app.buttons["speechSettings"].tap()
        XCTAssertEqual(app.buttons[identifier].value as? String, "選択中")
        app.buttons["previewSpeechVoice"].tap()
        XCTAssertEqual(app.buttons["previewSpeechVoice"].label, "試聴を停止")
        app.buttons["previewSpeechVoice"].tap()
        app.buttons["speechVoice-automatic"].tap()
        XCTAssertEqual(app.buttons["speechVoice-automatic"].value as? String, "選択中")
        capture("reading-voice-settings")
    }

    func testExampleControlsRemainReachableAtLargestTextSize() {
        launch(large: true)
        app.buttons["featuredDetails"].tap()
        reach(app.buttons["featuredExample-1-meaning"])
        app.buttons["featuredExample-1-meaning"].tap()
        XCTAssertTrue(app.navigationBars["例文の意味"].exists)
        XCTAssertTrue(app.buttons["closeSentenceMeaning"].isHittable)
        capture("example-meaning-largest-text")
        app.buttons["closeSentenceMeaning"].tap()
        reach(app.buttons["featuredExample-1-slow"])
        XCTAssertTrue(app.buttons["featuredExample-1-slow"].isHittable)
        capture("example-controls-largest-text")
    }
}
