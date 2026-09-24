import SwiftUI

struct PracticeSelection: Identifiable {
    let id = UUID()
    let phrases: [Phrase]
}

/// Which phrase's meaning and examples are open in the bottom sheet.
private struct AnswerRequest: Identifiable { let id: String }

struct TodayView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @Environment(ReviewReminderCenter.self) private var reminders
    @Environment(\.appAccent) private var accent
    @Namespace private var modePill
    @Namespace private var phraseZoom
    @State private var session: PracticeSelection?
    @State private var settings = false
    @State private var newPhrasesShown = false
    @State private var stats = false
    @State private var reviewingToday = false
    @State private var answerRequest: AnswerRequest?
    /// The completion card, drawn once when the day is complete and redrawn if its contents change.
    @State private var completionCard: Image?
    private enum Mode: String, CaseIterable {
        case learning = "Today's learning"
        case explore = "Explore"
    }
    @State private var mode: Mode = .learning
    @State private var learningID = ""
    @State private var exploreID = ""
    private var selectedID: String {
        get { mode == .learning ? learningID : exploreID }
        nonmutating set {
            if mode == .learning { learningID = newValue } else { exploreID = newValue }
        }
    }
    private var selection: Binding<String> { Binding(get: { selectedID }, set: { selectedID = $0 }) }
    @State private var previewedIDs: Set<String> = []
    /// The answer just tapped: already recorded, shown in color for a moment before the card moves on.
    @State private var pendingRating: (id: String, rating: MemoryRating, mode: Mode)?
    @State private var voice = VoicePractice()
    @State private var now = Date.now
    private let lockID = HomeDerivation.lockID
    private let completeID = HomeDerivation.completeID
    /// One pass over the catalog per render; handlers call this again when they run.
    private func derive() -> HomeDerivation {
        HomeDerivation(phrases: store.phrases, purchased: purchases.hasFullAccess, kind: store.data.homeKindFilter,
                       memory: store.data.memoryReviews ?? [:], reviews: store.data.reviews, focus: store.data.focus,
                       dailyNew: store.data.newPhrasesPerDay, now: now, mode: mode == .learning ? .learning : .explore,
                       selectedID: selectedID)
    }

    var body: some View {
        let d = derive()
        Group {
            if typeSize.isAccessibilitySize {
                ScrollViewReader { proxy in
                    ScrollView { pageContent(d).id("homeTop") }
                        .onChange(of: selectedID) { _, _ in
                            withTransaction(Transaction(animation: nil)) { proxy.scrollTo("homeTop", anchor: .top) }
                        }
                }
            } else {
                pageContent(d)
            }
        }.frame(maxWidth: 680).frame(maxWidth: .infinity)
            .background { TodayLandscapeBackground(background: store.data.background(fullAccess: purchases.hasFullAccess)) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings) { SettingsView() }
            .sheet(isPresented: $stats) {
                NavigationStack {
                    ProgressViewScreen()
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { stats = false }.accessibilityIdentifier("closeStats") } }
                }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $reviewingToday) {
                NavigationStack {
                    PracticeDayView(day: now)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { reviewingToday = false } } }
                }.presentationDetents([.large]).presentationDragIndicator(.visible)
            }
            .sheet(item: $answerRequest) { request in
                if let phrase = d.browsing.first(where: { $0.id == request.id }) {
                    PhraseAnswerSheet(phrase: phrase, voice: voice)
                        .presentationDetents([.fraction(0.75), .large]).presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $newPhrasesShown) {
                // Opens on the tab the card on show belongs to.
                TodayPhrasesView(now: now, tab: d.learning.contains { $0.id == learningID } && d.isReview(learningID) ? .review : .new) { phrase in
                    newPhrasesShown = false
                    learningID = phrase.id
                }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $session) { SpeakingSessionView(phrases: $0.phrases, primedIDs: previewedIDs) }
            .onAppear {
                now = .now
                reconcileSelection()
                rememberPreview()
            }
            // `initial` covers a tap that arrived before Home was on screen.
            .onChange(of: reminders.reviewRequest, initial: true) { _, request in
                if request != nil { showRequestedLearning() }
            }
            .onChange(of: purchases.hasFullAccess) { _, _ in
                reconcileSelection()
                voice.stopPlayback()
            }
            .onChange(of: mode) { _, _ in
                reconcileSelection()
                voice.stopPlayback()
                rememberPreview()
            }
            .onChange(of: d.pageIDs) { _, _ in reconcileSelection() }
            .onChange(of: selectedID) { _, _ in
                voice.stopPlayback()
                rememberPreview()
            }
            .onChange(of: store.data.focus) { _, focus in
                exploreID = derive().visible.first { $0.scene == focus }?.id ?? exploreID
                reconcileSelection()
            }
            // The phrases to learn are chosen in Settings, which can be open over Home.
            .onChange(of: store.data.homeKindFilter) { _, _ in
                reconcileSelection()
            }
            .onChange(of: scenePhase) { _, value in
                if value == .active { now = .now } else { voice.stopPlayback() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in now = .now }
            .onChange(of: session == nil) { _, value in if value { now = .now } }
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in now = .now }
            .onDisappear { voice.clear() }
    }

    private func pageContent(_ d: HomeDerivation) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                let streak = store.streak(now: now)
                Button { stats = true } label: {
                    Label {
                        Text("\(streak.current) days").monospacedDigit()
                            .contentTransition(.numericText(value: Double(streak.current)))
                    } icon: { Image(systemName: "flame") }
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                        .animation(reduceMotion ? nil : Motion.snappy, value: streak.current)
                }.buttonStyle(PressStyle()).accessibilityLabel("\(streak.current)-day streak").accessibilityIdentifier("streakSummary")
                    .accessibilityHint("Opens your stats")
                Spacer()
                speakingButton(d)
            }.foregroundStyle(Palette.ink).padding(.leading, Spacing.xl).padding(.trailing, Spacing.md).padding(.top, Spacing.xs)

            modePicker

            if store.phrases.isEmpty {
                ContentUnavailableView("No phrases available", systemImage: "text.book.closed")
            } else if mode == .learning && d.learning.isEmpty {
                // Nothing was due or new today at all.
                completion(d)
            } else if typeSize.isAccessibilitySize {
                if let phrase = d.browsing.first(where: { $0.id == selectedID }) {
                    FeaturedPhraseView(phrase: phrase, voice: voice, isSelected: true, scrolls: false, siblings: d.browsing, zoom: phraseZoom) { openAnswer(phrase) }
                        .id(phrase.id)
                } else if selectedID == lockID {
                    ProLockView(place: "home")
                } else if selectedID == completeID {
                    completion(d)
                }
            } else {
                TabView(selection: selection) {
                    ForEach(d.browsing) { phrase in
                        FeaturedPhraseView(phrase: phrase, voice: voice, isSelected: selectedID == phrase.id, siblings: d.browsing, zoom: phraseZoom) { openAnswer(phrase) }.tag(phrase.id)
                    }
                    if d.showsLock { ProLockView(place: "explore").tag(lockID) }
                    // Answered cards stay in the deck; the completion follows the last one.
                    if d.showsComplete { completion(d).tag(completeID) }
                }.tabViewStyle(.page(indexDisplayMode: .never)).id(mode)
                    .accessibilityIdentifier("todayCards")
            }

            learningFooter(d)
        }
    }

    /// Same completion as the review screen: mark, serif title, next step. A rare moment, so it enters in steps.
    private func completion(_ d: HomeDerivation) -> some View {
        let streak = store.streak(now: now).current
        return VStack(spacing: Spacing.md) {
            CompletionMark()
            Text("All done!").font(Typography.phraseRow).staggeredEntrance(1)
            if let nextDue = d.visible.compactMap({ store.data.memoryReviews?[$0.id]?.due }).min(), nextDue > now {
                Text("Next review: \(nextDue.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.subheadline.monospacedDigit()).foregroundStyle(Palette.secondary)
                    .accessibilityIdentifier("nextMemoryReview")
                    .staggeredEntrance(2)
            }
            // The share sheet lists X, Threads, Instagram and LINE when they are installed; each takes the card.
            if let card = completionCard {
                ShareLink(item: card, message: Text(completionShareMessage(streak: streak)),
                          preview: SharePreview(Text("Phrases I learned on Izzy today"), image: card)) {
                    SecondaryButtonLabel(title: String(localized: "Share today's learning"), symbol: "square.and.arrow.up")
                }.buttonStyle(PressStyle()).frame(maxWidth: 360)
                    .accessibilityIdentifier("shareCompletion")
                    .staggeredEntrance(3)
            }
            // The day's phrases, as the Stats calendar lists them.
            Button("Review today's phrases") { voice.stopPlayback(); reviewingToday = true }
                .font(Typography.control).frame(minHeight: 44).buttonStyle(PressStyle())
                .accessibilityIdentifier("reviewTodayAfterLearning")
                .staggeredEntrance(4)
        }.multilineTextAlignment(.center).padding(Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .task(id: "\(d.learning.map(\.id))\(streak)") { completionCard = renderCompletionCard(d.learning, streak: streak) }
    }

    private func renderCompletionCard(_ phrases: [Phrase], streak: Int) -> Image? {
        let card = CompletionShareCard(phrases: phrases.map(\.phrase), streak: streak,
                                       typeface: store.data.typeface(fullAccess: purchases.hasFullAccess))
        let renderer = ImageRenderer(content: card)
        renderer.scale = 3
        return renderer.uiImage.map { Image(uiImage: $0) }
    }

    /// The words that go with the card; the link's social card does the introducing.
    private func completionShareMessage(streak: Int) -> String {
        let done = streak > 1 ? String(localized: "Finished today's learning on Izzy. \(streak) days in a row.")
            : String(localized: "Finished today's learning on Izzy.")
        return done + "\n" + AppSupport.shareURL.absoluteString
    }

    private func learningFooter(_ d: HomeDerivation) -> some View {
        VStack(spacing: Spacing.xs) {
            // Rating stays on Home in both modes and can be tapped at any time; only the brief pause after a tap disables it.
            if let phrase = d.browsing.first(where: { $0.id == selectedID }) {
                let selected = pendingRating?.id == phrase.id ? pendingRating?.rating : store.memoryRating(for: phrase.id, on: now)
                // Today's learning says which kind of card this is; Explore is browsing and only asks.
                let title: LocalizedStringKey = mode == .explore ? "How well did you remember?"
                    : d.isReview(phrase.id) ? "Review: did you remember the meaning?" : "New: did you know the meaning?"
                MemoryRatingControls(state: store.data.memoryReviews?[phrase.id], now: now, compact: true, title: title, selected: selected) { rating in
                    if mode == .learning { rateLearning(phrase, rating) } else { rateExplored(phrase, rating) }
                }
                .disabled(pendingRating != nil)
                .padding(.bottom, Spacing.xs)
            }
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: Spacing.xxs))
                : AnyLayout(HStackLayout(spacing: Spacing.xs))
            layout {
                if mode == .learning {
                    // Opens today's phrases (new and reviews); the daily goal is changed from there.
                    // The label names the list; progress stays available to VoiceOver as the value.
                    Button { voice.stopPlayback(); newPhrasesShown = true } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text("Today's plan").font(.caption)
                            Image(systemName: "chevron.down").font(.caption2)
                        }.frame(minHeight: 44)
                    }.buttonStyle(PressStyle())
                        .accessibilityIdentifier("todayPhrases")
                        .accessibilityValue(Text("\(min(d.progress.introduced, d.progress.target)) / \(d.progress.target) new") + Text(verbatim: ", ") + Text("\(d.progress.dueReviews) reviews due"))
                        .accessibilityHint("Shows today's phrases")
                }
                // Both modes keep the count at the bottom right.
                if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                if !d.pageIDs.isEmpty { pageNavigation(d) }
            }

        }.padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.sm)
    }

    private func rateLearning(_ phrase: Phrase, _ rating: MemoryRating) {
        guard mode == .learning, learningID == phrase.id, pendingRating == nil,
              derive().learning.contains(where: { $0.id == phrase.id }) else { return }
        // The answered card stays in today's deck; move on to the next card (or the completion after the last).
        commit(rating, for: phrase) { step(1) }
    }

    /// Explore rates the phrase on show and moves to the next card; the daily queue is untouched.
    private func rateExplored(_ phrase: Phrase, _ rating: MemoryRating) {
        guard mode == .explore, exploreID == phrase.id, pendingRating == nil else { return }
        commit(rating, for: phrase) { step(1) }
    }

    /// Records the answer at once, shows it in color while the card stays put, then moves on.
    /// Recording first means leaving the screen or the app during the pause loses nothing.
    private func commit(_ rating: MemoryRating, for phrase: Phrase, then advance: @escaping () -> Void) {
        voice.stopPlayback()
        let ratedMode = mode
        pendingRating = (phrase.id, rating, ratedMode)
        // Recorded at the time the buttons previewed, so the saved interval is the one that was shown.
        store.rateMemory(phrase, rating, now: now)
        Analytics.shared.record(.phraseReviewed, ["rating": rating.rawValue, "kind": phrase.isIdiom ? "idiom" : "verb", "mode": ratedMode == .learning ? "learning" : "explore"])
        now = .now
        // Long enough to see the chosen color, short enough for an action repeated on every card.
        let delay: Duration = reduceMotion ? .zero : .milliseconds(200)
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard pendingRating?.id == phrase.id else { return }
            pendingRating = nil
            // Only move on from the card that was rated: a swipe, arrow or mode switch during the pause already moved.
            guard mode == ratedMode, selectedID == phrase.id else { return }
            advance()
        }
    }

    /// "3 / 5" in Today's learning; Explore counts the whole collection for the filter, Pro phrases included.
    private func positionLabel(_ d: HomeDerivation) -> String {
        if selectedID == lockID { return "Izzy Pro" }
        if selectedID == completeID { return String(localized: "Done") }
        return "\((d.position + 1).formatted()) / \(positionTotal(d).formatted())"
    }
    private func positionTotal(_ d: HomeDerivation) -> Int { mode == .explore ? d.collectionCount : d.learning.count }

    private func pageNavigation(_ d: HomeDerivation) -> some View {
        HStack(spacing: 0) {
            Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .disabled(d.position == 0).accessibilityLabel("Previous phrase")
            Text(positionLabel(d))
                .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("todayPosition")
                .accessibilityLabel(selectedID == lockID ? "Izzy Pro" : selectedID == completeID ? String(localized: "Today's learning complete")
                                    : "Phrase \(d.position + 1) of \(positionTotal(d))")
            Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .disabled(d.position >= d.pageIDs.count - 1).accessibilityLabel("Next phrase")
        }.buttonStyle(PressStyle())
    }

    private func speakingButton(_ d: HomeDerivation) -> some View {
        Button {
            voice.stopPlayback()
            session = .init(phrases: derive().speaking)
        } label: {
            Image(systemName: "waveform").frame(width: 44, height: 44)
        }.buttonStyle(PressStyle()).disabled(d.speaking.isEmpty)
            .accessibilityLabel("Practice")
            .accessibilityIdentifier("dailyPractice")
            .accessibilityValue(mode == .explore ? "Current expression" : "\(d.speaking.count) phrases")
    }

    private var modePicker: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(spacing: Spacing.xxs))
        return layout {
            ForEach(Mode.allCases, id: \.self) { item in
                Button { switchMode(to: item) } label: {
                    // One weight in both states, so the label never changes width; color and the pill carry selection.
                    Text(LocalizedStringKey(item.rawValue)).font(.footnote.weight(.medium))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 32)
                        .padding(.horizontal, Spacing.md)
                        .foregroundStyle(mode == item ? accent.color : Palette.ink)
                        .background {
                            // One pill slides between the options instead of each option painting its own.
                            if mode == item {
                                RoundedRectangle(cornerRadius: typeSize.isAccessibilitySize ? Radius.small : 100)
                                    .fill(accent.soft)
                                    .matchedGeometryEffect(id: "modePill", in: modePill)
                            }
                        }
                        .hitArea(vertical: 6) // 32 pt drawn, 44 pt to touch; never overlaps the neighbor
                }.buttonStyle(PressStyle())
                    .accessibilityAddTraits(mode == item ? .isSelected : [])
                    .accessibilityIdentifier(item == .learning ? "todayLearningMode" : "todayExploreMode")
            }
        }.padding(Spacing.xxs)
            // Concentric: the track's radius is the pill's plus the 4 pt between them.
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: typeSize.isAccessibilitySize ? Radius.small + Spacing.xxs : 100))
            .animation(reduceMotion ? Motion.reducedFade : Motion.snappy, value: mode)
            .padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.xs)
            .frame(maxWidth: .infinity)
    }

    /// The deck swaps at once; only the selection pill moves (see `modePicker`). Animating the swap
    /// would lay out both decks together for the length of the spring.
    private func switchMode(to item: Mode) {
        guard mode != item else { return }
        mode = item
    }

    private func reconcileSelection() {
        let d = derive()
        let learningIDs = d.learning.map(\.id) + (d.remaining.isEmpty && !d.learning.isEmpty ? [completeID] : [])
        // Open on the first card still to do, or on the completion once everything is answered.
        if !learningIDs.contains(learningID) { learningID = d.remaining.first?.id ?? learningIDs.last ?? "" }
        let exploreIDs = d.visible.map(\.id) + (purchases.hasFullAccess ? [] : [lockID])
        if !exploreIDs.contains(exploreID) { exploreID = exploreIDs.first ?? "" }
    }

    /// A notification tap reviews in Today's learning: close Home's own presentations (other screens close
    /// through `closesForReviewRequest`) and open on the first card still to do.
    private func showRequestedLearning() {
        voice.stopPlayback()
        settings = false
        session = nil
        stats = false
        reviewingToday = false
        answerRequest = nil
        newPhrasesShown = false
        now = .now
        mode = .learning
        learningID = "" // not in the deck, so reconciling picks the first card still to do
        reconcileSelection()
    }

    private func openAnswer(_ phrase: Phrase) {
        voice.stopPlayback()
        answerRequest = AnswerRequest(id: phrase.id)
    }
    private func rememberPreview() {
        if !selectedID.isEmpty && selectedID != lockID && selectedID != completeID { previewedIDs.insert(selectedID) }
    }
    private func step(_ offset: Int) {
        let d = derive()
        let next = d.position + offset
        guard d.pageIDs.indices.contains(next) else { return }
        withAnimation(reduceMotion ? nil : Motion.snappy) { selectedID = d.pageIDs[next] }
    }
}

/// A fixed landscape keeps its position while phrases move across it.
struct TodayLandscapeBackground: View {
    let background: TodayBackground
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    private var imageOpacity: Double {
        if contrast == .increased { return 0.12 }
        return colorScheme == .dark ? 0.22 : 0.38
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                background.color ?? Palette.paper
                if !reduceTransparency, let imageName = background.imageName {
                    Image(imageName)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
                        .opacity(imageOpacity)

                    // A paper veil softens the sky and clears the lower controls.
                    LinearGradient(stops: [
                        .init(color: Palette.paper.opacity(0.30), location: 0),
                        .init(color: Palette.paper.opacity(0.08), location: 0.32),
                        .init(color: Palette.paper.opacity(0.24), location: 0.55),
                        .init(color: Palette.paper.opacity(0.88), location: 0.84),
                        .init(color: Palette.paper, location: 1)
                    ], startPoint: .top, endPoint: .bottom)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct FeaturedPhraseView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.phraseTypeface) private var typeface
    @Environment(\.appAccent) private var accent
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = 48.0
    @Environment(\.dynamicTypeSize) private var typeSize
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    let isSelected: Bool
    var scrolls = true
    /// The cards on either side, so Phrase notes can be swiped in the same order.
    var siblings: [Phrase] = []
    let zoom: Namespace.ID
    var onInfo: () -> Void
    var body: some View {
        Group {
            if scrolls { ScrollView { content } }
            else { content }
        }.accessibilityHidden(!isSelected)
    }

    private var content: some View {
        VStack(spacing: Spacing.md) {
            VStack(spacing: Spacing.xxs) {
                NavigationLink { PhraseDetailView(phrase: phrase, siblings: siblings).zoomDestination(id: phrase.id, in: zoom).dismissesForReviewRequest() } label: {
                    // One line: long phrases shrink rather than wrap; accessibility sizes may wrap.
                    Text(phrase.phrase).font(typeface.font(size: wordSize))
                        .tracking(wordSize * typeface.displayTracking).foregroundStyle(Palette.ink)
                        .lineLimit(typeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(0.55)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("featuredPhrase")
                        .zoomSource(id: phrase.id, in: zoom)
                }.buttonStyle(PressStyle()).accessibilityIdentifier("featuredDetails").accessibilityHint("Opens phrase details")
                PhrasePronunciation(phrase: phrase)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(0.7)
            }
            PhraseDifficultyButton(phrase: phrase)
            // Hear it, open the meaning and examples, save it: the three actions for a phrase.
            HStack(spacing: Spacing.lg) {
                Button { voice.speak(phrase.phrase, voiceIdentifier: store.data.speechVoiceID) } label: { Image(systemName: "speaker.wave.2").frame(width: 48, height: 48) }
                    .foregroundStyle(voice.isSpeaking ? accent.mark : Palette.ink)
                    .accessibilityLabel("Hear phrase").accessibilityValue(voice.isSpeaking ? "Playing" : "")
                Button(action: onInfo) { Image(systemName: "info.circle").frame(width: 48, height: 48) }
                    .foregroundStyle(Palette.ink)
                    .accessibilityLabel("Meaning & examples").accessibilityIdentifier("toggleAnswer")
                SavePhraseButton(phraseID: phrase.id, featured: true)
            }.font(.title3).buttonStyle(PressStyle())
            Text(voice.message ?? " ").font(.caption).foregroundStyle(Palette.secondary)
                .accessibilityHidden(voice.message == nil)
        }.multilineTextAlignment(.center).padding(.horizontal, Spacing.xl).padding(.vertical, Spacing.lg)
            .frame(maxWidth: .infinity, alignment: .top)
    }
}

/// The meaning and examples rise from the bottom of Home.
struct PhraseAnswerSheet: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    var body: some View {
        NavigationStack {
            PaperPage {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(phrase.phrase).phraseFont(.title2)
                    PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, identifier: "featuredMeaning")
                    PhraseExamples(phrase: phrase, voice: voice)
                }.multilineTextAlignment(.leading)
            }.foregroundStyle(Palette.ink)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closeAnswer") } }
        }.onDisappear { voice.stopPlayback() }
    }
}

/// What the completion screen shares: today's phrases on the icon's black, 4:5 so feeds show it whole.
private struct CompletionShareCard: View {
    let phrases: [String]
    let streak: Int
    let typeface: PhraseTypeface
    private let shown = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("LaunchMark").resizable().scaledToFit().frame(width: 56, height: 56)
            Spacer(minLength: 24)
            Text("Phrases I learned on Izzy today").font(.system(size: 28, design: .serif))
                .fixedSize(horizontal: false, vertical: true)
            if streak > 1 {
                Text("\(streak)-day streak").font(.system(size: 16, weight: .medium)).opacity(0.6).padding(.top, 8)
            }
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(phrases.prefix(shown).enumerated()), id: \.offset) { _, phrase in
                    Text(verbatim: phrase).font(typeface.font(size: 24)).lineLimit(1).minimumScaleFactor(0.6)
                }
                if phrases.count > shown {
                    Text(verbatim: "+\(phrases.count - shown)").font(.system(size: 16, weight: .medium)).opacity(0.6)
                }
            }.padding(.top, 28)
            Spacer(minLength: 24)
        }
        .foregroundStyle(.white).padding(36)
        .frame(width: 360, height: 450, alignment: .topLeading)
        .background(.black)
    }
}
