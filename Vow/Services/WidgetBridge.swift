import Foundation
import WidgetKit

/// Keeps the home-screen widgets in step with saved progress.
///
/// Building either file walks the accessible catalog, and WidgetKit's reload budget is finite, so the
/// app compares a cheap summary before building, and then reloads only the widget whose file changed.
@MainActor enum WidgetBridge {
    private static var companion: CompanionSnapshot?
    private static var pool: WidgetPhrasePool?

    static func update(store: LearningStore, purchased: Bool, now: Date = .now) {
        let kind = store.data.homeKindFilter
        let visible = store.phrases.filter { AccessPolicy.allows($0, purchased: purchased) && kind.allows($0) }
        write(CompanionSnapshot(data: store.data, phrases: visible, now: now), last: &companion)
        write(WidgetPhrasePool(data: store.data, phrases: visible,
                               typeface: store.data.typeface(fullAccess: purchased), now: now), last: &pool)
    }

    private static func write<T: WidgetShared>(_ value: T, last: inout T?) {
        guard value != last else { return }
        last = value
        // A container the app group hasn't granted yet, or a full disk: the widget keeps its last
        // timeline, which is a better failure than an empty one.
        guard (try? WidgetSharing.write(value)) != nil else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: T.widgetKind)
    }
}

/// What the widget files are built from, reduced to values that are cheap to compare on every render.
struct CompanionInput: Equatable {
    let events: Int
    let lastEvent: Date?
    let rehearsals: Int
    let reviews: Int
    let goal: Int
    let kind: PhraseKindFilter
    let accent: AppAccent
    let typeface: PhraseTypeface
    let japanese: Bool
    let purchased: Bool
    /// The day itself, so returning to the app after midnight rewrites the day's counts.
    let day: Date

    init(data: LearningData, purchased: Bool, now: Date = .now, calendar: Calendar = .autoupdatingCurrent) {
        events = data.events.count
        // A second answer to the same phrase on the same day replaces its event instead of adding one.
        lastEvent = data.events.last?.date
        rehearsals = data.rehearsalCount
        reviews = (data.memoryReviews ?? [:]).count
        goal = data.newPhrasesPerDay
        kind = data.homeKindFilter
        accent = data.accentColor
        typeface = data.typeface(fullAccess: purchased)
        japanese = data.meaningLanguage == .japanese
        self.purchased = purchased
        day = calendar.startOfDay(for: now)
    }
}
