import Foundation
import WidgetKit

/// Keeps the home-screen widgets in step with saved progress.
///
/// Building either file walks the accessible catalog, so `RootView` gates this on `WidgetInput`
/// first. WidgetKit's reload budget is finite, so a widget is reloaded only when the file it
/// reads actually changed, which also leaves the other widget's budget alone.
@MainActor enum WidgetBridge {
    private static var companion: CompanionSnapshot?
    private static var pool: WidgetPhrasePool?

    static func update(store: LearningStore, purchased: Bool, now: Date = .now) {
        let visible = HomeDerivation.visible(store.phrases, purchased: purchased, kind: store.data.homeKindFilter)
        write(CompanionSnapshot(data: store.data, phrases: visible, now: now), last: &companion)
        write(WidgetPhrasePool(data: store.data, phrases: visible,
                               typeface: store.data.typeface(fullAccess: purchased)), last: &pool)
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

/// When the widget files need rebuilding, as three values that are O(1) to compare on every render.
///
/// It watches the store's revision rather than listing the fields a snapshot happens to read: a
/// same-day re-rating replaces an event in place, leaving every count and the last date unchanged,
/// and a field that starts mattering would otherwise have to be added here by hand.
struct WidgetInput: Equatable, Sendable {
    let revision: Int
    let purchased: Bool
    /// The day itself, so returning to the app after midnight rewrites the day's counts.
    let day: Date

    @MainActor init(store: LearningStore, purchased: Bool, now: Date = .now, calendar: Calendar = .autoupdatingCurrent) {
        revision = store.revision
        self.purchased = purchased
        day = calendar.startOfDay(for: now)
    }
}
