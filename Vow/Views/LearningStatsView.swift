import SwiftUI

struct ProgressViewScreen: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.appAccent) private var accent
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var now = Date.now
    @State private var goal = false
    @State private var month = Date.now

    private var calendar: Calendar { .autoupdatingCurrent }
    private var stats: LearningStats {
        LearningStats(data: store.data, phrases: store.phrases.filter { purchases.allows($0) }, now: now, calendar: calendar)
    }
    private var columns: [GridItem] {
        Array(repeating: GridItem(.flexible(), alignment: .leading), count: typeSize.isAccessibilitySize ? 1 : 2)
    }

    var body: some View {
        let snapshot = stats
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                today(snapshot)
                monthCalendar(snapshot)
            }.foregroundStyle(Palette.ink)
        }
        .navigationTitle("Stats").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $goal) { NavigationStack { DailyGoalView() } }
        .closesForReviewRequest($goal)
        .onAppear { now = .now }
        .onChange(of: store.data.events.count) { _, _ in now = .now }
        .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            if scenePhase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in now = .now }
    }

    private func today(_ stats: LearningStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
                metric("\(stats.streak.current)", "Current streak")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Current streak, \(stats.streak.current) \(stats.streak.current == 1 ? "day" : "days")")
                    .accessibilityIdentifier("currentStreak")
                metric("\(stats.streak.longest)", "Best streak")
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Best streak, \(stats.streak.longest) \(stats.streak.longest == 1 ? "day" : "days")")
                    .accessibilityIdentifier("bestStreak")
            }
            VStack(alignment: .leading, spacing: Spacing.sm) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Today").font(.headline)
                    Spacer()
                    Button("Daily goal") { goal = true }
                        .font(.subheadline).frame(minHeight: 44).accessibilityIdentifier("statsDailyGoal")
                }
                Text("\(stats.daily.introduced) / \(stats.daily.goal) new expressions")
                    .font(.title3.monospacedDigit()).accessibilityIdentifier("statsDailyProgress")
                LearningProgressTrack(completed: stats.daily.introduced, total: stats.daily.goal)
                Text("\(stats.daily.dueReviews) \(stats.daily.dueReviews == 1 ? "review" : "reviews") due now")
                    .font(.subheadline).foregroundStyle(Palette.secondary).accessibilityIdentifier("statsDueNow")
                if stats.daily.isComplete {
                    Label("Today's learning complete", systemImage: "checkmark.circle")
                        .font(.subheadline).foregroundStyle(accent.color)
                }
            }.padding(Spacing.lg).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    /// One month at a time: a dot on practiced days, the number of reviews due on coming days.
    /// A day with either opens its phrases.
    private func monthCalendar(_ stats: LearningStats) -> some View {
        let reviews = store.phrases.filter { purchases.allows($0) }.compactMap { store.data.memoryReviews?[$0.id] }
        let sheet = LearningCalendar(month: month, events: store.data.events, stories: store.data.rehearsalDates ?? [],
                                     reviews: reviews, now: now, calendar: calendar)
        let today = calendar.startOfDay(for: now)
        let atCurrentMonth = calendar.isDate(sheet.month, equalTo: now, toGranularity: .month)
        return VStack(alignment: .leading, spacing: Spacing.md) {
            HStack {
                Text(sheet.month.formatted(.dateTime.year().month(.wide))).font(Typography.section)
                    .accessibilityAddTraits(.isHeader)
                Spacer()
                Button { month = calendar.date(byAdding: .month, value: -1, to: sheet.month) ?? month } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }.accessibilityLabel("Previous month").accessibilityIdentifier("calendarPreviousMonth")
                Button { month = calendar.date(byAdding: .month, value: 1, to: sheet.month) ?? month } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }.disabled(atCurrentMonth).accessibilityLabel("Next month").accessibilityIdentifier("calendarNextMonth")
            }.buttonStyle(.plain)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
                ForEach(0..<7, id: \.self) { offset in
                    let symbol = calendar.veryShortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + offset) % 7]
                    Text(symbol).font(.caption2).foregroundStyle(Palette.secondary)
                }
                ForEach(Array(sheet.days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        let isToday = calendar.isDate(day, inSameDayAs: today)
                        let active = sheet.isActive(day)
                        let due = sheet.dueCount(on: day)
                        NavigationLink { PracticeDayView(day: day) } label: {
                            VStack(spacing: 2) {
                                Text(day.formatted(.dateTime.day())).font(.subheadline.monospacedDigit())
                                if due > 0 {
                                    Text("\(due)").font(.caption2.monospacedDigit()).foregroundStyle(accent.color)
                                } else {
                                    Circle().fill(active ? accent.color : .clear).frame(width: 5, height: 5)
                                }
                            }.frame(maxWidth: .infinity, minHeight: 40)
                                .selectionSurface(isToday, cornerRadius: 10, restFill: .clear)
                                .opacity(day > today && due == 0 ? 0.35 : 1)
                        }.buttonStyle(.plain).disabled(!active && due == 0)
                            .accessibilityLabel(day.formatted(.dateTime.month(.wide).day()))
                            .accessibilityValue([active ? "practiced" : nil, due > 0 ? "\(due) reviews due" : nil].compactMap { $0 }.joined(separator: ", "))
                            .accessibilityIdentifier("calendarDay-\(day.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits)))")
                    } else {
                        Color.clear.frame(minHeight: 40)
                    }
                }
            }
            if let next = stats.nextReview {
                Text("Next scheduled: \(next.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.subheadline).foregroundStyle(Palette.secondary).accessibilityIdentifier("statsNextReview")
            } else if stats.started == 0 {
                Text("Study your first expression to start a review schedule.").font(.subheadline).foregroundStyle(Palette.secondary)
            }
        }
    }

    private func title(_ text: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(text).font(Typography.family)
            Text(detail).font(.subheadline.monospacedDigit()).foregroundStyle(Palette.secondary)
        }.accessibilityAddTraits(.isHeader)
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(value).font(Typography.counter)
            Text(label).font(.caption).foregroundStyle(Palette.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

}

/// What was practiced on one day, opened from the Stats calendar.
struct PracticeDayView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    let day: Date
    private var calendar: Calendar { .autoupdatingCurrent }
    var body: some View {
        let practiced = LearningCalendar.phraseIDs(on: day, events: store.data.events, calendar: calendar)
            .compactMap { id in store.phrases.first { $0.id == id } }
        let today = calendar.startOfDay(for: .now)
        let target = calendar.startOfDay(for: day)
        // Reviews scheduled for this day; on today, everything overdue as well.
        let due = store.phrases.filter { phrase in
            guard purchases.allows(phrase), let review = store.data.memoryReviews?[phrase.id] else { return false }
            let dueDay = max(today, calendar.startOfDay(for: review.due))
            return dueDay == target
        }.sorted { ($0.phrase, $0.id) < ($1.phrase, $1.id) }
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                if !practiced.isEmpty { section("Learned", practiced, prefix: "calendarPhrase") }
                if !due.isEmpty { section("Reviews due", due, prefix: "calendarDue") }
                if practiced.isEmpty && due.isEmpty {
                    Text("No learning on this day").font(.subheadline).foregroundStyle(Palette.secondary)
                }
            }
        }.navigationTitle(day.formatted(.dateTime.month(.wide).day())).navigationBarTitleDisplayMode(.inline)
    }

    private func section(_ title: LocalizedStringKey, _ phrases: [Phrase], prefix: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(title).font(.headline)
                Spacer()
                Text("\(phrases.count)").font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
            }
            LazyVStack(spacing: 0) {
                ForEach(phrases) { phrase in
                    NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }
                        .buttonStyle(.plain).accessibilityIdentifier("\(prefix)-\(phrase.id)")
                    Divider()
                }
            }
        }
    }
}
