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
                ForgettingCurveView()
                activity(snapshot)
                collection(snapshot)
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

    private func activity(_ stats: LearningStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            title("Your last 7 days", detail: "\(stats.activeDays) active \(stats.activeDays == 1 ? "day" : "days")")
            Chart(stats.activity) { day in
                BarMark(x: .value("Day", day.date, unit: .day), y: .value("Practice actions", day.total))
                    .foregroundStyle(accent.color).cornerRadius(4)
                    .accessibilityLabel(Text(day.date.formatted(.dateTime.month(.abbreviated).day())))
                    .accessibilityValue(Text("\(day.memoryAnswers) memory answers, \(day.speakingReplies) speaking replies, \(day.stories) stories"))
            }
            .chartYScale(domain: 0...max(1, stats.activity.map(\.total).max() ?? 0))
            .chartXAxis {
                AxisMarks(values: visibleDates(stats.activity.map(\.date))) { value in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: false, anchor: axisAnchor(value))
                }
            }
            .chartYAxis { AxisMarks(position: .leading, values: ticks(stats.activity.map(\.total).max() ?? 0)) }
            .frame(height: 140).accessibilityIdentifier("statsActivityChart")
            LazyVGrid(columns: columns, alignment: .leading, spacing: Spacing.md) {
                metric("\(stats.memoryAnswers)", "Memory answers")
                metric("\(stats.speakingReplies)", "Speaking replies")
                metric("\(stats.stories)", "Completed stories")
            }
            Text(stats.activeDays == 0 ? "Your first completed answer will start this chart. Browsing and saving don't count as practice." : "Each rated answer or completed story counts once. Repeat answers count again; simply revealing an example doesn't.")
                .font(.caption).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }

    private func collection(_ stats: LearningStats) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            title("Your expressions", detail: "\(stats.started) of \(stats.totalPhrases) started")
            SwiftUI.ProgressView(value: Double(stats.started), total: Double(max(1, stats.totalPhrases)))
                .tint(accent.color).accessibilityLabel("Expressions started")
                .accessibilityValue("\(stats.started) of \(stats.totalPhrases)")
                .accessibilityIdentifier("statsCollectionProgress")
            countRow("Not started", stats.unseen)
            countRow("Building a memory", stats.learning)
            countRow("At longer intervals", stats.longerIntervals)
            Divider()
            countRow("Phrasal verbs started", stats.started - stats.idiomsStarted)
            countRow("Idioms started", stats.idiomsStarted)
            Text("Based on meaning reviews in your available collection. Longer intervals are 21 days or more, not a guarantee of permanent recall.")
                .font(.caption).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
        }.accessibilityIdentifier("statsCollection")
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
            Text("Current meaning-review dates, including reviews later today. Dates change with your answers; new expressions and future repeat reviews aren't forecast here.")
                .font(.caption).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
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

    private func countRow(_ label: String, _ value: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Spacing.md) {
            Text(label).fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: Spacing.xs)
            Text("\(value)").monospacedDigit().fixedSize()
        }.font(.subheadline).accessibilityElement(children: .combine)
    }
}

private struct ForgettingCurveView: View {
    @Environment(\.appAccent) private var accent
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showReviews = true
    private let baseline = ForgettingIllustration.points(withReviews: false)
    private let reviewed = ForgettingIllustration.points(withReviews: true)

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Forgetting curve").font(Typography.family)
                Text("An illustration, not your measured recall")
                    .font(.caption).foregroundStyle(Palette.secondary)
                    .accessibilityIdentifier("forgettingIllustrationNote")
            }.accessibilityAddTraits(.isHeader)
            Text("Recall can fade between reviews. Returning to an expression can help you remember it for longer.")
                .font(.subheadline).fixedSize(horizontal: false, vertical: true)
            Toggle("Compare spaced reviews", isOn: $showReviews)
                .font(.subheadline).tint(accent.color).accessibilityIdentifier("compareSpacedReviews")
            Text("Easier to recall ↑").font(.caption).foregroundStyle(Palette.secondary)
            Chart {
                ForEach(baseline) { point in
                    LineMark(x: .value("Days", point.day), y: .value("Recall ease", point.recall), series: .value("Path", "Without review"))
                        .foregroundStyle(Palette.secondary).lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 4]))
                }
                if showReviews {
                    ForEach(reviewed) { point in
                        LineMark(x: .value("Days", point.day), y: .value("Recall ease", point.recall), series: .value("Path", "Review segment \(point.segment)"))
                            .foregroundStyle(accent.color).lineStyle(StrokeStyle(lineWidth: 3))
                    }
                    ForEach(ForgettingIllustration.reviewDays, id: \.self) { day in
                        RuleMark(x: .value("Review day", day))
                            .foregroundStyle(accent.color.opacity(0.25)).lineStyle(StrokeStyle(lineWidth: 1, dash: [2, 3]))
                        PointMark(x: .value("Review day", day), y: .value("Recall ease", 1.0))
                            .foregroundStyle(accent.color).symbolSize(35)
                    }
                }
            }
            .chartXScale(domain: 0...ForgettingIllustration.horizon)
            .chartYScale(domain: 0...1.05)
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: typeSize.isAccessibilitySize ? [0.0, 14.0, 30.0] : [0.0, 7.0, 14.0, 21.0, 30.0]) { value in
                    AxisGridLine()
                    AxisValueLabel(anchor: value.index == 0 ? .topLeading : (value.index == value.count - 1 ? .topTrailing : .top)) {
                        if let day = value.as(Double.self) { Text("\(Int(day))d").fixedSize() }
                    }
                }
            }
            .frame(height: 190)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Forgetting curve illustration")
            .accessibilityValue(showReviews ? "Without review, recall fades. Example reviews on days 1, 7 and 22 raise recall and make the decline gentler. This is not a personal prediction." : "Without review, the illustrative curve declines over 30 days. This is not a personal prediction.")
            .accessibilityIdentifier("forgettingCurve")
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Label("Dashed · Without review", systemImage: "minus")
                    .foregroundStyle(Palette.secondary)
                if showReviews {
                    Label("Solid · With spaced reviews", systemImage: "circle.fill").foregroundStyle(accent.color)
                    Text("Dots mark example reviews on days 1, 7 and 22.").foregroundStyle(Palette.secondary)
                }
            }.font(.caption).fixedSize(horizontal: false, vertical: true)
            Text("Days since first study →").font(.caption).foregroundStyle(Palette.secondary)
            Link("About spacing & recall", destination: URL(string: "https://doi.org/10.1038/s44159-022-00089-1")!)
                .font(.caption).frame(minHeight: 44)
        }.padding(Spacing.md).background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
