import Foundation

struct Phrase: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let phrase: String
    let meaning: String
    let easyEnglish: String
    let japanese: String
    let scene: String
    let cue: String
    let reply: String
    let transferCue: String
    let transferReply: String
    let frame: String
    let nuance: String
    let contrast: String
    let source: String
    // Optional additions keep the original 80 lessons decodable and their IDs stable.
    var aliases: [String]?
    var referenceUsage: PhraseUsage?
    var exampleRecall: Bool?
    var usesExampleRecall: Bool { exampleRecall == true }
    /// Keep the lesson's two contexts distinct from supplemental dictionary senses.
    var examples: [String] {
        var seen = Set<String>()
        return [reply, transferReply].filter {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && seen.insert($0).inserted
        }
    }
    var baseVerb: String { phrase.split(separator: " ").first.map(String.init)?.lowercased() ?? "" }
    func explanation(in language: MeaningLanguage) -> String {
        language == .japanese ? japanese : easyEnglish
    }
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let terms = [phrase, meaning, easyEnglish, japanese, scene] + (aliases ?? [])
            + (referenceUsage.map { [$0.japanese, $0.easyEnglish, $0.example] } ?? [])
        return query.isEmpty || terms.contains { $0.localizedCaseInsensitiveContains(query) }
    }
}

struct PhraseUsage: Codable, Hashable, Sendable {
    let japanese: String
    let easyEnglish: String
    let example: String
    func explanation(in language: MeaningLanguage) -> String {
        language == .japanese ? japanese : easyEnglish
    }
}

enum AppAccent: String, Codable, CaseIterable, Sendable {
    case black, blue, green, yellow, pink, orange, purple
    var title: String { rawValue.capitalized }
}

enum MeaningLanguage: String, CaseIterable, Sendable {
    case japanese, easyEnglish
    var title: String { self == .japanese ? "日本語" : "Easy English" }
}

enum PhraseSort: String, Codable, CaseIterable, Sendable {
    case alphabetical, reverseAlphabetical, unpracticed, reviewDate
    var title: String {
        switch self {
        case .alphabetical: "A–Z"
        case .reverseAlphabetical: "Z–A"
        case .unpracticed: "Unpracticed first"
        case .reviewDate: "Review date"
        }
    }

    func ordered(_ phrases: [Phrase], reviews: [String: ReviewState]) -> [Phrase] {
        phrases.sorted { precedes($0, $1, reviews: reviews) }
    }

    func ordered(_ groups: [VerbGroup], reviews: [String: ReviewState]) -> [VerbGroup] {
        groups.map { VerbGroup(verb: $0.verb, phrases: ordered($0.phrases, reviews: reviews)) }
            .sorted {
                guard let a = $0.phrases.first, let b = $1.phrases.first else { return $0.verb < $1.verb }
                return precedes(a, b, reviews: reviews)
            }
    }

    private func precedes(_ a: Phrase, _ b: Phrase, reviews: [String: ReviewState]) -> Bool {
        let aReviewed = (reviews[a.id]?.reviews ?? 0) > 0
        let bReviewed = (reviews[b.id]?.reviews ?? 0) > 0
        switch self {
        case .unpracticed:
            if aReviewed != bReviewed { return !aReviewed }
        case .reviewDate:
            // Scheduled reviews precede phrases that have never been practiced.
            if aReviewed != bReviewed { return aReviewed }
            if aReviewed, let aDue = reviews[a.id]?.due, let bDue = reviews[b.id]?.due, aDue != bDue {
                return aDue < bDue
            }
        case .alphabetical, .reverseAlphabetical: break
        }
        if a.phrase == b.phrase { return a.id < b.id }
        return self == .reverseAlphabetical ? a.phrase > b.phrase : a.phrase < b.phrase
    }
}

struct VerbGroup: Identifiable, Sendable {
    let verb: String
    let phrases: [Phrase]
    var id: String { verb }

    static func groups(for phrases: [Phrase]) -> [VerbGroup] {
        Dictionary(grouping: phrases, by: \.baseVerb).map { verb, entries in
            VerbGroup(verb: verb, phrases: entries.sorted { $0.phrase < $1.phrase })
        }.sorted { $0.verb < $1.verb }
    }
}

struct Scene: Identifiable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let symbol: String
    let prompt: String
    static let all: [Scene] = [
        .init(id: "work", title: "Find your voice", subtitle: "Meetings & ideas", symbol: "waveform", prompt: "Tell a colleague about a project that went off track. Explain the problem, suggest a way forward, and invite their opinion."),
        .init(id: "connect", title: "A little closer", subtitle: "Friends & connection", symbol: "bubble.left.and.bubble.right", prompt: "Catch up with a friend you haven't seen in a while. Explain what has changed, ask about their life, and suggest meeting again."),
        .init(id: "plans", title: "Leave room", subtitle: "Plans & uncertainty", symbol: "arrow.triangle.branch", prompt: "Your weekend plans have changed. Explain what happened, weigh two alternatives, and agree on a new plan."),
        .init(id: "perspective", title: "See it differently", subtitle: "Opinions & nuance", symbol: "circle.lefthalf.filled", prompt: "Describe a decision you changed your mind about. Explain your original view, what you learned, and how you see it now."),
        .init(id: "everyday", title: "Everyday English", subtitle: "Everyday English", symbol: "cup.and.saucer", prompt: "Tell someone about your day. Describe what happened, something you needed to do, and what you plan to do next.")
    ]
}

enum RecallRating: String, Codable, CaseIterable, Sendable {
    case again, effort, ready
    var title: String { switch self { case .again: "Not yet"; case .effort: "With effort"; case .ready: "Came naturally" } }
}

struct ReviewState: Codable, Sendable {
    var intervalDays: Double = 0
    var due: Date = .distantPast
    var reviews = 0
    var naturalRecalls = 0
    var lastReviewed: Date?
}

enum Scheduler {
    static func review(_ old: ReviewState, rating: RecallRating, now: Date) -> ReviewState {
        var state = old
        state.reviews += 1
        state.lastReviewed = now
        // Extra scene practice before a review is due is useful, but it is not
        // evidence of recall after the scheduled gap. Keep the existing date.
        if old.reviews > 0, old.due > now, rating != .again { return state }
        switch rating {
        case .again:
            state.intervalDays = 0
            state.naturalRecalls = 0
            state.due = now.addingTimeInterval(600)
        case .effort:
            state.intervalDays = max(1, min(30, old.intervalDays * 1.2))
            state.due = now.addingTimeInterval(state.intervalDays * 86400)
        case .ready:
            state.naturalRecalls += 1
            state.intervalDays = old.intervalDays < 1 ? 1 : min(60, old.intervalDays * 2.5)
            state.due = now.addingTimeInterval(state.intervalDays * 86400)
        }
        return state
    }
}

struct PracticeEvent: Codable, Identifiable, Sendable {
    var id = UUID()
    let phraseID: String
    let date: Date
    let rating: RecallRating
    let mode: String
}

struct LearningStreak: Sendable {
    let current: Int
    let longest: Int
    let activeDays: Set<Date>

    static func calculate(dates: [Date], now: Date, calendar: Calendar = .autoupdatingCurrent) -> LearningStreak {
        let days = Set(dates.filter { $0 <= now }.map { calendar.startOfDay(for: $0) })
        var previous: Date?
        var run = 0
        var longest = 0
        for day in days.sorted() {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                run += 1
            } else { run = 1 }
            longest = max(longest, run)
            previous = day
        }
        let today = calendar.startOfDay(for: now)
        var cursor = days.contains(today) ? Optional(today) : calendar.date(byAdding: .day, value: -1, to: today)
        var current = 0
        while let day = cursor, days.contains(day) {
            current += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: day)
        }
        return LearningStreak(current: current, longest: longest, activeDays: days)
    }
}

struct LearningData: Codable, Sendable {
    var schema = 1
    var reviews: [String: ReviewState] = [:]
    var saved: Set<String> = []
    var notes: [String: String] = [:]
    var events: [PracticeEvent] = []
    var focus = "work"
    var japaneseHints = true
    var accent: AppAccent?
    var accentColor: AppAccent { accent ?? .black }
    var phraseSort: PhraseSort?
    var sortOrder: PhraseSort { phraseSort ?? .alphabetical }
    // Keep the original stored key so existing preferences and progress decode unchanged.
    var meaningLanguage: MeaningLanguage {
        get { japaneseHints ? .japanese : .easyEnglish }
        set { japaneseHints = newValue == .japanese }
    }
    var gentleMode = false
    var onboardingDone = false
    var rehearsalCount = 0
    // Older versions stored only a total, so their undated stories cannot be backfilled.
    var rehearsalDates: [Date]?
}

enum SessionPlanner {
    static func queue(phrases: [Phrase], states: [String: ReviewState], focus: String, now: Date, limit: Int = 3) -> [Phrase] {
        let due = phrases.filter { if let state = states[$0.id] { return state.due <= now }; return false }
            .sorted { (states[$0.id]?.due ?? .distantPast) < (states[$1.id]?.due ?? .distantPast) }
        let fresh = phrases.filter { states[$0.id] == nil }
            .sorted { a, b in
                if (a.scene == focus) != (b.scene == focus) { return a.scene == focus }
                return a.id < b.id
            }
        return Array((due + fresh).prefix(limit))
    }
}

enum Catalog {
    static func load(bundle: Bundle? = nil) throws -> [Phrase] {
        #if SWIFT_PACKAGE
        let resourceBundle = bundle ?? Bundle.module
        #else
        let resourceBundle = bundle ?? Bundle.main
        #endif
        guard let url = resourceBundle.url(forResource: "phrases", withExtension: "json") else { throw CocoaError(.fileNoSuchFile) }
        let phrases = try JSONDecoder().decode([Phrase].self, from: Data(contentsOf: url))
        guard !phrases.isEmpty, Set(phrases.map(\.id)).count == phrases.count else { throw CocoaError(.coderReadCorrupt) }
        return phrases
    }
}
