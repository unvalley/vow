import SwiftUI
import WidgetKit

extension CompanionStatus {
    /// One line under the figure, in the app's plain register: where today stands, and nothing more.
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
    /// Read aloud in place of the figure, which carries the same meaning by its pose alone.
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

    private var small: some View {
        VStack(spacing: Spacing.xs) {
            CompanionFigure(mood: status.mood, accent: entry.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(status.headline)
                .font(Typography.context).foregroundStyle(Palette.secondary)
                .lineLimit(1).minimumScaleFactor(0.8)
            streak(size: .title3)
        }
    }

    private var medium: some View {
        HStack(spacing: Spacing.md) {
            CompanionFigure(mood: status.mood, accent: entry.accent)
                .frame(width: 100)
            // Three tight lines rather than a block at each end: the count and what it means belong together.
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    streak(size: .largeTitle)
                    Text("day streak")
                        .font(Typography.metadata).foregroundStyle(Palette.secondary)
                }
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

    /// Zero is shown rather than hidden: a streak that has ended is the thing the widget is reporting.
    private func streak(size: Font.TextStyle) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
            Image(systemName: "flame.fill")
                .font(.footnote)
            Text("\(status.streak)")
                .font(.system(size, weight: .semibold)).monospacedDigit()
        }
        .foregroundStyle(status.streak > 0 ? entry.accent.color : Palette.secondary)
    }
}

// The timeline builder takes entries, not an array, so each preview spells its own loop.
#Preview("Small", as: .systemSmall) {
    CompanionWidget()
} timeline: {
    for mood in CompanionMood.allCases {
        CompanionEntry(date: .now, status: .preview(mood), accent: .blue)
    }
}

#Preview("Medium", as: .systemMedium) {
    CompanionWidget()
} timeline: {
    for mood in CompanionMood.allCases {
        CompanionEntry(date: .now, status: .preview(mood), accent: .blue)
    }
}

extension CompanionStatus {
    static func preview(_ mood: CompanionMood) -> CompanionStatus {
        let started = mood != .lapsed && mood != .fresh
        return CompanionStatus(mood: mood, streak: started ? 12 : 0,
                               introduced: mood == .celebrating ? 5 : (started ? 3 : 0), target: 5,
                               remaining: mood == .celebrating ? 0 : 4)
    }
}
