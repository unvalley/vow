#if DEBUG
import SwiftUI

/// Prototype: today's learning as one pack to open and solve, an idea taken from Sudoku a Day and
/// drawn in Izzy's own terms: today's phrase cards lie on the Home landscape, the date is set in the
/// serif that names phrases, and a finished pack squares up with its receipt on top.
/// Debug builds only, in its own tab beside Home.
struct TodayPackView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.scenePhase) private var scenePhase
    @Namespace private var packZoom
    @Namespace private var dayPill
    @State private var opened = false
    /// The day whose phrases are open in the look-back sheet.
    @State private var lookingBack: Pack?
    /// A finished day's phrases, opened in speaking practice.
    @State private var speaking: PracticeSelection?
    @State private var now = Date.now
    /// Days from today: the four days before, today's, and tomorrow's still sealed.
    @State private var selectedDay = 0
    private let days = -4...1
    private let calendar = Calendar.autoupdatingCurrent

    private func date(_ offset: Int) -> Date {
        calendar.date(byAdding: .day, value: offset, to: calendar.startOfDay(for: now)).map(calendar.startOfDay) ?? now
    }

    /// Everything one day's pack shows.
    private struct Pack: Identifiable {
        /// Days from today.
        let offset: Int
        let day: Date
        let state: PackState
        /// Front first: today's next phrases, or what a past day practiced.
        var phrases: [Phrase] = []
        /// Today's cards and how many of them are answered; zero for any other day.
        var total = 0
        var answered = 0
        var id: Int { offset }
        var isToday: Bool { offset == 0 }
        /// Today's share answered, 0 to 1.
        var progress: Double { total == 0 ? 0 : Double(answered) / Double(total) }
    }

    /// The pack of every day in the row, in order.
    private func dayPacks(_ d: HomeDerivation) -> [Pack] {
        let byID = Dictionary(store.phrases.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        return days.map { offset -> Pack in
            let day = date(offset)
            if offset == 0 {
                if d.learning.isEmpty { return Pack(offset: offset, day: day, state: .missed) }
                let answered = d.learning.filter { p in !d.remaining.contains { $0.id == p.id } }
                return Pack(offset: offset, day: day, state: d.remaining.isEmpty ? .sealed : .open, phrases: d.remaining + answered,
                            total: d.learning.count, answered: answered.count)
            }
            if offset > 0 { return Pack(offset: offset, day: day, state: .upcoming) }
            let practiced = LearningCalendar.phraseIDs(on: day, events: store.data.events, calendar: calendar).compactMap { byID[$0] }
            return Pack(offset: offset, day: day, state: practiced.isEmpty ? .missed : .sealed, phrases: practiced)
        }
    }

    var body: some View {
        let d = HomeDerivation(store: store, purchased: purchases.hasFullAccess, now: now)
        let packs = dayPacks(d)
        let selected = packs[selectedDay - days.lowerBound]
        VStack(spacing: 0) {
            VStack(spacing: Spacing.xxs) {
                Text(selected.day.formatted(.dateTime.weekday(.wide))).font(Typography.section).foregroundStyle(Palette.secondary)
                Text(selected.day.formatted(.dateTime.month(.wide).day())).font(Typography.phrase).foregroundStyle(Palette.ink)
                    .contentTransition(.numericText(value: Double(selectedDay)))
            }.padding(.top, Spacing.lg)
                .animation(Motion.snappy, value: selectedDay)
            dayStrip(packs).padding(.top, Spacing.md)
            // Swipe between days as well as tapping them.
            // The status line belongs to its day, so it travels with the swipe.
            TabView(selection: $selectedDay) {
                ForEach(packs) { pack in
                    VStack(spacing: Spacing.lg) {
                        deck(pack, d)
                        status(pack, d)
                    }.tag(pack.offset)
                }
            }.tabViewStyle(.page(indexDisplayMode: .never))
                .frame(maxHeight: .infinity)
            action(selected).frame(minHeight: 56)
                .fullScreenCover(item: $speaking) { SpeakingSessionView(phrases: $0.phrases) }
        }.padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.lg)
            .frame(maxWidth: 520).frame(maxWidth: .infinity)
            .background { TodayLandscapeBackground(background: store.data.background(fullAccess: purchases.hasFullAccess)) }
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $opened, onDismiss: { now = .now }) {
                PackSolveView().zoomDestination(id: "todayPack", in: packZoom)
            }
            .sheet(item: $lookingBack) { pack in
                NavigationStack {
                    PracticeDayView(day: pack.day)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { lookingBack = nil } } }
                }.presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sensoryFeedback(.impact(weight: .medium), trigger: opened) { _, new in new }
            .sensoryFeedback(.selection, trigger: selectedDay)
            .onAppear { now = .now }
            .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
    }

    @ViewBuilder private func deck(_ pack: Pack, _ d: HomeDerivation) -> some View {
        let deck = PackDeck(phrases: pack.phrases, state: pack.state) { front(pack, d) }
        if pack.isToday {
            Button { open(pack) } label: { deck }
                .buttonStyle(PressStyle()).disabled(pack.state == .missed)
                .zoomSource(id: "todayPack", in: packZoom)
                .accessibilityLabel(actionTitle(pack))
        } else {
            deck.contentShape(Rectangle())
                .onTapGesture { open(pack) }
        }
    }

    @ViewBuilder private func front(_ pack: Pack, _ d: HomeDerivation) -> some View {
        switch pack.state {
        case .open:
            if let phrase = pack.phrases.first {
                PackTicket(label: d.isReview(phrase.id) ? "Review" : "New", counter: "\(pack.answered + 1)/\(pack.total)",
                           phrase: phrase)
            }
        case .sealed:
            PackReceipt(day: pack.day, phrases: pack.phrases, next: pack.isToday ? store.nextDue(among: d.visible, after: now) : nil)
        case .missed:
            Text(pack.isToday ? "Nothing due today" : "No practice on this day")
                .font(Typography.phraseRow).foregroundStyle(Palette.secondary)
        case .upcoming:
            VStack(spacing: Spacing.xs) {
                Text("Tomorrow's pack").font(Typography.phraseRow).foregroundStyle(Palette.ink)
                Text("Opens at midnight").font(.caption).foregroundStyle(Palette.secondary)
            }
        }
    }

    /// The days as a row, each marked like a status badge: filled with a check once sealed, a pie that
    /// fills as today's pack is answered, a dotted ring for tomorrow, a faint ring for an empty day.
    private func dayStrip(_ packs: [Pack]) -> some View {
        HStack(spacing: Spacing.xxs) {
            ForEach(packs) { pack in
                let isSelected = pack.offset == selectedDay
                Button { withAnimation(Motion.snappy) { selectedDay = pack.offset } } label: {
                    VStack(spacing: 3) {
                        Text(pack.day.formatted(.dateTime.weekday(.narrow))).font(.caption2.weight(.medium))
                            .foregroundStyle(Palette.secondary)
                        Text(pack.day.formatted(.dateTime.day())).font(.subheadline.weight(pack.isToday ? .bold : .medium)).monospacedDigit()
                            .foregroundStyle(pack.state == .upcoming ? Palette.secondary : Palette.ink)
                        DayMark(state: pack.state, progress: pack.progress)
                    }.frame(maxWidth: .infinity, minHeight: 64)
                        .background {
                            if isSelected {
                                RoundedRectangle(cornerRadius: Radius.small).fill(Palette.paper)
                                    .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
                                    .overlay { RoundedRectangle(cornerRadius: Radius.small).strokeBorder(Palette.outline) }
                                    .matchedGeometryEffect(id: "selectedDay", in: dayPill)
                            }
                        }
                }.buttonStyle(PressStyle())
                    .accessibilityLabel(pack.day.formatted(.dateTime.weekday(.wide).month(.wide).day()))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }

    @ViewBuilder private func action(_ pack: Pack) -> some View {
        switch pack.state {
        case .open:
            PrimaryButton(title: actionTitle(pack)) { open(pack) }
        case .sealed:
            // Look back at the day, or use its phrases again out loud: speaking keeps its own schedule,
            // so this never disturbs the meaning reviews.
            HStack(spacing: Spacing.xs) {
                SecondaryButton(title: actionTitle(pack), symbol: "book.pages") { open(pack) }
                SecondaryButton(title: String(localized: "Speak them"), symbol: "waveform") {
                    speaking = PracticeSelection(phrases: pack.phrases)
                }
            }
        case .upcoming:
            SecondaryButton(title: actionTitle(pack), symbol: "calendar") { open(pack) }
        case .missed:
            if !pack.isToday {
                Button("Back to today") { open(pack) }
                    .font(Typography.control).frame(minHeight: 44).buttonStyle(PressStyle())
            }
        }
    }

    private func open(_ pack: Pack) {
        switch pack.state {
        case .open: opened = true
        case .sealed, .upcoming: lookingBack = pack
        case .missed:
            if !pack.isToday { withAnimation(Motion.snappy) { selectedDay = 0 } }
        }
    }

    private func actionTitle(_ pack: Pack) -> String {
        switch pack.state {
        case .open: pack.answered == 0 ? String(localized: "Open today's pack") : String(localized: "Continue")
        case .sealed: String(localized: "Look back")
        case .upcoming: String(localized: "See what's due")
        case .missed: ""
        }
    }

    /// "Yesterday", "4 days ago": only the first letter is raised.
    private func dayName(_ day: Date) -> String {
        let relative = day.formatted(.relative(presentation: .named))
        return relative.prefix(1).localizedUppercase + relative.dropFirst()
    }

    /// What is inside, or how far along the pack is.
    private func status(_ pack: Pack, _ d: HomeDerivation) -> some View {
        Group {
            switch pack.state {
            case .open where pack.answered == 0:
                let new = d.learnedToday.count + d.upcomingNew.count
                let reviews = pack.total - new
                if reviews == 0 { Text("\(new) new") }
                else if new == 0 { Text("\(reviews) reviews") }
                else { Text("\(new) new · \(reviews) reviews") }
            case .open:
                Text("\(pack.answered) of \(pack.total) done")
            case .sealed:
                if pack.isToday { Text("Today's pack is done") } else { Text(verbatim: dayName(pack.day)) }
            case .upcoming:
                Text("Opens in \(Text(pack.day, style: .relative))")
            case .missed:
                Text(verbatim: pack.isToday ? " " : dayName(pack.day))
            }
        }.font(.subheadline.monospacedDigit()).foregroundStyle(Palette.secondary)
    }
}

private extension LearningStore {
    /// The soonest review still ahead among these phrases.
    func nextDue(among phrases: [Phrase], after now: Date) -> Date? {
        phrases.compactMap { data.memoryReviews?[$0.id]?.due }.filter { $0 > now }.min()
    }
}

private extension View {
    /// The small capitals along the top of a ticket or receipt.
    func ticketLabel() -> some View {
        font(.caption2.weight(.semibold)).textCase(.uppercase).tracking(1.2)
    }
}

private enum PackState: Equatable { case open, sealed, missed, upcoming }

/// A day's cards on the landscape. Open, they lie loose at their own angles with the next one in front;
/// finished, they square up into one neat stack with the day's receipt on top. A day without practice
/// is a faded, empty stack; tomorrow's is squared and waiting.
private struct PackDeck<Front: View>: View {
    let phrases: [Phrase]
    let state: PackState
    @ViewBuilder var front: Front
    @Environment(\.phraseTypeface) private var typeface
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    private let loose: [(angle: Double, offset: CGSize)] = [(-2, .init(width: 0, height: 44)), (-4, .init(width: -10, height: 0)), (5, .init(width: 12, height: -46))]
    private let squared: [(angle: Double, offset: CGSize)] = [(0, .init(width: 0, height: 12)), (1.5, .init(width: 2, height: 2)), (-1.5, .init(width: -2, height: -8))]

    private var height: CGFloat { state == .sealed ? PackReceipt.height(phrases.count) : 180 }

    var body: some View {
        ZStack {
            ForEach(Array((0..<3).reversed()), id: \.self) { index in
                let place = state == .open ? loose[index] : squared[index]
                PackCard(front: index == 0, height: height) {
                    if index == 0 { front }
                    else if state == .open, phrases.indices.contains(index) {
                        // Only a back card's first line shows above the card in front.
                        Text(phrases[index].phrase).font(typeface.font(size: 20)).foregroundStyle(Palette.ink.opacity(0.75))
                            .lineLimit(1).minimumScaleFactor(0.6).padding(.top, -Spacing.xs)
                    }
                }
                    .rotationEffect(.degrees(place.angle))
                    .offset(place.offset)
            }
        }.opacity(state == .missed ? 0.7 : 1)
            .frame(height: 300)
            .animation(reduceMotion ? nil : .spring(duration: 0.55, bounce: 0.3), value: state)
    }
}

/// A day's mark in the row of days.
private struct DayMark: View {
    let state: PackState
    /// Today's share answered, 0 to 1.
    let progress: Double
    @Environment(\.appAccent) private var accent
    var body: some View {
        ZStack {
            switch state {
            case .sealed:
                Circle().fill(Palette.ink)
                Image(systemName: "checkmark").font(.system(size: 7, weight: .black)).foregroundStyle(Palette.paper)
            case .open:
                Circle().strokeBorder(Palette.ink, lineWidth: 1.5)
                // A pie from twelve o'clock, clockwise: a ring stroked as wide as its radius.
                Circle().inset(by: 2).trim(from: 0, to: progress).stroke(accent.mark, lineWidth: 4)
                    .rotationEffect(.degrees(-90)).padding(3)
                    .animation(Motion.snappy, value: progress)
            case .missed:
                Circle().strokeBorder(Palette.secondary.opacity(0.35), lineWidth: 1.5)
            case .upcoming:
                Circle().strokeBorder(Palette.secondary, style: StrokeStyle(lineWidth: 1.5, dash: [2, 2.2]))
            }
        }.frame(width: 14, height: 14).accessibilityHidden(true)
    }
}

/// A front card printed like a receipt: a title, the phrases with the answer given, and a footer.
/// It prints in from the top when it appears.
private struct PackReceipt: View {
    let day: Date
    let phrases: [Phrase]
    /// When the next review falls due, where the receipt says so.
    var next: Date?
    @Environment(LearningStore.self) private var store
    @Environment(\.phraseTypeface) private var typeface
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @State private var printed = false
    private static let shown = 3
    /// A receipt card is as long as what it lists, up to three lines.
    static func height(_ count: Int) -> CGFloat { 150 + CGFloat(max(min(count, shown) - 1, 0)) * 26 + (count > shown ? 18 : 0) }
    private var footer: String {
        next.map { String(localized: "\(phrases.count) phrases · next \($0.formatted(.dateTime.month(.abbreviated).day()))") }
            ?? String(localized: "\(phrases.count) phrases")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(verbatim: day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                .ticketLabel().foregroundStyle(Palette.secondary)
            DashedRule()
            ForEach(phrases.prefix(Self.shown)) { phrase in
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    Text(phrase.phrase).font(typeface.font(size: 18)).foregroundStyle(Palette.ink)
                        .lineLimit(1).minimumScaleFactor(0.7)
                    Spacer(minLength: Spacing.xs)
                    if let answer = store.memoryRating(for: phrase.id, on: day) {
                        Image(systemName: answer.symbol).font(.caption2.weight(.semibold)).foregroundStyle(Palette.secondary)
                    }
                }
            }
            if phrases.count > Self.shown {
                Text("+\(phrases.count - Self.shown) more").font(.caption2).foregroundStyle(Palette.secondary)
            }
            Spacer(minLength: 0)
            DashedRule()
            Text(verbatim: footer).font(.caption2.monospacedDigit()).foregroundStyle(Palette.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            // Printed: revealed from the top edge down, the way a receipt feeds out.
            .mask(alignment: .top) {
                Rectangle().scaleEffect(x: 1, y: printed || reduceMotion ? 1 : 0.02, anchor: .top)
            }
            .onAppear { withAnimation(.easeOut(duration: 0.8).delay(0.15)) { printed = true } }
    }
}

private struct DashedRule: View {
    var body: some View {
        Line().stroke(Palette.secondary.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            .frame(height: 1)
    }
    private struct Line: Shape {
        func path(in rect: CGRect) -> Path {
            Path { $0.move(to: CGPoint(x: rect.minX, y: rect.midY)); $0.addLine(to: CGPoint(x: rect.maxX, y: rect.midY)) }
        }
    }
}

/// An open card's face: its kind and place in the pack along the top, like a ticket, and the next
/// phrase centred as Home shows it, set a size down.
private struct PackTicket: View {
    let label: LocalizedStringKey
    let counter: String
    let phrase: Phrase
    @Environment(\.phraseTypeface) private var typeface
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(label).ticketLabel()
                Spacer()
                Text(verbatim: counter).font(.caption2.monospacedDigit())
            }.foregroundStyle(Palette.secondary)
            Spacer(minLength: 0)
            VStack(spacing: Spacing.xxs) {
                Text(phrase.phrase).font(typeface.font(size: 34)).tracking(34 * typeface.displayTracking)
                    .foregroundStyle(Palette.ink).lineLimit(1).minimumScaleFactor(0.6)
                PhrasePronunciation(phrase: phrase)
            }
            Spacer(minLength: 0)
            // Balances the header so the phrase sits at the card's optical centre.
            Color.clear.frame(height: 12)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// A paper card on the landscape, the size of one phrase.
private struct PackCard<Content: View>: View {
    let front: Bool
    let height: CGFloat
    @ViewBuilder var content: Content
    var body: some View {
        // The clear base keeps a card with nothing written on it (a finished day's back cards) drawn.
        ZStack(alignment: front ? .center : .topLeading) {
            Color.clear
            content.padding(20)
        }
            .frame(width: 290, height: height)
            .background {
                RoundedRectangle(cornerRadius: Radius.large).fill(Palette.paper)
                    .shadow(color: .black.opacity(front ? 0.10 : 0.06), radius: front ? 18 : 8, y: front ? 8 : 3)
            }
            .overlay { RoundedRectangle(cornerRadius: Radius.large).strokeBorder(Palette.outline) }
    }
}

/// The opened pack: one card at a time, rated to move on, then the pack closes.
private struct PackSolveView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.phraseTypeface) private var typeface
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = 48.0
    @State private var voice = VoicePractice()
    @State private var now = Date.now
    /// The card on show; kept through the pause after an answer so the chosen rating can be seen.
    @State private var currentID: String?
    @State private var pending: MemoryRating?
    @State private var showsAnswer = false
    @State private var completions = 0
    @State private var printed = false

    private func derive() -> HomeDerivation {
        HomeDerivation(store: store, purchased: purchases.hasFullAccess, now: now)
    }

    var body: some View {
        let d = derive()
        let phrase = d.learning.first { $0.id == currentID }
        VStack(spacing: 0) {
            topBar(d)
            if let phrase {
                // The card on show sits on the rest of the pack; an answered card is tossed aside and the
                // next one comes up from the pile.
                let pile = min(2, d.remaining.filter { $0.id != phrase.id }.count), isReview = d.isReview(phrase.id)
                ZStack {
                    ForEach(Array((0..<pile).reversed()), id: \.self) { depth in
                        Self.paper
                            .frame(height: Self.cardHeight)
                            .scaleEffect(1 - CGFloat(depth + 1) * 0.04)
                            .offset(y: CGFloat(depth + 1) * 12)
                    }
                    card(phrase, isReview: isReview)
                        .id(phrase.id)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .scale(scale: 0.94).combined(with: .opacity),
                            removal: .modifier(active: Tossed(progress: 1), identity: Tossed(progress: 0))))
                }.animation(reduceMotion ? nil : Motion.snappy, value: pile)
                    .padding(.horizontal, Spacing.lg)
                    .frame(maxHeight: .infinity)
                MemoryRatingControls(state: store.data.memoryReviews?[phrase.id], now: now, compact: true,
                                     title: isReview ? "Review: did you remember the meaning?" : "New: did you know the meaning?",
                                     selected: pending) { rate(phrase, $0) }
                    .disabled(pending != nil)
                    .padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.lg)
            } else {
                finished(d).frame(maxHeight: .infinity)
            }
        }.frame(maxWidth: 680).frame(maxWidth: .infinity)
            .background { TodayLandscapeBackground(background: store.data.background(fullAccess: purchases.hasFullAccess)) }
            .sheet(isPresented: $showsAnswer) {
                if let phrase {
                    PhraseAnswerSheet(phrase: phrase, voice: voice)
                        .presentationDetents([.fraction(0.75), .large]).presentationDragIndicator(.visible)
                }
            }
            .sensoryFeedback(.success, trigger: completions)
            .onAppear { currentID = d.remaining.first?.id }
            .onDisappear { voice.clear() }
    }

    private func topBar(_ d: HomeDerivation) -> some View {
        let answered = d.learning.count - d.remaining.count
        return HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.down").font(.body.weight(.semibold))
                    .frame(width: 44, height: 44).background(Palette.surface, in: Circle())
            }.buttonStyle(PressStyle()).accessibilityLabel("Close")
            Spacer()
            VStack(spacing: 2) {
                Text(now.formatted(.dateTime.month(.wide).day())).font(.subheadline.weight(.semibold))
                Text("\(min(answered + (currentID == nil ? 0 : 1), d.learning.count)) / \(d.learning.count)")
                    .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
            Color.clear.frame(width: 44, height: 44)
        }.foregroundStyle(Palette.ink).padding(.horizontal, Spacing.md).padding(.top, Spacing.xs)
    }

    private func card(_ phrase: Phrase, isReview: Bool) -> some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xxs) {
                Text(phrase.phrase).font(typeface.font(size: wordSize))
                    .tracking(wordSize * typeface.displayTracking).foregroundStyle(Palette.ink)
                    .lineLimit(1).minimumScaleFactor(0.55)
                PhrasePronunciation(phrase: phrase)
            }
            PhraseDifficultyButton(phrase: phrase)
            HStack(spacing: Spacing.lg) {
                Button { voice.speak(phrase.phrase, voiceIdentifier: store.data.speechVoiceID) } label: {
                    Image(systemName: "speaker.wave.2").frame(width: 48, height: 48)
                }.foregroundStyle(voice.isSpeaking ? accent.mark : Palette.ink).accessibilityLabel("Hear phrase")
                Button { voice.stopPlayback(); showsAnswer = true } label: {
                    Image(systemName: "info.circle").frame(width: 48, height: 48)
                }.foregroundStyle(Palette.ink).accessibilityLabel("Meaning & examples")
                SavePhraseButton(phraseID: phrase.id, featured: true)
            }.font(.title3).buttonStyle(PressStyle())
        }.multilineTextAlignment(.center).padding(.horizontal, Spacing.lg)
            .frame(maxWidth: .infinity).frame(height: Self.cardHeight)
            // The same ticket label as the pack's cover.
            .overlay(alignment: .topLeading) {
                Text(isReview ? "Review" : "New").ticketLabel().foregroundStyle(Palette.secondary).padding(20)
            }
            .background { Self.paper }
    }

    private static let cardHeight: CGFloat = 340
    /// The same paper card as the pack's cover, full width.
    static var paper: some View {
        RoundedRectangle(cornerRadius: Radius.large).fill(Palette.paper)
            .overlay { RoundedRectangle(cornerRadius: Radius.large).strokeBorder(Palette.outline) }
            .shadow(color: .black.opacity(0.08), radius: 14, y: 6)
    }

    /// The day's receipt prints out.
    private func finished(_ d: HomeDerivation) -> some View {
        VStack(spacing: Spacing.xl) {
            Text("All done!").font(Typography.phrase).foregroundStyle(Palette.ink).staggeredEntrance(0)
            PackCard(front: true, height: PackReceipt.height(d.learning.count)) {
                PackReceipt(day: now, phrases: d.learning, next: store.nextDue(among: d.visible, after: now))
            }
            Button { dismiss() } label: { SecondaryButtonLabel(title: String(localized: "Close")) }
                .buttonStyle(PressStyle()).frame(maxWidth: 290).staggeredEntrance(3)
        }.padding(Spacing.xl)
            .task {
                // A firm tap as the receipt finishes printing.
                try? await Task.sleep(for: .milliseconds(reduceMotion ? 0 : 950))
                printed = true
            }
            .sensoryFeedback(.impact(flexibility: .rigid, intensity: 0.8), trigger: printed)
    }

    private func rate(_ phrase: Phrase, _ rating: MemoryRating) {
        guard pending == nil else { return }
        voice.stopPlayback()
        pending = rating
        store.rateMemory(phrase, rating, now: now)
        Task { @MainActor in
            try? await Task.sleep(for: reduceMotion ? .zero : .milliseconds(200))
            now = .now
            let next = derive().remaining.first?.id
            withAnimation(reduceMotion ? Motion.reducedFade : Motion.snappy) {
                pending = nil
                currentID = next
            }
            if next == nil { completions += 1 }
        }
    }
}

/// An answered card leaves to the side at an angle, as if dropped on the done pile.
private struct Tossed: ViewModifier {
    let progress: Double
    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(-14 * progress)).offset(x: -460 * progress, y: 70 * progress)
    }
}
#endif
