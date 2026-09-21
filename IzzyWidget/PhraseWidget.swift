import SwiftUI
import WidgetKit

struct PhraseEntry: TimelineEntry {
    let date: Date
    /// Nothing to show before the app has written a pool, or when the plan opens no expressions.
    let phrase: WidgetPhrase?
    let typeface: PhraseTypeface
    /// The learner's color, which marks the expression inside its example as the app does.
    let accent: AppAccent
}

/// The pool turns on a fixed clock, so the widget can lay out a timeline that keeps changing for
/// days while the app goes unopened — one entry per expression it holds.
struct PhraseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PhraseEntry { entry(from: .gallery, at: .now) }

    func getSnapshot(in context: Context, completion: @escaping (PhraseEntry) -> Void) {
        let pool = context.isPreview ? .gallery : (WidgetSharing.read(WidgetPhrasePool.self) ?? WidgetPhrasePool())
        completion(entry(from: pool, at: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PhraseEntry>) -> Void) {
        let pool = WidgetSharing.read(WidgetPhrasePool.self) ?? WidgetPhrasePool()
        let now = Date.now
        let entries = ([now] + pool.turnDates(from: now)).map { entry(from: pool, at: $0) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

    private func entry(from pool: WidgetPhrasePool, at date: Date) -> PhraseEntry {
        PhraseEntry(date: date, phrase: pool.phrase(at: date), typeface: pool.typeface, accent: pool.accent)
    }
}

extension WidgetPhrasePool {
    /// One expression for the widget gallery and for previews, where no pool has been written yet.
    static let gallery = WidgetPhrasePool(phrases: [
        WidgetPhrase(id: "26-look-into", phrase: "look into", lead: "investigate",
                     meaning: "to try to find out the facts about something",
                     example: "I'll look into it and get back to you tomorrow.")
    ])
}

struct PhraseWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: WidgetPhrasePool.widgetKind, provider: PhraseProvider()) { entry in
            PhraseWidgetView(entry: entry)
                .containerBackground(Palette.paper, for: .widget)
        }
        .configurationDisplayName("Expression")
        .description("An expression to review, changing through the day.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
    }
}
