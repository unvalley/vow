import SwiftUI
import WidgetKit

struct PhraseWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: PhraseEntry

    var body: some View {
        Group {
            if let phrase = entry.phrase {
                content(phrase)
            } else {
                empty
            }
        }
        .widgetURL(WidgetSharing.todayURL)
    }

    @ViewBuilder private func content(_ phrase: WidgetPhrase) -> some View {
        switch family {
        case .accessoryRectangular: accessory(phrase)
        case .systemMedium: medium(phrase)
        default: small(phrase)
        }
    }

    /// The expression, then what it means. The example needs room to be read, so it waits for medium.
    /// Centred rather than pinned to the top: an expression and two lines leave half a small widget
    /// empty either way, and the middle is where the eye lands.
    private func small(_ phrase: WidgetPhrase) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(phrase.phrase)
                .font(entry.typeface.font(.title2)).foregroundStyle(Palette.ink)
                .lineLimit(2).minimumScaleFactor(0.7)
            Text(meaning(phrase))
                .font(Typography.metadata).foregroundStyle(Palette.secondary)
                .lineLimit(5)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func medium(_ phrase: WidgetPhrase) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(phrase.phrase)
                .font(entry.typeface.font(.title)).foregroundStyle(Palette.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            Text(meaning(phrase))
                .font(Typography.metadata).foregroundStyle(Palette.secondary)
                .lineLimit(2)
            if !phrase.example.isEmpty {
                // The example is set in the phrase's own face: it is the expression in use, not a caption.
                // One gap separates it from the meaning instead of a spacer pushing it to the floor.
                Text(phrase.example)
                    .font(entry.typeface.font(.subheadline)).foregroundStyle(Palette.ink)
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The Lock Screen renders one color, so this size leans on weight and size instead.
    private func accessory(_ phrase: WidgetPhrase) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(phrase.phrase).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
            Text(meaning(phrase)).font(.caption).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Before the app has written a pool, or with no expression the plan opens.
    private var empty: some View {
        Text("Open the app to load expressions")
            .font(Typography.context).foregroundStyle(Palette.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// The short equivalent leads where there is one, joined on a single line because a widget has
    /// no room for the app's two-line `PhraseMeaning`; a Japanese explanation has none and stands alone.
    private func meaning(_ phrase: WidgetPhrase) -> String {
        guard let lead = phrase.lead, !lead.isEmpty else { return phrase.meaning }
        return "\(lead) — \(phrase.meaning)"
    }
}

#Preview("Phrase, small", as: .systemSmall) {
    PhraseWidget()
} timeline: {
    PhraseEntry(date: .now, phrase: WidgetPhrasePool.gallery.phrases.first, typeface: .newYork)
    PhraseEntry(date: .now, phrase: nil, typeface: .newYork)
}

#Preview("Phrase, medium", as: .systemMedium) {
    PhraseWidget()
} timeline: {
    PhraseEntry(date: .now, phrase: WidgetPhrasePool.gallery.phrases.first, typeface: .newYork)
}
