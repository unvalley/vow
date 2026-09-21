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

    /// A dictionary entry's order, the one the app's own meaning uses: the expression, the short
    /// equivalent in ink, then the explanation stepped down. Joining the two into one grey line read
    /// as a single block of small type, and the one word worth catching was buried in it.
    ///
    /// The example needs room to be read, so it waits for medium. Centred rather than pinned to the
    /// top: an expression and two lines leave half a small widget empty either way, and the middle is
    /// where the eye lands.
    private func small(_ phrase: WidgetPhrase) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(phrase.phrase)
                .font(entry.typeface.font(.title2)).foregroundStyle(Palette.ink)
                .lineLimit(2).minimumScaleFactor(0.7)
            if let lead = phrase.lead, !lead.isEmpty {
                Text(lead)
                    .font(Typography.context).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.8)
                Text(phrase.meaning)
                    .font(Typography.metadata).foregroundStyle(Palette.secondary)
                    .lineLimit(3)
            } else {
                // A Japanese explanation has no equivalent to lead with, and takes the room instead.
                Text(phrase.meaning)
                    .font(Typography.metadata).foregroundStyle(Palette.secondary)
                    .lineLimit(4)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The medium size has the width for a headword line, so the equivalent sits beside the
    /// expression rather than under it, and the example gets the block below to itself.
    private func medium(_ phrase: WidgetPhrase) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(phrase.phrase)
                    .font(entry.typeface.font(.title)).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if let lead = phrase.lead, !lead.isEmpty {
                    Text(lead)
                        .font(Typography.context).foregroundStyle(Palette.secondary)
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            Text(phrase.meaning)
                .font(Typography.metadata).foregroundStyle(Palette.secondary)
                .lineLimit(2)
            if !phrase.example.isEmpty {
                // The example is set in the phrase's own face: it is the expression in use, not a caption.
                // One gap separates it from the meaning instead of a spacer pushing it to the floor.
                Text(example(phrase))
                    .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The Lock Screen renders one color, so this size leans on weight and size instead, and the
    /// equivalent joins the explanation on one line for want of a third.
    private func accessory(_ phrase: WidgetPhrase) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(phrase.phrase).font(.headline).lineLimit(1).minimumScaleFactor(0.7)
            Text(joined(phrase)).font(.caption).lineLimit(2)
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

    /// The example with the expression marked inside it, as the app marks every example: what the
    /// widget teaches in one glance is where the expression lands in a sentence. The app's soft wash
    /// behind the words is left off here — at this size it reads as a highlighter over a third of the
    /// line — so the mark is the accent and the weight alone. An example phrased around an alternative
    /// form the pool does not carry simply stays unmarked.
    private func example(_ phrase: WidgetPhrase) -> AttributedString {
        let font = entry.typeface.font(.subheadline)
        var result = AttributedString()
        var cursor = phrase.example.startIndex
        for range in PhraseHighlight.ranges(in: phrase.example, expressions: [phrase.phrase], allowsGaps: !phrase.idiom) {
            var plain = AttributedString(String(phrase.example[cursor..<range.lowerBound]))
            plain.foregroundColor = Palette.ink
            plain.font = font
            result.append(plain)
            var marked = AttributedString(String(phrase.example[range]))
            marked.foregroundColor = entry.accent.color
            marked.font = font.weight(.semibold)
            result.append(marked)
            cursor = range.upperBound
        }
        var tail = AttributedString(String(phrase.example[cursor...]))
        tail.foregroundColor = Palette.ink
        tail.font = font
        result.append(tail)
        return result
    }

    /// One line for the Lock Screen: the short equivalent leads where there is one, joined because a
    /// rectangular accessory has no room for the app's two-line meaning.
    private func joined(_ phrase: WidgetPhrase) -> String {
        guard let lead = phrase.lead, !lead.isEmpty else { return phrase.meaning }
        return "\(lead) — \(phrase.meaning)"
    }
}

#Preview("Phrase, small", as: .systemSmall) {
    PhraseWidget()
} timeline: {
    PhraseEntry(date: .now, phrase: WidgetPhrasePool.gallery.phrases.first, typeface: .newYork, accent: .black)
    PhraseEntry(date: .now, phrase: nil, typeface: .newYork, accent: .black)
}

#Preview("Phrase, medium", as: .systemMedium) {
    PhraseWidget()
} timeline: {
    PhraseEntry(date: .now, phrase: WidgetPhrasePool.gallery.phrases.first, typeface: .newYork, accent: .black)
}
