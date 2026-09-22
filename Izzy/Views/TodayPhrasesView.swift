import SwiftUI

/// Today's phrases, opened from the progress count on Home. One tab lists today's new phrases (learned so far
/// and still to come, where the daily goal is changed), the other today's reviews. Tapping a phrase goes to its card.
struct TodayPhrasesView: View {
    enum Tab: Hashable { case new, review }
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    let now: Date
    @State var tab: Tab
    var onSelect: (Phrase) -> Void

    var body: some View {
        // Derived here rather than passed in, so a goal change on the pushed editor refills the list at once.
        let d = HomeDerivation(phrases: store.phrases, purchased: purchases.hasFullAccess, kind: store.data.homeKindFilter,
                               memory: store.data.memoryReviews ?? [:], reviews: store.data.reviews, focus: store.data.focus,
                               dailyNew: store.data.newPhrasesPerDay, now: now, mode: .learning, selectedID: "")
        NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    // Each tab carries its count, so the lists below need none.
                    Picker("Show", selection: $tab) {
                        Text("New (\(d.learnedToday.count + d.upcomingNew.count))").tag(Tab.new)
                        Text("Review (\(d.reviewedToday.count + d.upcomingReviews.count))").tag(Tab.review)
                    }.pickerStyle(.segmented).labelsHidden().accessibilityIdentifier("todayPhrasesTab")
                    switch tab {
                    case .new: newPhrases(d)
                    case .review: reviews(d)
                    }
                }
            }.foregroundStyle(Palette.ink)
                .navigationTitle("Today's phrases").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closeTodayPhrases") } }
        }
    }

    @ViewBuilder private func newPhrases(_ d: HomeDerivation) -> some View {
        if !d.learnedToday.isEmpty { section("Learned today", d.learnedToday, prefix: "newPhraseLearned") }
        if !d.upcomingNew.isEmpty { section("Up next", d.upcomingNew, prefix: "newPhraseUpcoming") }
        if d.learnedToday.isEmpty && d.upcomingNew.isEmpty {
            Text("No new phrases left in this collection").font(.subheadline).foregroundStyle(Palette.secondary)
        }
        NavigationLink { DailyGoalView() } label: {
            HStack(spacing: Spacing.sm) {
                Text("Change daily goal").font(Typography.control)
                Spacer()
                Text("\(store.data.newPhrasesPerDay) new phrases per day").font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary)
            }.frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(RowPressStyle()).accessibilityIdentifier("changeDailyGoal")
    }

    @ViewBuilder private func reviews(_ d: HomeDerivation) -> some View {
        let total = d.reviewedToday.count + d.upcomingReviews.count
        if total == 0 {
            Text("No reviews due").font(.subheadline).foregroundStyle(Palette.secondary)
        } else {
            // What is still to do comes first and needs no heading.
            if !d.upcomingReviews.isEmpty { section(nil, d.upcomingReviews, prefix: "reviewUpcoming") }
            if !d.reviewedToday.isEmpty { section("Reviewed today", d.reviewedToday, prefix: "reviewDone") }
        }
    }

    private func section(_ title: LocalizedStringKey?, _ phrases: [Phrase], prefix: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let title { Text(title).font(Typography.section).accessibilityAddTraits(.isHeader) }
            LazyVStack(spacing: 0) {
                ForEach(phrases) { phrase in
                    Button { onSelect(phrase) } label: { PhraseRow(phrase: phrase) }
                        .buttonStyle(RowPressStyle()).accessibilityIdentifier("\(prefix)-\(phrase.id)")
                        .accessibilityHint("Shows this card")
                    Divider()
                }
            }
        }
    }
}
