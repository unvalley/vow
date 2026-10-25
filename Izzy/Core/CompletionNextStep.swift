import Foundation

/// The one thing Home's completion offers beyond tomorrow's reviews, most important first. Most people
/// leave a learning app within its first days, long before a free plan runs out, so a finished day first
/// asks for what brings them back (a reminder at the hour they just studied), then offers the Pro trial
/// while it can still shape what they learn. Either can be put off for a week.
enum CompletionNextStep: Equatable, Sendable {
    case freePlanFinished
    case proReviewsWaiting
    case reminder
    case trial

    static let snooze: TimeInterval = 7 * 86_400
    /// Where Home keeps when each card was put off.
    static let reminderSnoozedKey = "completion.reminderSnoozed"
    static let trialSnoozedKey = "completion.trialSnoozed"

    struct State: Sendable {
        var hasFullAccess = false
        var freePlanFinished = false
        var pausedProReviews = 0
        var remindersOn = false
        var notificationsDenied = false
        var reminderSnoozed: Date?
        var trialOffered = false
        var trialSnoozed: Date?
    }

    static func choose(_ state: State, now: Date) -> CompletionNextStep? {
        func snoozed(_ date: Date?) -> Bool { date.map { now.timeIntervalSince($0) < snooze } ?? false }
        if !state.hasFullAccess {
            if state.freePlanFinished { return .freePlanFinished }
            if state.pausedProReviews > 0 { return .proReviewsWaiting }
        }
        if !state.remindersOn, !state.notificationsDenied, !snoozed(state.reminderSnoozed) { return .reminder }
        if state.trialOffered, !snoozed(state.trialSnoozed) { return .trial }
        return nil
    }

    /// The reminder time offered: the next five-minute mark after the day was finished, so the habit keeps
    /// the slot the learner already found. Never earlier: a reminder fires at the first chosen time on or after
    /// a review is due, and today's answers fall due a day after they were given, so an earlier minute would
    /// skip tomorrow, the return that matters most. Just before midnight it stays at 23:59 for the same reason.
    static func reminderTime(for date: Date, calendar: Calendar = .autoupdatingCurrent) -> (hour: Int, minute: Int) {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        let next = ((parts.hour ?? 19) * 60 + (parts.minute ?? 0)) / 5 * 5 + 5
        return next >= 24 * 60 ? (23, 59) : (next / 60, next % 60)
    }
}
