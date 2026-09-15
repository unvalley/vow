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

    func label(for scale: DifficultyScale) -> String {
        // The level name follows the app language (B1 · 中級); the code and exam references stay as they are.
        guard let reference = reference(for: scale) else { return "\(rawValue) · \(String(localized: String.LocalizationValue(title)))" }
        return "\(rawValue) · \(scale.shortTitle) ≈\(reference)"
    }
}

enum DifficultyScale: String, Codable, CaseIterable, Sendable {
    case cefr, ielts, toefl, eiken

    var title: String {
        switch self {
        case .cefr: "CEFR"
        case .ielts: "IELTS"
        case .toefl: "TOEFL iBT (1–6)"
        case .eiken: "EIKEN · 英検"
        }
    }

    var shortTitle: String {
        switch self {
        case .cefr: "CEFR"
        case .ielts: "IELTS"
        case .toefl: "TOEFL"
        case .eiken: "英検"
        }
    }
}
