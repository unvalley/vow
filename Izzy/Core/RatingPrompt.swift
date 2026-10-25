import Foundation

/// When Home asks for an App Store rating. Ratings decide much of whether a stranger on the store
/// installs Izzy, and the most honest moment to ask is right after the app has visibly helped:
/// a finished day, on a streak, from someone who has learned enough to judge it.
enum RatingPrompt {
    static let lastAskedKey = "rating.lastAsked"
    static let minimumStreak = 3
    static let minimumLearned = 15
    /// iOS shows the sheet at most three times a year anyway; asking less often keeps each one welcome.
    static let interval: TimeInterval = 120 * 86_400

    static func shouldAsk(streak: Int, learned: Int, lastAsked: Date?, now: Date) -> Bool {
        guard streak >= minimumStreak, learned >= minimumLearned else { return false }
        guard let lastAsked else { return true }
        return now.timeIntervalSince(lastAsked) >= interval
    }
}
