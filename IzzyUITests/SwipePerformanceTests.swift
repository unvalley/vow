import XCTest

@MainActor final class SwipePerformanceTests: XCTestCase {
    func testWarmFeaturedSwipes() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons.matching(identifier: "featuredDetails").matching(NSPredicate(format: "label == %@", "bring up")).firstMatch.waitForExistence(timeout: 10))
        app.swipeLeft()
        XCTAssertTrue(app.buttons.matching(identifier: "featuredDetails").matching(NSPredicate(format: "label == %@", "get across")).firstMatch.isHittable)
        app.swipeRight()
        XCTAssertTrue(app.buttons.matching(identifier: "featuredDetails").matching(NSPredicate(format: "label == %@", "bring up")).firstMatch.isHittable)

        let options = XCTMeasureOptions()
        options.iterationCount = 10
        var metrics: [any XCTMetric] = [
            XCTClockMetric(), XCTCPUMetric(application: app), XCTMemoryMetric(application: app),
            XCTOSSignpostMetric.scrollingAndDecelerationMetric
        ]
        if #available(iOS 26.0, *) { metrics.append(XCTHitchMetric(application: app)) }
        measure(metrics: metrics, options: options) {
            app.swipeLeft()
            XCTAssertTrue(app.buttons.matching(identifier: "featuredDetails").matching(NSPredicate(format: "label == %@", "get across")).firstMatch.isHittable)
            app.swipeRight()
            XCTAssertTrue(app.buttons.matching(identifier: "featuredDetails").matching(NSPredicate(format: "label == %@", "bring up")).firstMatch.isHittable)
        }
    }
}
