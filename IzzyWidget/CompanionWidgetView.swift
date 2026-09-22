import SwiftUI
import WidgetKit

extension CompanionStatus {
    /// One line under the count, in the app's plain register: where today stands, and nothing more.
    var headline: LocalizedStringKey {
        switch mood {
        case .fresh: "Start your first day"
        case .resting: "Not practiced today"
        case .urging: "Today is almost over"
        case .working: "\(remaining ?? 0) left today"
        case .celebrating: "Today is done"
        case .lapsed: "Start again today"
        }
    }
    /// Read aloud for the whole widget, with the streak as its value.
    var spokenMood: LocalizedStringKey {
        switch mood {
        case .fresh: "Nothing practiced yet"
        case .resting: "Not practiced today"
        case .urging: "Not practiced today, and the day is almost over"
        case .working: "Practicing today"
        case .celebrating: "Today's learning is complete"
        case .lapsed: "The streak has ended"
        }
    }
}

struct CompanionWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CompanionEntry

    private var status: CompanionStatus { entry.status }

    var body: some View {
        Group {
            switch family {
            case .systemMedium: medium
            default: small
            }
        }
        .widgetURL(WidgetSharing.todayURL)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(status.spokenMood)
        .accessibilityValue("\(status.streak) day streak")
    }

    /// The mark sits small in the corner and the count takes the rest: the streak is what the widget is for.
    /// The row of days under it shows the count as a run, so a number has something to stand on.
    private var small: some View {
        VStack(alignment: .leading, spacing: 0) {
            IzzyMark()
            Spacer(minLength: Spacing.xs)
            streak
            WeekRow(days: status.week, mood: status.mood, accent: entry.accent, dot: 11)
                .padding(.top, Spacing.xxs)
            Text(status.headline)
                .font(Typography.context).foregroundStyle(Palette.ink)
                .lineLimit(1).minimumScaleFactor(0.8)
                .padding(.top, Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 0) {
            IzzyMark()
            Spacer(minLength: Spacing.xs)
            HStack(alignment: .bottom, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    streak
                    WeekRow(days: status.week, mood: status.mood, accent: entry.accent, dot: 13)
                }
                // Where today stands reads beside the count, its last line level with the row of days.
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text(status.headline)
                        .font(Typography.section).foregroundStyle(Palette.ink)
                        .lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    if let introduced = status.introduced, let target = status.target, target > 0 {
                        Text("\(introduced) of \(target) new today")
                            .font(Typography.metadata).foregroundStyle(Palette.secondary)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    /// Zero is shown rather than hidden: a streak that has ended is the thing the widget is reporting.
    private var streak: some View {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(flameColor)
                .widgetAccentable()
            Text("\(status.streak)")
                .font(.system(size: 54, weight: .semibold)).monospacedDigit().tracking(-1.5)
                .foregroundStyle(status.streak > 0 ? Palette.ink : Palette.secondary)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
    }

    /// One color throughout: the accent while there is a streak to keep, gray once there is none.
    private var flameColor: Color { status.streak > 0 ? entry.accent.fill : Palette.secondary }
}

/// The last seven days as dots, today at the end. A practised day is filled; today, still open, is a
/// ring, which turns to the accent once the evening has come and the day still needs doing.
private struct WeekRow: View {
    let days: [Bool]
    let mood: CompanionMood
    let accent: AppAccent
    let dot: CGFloat

    var body: some View {
        HStack(spacing: dot * 0.5) {
            ForEach(days.indices, id: \.self) { index in
                let isToday = index == days.count - 1
                if days[index] {
                    Circle().fill(accent.fill).frame(width: dot, height: dot).widgetAccentable()
                } else if isToday {
                    Circle().strokeBorder(mood == .urging ? accent.fill : Palette.secondary, lineWidth: 1.5)
                        .frame(width: dot, height: dot).widgetAccentable(mood == .urging)
                } else {
                    Circle().fill(Palette.secondary.opacity(0.22)).frame(width: dot, height: dot)
                }
            }
        }
    }
}

/// The app icon in miniature: the mark on its black tile, so the widget says whose it is. A tinted or
/// clear Home Screen paints everything one color, where a tile would turn into a blank square, so
/// there the mark stands alone.
private struct IzzyMark: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    private let side: CGFloat = 22

    var body: some View {
        Group {
            if renderingMode == .fullColor {
                Image("IzzyMark")
                    .resizable()
                    .background(.black)
                    .clipShape(shape)
                    // The tile is black on the dark theme's near-black paper too, so a hairline keeps its edge.
                    .overlay(shape.strokeBorder(Palette.outline, lineWidth: 0.5))
            } else if #available(iOS 18, *) {
                Image("IzzyMark")
                    .resizable()
                    .widgetAccentedRenderingMode(.accented)
            } else {
                Image("IzzyMark").resizable()
            }
        }
        .frame(width: side, height: side)
        .accessibilityHidden(true)
    }

    private var shape: RoundedRectangle { RoundedRectangle(cornerRadius: side * 0.225, style: .continuous) }
}

// The timeline builder takes entries, not an array, so each preview spells its own loop.
#Preview("Small", as: .systemSmall) {
    CompanionWidget()
} timeline: {
    for mood in CompanionMood.allCases {
        CompanionEntry(date: .now, status: .preview(mood), accent: .black)
    }
}

#Preview("Medium", as: .systemMedium) {
    CompanionWidget()
} timeline: {
    for mood in CompanionMood.allCases {
        CompanionEntry(date: .now, status: .preview(mood), accent: .black)
    }
}

extension CompanionStatus {
    static func preview(_ mood: CompanionMood) -> CompanionStatus {
        let started = mood != .lapsed && mood != .fresh
        return CompanionStatus(mood: mood, streak: started ? 12 : 0,
                               introduced: mood == .celebrating ? 5 : (started ? 3 : 0), target: 5,
                               remaining: mood == .celebrating ? 0 : 4,
                               week: started ? [true, true, true, true, true, true, mood == .working || mood == .celebrating]
                                             : [true, true, false, false, false, false, false].map { $0 && mood == .lapsed })
    }
}
