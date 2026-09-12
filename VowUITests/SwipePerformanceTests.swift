import XCTest

@MainActor final class SwipePerformanceTests: XCTestCase {
    func testWarmFeaturedSwipes() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["bring up"].waitForExistence(timeout: 10))
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["get across"].isHittable)
        app.swipeRight()
        XCTAssertTrue(app.staticTexts["bring up"].isHittable)

        let options = XCTMeasureOptions()
        options.iterationCount = 10
        var metrics: [any XCTMetric] = [
            XCTClockMetric(), XCTCPUMetric(application: app), XCTMemoryMetric(application: app),
            XCTOSSignpostMetric.scrollingAndDecelerationMetric
        ]
        if #available(iOS 26.0, *) { metrics.append(XCTHitchMetric(application: app)) }
        measure(metrics: metrics, options: options) {
            app.swipeLeft()
            XCTAssertTrue(app.staticTexts["get across"].isHittable)
            app.swipeRight()
            XCTAssertTrue(app.staticTexts["bring up"].isHittable)
        }
    }
}
