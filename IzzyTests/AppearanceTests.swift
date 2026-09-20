import SwiftUI
import XCTest
@testable import Izzy

/// Tests for how the design tokens resolve. These need `Izzy/Views`, so they run in the Xcode
/// `IzzyTests` target, which depends on the whole app. The SwiftPM package builds `Izzy/Core`
/// only and excludes this file; see `Package.swift`.
final class AppearanceTests: XCTestCase {
    func testTheBlackAccentReadsAsInkInBothThemes() {
        // Black is the ink token, so the same choice reads as graphite on light and near-white on dark.
        XCTAssertLessThan(AppAccent.black.color.luminance(in: .light), 0.1)
        XCTAssertGreaterThan(AppAccent.black.color.luminance(in: .dark), 0.8)
    }
}
