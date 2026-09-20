// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IzzyLearning",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "Izzy", targets: ["Izzy"])],
    targets: [
        .target(name: "Izzy", path: "Izzy", exclude: ["Views", "Services", "IzzyApp.swift", "Resources/Assets.xcassets", "Resources/Localizable.xcstrings", "Resources/InfoPlist.xcstrings", "PrivacyInfo.xcprivacy", "Info.plist"], sources: ["Core"], resources: [.process("Resources/phrases.json")]),
        // `AppearanceTests` exercises the design tokens in `Izzy/Views`, which this package does
        // not build, so it belongs to the Xcode test target alone.
        .testTarget(name: "IzzyTests", dependencies: ["Izzy"], path: "IzzyTests", exclude: ["AppearanceTests.swift"])
    ]
)
