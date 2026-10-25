import Foundation

/// Stable free IDs; adding or sorting the catalog never changes the free selection.
enum AccessPolicy {
    static let productID = "me.unvalley.izzy.pro.lifetime"
    /// A ¥0 non-consumable that opens Pro for `trialDays`, the time-based trial App Review Guideline 3.1.1
    /// allows apps without subscriptions. Owning it is permanent, so each Apple Account gets one trial;
    /// the clock starts at the Apple-signed purchase date, and nothing is charged when it ends.
    static let trialProductID = "me.unvalley.izzy.pro.trial"
    static let trialDays = 7
    static func trialEnd(startedAt start: Date) -> Date { start.addingTimeInterval(TimeInterval(trialDays) * 86_400) }
    static let freePhraseIDs: Set<String> = [
        "01-bring-up", "02-get-across", "03-follow-up", "04-push-back", "05-talk-through",
        "06-wrap-up", "07-catch-up", "08-open-up", "09-reach-out", "10-drift-apart",
        "11-let-down", "12-bring-out", "13-put-off", "14-work-out", "15-fall-through",
        "16-turn-down", "17-come-up", "18-rule-out", "19-come-across", "20-figure-out",
        "21-back-up", "22-go-over", "23-think-through", "24-point-out", "25-look-for",
        "26-look-into", "27-look-after", "28-look-up", "29-look-forward-to", "30-look-out-for",
        "31-look-up-to", "32-look-back-on", "33-look-through", "34-look-down-on", "35-get-back-to",
        "36-get-around-to", "37-get-along-with", "38-get-over", "39-get-through", "40-get-away-with",
        "41-get-by", "42-take-on", "43-take-over", "44-take-in", "45-take-up",
        "46-take-back", "47-take-off", "48-put-up-with", "49-put-forward", "50-put-together"
    ]
    /// Twenty well-known idioms, then a spread from A2 to C1, so whichever levels a learner chooses,
    /// the free plan has some at their level to try.
    static let freeIdiomIDs: Set<String> = [
        "idiom-break-the-ice",
        "idiom-a-piece-of-cake",
        "idiom-under-the-weather",
        "idiom-on-the-same-page",
        "idiom-once-in-a-blue-moon",
        "idiom-the-ball-is-in-your-court",
        "idiom-spill-the-beans",
        "idiom-hit-the-nail-on-the-head",
        "idiom-cost-an-arm-and-a-leg",
        "idiom-call-it-a-day",
        "idiom-get-cold-feet",
        "idiom-in-the-long-run",
        "idiom-out-of-the-blue",
        "idiom-a-blessing-in-disguise",
        "idiom-the-last-straw",
        "idiom-on-the-fence",
        "idiom-miss-the-boat",
        "idiom-go-the-extra-mile",
        "idiom-cut-corners",
        "idiom-in-hot-water",
        "idiom-a-pain-in-the-neck",
        "idiom-all-ears",
        "idiom-at-first-glance",
        "idiom-in-the-same-boat",
        "idiom-back-to-square-one",
        "idiom-a-long-shot",
        "idiom-take-it-easy",
        "idiom-long-time-no-see",
        "idiom-by-the-way",
        "idiom-keep-in-touch",
        "idiom-make-sure",
        "idiom-just-in-case",
        "idiom-take-your-time",
        "idiom-feel-free",
        "idiom-it-depends",
        "idiom-once-in-a-while",
        "idiom-get-the-hang-of",
        "idiom-give-it-a-shot",
        "idiom-easier-said-than-done",
        "idiom-from-scratch",
        "idiom-keep-an-eye-on",
        "idiom-ring-a-bell",
        "idiom-on-the-right-track",
        "idiom-not-my-cup-of-tea",
        "idiom-make-the-most-of",
        "idiom-the-elephant-in-the-room",
        "idiom-play-devil's-advocate",
        "idiom-turn-a-blind-eye",
        "idiom-leave-no-stone-unturned",
        "idiom-when-push-comes-to-shove"
    ]
    static let freeIDs = freePhraseIDs.union(freeIdiomIDs)
    static func allows(_ phrase: Phrase, purchased: Bool) -> Bool { purchased || freeIDs.contains(phrase.id) }

    /// The free plan keeps up to this many saved phrases, and as many notes; Pro has no limit.
    /// Nothing already kept is removed: past the limit, unsaving and editing still work, adding waits for Pro.
    static let freeKeepLimit = 10
    static func canSave(_ id: String, saved: Set<String>, purchased: Bool) -> Bool {
        purchased || saved.contains(id) || saved.count < freeKeepLimit
    }
    static func canWriteNote(for id: String, notes: [String: String], purchased: Bool) -> Bool {
        purchased || hasText(notes[id]) || notes.values.filter(hasText).count < freeKeepLimit
    }
    /// Clearing a note leaves an empty string behind; only text counts toward the limit.
    private static func hasText(_ note: String?) -> Bool {
        !(note ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
