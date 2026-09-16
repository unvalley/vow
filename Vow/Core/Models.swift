import Foundation

enum PhraseKind: String, Codable, Sendable {
    case phrasalVerb, idiom
}

/// What Home shows in both modes: everything, phrasal verbs only, or idioms only.
enum PhraseKindFilter: String, Codable, CaseIterable, Sendable {
    case all, phrasalVerbs, idioms
    var title: String {
        switch self {
        case .all: "All"
        case .phrasalVerbs: "Phrasal verbs"
        case .idioms: "Idioms"
        }
    }
    func allows(_ phrase: Phrase) -> Bool {
        switch self {
        case .all: true
        case .phrasalVerbs: !phrase.isIdiom
        case .idioms: phrase.isIdiom
        }
    }
}

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
    /// Authored sentence meanings keyed by the exact English source, never by list position.
    var exampleTranslations: [String: String]?
    var exampleRecall: Bool?
    var difficulty: PhraseDifficulty?
    /// The bluntest English equivalent of the taught sense (look into → investigate).
    /// Shown before the Easy English explanation; older catalogs without it fall back to the sentence alone.
    var gloss: String?
    /// Japanese for the usage tip and the look-alike comparison; the English pattern (`frame`) stays English.
    var nuanceJapanese: String?
    var contrastJapanese: String?
    // Missing metadata preserves the classification of the original catalog.
    var kind: PhraseKind?
    var isIdiom: Bool { kind == .idiom }
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
    /// The usage pattern as shown: a frame is a fragment to reuse, not a sentence, so it starts lowercase
    /// ("something is a dime a dozen") unless it starts with "I" or with the phrase's own capital.
    var pattern: String {
        guard let first = frame.first, first.isUppercase else { return frame }
        let firstWord = frame.prefix { !$0.isWhitespace }
        if ["I", "I'm", "I’m", "I've", "I’ve", "I'd", "I’d", "I'll", "I’ll"].contains(String(firstWord)) { return frame }
        if phrase.first?.isUppercase == true, frame.hasPrefix(phrase.prefix(1)) { return frame }
        return first.lowercased() + frame.dropFirst()
    }
    func nuance(in language: MeaningLanguage) -> String {
        language == .japanese ? (nuanceJapanese ?? nuance) : nuance
    }
    func contrast(in language: MeaningLanguage) -> String {
        language == .japanese ? (contrastJapanese ?? contrast) : contrast
    }
    /// The short equivalent that leads the English meaning; Japanese explanations are already terse.
    func lead(in language: MeaningLanguage) -> String? {
        guard language == .easyEnglish, let gloss, !gloss.isEmpty else { return nil }
        return gloss
    }
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        var terms = [phrase, meaning, easyEnglish, japanese, scene] + (aliases ?? [])
            + (referenceUsage.map { [$0.japanese, $0.easyEnglish, $0.example] } ?? [])
        if let gloss { terms.append(gloss) }
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

enum AppTheme: String, Codable, CaseIterable, Sendable {
    case light, dark, system
    var title: String { rawValue.capitalized }
}

enum TodayBackground: String, Codable, CaseIterable, Sendable {
    case mountains, ocean, waterLilies, forest, lake, dunes, hills, clouds

    var title: String {
        switch self {
        case .mountains: "Mountains"
        case .ocean: "Ocean"
        case .waterLilies: "Water Lilies"
        case .forest: "Misty Forest"
        case .lake: "Alpine Lake"
        case .dunes: "White Dunes"
        case .hills: "Misty Hills"
        case .clouds: "Clouds"
        }
    }

    var imageName: String {
        switch self {
        case .mountains: "TodayMountains"
        case .ocean: "TodayOcean"
        case .waterLilies: "TodayWaterLilies"
        case .forest: "TodayForest"
        case .lake: "TodayLake"
        case .dunes: "TodayDunes"
        case .hills: "TodayHills"
        case .clouds: "TodayClouds"
        }
    }
}

extension TodayBackground {
    /// Mountains and Ocean come with the free plan; the rest open with Vow Pro.
    var isFree: Bool { self == .mountains || self == .ocean }
}

/// The typeface for phrases wherever they appear. Every face ships with iOS, so nothing is bundled.
enum PhraseTypeface: String, Codable, CaseIterable, Sendable {
    case newYork, sfPro, rounded, georgia, palatino, baskerville, charter, didot, avenir, typewriter

    var title: String {
        switch self {
        case .newYork: "New York"
        case .sfPro: "SF Pro"
        case .rounded: "SF Pro Rounded"
        case .georgia: "Georgia"
        case .palatino: "Palatino"
        case .baskerville: "Baskerville"
        case .charter: "Charter"
        case .didot: "Didot"
        case .avenir: "Avenir Next"
        case .typewriter: "American Typewriter"
        }
    }

    /// New York and SF Pro come with the free plan.
    var isFree: Bool { self == .newYork || self == .sfPro }
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
        Dictionary(grouping: phrases.filter { !$0.isIdiom }, by: \.baseVerb).map { verb, entries in
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
    /// The exact meaning rating, so Home can show which button was chosen; older events have none.
    var memoryRating: MemoryRating?
}

struct LearningStreak: Sendable {
    let current: Int
    let longest: Int

    static func calculate(dates: [Date], now: Date, calendar: Calendar = .autoupdatingCurrent) -> LearningStreak {
        let days = Set(dates.filter { $0 <= now }.map { calendar.startOfDay(for: $0) })
        var previous: Date?
        var run = 0
        var longest = 0
        for day in days.sorted() {
            // Normalized: where daylight saving skips midnight, a day starts at 01:00 and adding a day keeps that hour.
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous).map(calendar.startOfDay) == day {
                run += 1
            } else { run = 1 }
            longest = max(longest, run)
            previous = day
        }
        let today = calendar.startOfDay(for: now)
        var cursor = days.contains(today) ? Optional(today) : calendar.date(byAdding: .day, value: -1, to: today).map(calendar.startOfDay)
        var current = 0
        while let day = cursor, days.contains(day) {
            current += 1
            cursor = calendar.date(byAdding: .day, value: -1, to: day).map(calendar.startOfDay)
        }
        return LearningStreak(current: current, longest: longest)
    }
}

struct LearningData: Codable, Sendable {
    var schema = 1
    var reviews: [String: ReviewState] = [:]
    var memoryReviews: [String: MemoryReview]?
    var reviewReminders: ReviewReminderPreferences?
    var reminderPreferences: ReviewReminderPreferences { reviewReminders ?? .init() }
    var saved: Set<String> = []
    var notes: [String: String] = [:]
    var events: [PracticeEvent] = []
    var focus = "work"
    var japaneseHints = true
    var theme: AppTheme?
    var themeChoice: AppTheme { theme ?? .system }
    var accent: AppAccent?
    var accentColor: AppAccent { accent ?? .blue }
    var todayBackground: TodayBackground?
    var backgroundChoice: TodayBackground { todayBackground ?? .mountains }
    var phraseTypeface: PhraseTypeface?
    var typefaceChoice: PhraseTypeface { phraseTypeface ?? .newYork }
    /// The choices in effect: a Pro choice kept after access ends falls back to the default instead of being erased.
    func background(fullAccess: Bool) -> TodayBackground { fullAccess || backgroundChoice.isFree ? backgroundChoice : .mountains }
    func typeface(fullAccess: Bool) -> PhraseTypeface { fullAccess || typefaceChoice.isFree ? typefaceChoice : .newYork }
    var dailyNewGoal: Int?
    /// Set when the learner chose Decide later on the first-run goal sheet; the default pace applies.
    var dailyGoalSkipped: Bool?
    var needsDailyGoal: Bool { dailyNewGoal == nil && dailyGoalSkipped != true }
    var newPhrasesPerDay: Int { min(50, max(1, dailyNewGoal ?? 5)) }
    var difficultyScale: DifficultyScale?
    var difficultyDisplay: DifficultyScale { difficultyScale ?? .cefr }
    var phraseSort: PhraseSort?
    /// Home's kind filter; older files have none and show everything.
    var homeKind: PhraseKindFilter?
    var homeKindFilter: PhraseKindFilter { homeKind ?? .all }
    // Optional for compatibility with all existing learning files. nil = automatic.
    var speechVoiceID: String?
    var listeningPreferences: ListeningPreferences?
    var sortOrder: PhraseSort { phraseSort ?? .alphabetical }
    // Keep the original stored key so existing preferences and progress decode unchanged.
    var meaningLanguage: MeaningLanguage {
        get { japaneseHints ? .japanese : .easyEnglish }
        set { japaneseHints = newValue == .japanese }
    }
    var onboardingDone = false
    /// A fresh install shows the introduction; installs that already chose a daily goal skip it.
    var needsOnboarding: Bool { !onboardingDone && dailyNewGoal == nil }
    var rehearsalCount = 0
    // Older versions stored only a total, so their undated stories cannot be backfilled.
    var rehearsalDates: [Date]?
}

enum SessionPlanner {
    static func queue(phrases: [Phrase], states: [String: ReviewState], focus: String, now: Date, limit: Int = 3) -> [Phrase] {
        let due = phrases.filter { if let state = states[$0.id] { return state.due <= now }; return false }
            .smallest(limit) { (states[$0.id]?.due ?? .distantPast) < (states[$1.id]?.due ?? .distantPast) }
        guard due.count < limit else { return due }
        let fresh = phrases.filter { states[$0.id] == nil }
            .smallest(limit - due.count) { a, b in
                if (a.scene == focus) != (b.scene == focus) { return a.scene == focus }
                return a.id < b.id
            }
        return due + fresh
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
