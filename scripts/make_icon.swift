import Foundation

// Compatibility entry point. The approved outlined mark is the single source.
// Usage: swift scripts/make_icon.swift OUTPUT.png
let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
process.arguments = ["node", root.appendingPathComponent("scripts/build_brand.mjs").path]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { exit(process.terminationStatus) }
if CommandLine.arguments.count > 1 {
    let output = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
    let source = root.appendingPathComponent("Brand/vow-icon-1024.png").standardizedFileURL
    if output != source { try Data(contentsOf: source).write(to: output, options: .atomic) }
}
