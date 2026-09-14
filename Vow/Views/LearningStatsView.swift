import SwiftUI
import Charts

struct ProgressViewScreen: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.appAccent) private var accent
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var now = Date.now
    @State private var review = false
    @State private var goal = false

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
                upcoming(snapshot)
            }.foregroundStyle(Palette.ink)
        }
        .navigationTitle("Stats").navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $review) { MemoryReviewView() }
        .sheet(isPresented: $goal) { NavigationStack { DailyGoalView() } }
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
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: typeSize.isAccessibilitySize ? 3 : 7), spacing: Spacing.md) {
                ForEach(stats.activity) { day in
                    VStack(spacing: Spacing.xs) {
                        Image(systemName: day.total > 0 ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                            .foregroundStyle(day.total > 0 ? accent.color : Palette.secondary)
                        Text(day.date.formatted(.dateTime.weekday(.narrow)))
                            .font(.caption2).foregroundStyle(Palette.secondary)
                    }.frame(maxWidth: .infinity)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(day.date.formatted(.dateTime.weekday(.wide))), \(day.total > 0 ? "practiced" : "no practice")")
                }
            }.padding(.vertical, Spacing.sm)
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
                } else {
                    Button(stats.daily.dueReviews > 0 ? "Review now" : "Continue today's learning", systemImage: "arrow.right") { review = true }
                        .font(Typography.control).frame(minHeight: 44).accessibilityIdentifier("statsReviewNow")
                }
            }.padding(Spacing.lg).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func upcoming(_ stats: LearningStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            title("Next 7 days", detail: "Your review schedule")
            Chart(stats.upcoming) { day in
                BarMark(x: .value("Date", day.date, unit: .day), y: .value("Expressions due", day.count))
                    .foregroundStyle(calendar.isDate(day.date, inSameDayAs: now) ? accent.color : Palette.secondary)
                    .cornerRadius(4)
                    .accessibilityLabel(Text(day.date.formatted(.dateTime.month(.abbreviated).day())))
                    .accessibilityValue(Text("\(day.count) expressions due"))
            }
            .chartYScale(domain: 0...max(1, stats.upcoming.map(\.count).max() ?? 0))
            .chartXAxis {
                AxisMarks(values: visibleDates(stats.upcoming.map(\.date))) { value in
                    AxisValueLabel(centered: false, anchor: axisAnchor(value)) {
                        if let date = value.as(Date.self) { Text(date.formatted(.dateTime.day())).fixedSize() }
                    }
                }
            }
            .chartYAxis { AxisMarks(position: .leading, values: ticks(stats.upcoming.map(\.count).max() ?? 0)) }
            .frame(height: 140).accessibilityIdentifier("statsUpcomingChart")
            if stats.overdue > 0 {
                Text("Today's bar includes \(stats.overdue) overdue \(stats.overdue == 1 ? "expression" : "expressions").")
                    .font(.subheadline).accessibilityIdentifier("statsOverdue")
            }
            if let next = stats.nextReview {
                Text("Next scheduled: \(next.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.subheadline).accessibilityIdentifier("statsNextReview")
            } else if stats.started == 0 {
                Text("Study your first expression to start a review schedule.").font(.subheadline)
            } else if stats.daily.dueReviews > 0 {
                Text("Your scheduled expressions are ready to review now.").font(.subheadline)
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

    private func ticks(_ maximum: Int) -> [Int] {
        let maximum = max(1, maximum)
        let step = max(1, Int(ceil(Double(maximum) / 3)))
        return Array(stride(from: 0, through: maximum, by: step))
    }

    private func visibleDates(_ dates: [Date]) -> [Date] {
        typeSize.isAccessibilitySize ? dates.enumerated().compactMap { $0.offset.isMultiple(of: 3) ? $0.element : nil } : dates
    }

    private func axisAnchor(_ value: AxisValue) -> UnitPoint {
        value.index == 0 ? .topLeading : (value.index == value.count - 1 ? .topTrailing : .top)
    }
}
