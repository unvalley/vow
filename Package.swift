// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "VowLearning",
    platforms: [.macOS(.v14), .iOS(.v17)],
    products: [.library(name: "Vow", targets: ["Vow"])],
    targets: [
        .target(name: "Vow", path: "Vow", exclude: ["Views", "Services", "VowApp.swift", "Resources/Assets.xcassets", "PrivacyInfo.xcprivacy"], sources: ["Core"], resources: [.process("Resources/phrases.json")]),
        .testTarget(name: "VowTests", dependencies: ["Vow"], path: "VowTests")
    ]
)
