import SwiftUI

/// Shared by Home and Phrase notes so intervals and rating actions agree.
struct MemoryRatingControls: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.isEnabled) private var isEnabled
    let state: MemoryReview?
    let now: Date
    var compact = false
    /// The answer already given: drawn in the accent color so a rated phrase reads as rated.
    var selected: MemoryRating? = nil
    let onRate: (MemoryRating) -> Void
    @State private var taps = 0

    private var columns: Int {
        if typeSize.isAccessibilitySize { return 1 }
        return compact && typeSize < .xxLarge ? 4 : 2
    }

    var body: some View {
        VStack(spacing: Spacing.sm) {
            Text("How well did you remember?")
                .font(Typography.section).foregroundStyle(Palette.ink)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: columns), spacing: Spacing.xs) {
                ForEach(MemoryRating.allCases, id: \.self) { rating in
                    let next = MemoryScheduler.rate(state, rating: rating, now: now)
                    Button { taps += 1; onRate(rating) } label: {
                        VStack(spacing: Spacing.xxs) {
                            Image(systemName: symbol(for: rating))
                                .font(.body).frame(minHeight: 22).accessibilityHidden(true)
                            Text(LocalizedStringKey(rating.title)).font(.subheadline.weight(.medium))
                            Text(MemoryScheduler.intervalLabel(until: next.due, now: now))
                                .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                        }.frame(maxWidth: .infinity, minHeight: 44)
                            .padding(.horizontal, Spacing.xxs).padding(.vertical, Spacing.sm)
                            .selectionSurface(selected == rating, cornerRadius: Radius.medium)
                            .opacity(isEnabled || selected == rating ? 1 : DisabledStyle.opacity)
                            // Half of the gap on each side belongs to a cell, so a tap between two cells still lands.
                            .hitArea(Spacing.xs / 2)
                    }.buttonStyle(PressStyle(dimsWhenDisabled: false)).accessibilityIdentifier("memoryRate-\(rating.rawValue)")
                }
            }
        }.sensoryFeedback(.selection, trigger: taps)
    }

    private func symbol(for rating: MemoryRating) -> String {
        switch rating {
        case .again: "arrow.counterclockwise"
        case .hard: "hourglass" // the tortoise means "Slower" on example audio
        case .good: "checkmark"
        case .easy: "bolt"
        }
    }
}
