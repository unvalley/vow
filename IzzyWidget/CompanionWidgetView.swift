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
    /// How far into today's new expressions, or nil when the counts belong to an earlier day and
    /// there is nothing to draw. A finished day reads full even where the goal was already met.
    var progress: Double? {
        guard let introduced, let target, target > 0 else { return nil }
        return min(Double(introduced) / Double(target), 1)
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

    /// One thought per size. The small one is the figure, with what today asks for underneath it and
    /// the streak kept to a corner: the widget is there to bring the learner back today, and the run
    /// of days is the reason, not the instruction.
    private var small: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            // Where Today keeps it: the flame and the count sit at the top leading corner there too.
            streak(spellsOutUnit: false)
            CompanionFigure(mood: status.mood, accent: entry.accent)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            Text(status.headline)
                .font(Typography.section).foregroundStyle(Palette.ink)
                .lineLimit(2).minimumScaleFactor(0.8)
            if let progress = status.progress {
                ProgressTrack(progress: progress, accent: entry.accent)
            }
        }
    }

    /// The width belongs to the day's state, so the text column runs the full remaining measure
    /// instead of ending in a spacer: message, then the day's progress, then the streak beneath.
    private var medium: some View {
        HStack(spacing: Spacing.lg) {
            CompanionFigure(mood: status.mood, accent: entry.accent)
                .frame(width: 88)
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(status.headline)
                    // One step above the small size's line: the medium widget is read from further off.
                    .font(.system(.title3, weight: .medium)).foregroundStyle(Palette.ink)
                    .lineLimit(2).minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                if let progress = status.progress, let introduced = status.introduced, let target = status.target {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        ProgressTrack(progress: progress, accent: entry.accent)
                        Text("\(introduced) of \(target) new today")
                            .font(Typography.metadata).foregroundStyle(Palette.secondary)
                            .monospacedDigit()
                    }
                }
                Spacer(minLength: 0)
                streak(spellsOutUnit: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Zero is shown rather than hidden: a streak that has ended is the thing the widget is reporting.
    /// The flame is the outline symbol Home puts it behind, in ink rather than the accent, which stays
    /// on the figure and the day's progress.
    private func streak(spellsOutUnit: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.xxs) {
            Image(systemName: "flame")
                .font(.caption2)
            Text("\(status.streak)")
                .font(Typography.context).monospacedDigit()
            if spellsOutUnit {
                Text("day streak")
                    .font(Typography.metadata).foregroundStyle(Palette.secondary)
            }
        }
        .foregroundStyle(status.streak > 0 ? Palette.ink : Palette.secondary)
    }
}

/// Today's new expressions as a filled track. The two counts were already there as a sentence; the
/// track is what reads before the sentence does, and it is the one place besides the figure where
/// the learner's accent appears.
private struct ProgressTrack: View {
    let progress: Double
    let accent: AppAccent

    private var height: CGFloat { 5 }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule(style: .continuous).fill(Palette.surface)
                // A started day never shows an empty track: below one bar's width it keeps a round cap.
                Capsule(style: .continuous).fill(accent.fill)
                    .frame(width: max(geometry.size.width * progress, progress > 0 ? height : 0))
                    .widgetAccentable()
            }
        }
        .frame(height: height)
        .accessibilityHidden(true)
    }
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
                               remaining: mood == .celebrating ? 0 : 4)
    }
}
