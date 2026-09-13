import Foundation

struct ReviewReminderPreferences: Codable, Equatable, Sendable {
    var enabled = false
    var hour = 19
    var minute = 0

    var safeHour: Int { min(23, max(0, hour)) }
    var safeMinute: Int { min(59, max(0, minute)) }
}

struct ReviewReminderInput: Equatable, Sendable {
    var preferences: ReviewReminderPreferences
    var reviews: [String: MemoryReview]
    var allowedIDs: Set<String>
    var japanese: Bool
}

struct ReviewReminder: Equatable, Sendable {
    var date: Date
    var count: Int
}

/// Uses actual SM-2 review deadlines, not a second estimate of the forgetting curve.
/// One reminder per due day, at the first chosen local time on or after the deadline.
enum ReviewReminderPlan {
    static let limit = 32

    static func make(_ input: ReviewReminderInput, now: Date, calendar: Calendar = .autoupdatingCurrent) -> [ReviewReminder] {
        guard input.preferences.enabled else { return [] }
        var groups: [Date: Int] = [:]
        for (id, review) in input.reviews where input.allowedIDs.contains(id) {
            guard review.due.timeIntervalSince1970.isFinite else { continue }
            // Never schedule in the past or immediately upon opening the app.
            let earliest = max(review.due, now.addingTimeInterval(1))
            let start = calendar.startOfDay(for: earliest)
            var components = DateComponents()
            components.hour = input.preferences.safeHour
            components.minute = input.preferences.safeMinute
            components.second = 0
            // nextTime preserves a valid local reminder time across DST gaps.
            guard var date = calendar.nextDate(after: start.addingTimeInterval(-1), matching: components,
                                               matchingPolicy: .nextTime, repeatedTimePolicy: .first) else { continue }
            if date < earliest {
                guard let tomorrow = calendar.date(byAdding: .day, value: 1, to: start),
                      let next = calendar.nextDate(after: tomorrow.addingTimeInterval(-1), matching: components,
                                                   matchingPolicy: .nextTime, repeatedTimePolicy: .first) else { continue }
                date = next
            }
            groups[date, default: 0] += 1
        }
        // Counts include earlier, still-unreviewed cards. App activity replaces these plans.
        var count = 0
        return groups.keys.sorted().prefix(limit).map { date in
            count += groups[date, default: 0]
            return ReviewReminder(date: date, count: count)
        }
    }
}
