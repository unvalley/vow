import XCTest

@MainActor final class AppearanceUITests: XCTestCase {
    private var app: XCUIApplication!

    private func launch(reset: Bool = true) {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-tests", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if reset { app.launchArguments.append("--reset-ui-tests") }
        app.launch()
        XCTAssertTrue(app.buttons["practiceSettings"].waitForExistence(timeout: 10))
        app.buttons["practiceSettings"].tap()
    }

    private func capture(_ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name
        image.lifetime = .keepAlways
        add(image)
    }

    func testThemeSwitchesAndPersistsAcrossLaunch() {
        launch()
        let picker = app.buttons["appTheme"]
        XCTAssertTrue(picker.label.contains("System") || (picker.value as? String) == "System")
        for theme in ["Light", "Dark"] {
            picker.tap()
            app.buttons[theme].tap()
            XCTAssertTrue(picker.label.contains(theme) || (picker.value as? String) == theme)
            capture("settings-theme-\(theme.lowercased())")
            app.buttons["Done"].tap()
            capture("home-theme-\(theme.lowercased())")
            app.buttons["practiceSettings"].tap()
        }
        app.terminate()
        launch(reset: false)
        XCTAssertTrue(app.buttons["appTheme"].label.contains("Dark") || (app.buttons["appTheme"].value as? String) == "Dark")
        app.buttons["appTheme"].tap()
        app.buttons["System"].tap()
        capture("settings-theme-system")
    }

    func testBackgroundGridHasEqualTilesAndNewChoicesPersist() {
        launch()
        app.buttons["todayBackground"].tap()
        let mountains = app.buttons["background-mountains"]
        let ocean = app.buttons["background-ocean"]
        let lilies = app.buttons["background-waterLilies"]
        XCTAssertTrue(mountains.waitForExistence(timeout: 5))
        let tileWidth = mountains.frame.width
        let tileHeight = mountains.frame.height
        for tile in [ocean, lilies] {
            XCTAssertEqual(tile.frame.width, tileWidth, accuracy: 1)
            XCTAssertEqual(tile.frame.height, tileHeight, accuracy: 1)
        }
        capture("background-grid-first-rows")
        for name in ["forest", "lake", "dunes", "hills", "clouds"] {
            let tile = app.buttons["background-\(name)"]
            for _ in 0..<8 {
                if tile.exists, tile.isHittable, app.frame.insetBy(dx: 0, dy: 100).contains(CGPoint(x: tile.frame.midX, y: tile.frame.midY)) { break }
                app.swipeUp()
            }
            XCTAssertEqual(tile.frame.width, tileWidth, accuracy: 1)
            tile.tap()
            XCTAssertTrue(tile.isSelected)
        }
        capture("background-grid-new-choices")
        app.terminate()
        launch(reset: false)
        XCTAssertTrue(app.buttons["todayBackground"].label.contains("Clouds"))
    }
}
