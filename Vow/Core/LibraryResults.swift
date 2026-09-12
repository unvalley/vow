import Foundation
import os

enum LibraryCollection: String, CaseIterable, Sendable {
    case all = "All phrases", verbs = "By verb", saved = "Saved"
}

/// One projection per view update. Rows and the count share the same result;
/// no cache survives the update, so saved phrases and review order stay current.
struct LibraryResults {
    let phrases: [Phrase]
    let groups: [VerbGroup]
    var isEmpty: Bool { phrases.isEmpty && groups.isEmpty }

    private static let log = OSLog(subsystem: "me.unvalley.verve", category: .pointsOfInterest)

    init(phrases: [Phrase], collection: LibraryCollection, query: String, sort: PhraseSort,
         reviews: [String: ReviewState], saved: Set<String>) {
        let signpostID = OSSignpostID(log: Self.log)
        os_signpost(.begin, log: Self.log, name: "LibraryResults", signpostID: signpostID)
        defer { os_signpost(.end, log: Self.log, name: "LibraryResults", signpostID: signpostID) }

        switch collection {
        case .verbs:
            self.phrases = []
            let matchingVerbs = Set(phrases.filter { $0.matches(query) }.map(\.baseVerb))
            if matchingVerbs.isEmpty {
                groups = []
            } else {
                // A matching phrase exposes its whole verb family, including
                // siblings that do not match the search (look into → look for).
                groups = sort.ordered(VerbGroup.groups(for: phrases.filter {
                    matchingVerbs.contains($0.baseVerb)
                }), reviews: reviews)
            }
        case .all, .saved:
            groups = []
            self.phrases = sort.ordered(phrases.filter {
                (collection != .saved || saved.contains($0.id)) && $0.matches(query)
            }, reviews: reviews)
        }
    }
}
