// Compile with Models.swift and ParticleConcept.swift using swiftc -O.
// Reports warm, synchronous catalog/search work, not GPU or input-to-display latency.
import Foundation

@main
struct LibraryBenchmark {
    static func main() throws {
        let bytes = try Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[1]))
        let phrases = try JSONDecoder().decode([Phrase].self, from: bytes)
        let queries = CommandLine.arguments.count > 2 ? [CommandLine.arguments[2]] : ["", "   ", "l", "look", "look into", "調べ", "round", "zzzz-no-match"]
        let samples = CommandLine.arguments.count > 3 ? Int(CommandLine.arguments[3])! : 100
        var checksum = 0
        print("operation,query,sample,milliseconds,count")
        for query in queries {
            for operation in ["all-view-results", "verb-view-results"] {
                for sample in -10..<samples {
                    let start = ContinuousClock.now
                    let count: Int
                    switch operation {
                    case "all-view-results":
                        #if OPTIMIZED_LIBRARY
                        let result = LibraryResults(phrases: phrases, collection: .all, query: query, sort: .alphabetical, reviews: [:], saved: [])
                        count = result.isEmpty ? 0 : result.phrases.count * 2
                        #else
                        func filtered() -> [Phrase] {
                            PhraseSort.alphabetical.ordered(phrases.filter { $0.matches(query) }, reviews: [:])
                        }
                        // Original LibraryView: empty state, displayed count, ForEach data.
                        count = filtered().isEmpty ? 0 : filtered().count + filtered().count
                        #endif
                    default:
                        #if OPTIMIZED_LIBRARY
                        let result = LibraryResults(phrases: phrases, collection: .verbs, query: query, sort: .alphabetical, reviews: [:], saved: [])
                        count = result.isEmpty ? 0 : result.groups.count * 2
                        #else
                        func groups() -> [VerbGroup] {
                            PhraseSort.alphabetical.ordered(
                                VerbGroup.groups(for: phrases).filter { $0.phrases.contains { $0.matches(query) } }, reviews: [:])
                        }
                        let filtered = PhraseSort.alphabetical.ordered(phrases.filter { $0.matches(query) }, reviews: [:])
                        count = filtered.isEmpty ? 0 : groups().count + groups().count
                        #endif
                    }
                    let duration = start.duration(to: .now).components
                    let milliseconds = Double(duration.seconds) * 1000 + Double(duration.attoseconds) / 1e15
                    checksum += count
                    if sample >= 0 { print("\(operation),\(query),\(sample),\(milliseconds),\(count)") }
                }
            }
        }
        FileHandle.standardError.write(Data("phrases=\(phrases.count) checksum=\(checksum)\n".utf8))
    }
}
