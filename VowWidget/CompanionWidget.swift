import SwiftUI
import WidgetKit

struct CompanionEntry: TimelineEntry {
    let date: Date
    let status: CompanionStatus
    let accent: AppAccent
}

/// The widget re-reads one small file and derives the pose itself, so it stays right between the
/// app's writes: the figure changes at the evening mark and at midnight on its own.
struct CompanionProvider: TimelineProvider {
    func placeholder(in context: Context) -> CompanionEntry { entry(from: .gallery, at: .now) }

    func getSnapshot(in context: Context, completion: @escaping (CompanionEntry) -> Void) {
        // In the gallery there is nothing to report yet, so show the widget at its best instead of empty.
        let snapshot = context.isPreview ? .gallery : (WidgetSharing.read(CompanionSnapshot.self) ?? CompanionSnapshot())
        completion(entry(from: snapshot, at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CompanionEntry>) -> Void) {
        let snapshot = WidgetSharing.read(CompanionSnapshot.self) ?? CompanionSnapshot()
        let now = Date.now
        let entries = ([now] + snapshot.refreshDates(from: now)).map { entry(from: snapshot, at: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(from snapshot: CompanionSnapshot, at date: Date) -> CompanionEntry {
        CompanionEntry(date: date, status: snapshot.status(now: date), accent: snapshot.accent)
    }
}

extension CompanionSnapshot {
    /// A day part-way through, for the widget gallery and for previews.
    static var gallery: CompanionSnapshot {
        var snapshot = CompanionSnapshot()
        snapshot.lastPracticeDay = Calendar.autoupdatingCurrent.startOfDay(for: .now)
        snapshot.day = snapshot.lastPracticeDay ?? .now
        snapshot.streak = 12
        snapshot.longest = 21
        snapshot.introduced = 3
        snapshot.target = 5
        snapshot.remaining = 4
        return snapshot
    }
}

struct CompanionWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: CompanionSnapshot.widgetKind, provider: CompanionProvider()) { entry in
            CompanionWidgetView(entry: entry)
                .containerBackground(Palette.paper, for: .widget)
        }
        .configurationDisplayName("Streak")
        .description("Today's practice and your current streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

@main
struct VowWidgetBundle: WidgetBundle {
    var body: some Widget {
        CompanionWidget()
        PhraseWidget()
    }
}
