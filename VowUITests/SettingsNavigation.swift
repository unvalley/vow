import XCTest

extension XCUIApplication {
    /// Settings is the third tab; opening it replaces the former Home button and sheet.
    func openSettings() {
        tabBars.buttons["Settings"].tap()
        XCTAssertTrue(navigationBars["Settings"].waitForExistence(timeout: 5))
    }

    /// Returns to Home; the former sheet closed with Done.
    func closeSettings() {
        tabBars.buttons["Home"].tap()
    }

    /// Waits until the featured phrase differs from `previous`: a rating shows its color briefly before the card moves on.
    func waitForFeaturedPhrase(toChangeFrom previous: String, timeout: TimeInterval = 5) {
        let changed = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label != %@", previous), object: buttons["featuredDetails"])
        XCTAssertEqual(XCTWaiter.wait(for: [changed], timeout: timeout), .completed)
    }
}
