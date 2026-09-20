import Foundation

/// One expression as a widget shows it, already in the learner's explanation language and chosen
/// typeface. Resolving those in the app keeps the catalog — 3.7 MB and 3,008 entries — out of an
/// extension that is given a few tens of megabytes to render in.
struct WidgetPhrase: Codable, Sendable, Equatable, Identifiable {
    var id: String
    var phrase: String
    /// The short English equivalent that leads the explanation (look into → investigate).
    /// Japanese explanations have none: they are already terse.
    var lead: String?
    var meaning: String
    var example: String

}

extension WidgetPhrase {
    init(_ phrase: Phrase, in language: MeaningLanguage) {
        self.init(id: phrase.id, phrase: phrase.phrase, lead: phrase.lead(in: language),
                  meaning: phrase.explanation(in: language), example: phrase.examples.first ?? "")
    }
}

/// The expressions the phrase widget rotates through, soonest review first.
struct WidgetPhrasePool: WidgetShared {
    static let fileName = "phrases.json"
    static let widgetKind = "PhraseWidget"
    var schema = 1
    var phrases: [WidgetPhrase] = []
    /// The learner's phrase face, so the widget sets expressions the way the app does.
    var typeface: PhraseTypeface = .newYork

    /// How many are kept. At one every few hours this is a couple of days of distinct expressions,
    /// so the widget keeps changing while the app goes unopened.
    static let size = 24
    /// How long one expression stays on screen.
    static let interval: TimeInterval = 3 * 60 * 60


    /// The expression to show at `date`. It turns on a fixed clock rather than on a stored position,
    /// so every entry in a timeline is reproducible and two widgets agree with each other.
    func phrase(at date: Date) -> WidgetPhrase? {
        guard !phrases.isEmpty else { return nil }
        let step = Int((date.timeIntervalSince1970 / Self.interval).rounded(.down))
        return phrases[((step % phrases.count) + phrases.count) % phrases.count]
    }

    /// When the expression changes next, and the turns after that: one entry per expression covers
    /// the whole pool, so the widget keeps changing even if the app is never opened.
    func turnDates(from now: Date) -> [Date] {
        guard !phrases.isEmpty else { return [] }
        let step = (now.timeIntervalSince1970 / Self.interval).rounded(.down)
        return (1...phrases.count).map { Date(timeIntervalSince1970: (step + Double($0)) * Self.interval) }
    }
}

extension WidgetPhrasePool {
    /// `phrases` is the currently accessible catalog, as the daily deck and Stats both use.
    init(data: LearningData, phrases: [Phrase], typeface: PhraseTypeface) {
        self.init()
        self.typeface = typeface
        let language = data.meaningLanguage
        let states = data.memoryReviews ?? [:]
        // Soonest review first, so what is closest to being forgotten comes round most often. A phrase
        // answered today has the shortest interval of all, which puts the newly learned near the front.
        // Ties break on the id so the order is the same on every write. Only `size` are kept, so this
        // picks them with the bounded selection the daily queue uses rather than sorting the catalog.
        let studied = phrases.filter { states[$0.id] != nil }.smallest(Self.size) {
            let a = states[$0.id]!.due, b = states[$1.id]!.due
            return a == b ? $0.id < $1.id : a < b
        }
        // Expressions never introduced top up the rest, and are not even walked once the pool is full.
        let fill = Self.size - studied.count
        let unseen = fill > 0 ? Array(phrases.lazy.filter { states[$0.id] == nil }.prefix(fill)) : []
        self.phrases = (studied + unseen).map { WidgetPhrase($0, in: language) }
    }
}
