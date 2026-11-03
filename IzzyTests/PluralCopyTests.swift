import XCTest
@testable import Izzy

/// English counts come from the string catalog's plural forms, so one of anything never reads "1 expressions".
/// The runtime checks read the app's compiled catalog, so this file runs in the Xcode `IzzyTests` target only,
/// like `AppearanceTests`; see `Package.swift`.
final class PluralCopyTests: XCTestCase {
    private func english(_ value: String.LocalizationValue) throws -> String {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let bundle = try XCTUnwrap(Bundle(path: path))
        return String(localized: value, bundle: bundle, locale: Locale(identifier: "en"))
    }

    func testOneOfAnythingReadsSingular() throws {
        let one = 1
        XCTAssertEqual(try english("\(one) expressions"), "1 expression")
        XCTAssertEqual(try english("Verb family: \("look"), \(one) phrases"), "Verb family: look, 1 phrase")
        XCTAssertEqual(try english("The free plan keeps up to \(one) notes. See Izzy Pro"), "The free plan keeps up to 1 note. See Izzy Pro")
        XCTAssertEqual(try english("Finished today's learning on Izzy. \(one) days in a row."), "Finished today's learning on Izzy. 1 day in a row.")
        XCTAssertEqual(try english("Try every phrase free for \(one) days"), "Try every phrase free for 1 day")
        XCTAssertEqual(try english("Try Izzy Pro free for \(one) days"), "Try Izzy Pro free for 1 day")
        XCTAssertEqual(try english("Try every expression free for \(one) days."), "Try every expression free for 1 day.")
        XCTAssertEqual(try english("Every expression in Izzy Pro, free for \(one) days."), "Every expression in Izzy Pro, free for 1 day.")
        XCTAssertEqual(try english("\(one) new phrases per day"), "1 new phrase per day")
        XCTAssertEqual(try english("\(one) more \("look") phrases with Izzy Pro"), "1 more look phrase with Izzy Pro")
        XCTAssertEqual(try english("Reviews for \(one) Pro expressions are waiting."), "Reviews for 1 Pro expression are waiting.")
    }

    func testOtherCountsStayPlural() throws {
        let none = 0, many = 16
        XCTAssertEqual(try english("\(none) expressions"), "0 expressions")
        XCTAssertEqual(try english("Verb family: \("look"), \(many) phrases"), "Verb family: look, 16 phrases")
        XCTAssertEqual(try english("Try Izzy Pro free for \(AccessPolicy.trialDays) days"), "Try Izzy Pro free for \(AccessPolicy.trialDays) days")
        XCTAssertEqual(try english("\(many) more \("look") phrases with Izzy Pro"), "16 more look phrases with Izzy Pro")
        XCTAssertEqual(try english("Reviews for \(many) Pro expressions are waiting."), "Reviews for 16 Pro expressions are waiting.")
    }

    /// The guard: an English string that counts a plural noun with `%lld` has `one` and `other` forms. Up to two
    /// words may sit between the count and the noun ("%lld new phrases", "%lld more %@ phrases").
    func testCountedEnglishCopyHasPluralForms() throws {
        let root = URL(filePath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let counted = try NSRegularExpression(pattern: #"%(\d+\$)?lld(?: (?:[A-Za-z]+|%(?:\d+\$)?@)){0,2} [a-z]+s\b"#)
        var found: [String] = []
        for catalog in ["Izzy/Resources/Localizable.xcstrings", "IzzyWidget/Localizable.xcstrings"] {
            let data = try Data(contentsOf: root.appending(path: catalog))
            let strings = try XCTUnwrap((try JSONSerialization.jsonObject(with: data) as? [String: Any])?["strings"] as? [String: Any])
            for (key, entry) in strings {
                let localizations = (entry as? [String: Any])?["localizations"] as? [String: Any]
                let english = localizations?["en"] as? [String: Any]
                let plural = (english?["variations"] as? [String: Any])?["plural"] as? [String: Any]
                let text = ((english?["stringUnit"] as? [String: Any])?["value"] as? String) ?? key
                let range = NSRange(text.startIndex..., in: text)
                if counted.firstMatch(in: text, range: range) != nil, plural?["one"] == nil || plural?["other"] == nil {
                    found.append(key)
                }
            }
        }
        XCTAssertEqual(found.sorted(), [], "give these English plural forms in the catalog")
    }
}
