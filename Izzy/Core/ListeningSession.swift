import Foundation

enum ListeningCollection: String, Codable, CaseIterable, Sendable {
    case all, phrasalVerbs, idioms, saved
    var title: String {
        switch self {
        case .all: "Phrasal verbs & idioms"
        case .phrasalVerbs: "Phrasal verbs"
        case .idioms: "Idioms"
        case .saved: "Saved"
        }
    }
}

struct ListeningPreferences: Codable, Equatable, Sendable {
    var collection: ListeningCollection = .all
    var includesMeaning = true
    var includesExample = true
    var shuffled = false
    var repeats = true
    var slower = false
    var sleepMinutes = 0
}

struct ListeningSegment: Equatable, Sendable {
    let text: String
    let language: String
}

/// Playback progress is deliberately separate from memory reviews and daily goals.
struct ListeningSession: Sendable {
    private(set) var phrases: [Phrase]
    let preferences: ListeningPreferences
    let meaningLanguage: MeaningLanguage
    private(set) var index = 0
    private(set) var segmentIndex = 0

    init(phrases: [Phrase], purchased: Bool, saved: Set<String>, preferences: ListeningPreferences, meaningLanguage: MeaningLanguage) {
        let allowed = phrases.filter { phrase in
            guard AccessPolicy.allows(phrase, purchased: purchased) else { return false }
            switch preferences.collection {
            case .all: return true
            case .phrasalVerbs: return !phrase.isIdiom
            case .idioms: return phrase.isIdiom
            case .saved: return saved.contains(phrase.id)
            }
        }
        self.phrases = preferences.shuffled ? allowed.shuffled() : allowed
        self.preferences = preferences
        self.meaningLanguage = meaningLanguage
    }

    var phrase: Phrase? { phrases.indices.contains(index) ? phrases[index] : nil }
    var segments: [ListeningSegment] {
        guard let phrase else { return [] }
        var segments = [ListeningSegment(text: phrase.phrase, language: "en-US")]
        if preferences.includesMeaning {
            segments.append(.init(text: phrase.explanation(in: meaningLanguage), language: meaningLanguage == .japanese ? "ja-JP" : "en-US"))
        }
        if preferences.includesExample, let example = phrase.examples.first {
            segments.append(.init(text: example, language: "en-US"))
        }
        return segments.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }
    var segment: ListeningSegment? { segments.indices.contains(segmentIndex) ? segments[segmentIndex] : nil }
    var canGoBack: Bool { !phrases.isEmpty && (index > 0 || preferences.repeats) }
    var canGoForward: Bool { !phrases.isEmpty && (index + 1 < phrases.count || preferences.repeats) }

    mutating func finishSegment() -> Bool {
        guard phrase != nil else { return false }
        if segmentIndex + 1 < segments.count { segmentIndex += 1; return true }
        return skip(1)
    }

    @discardableResult mutating func skip(_ offset: Int) -> Bool {
        guard !phrases.isEmpty else { return false }
        let target = index + offset
        guard preferences.repeats || phrases.indices.contains(target) else { return false }
        index = ((target % phrases.count) + phrases.count) % phrases.count
        segmentIndex = 0
        return true
    }

    mutating func restart() { index = 0; segmentIndex = 0 }

    mutating func restrict(to allowedIDs: Set<String>) {
        let currentID = phrase?.id
        phrases.removeAll { !allowedIDs.contains($0.id) }
        if let retained = phrases.firstIndex(where: { $0.id == currentID }) { index = retained }
        else { index = 0; segmentIndex = 0 }
    }
}
