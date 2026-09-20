import SwiftUI

struct ProgressViewScreen: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.appAccent) private var accent
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @State private var now = Date.now
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
                // Today's goal and due count live on Home; Stats keeps the longer view.
                streaks(snapshot)
                monthCalendar(snapshot)
            }.foregroundStyle(Palette.ink)
        }
        .navigationTitle("Stats").navigationBarTitleDisplayMode(.inline)
        .onAppear { now = .now; Analytics.shared.record(.statsOpened) }
        .onChange(of: store.data.events.count) { _, _ in now = .now }
        .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            if scenePhase == .active { now = .now }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in now = .now }
    }

    private func streaks(_ stats: LearningStats) -> some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
            metric("\(stats.streak.current)", "Current streak")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Current streak, \(stats.streak.current) days")
                .accessibilityIdentifier("currentStreak")
            metric("\(stats.streak.longest)", "Best streak")
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Best streak, \(stats.streak.longest) days")
                .accessibilityIdentifier("bestStreak")
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
                Button { showMonth(offset: -1, from: sheet.month) } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }.accessibilityLabel("Previous month").accessibilityIdentifier("calendarPreviousMonth")
                Button { showMonth(offset: 1, from: sheet.month) } label: {
                    Image(systemName: "chevron.right").frame(width: 44, height: 44)
                }.disabled(atCurrentMonth).accessibilityLabel("Next month").accessibilityIdentifier("calendarNextMonth")
            }.buttonStyle(PressStyle())
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: Spacing.xs) {
                ForEach(0..<7, id: \.self) { offset in
                    let symbol = calendar.veryShortStandaloneWeekdaySymbols[(calendar.firstWeekday - 1 + offset) % 7]
                    Text(symbol).font(.caption2).foregroundStyle(Palette.secondary)
                }
                ForEach(Array(sheet.days.enumerated()), id: \.offset) { _, day in
                    if let day {
                        CalendarDay(day: day, today: today, practiced: sheet.practiceCount(on: day), due: sheet.dueCount(on: day))
                    } else {
                        Color.clear.frame(minHeight: 44)
                    }
                }
            }
            if let next = stats.nextReview {
                Text("Next scheduled: \(next.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Palette.secondary).accessibilityIdentifier("statsNextReview")
            } else if stats.started == 0 {
                Text("Study your first expression to start a review schedule.").font(.subheadline).foregroundStyle(Palette.secondary)
            }
        }
    }

    /// A month change is a deliberate step, so the days cross-fade rather than jump.
    private func showMonth(offset: Int, from shown: Date) {
        withAnimation(reduceMotion ? Motion.reducedFade : Motion.snappy) {
            month = calendar.date(byAdding: .month, value: offset, to: shown) ?? month
        }
    }

    private func title(_ text: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(text).font(Typography.family)
            Text(detail).font(.subheadline.monospacedDigit()).foregroundStyle(Palette.secondary)
        }.accessibilityAddTraits(.isHeader)
    }

    /// The label is a localized key: a plain String would print the English through untranslated.
    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(value).font(Typography.counter)
                .contentTransition(.numericText(value: Double(value) ?? 0))
            Text(label).font(.caption).foregroundStyle(Palette.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

}

/// One day: a filled tile whose strength is how much was practiced that day (GitHub's contribution ramp
/// adapted to one accent) with the date on top. A day with reviews waiting is outlined instead of filled,
/// and today gets a stronger outline, so fill always means "practiced" and never competes with a count.
private struct CalendarDay: View {
    let day: Date
    let today: Date
    let practiced: Int
    let due: Int
    @Environment(\.appAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiateWithoutColor
    private var calendar: Calendar { .autoupdatingCurrent }
    private var isToday: Bool { calendar.isDate(day, inSameDayAs: today) }
    private var isFuture: Bool { calendar.startOfDay(for: day) > today }

    /// Five steps, as in a contribution graph: an empty past day still shows a tile so the month keeps its shape.
    private var fillAlpha: Double {
        switch practiced {
        case 0: return 0
        case 1...2: return 0.18
        case 3...5: return 0.36
        case 6...9: return 0.60
        default: return 0.85
        }
    }
    private var level: Int {
        switch practiced {
        case 0: return 0
        case 1...2: return 1
        case 3...5: return 2
        case 6...9: return 3
        default: return 4
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Radius.small - 3)
        NavigationLink { PracticeDayView(day: day) } label: {
            shape
                .fill(practiced > 0 ? accent.fill.opacity(fillAlpha) : (isFuture ? .clear : Palette.ink.opacity(0.05)))
                .overlay {
                    if isToday { shape.strokeBorder(accent.color, lineWidth: 1.5) }
                    else if due > 0 { shape.strokeBorder(accent.color.opacity(0.35), lineWidth: 1) }
                    else if practiced > 0 && differentiateWithoutColor { shape.strokeBorder(Palette.ink.opacity(0.3), lineWidth: 1) }
                }
                .frame(width: 36, height: 36)
                .overlay {
                    Text(verbatim: "\(calendar.component(.day, from: day))")
                        .font(.system(size: 15).monospacedDigit())
                        .foregroundStyle(numberColor)
                }
                .frame(maxWidth: .infinity, minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(PressStyle()).disabled(practiced == 0 && due == 0)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
            .accessibilityValue(practiced > 0 ? Text("Practice level \(level) of 4") : Text(""))
            .accessibilityAddTraits(isToday ? [.isButton, .isSelected] : .isButton)
            .accessibilityHint(practiced > 0 || due > 0 ? Text("Opens what you practiced") : Text(""))
            .accessibilityIdentifier("calendarDay-\(day.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits)))")
    }

    /// The date and its state in one sentence, so VoiceOver does not have to piece together a grid.
    private var label: Text {
        let date = day.formatted(.dateTime.weekday(.wide).month(.wide).day())
        if due > 0 { return Text("\(date). \(due) reviews due") }
        if practiced > 0 { return Text("\(date). \(practiced) expressions practiced") }
        return Text("\(date). Not practiced")
    }

    /// The number sits on the fill, so its color follows that fill's contrast rather than a fixed choice.
    private var numberColor: Color {
        if practiced > 0 { return accent.readableText(onFillAlpha: fillAlpha, scheme: scheme) }
        return isFuture ? Palette.ink.opacity(0.55) : Palette.ink
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
                Text(title).font(Typography.section).accessibilityAddTraits(.isHeader)
                Spacer()
                Text("\(phrases.count)").font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
            }
            LazyVStack(spacing: 0) {
                ForEach(phrases) { phrase in
                    NavigationLink { PhraseDetailView(phrase: phrase, siblings: phrases) } label: { PhraseRow(phrase: phrase) }
                        .buttonStyle(RowPressStyle()).accessibilityIdentifier("\(prefix)-\(phrase.id)")
                    Divider()
                }
            }
        }
    }
}
