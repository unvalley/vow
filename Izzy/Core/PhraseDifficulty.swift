import Foundation

/// Editorial estimates for the sense taught by a lesson, not exam item ratings.
enum PhraseDifficulty: String, Codable, CaseIterable, Sendable {
    case a1 = "A1", a2 = "A2", b1 = "B1", b2 = "B2", c1 = "C1", c2 = "C2"

    var title: String {
        switch self {
        case .a1: "Beginner"
        case .a2: "Elementary"
        case .b1: "Intermediate"
        case .b2: "Upper intermediate"
        case .c1: "Advanced"
        case .c2: "Proficient"
        }
    }

    var description: String {
        switch self {
        case .a1: "Basic actions and familiar daily routines."
        case .a2: "Everyday activities, travel and simple interactions."
        case .b1: "Common phrases for experiences, plans and relationships."
        case .b2: "More abstract meanings, opinions and workplace situations."
        case .c1: "Less transparent idioms and more nuanced or informal usage."
        case .c2: "Precise, idiomatic use with fine shades of meaning."
        }
    }

    // CEFR score bands and approximate EIKEN grade targets, checked 2026-09-13.
    // Grades are learning references, not conversions or predicted passes. See docs/phrase-difficulty.md.
    // Missing comparisons remain absent rather than extrapolating a score.
    func reference(for scale: DifficultyScale) -> String? {
        switch scale {
        case .cefr: return nil
        case .toeic:
            // TOEIC Listening & Reading: ETS's CEFR minimums added together (Listening 60/110/275/400/490 and
            // Reading 60/115/275/385/455), checked 2026-09-15. ETS reads the two sections separately; this is a rough total.
            switch self {
            case .a1: return "120–220"
            case .a2: return "225–545"
            case .b1: return "550–780"
            case .b2: return "785–940"
            case .c1: return "945–990"
            case .c2: return nil
            }
        case .ielts:
            switch self {
            case .a1, .a2: return nil
            case .b1: return "4.0–5.0"
            case .b2: return "5.5–6.5"
            case .c1: return "7.0–8.0"
            case .c2: return "8.5–9.0"
            }
        case .toefl:
            switch self {
            case .a1: return "1–1.5"
            case .a2: return "2–2.5"
            case .b1: return "3–3.5"
            case .b2: return "4–4.5"
            case .c1: return "5–5.5"
            case .c2: return "6"
            }
        case .eiken:
            switch self {
            case .a1: return "3級"
            case .a2: return "準2級・準2級プラス"
            case .b1: return "2級"
            case .b2: return "準1級"
            case .c1: return "1級"
            case .c2: return nil
            }
        }
    }

    /// "TOEIC 550–780 · 英検 2級 · IELTS 4.0–5.0 · TOEFL 3–3.5", in the order Japanese learners reach for
    /// the exams; an exam without a band for the level is left out.
    var examReferences: String {
        [DifficultyScale.toeic, .eiken, .ielts, .toefl]
            .compactMap { scale in reference(for: scale).map { "\(scale.shortTitle) \($0)" } }
            .joined(separator: " · ")
    }

    func label(for scale: DifficultyScale) -> String {
        // The level name follows the app language (B1 · 中級); the code and exam references stay as they are.
        guard let reference = reference(for: scale) else { return "\(rawValue) · \(String(localized: String.LocalizationValue(title)))" }
        return "\(rawValue) · \(scale.shortTitle) ≈\(reference)"
    }
}

extension PhraseDifficulty: Comparable {
    /// A1 to C2 in order; the codes sort that way as text.
    static func < (lhs: PhraseDifficulty, rhs: PhraseDifficulty) -> Bool { lhs.rawValue < rhs.rawValue }
}

/// The levels to learn, chosen in Settings and applied to both Home modes together with `PhraseKindFilter`.
/// No level chosen means every level, so the collection is whole until a learner narrows it.
struct PhraseLevelFilter: Equatable, Sendable {
    let levels: Set<PhraseDifficulty>
    static let all = PhraseLevelFilter(levels: [])

    init(levels: Set<PhraseDifficulty>) { self.levels = levels }

    var isAll: Bool { levels.isEmpty }
    /// The chosen levels in order, as they are saved and shown.
    var ordered: [PhraseDifficulty] { levels.sorted() }
    func contains(_ level: PhraseDifficulty) -> Bool { levels.contains(level) }
    /// A lesson without a level belongs to no chosen level; it shows only when every level does.
    func allows(_ phrase: Phrase) -> Bool { levels.isEmpty || phrase.difficulty.map(levels.contains) == true }

    /// Adds or removes one level. Choosing every level on offer is the same as choosing none: both
    /// show everything, and a level added to the catalog later is then included rather than left out.
    func toggling(_ level: PhraseDifficulty, among offered: Set<PhraseDifficulty>) -> PhraseLevelFilter {
        var next = levels
        if next.contains(level) { next.remove(level) } else { next.insert(level) }
        return next.isSuperset(of: offered) ? .all : PhraseLevelFilter(levels: next)
    }

    /// "A2 · B1" for the Settings row; nil when every level is included.
    var summary: String? { isAll ? nil : ordered.map(\.rawValue).joined(separator: " · ") }

    /// The choice as it applies to the levels on offer. Levels chosen under another plan or kind may
    /// not be on offer any more: those are set aside, and a choice with nothing left shows every level
    /// rather than an empty Home. The saved choice is untouched, so it returns with the plan or kind.
    func applied(to offered: Set<PhraseDifficulty>) -> PhraseLevelFilter {
        let kept = levels.intersection(offered)
        return kept.isEmpty || kept == offered ? .all : PhraseLevelFilter(levels: kept)
    }

    /// The choice as Home applies it: against the levels the plan opens for the chosen kind.
    func applied(phrases: [Phrase], purchased: Bool, kind: PhraseKindFilter) -> PhraseLevelFilter {
        guard !isAll else { return self }
        var offered = Set<PhraseDifficulty>()
        for phrase in phrases where kind.allows(phrase) && AccessPolicy.allows(phrase, purchased: purchased) {
            if let level = phrase.difficulty { offered.insert(level) }
        }
        return applied(to: offered)
    }
}

/// Where one level stands, for the level picker: how much of it the plan opens and how much has been met.
struct LevelProgress: Identifiable, Equatable, Sendable {
    let level: PhraseDifficulty
    /// Expressions at this level in the whole collection for the chosen kind, Pro included.
    let total: Int
    /// Those the plan opens.
    let available: Int
    /// Available expressions already introduced in meaning recall.
    let learned: Int
    var id: PhraseDifficulty { level }

    /// One entry per level the collection has for the chosen kind, in level order.
    static func levels(phrases: [Phrase], purchased: Bool, kind: PhraseKindFilter,
                       memory: [String: MemoryReview]) -> [LevelProgress] {
        var totals: [PhraseDifficulty: (total: Int, available: Int, learned: Int)] = [:]
        for phrase in phrases where kind.allows(phrase) {
            guard let level = phrase.difficulty else { continue }
            var entry = totals[level] ?? (0, 0, 0)
            entry.total += 1
            if AccessPolicy.allows(phrase, purchased: purchased) {
                entry.available += 1
                if memory[phrase.id] != nil { entry.learned += 1 }
            }
            totals[level] = entry
        }
        return totals.keys.sorted().map { level in
            let entry = totals[level]!
            return LevelProgress(level: level, total: entry.total, available: entry.available, learned: entry.learned)
        }
    }
}

enum DifficultyScale: String, Codable, CaseIterable, Sendable {
    case cefr, toeic, eiken, ielts, toefl

    var title: String {
        switch self {
        case .cefr: "CEFR"
        case .toeic: "TOEIC L&R"
        case .ielts: "IELTS"
        case .toefl: "TOEFL iBT (1–6)"
        case .eiken: "EIKEN · 英検"
        }
    }

    var shortTitle: String {
        switch self {
        case .cefr: "CEFR"
        case .toeic: "TOEIC"
        case .ielts: "IELTS"
        case .toefl: "TOEFL"
        case .eiken: "英検"
        }
    }
}
