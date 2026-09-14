import Foundation
import os

enum LibraryCollection: String, CaseIterable, Sendable {
    case all = "All", phrasalVerbs = "Phrasal verbs", idioms = "Idioms", saved = "Saved"
    /// Saved keeps both kinds; the other three are the same split Home uses.
    var kind: PhraseKindFilter {
        switch self {
        case .phrasalVerbs: .phrasalVerbs
        case .idioms: .idioms
        case .all, .saved: .all
        }
    }
}

/// One projection per view update. Rows and the count share the same result;
/// no cache survives the update, so saved phrases and review order stay current.
struct LibraryResults {
    let phrases: [Phrase]
    let groups: [VerbGroup]
    var isEmpty: Bool { phrases.isEmpty && groups.isEmpty }

    private static let log = OSLog(subsystem: "me.unvalley.verve", category: .pointsOfInterest)

    init(phrases: [Phrase], collection: LibraryCollection, query: String, sort: PhraseSort,
         reviews: [String: ReviewState], saved: Set<String>, difficulty: PhraseDifficulty? = nil, groupByVerb: Bool = false) {
        let signpostID = OSSignpostID(log: Self.log)
        os_signpost(.begin, log: Self.log, name: "LibraryResults", signpostID: signpostID)
        defer { os_signpost(.end, log: Self.log, name: "LibraryResults", signpostID: signpostID) }

        let kind = collection.kind
        let phrases = phrases.filter {
            (difficulty == nil || $0.difficulty == difficulty) &&
            (collection != .saved || saved.contains($0.id)) && kind.allows($0)
        }
        if groupByVerb && collection != .idioms {
            // Verb families only cover phrasal verbs; idioms have no base verb.
            let phrases = phrases.filter { !$0.isIdiom }
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
        } else {
            groups = []
            self.phrases = sort.ordered(phrases.filter { $0.matches(query) }, reviews: reviews)
        }
    }
}
