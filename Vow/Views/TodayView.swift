import SwiftUI

struct PracticeSelection: Identifiable {
    let id = UUID()
    let phrases: [Phrase]
}

/// Which phrase's meaning and examples are open in the bottom sheet.
private struct AnswerRequest: Identifiable { let id: String }

/// Everything that decides whether the notification-opened review can appear. A change restarts the
/// attempt with current values, since a running task keeps the view value it started with.
private struct ReviewRoute: Equatable {
    let request: UUID?
    let active: Bool
    let sceneActive: Bool
    let choosingGoal: Bool
}

struct TodayView: View {
    let isActive: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @Environment(ReviewReminderCenter.self) private var reminders
    @State private var session: PracticeSelection?
    @State private var reviewing = false
    @State private var settings = false
    @State private var editingGoal = false
    @State private var stats = false
    @State private var answerRequest: AnswerRequest?
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
    @State private var pendingRating: (id: String, rating: MemoryRating, index: Int, mode: Mode)?
    /// True while the notification-opened review is on screen.
    @State private var reviewShown = false
    @State private var voice = VoicePractice()
    @State private var now = Date.now
    private let lockID = HomeDerivation.lockID
    /// One pass over the catalog per render; handlers call this again when they run.
    private func derive() -> HomeDerivation {
        HomeDerivation(phrases: store.phrases, purchased: purchases.hasFullAccess, kind: store.data.homeKindFilter,
                       memory: store.data.memoryReviews ?? [:], reviews: store.data.reviews, focus: store.data.focus,
                       dailyNew: store.data.newPhrasesPerDay, now: now, mode: mode == .learning ? .learning : .explore,
                       selectedID: selectedID, pinned: pendingRating.flatMap { $0.mode == .learning ? ($0.id, $0.index) : nil })
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
            .background { TodayLandscapeBackground(background: store.data.backgroundChoice) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings, onDismiss: { openRequestedReview() }) { SettingsView() }
            .sheet(isPresented: $stats, onDismiss: { openRequestedReview() }) {
                NavigationStack {
                    ProgressViewScreen()
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { stats = false }.accessibilityIdentifier("closeStats") } }
                }.presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
            }
            .sheet(item: $answerRequest, onDismiss: { openRequestedReview() }) { request in
                if let phrase = d.browsing.first(where: { $0.id == request.id }) {
                    PhraseAnswerSheet(phrase: phrase, voice: voice)
                        .presentationDetents([.fraction(0.75), .large]).presentationDragIndicator(.visible)
                }
            }
            .sheet(isPresented: $editingGoal, onDismiss: { openRequestedReview() }) {
                NavigationStack {
                    DailyGoalView()
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editingGoal = false } } }
                }
            }
            .fullScreenCover(isPresented: $reviewing) {
                MemoryReviewView()
                    .onAppear { reviewShown = true; reminders.reviewRequest = nil }
                    .onDisappear { reviewShown = false }
            }
            .fullScreenCover(item: $session, onDismiss: { openRequestedReview() }) { SpeakingSessionView(phrases: $0.phrases, primedIDs: previewedIDs) }
            .onAppear {
                now = .now
                reconcileSelection()
                rememberPreview()
            }
            .task(id: ReviewRoute(request: reminders.reviewRequest, active: isActive, sceneActive: scenePhase == .active,
                                 choosingGoal: store.data.needsDailyGoal)) {
                await routeRequestedReview()
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
            .onChange(of: store.data.homeKindFilter) { _, _ in
                reconcileSelection()
            }
            .onChange(of: scenePhase) { _, value in
                if value == .active { now = .now } else { voice.stopPlayback() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in now = .now }
            .onChange(of: session == nil) { _, value in if value { now = .now } }
            .onChange(of: reviewing) { _, value in if !value { now = .now } }
            .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in now = .now }
            .onDisappear { voice.clear() }
    }

    private func pageContent(_ d: HomeDerivation) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                let streak = store.streak(now: now)
                Button { stats = true } label: {
                    Label("\(streak.current) day\(streak.current == 1 ? "" : "s")", systemImage: "flame")
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                }.buttonStyle(.plain).accessibilityLabel("\(streak.current)-day streak").accessibilityIdentifier("streakSummary")
                    .accessibilityHint("Opens your stats")
                Spacer()
                kindFilter
                speakingButton(d)
            }.foregroundStyle(Palette.ink).padding(.leading, Spacing.xl).padding(.trailing, Spacing.md).padding(.top, Spacing.xs)

            modePicker

            if store.phrases.isEmpty {
                ContentUnavailableView("No phrases available", systemImage: "text.book.closed")
            } else if mode == .learning && d.learning.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle").font(.largeTitle)
                    Text("Today's learning complete").font(Typography.control)
                    if let nextDue = d.visible.compactMap({ store.data.memoryReviews?[$0.id]?.due }).min(), nextDue > now {
                        Text("Next review: \(nextDue.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
                            .accessibilityIdentifier("nextMemoryReview")
                    }
                    Button("Explore more expressions") { mode = .explore }
                        .frame(minHeight: 44).accessibilityIdentifier("exploreAfterLearning")
                }.multilineTextAlignment(.center).padding(Spacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if typeSize.isAccessibilitySize {
                if let phrase = d.browsing.first(where: { $0.id == selectedID }) {
                    FeaturedPhraseView(phrase: phrase, voice: voice, isSelected: true, scrolls: false) { openAnswer(phrase) }
                        .id(phrase.id)
                } else if selectedID == lockID {
                    ProLockView()
                }
            } else {
                TabView(selection: selection) {
                    ForEach(d.browsing) { phrase in
                        FeaturedPhraseView(phrase: phrase, voice: voice, isSelected: selectedID == phrase.id) { openAnswer(phrase) }.tag(phrase.id)
                    }
                    if d.showsLock { ProLockView().tag(lockID) }
                }.tabViewStyle(.page(indexDisplayMode: .never)).id(mode)
                    .accessibilityIdentifier("todayCards")
            }

            learningFooter(d)
        }
    }

    private func learningFooter(_ d: HomeDerivation) -> some View {
        VStack(spacing: Spacing.xs) {
            // Rating stays on Home in both modes and can be tapped at any time; only the brief pause after a tap disables it.
            if let phrase = d.browsing.first(where: { $0.id == selectedID }) {
                let selected = pendingRating?.id == phrase.id ? pendingRating?.rating : store.memoryRating(for: phrase.id, on: now)
                MemoryRatingControls(state: store.data.memoryReviews?[phrase.id], now: now, compact: true, selected: selected) { rating in
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
                    Button { editingGoal = true } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text("\(min(d.progress.introduced, d.progress.target)) / \(d.progress.target) new")
                                .font(.caption.monospacedDigit())
                            Image(systemName: "chevron.down").font(.caption2)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("editDailyGoal")
                        .accessibilityLabel("\(min(d.progress.introduced, d.progress.target)) / \(d.progress.target) new")
                        .accessibilityValue("\(d.progress.dueReviews) reviews due")
                        .accessibilityHint("Change your daily goal")
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                }
                if !d.pageIDs.isEmpty { pageNavigation(d) }
            }

        }.padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.sm)
    }

    private func rateLearning(_ phrase: Phrase, _ rating: MemoryRating) {
        guard mode == .learning, learningID == phrase.id, pendingRating == nil,
              derive().learning.contains(where: { $0.id == phrase.id }) else { return }
        commit(rating, for: phrase) { reconcileSelection() }
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
        pendingRating = (phrase.id, rating, derive().position, ratedMode)
        // Recorded at the time the buttons previewed, so the saved interval is the one that was shown.
        store.rateMemory(phrase, rating, now: now)
        now = .now
        let delay: Duration = reduceMotion ? .zero : .milliseconds(350)
        Task { @MainActor in
            try? await Task.sleep(for: delay)
            guard pendingRating?.id == phrase.id else { return }
            pendingRating = nil
            // Only move on from the card that was rated: a swipe, arrow or mode switch during the pause already moved.
            guard mode == ratedMode, selectedID == phrase.id else { return }
            advance()
        }
    }

    /// Explore hides the running count (1 / 1,300 says little); VoiceOver still hears the position.
    private func positionLabel(_ d: HomeDerivation) -> String? {
        if selectedID == lockID { return "Vow Pro" }
        return mode == .explore ? nil : "\(d.position + 1) / \(d.browsing.count)"
    }

    private func pageNavigation(_ d: HomeDerivation) -> some View {
        HStack(spacing: 0) {
            Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .disabled(d.position == 0).accessibilityLabel("Previous phrase")
            Text(positionLabel(d) ?? " ") // a space keeps the element for VoiceOver when the count is hidden
                .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: Spacing.lg) // keeps the arrows apart when the label is empty
                .accessibilityIdentifier("todayPosition")
                .accessibilityLabel(selectedID == lockID ? "Vow Pro" : "Phrase \(d.position + 1) of \(d.browsing.count)")
            Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .disabled(d.position >= d.pageIDs.count - 1).accessibilityLabel("Next phrase")
        }.buttonStyle(.plain)
    }

    private func speakingButton(_ d: HomeDerivation) -> some View {
        Button {
            voice.stopPlayback()
            session = .init(phrases: derive().speaking)
        } label: {
            Image(systemName: "waveform").frame(width: 44, height: 44)
        }.buttonStyle(.plain).disabled(d.speaking.isEmpty)
            .accessibilityLabel("Practice speaking")
            .accessibilityIdentifier("dailyPractice")
            .accessibilityValue(mode == .explore ? "Current expression" : "\(d.speaking.count) phrases")
    }

    /// Header control for both modes: everything, phrasal verbs, or idioms. Same style as the Phrases filter.
    private var kindFilter: some View {
        Menu {
            Picker("Show", selection: Binding(get: { store.data.homeKindFilter }, set: { store.configure(homeKind: $0) })) {
                ForEach(PhraseKindFilter.allCases, id: \.self) { Text(LocalizedStringKey($0.title)).tag($0) }
            }
        } label: {
            MenuControlLabel(title: LocalizedStringKey(store.data.homeKindFilter.title), systemImage: "line.3.horizontal.decrease",
                             font: .subheadline, color: Palette.ink)
        }.accessibilityIdentifier("todayKindFilter").accessibilityLabel("Show")
            .accessibilityValue(store.data.homeKindFilter.title)
    }

    private var modePicker: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(spacing: Spacing.xxs))
        return layout {
            ForEach(Mode.allCases, id: \.self) { item in
                Button { mode = item } label: {
                    Text(item.rawValue).font(.footnote.weight(mode == item ? .semibold : .medium))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 32)
                        .padding(.horizontal, Spacing.md)
                        .selectionSurface(mode == item, cornerRadius: typeSize.isAccessibilitySize ? 12 : 100, restFill: .clear)
                }.buttonStyle(.plain)
                    .accessibilityAddTraits(mode == item ? .isSelected : [])
                    .accessibilityIdentifier(item == .learning ? "todayLearningMode" : "todayExploreMode")
            }
        }.padding(Spacing.xxs)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: typeSize.isAccessibilitySize ? 16 : 100))
            .padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.xs)
            .frame(maxWidth: .infinity)
    }

    private func reconcileSelection() {
        let d = derive()
        let learningIDs = d.learning.map(\.id)
        if !learningIDs.contains(learningID) { learningID = learningIDs.first ?? "" }
        let exploreIDs = d.visible.map(\.id) + (purchases.hasFullAccess ? [] : [lockID])
        if !exploreIDs.contains(exploreID) { exploreID = exploreIDs.first ?? "" }
    }

    /// A notification asks for the review: close Home's own presentations, then keep trying while other
    /// screens (closed by `closesForReviewRequest`) finish animating away. The request is cleared only once
    /// the review is on screen, so a tap that arrives while something is covering Home is not lost.
    private func routeRequestedReview() async {
        guard reminders.reviewRequest != nil else { return }
        voice.stopPlayback()
        settings = false
        session = nil
        stats = false
        answerRequest = nil
        editingGoal = false
        // Poll until the review is actually on screen: setting `reviewing` alone doesn't guarantee it appeared.
        for _ in 0..<20 {
            if reviewShown { reminders.reviewRequest = nil; return } // a request while the review is already open
            if reminders.reviewRequest == nil { return }
            if !reviewing { openRequestedReview() }
            try? await Task.sleep(for: .milliseconds(250))
            if Task.isCancelled { return }
        }
        // A cover that never appeared must not block the next attempt (scene activation, a sheet closing).
        if reviewing, !reviewShown { reviewing = false }
    }

    @discardableResult private func openRequestedReview() -> Bool {
        guard reminders.reviewRequest != nil else { return true }
        if reviewShown { reminders.reviewRequest = nil; return true }
        guard isActive, !store.data.needsDailyGoal, !reviewing, !settings, !stats, !editingGoal, answerRequest == nil,
              session == nil, !ScreenPresentation.isCovered else { return false }
        reviewing = true
        return true
    }

    private func openAnswer(_ phrase: Phrase) {
        voice.stopPlayback()
        answerRequest = AnswerRequest(id: phrase.id)
    }
    private func rememberPreview() {
        if !selectedID.isEmpty && selectedID != lockID { previewedIDs.insert(selectedID) }
    }
    private func step(_ offset: Int) {
        let d = derive()
        let next = d.position + offset
        guard d.pageIDs.indices.contains(next) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedID = d.pageIDs[next] }
    }
}

/// A fixed landscape keeps its position while phrases move across it.
private struct TodayLandscapeBackground: View {
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
                Palette.paper
                if !reduceTransparency {
                    Image(background.imageName)
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
    @Environment(\.appAccent) private var accent
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = 48.0
    @Environment(\.dynamicTypeSize) private var typeSize
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    let isSelected: Bool
    var scrolls = true
    var onInfo: () -> Void
    var body: some View {
        Group {
            if scrolls { ScrollView { content } }
            else { content }
        }.accessibilityHidden(!isSelected)
    }

    private var content: some View {
        VStack(spacing: Spacing.md) {
            NavigationLink { PhraseDetailView(phrase: phrase) } label: {
                // One line: long phrases shrink rather than wrap; accessibility sizes may wrap.
                Text(phrase.phrase).font(Typography.featured(size: wordSize))
                    .tracking(-wordSize * 0.018).foregroundStyle(Palette.ink)
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 1).minimumScaleFactor(0.55)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("featuredPhrase")
            }.buttonStyle(.plain).accessibilityIdentifier("featuredDetails").accessibilityHint("Opens phrase details")
            PhraseDifficultyButton(phrase: phrase)
            // Hear it, open the meaning and examples, save it: the three actions for a phrase.
            HStack(spacing: Spacing.lg) {
                Button { voice.speak(phrase.phrase, voiceIdentifier: store.data.speechVoiceID) } label: { Image(systemName: "speaker.wave.2").frame(width: 48, height: 48) }
                    .foregroundStyle(voice.isSpeaking ? accent.color : Palette.ink)
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
                    Text(phrase.phrase).font(Typography.phraseRow)
                    PhraseMeaning(phrase: phrase, language: store.data.meaningLanguage, identifier: "featuredMeaning")
                    PhraseExamples(phrase: phrase, voice: voice)
                }.multilineTextAlignment(.leading)
            }.foregroundStyle(Palette.ink)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() }.accessibilityIdentifier("closeAnswer") } }
        }.onDisappear { voice.stopPlayback() }
    }
}

struct ScenesView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Spacing.md)) : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.md))) {
                    VStack(spacing: Spacing.md) { tile(0); tile(2) }
                    VStack(spacing: Spacing.md) { tile(1); tile(3) }
                }
                tile(4)
            }
        }.navigationTitle("Scenes").navigationBarTitleDisplayMode(.inline)
    }
    private func tile(_ index: Int) -> some View {
        NavigationLink { SceneDetailView(scene: Scene.all[index]) } label: { SceneTile(scene: Scene.all[index], index: index) }.buttonStyle(PressStyle())
    }
}

struct SceneDetailView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    let scene: Scene
    @State private var session: PracticeSelection?
    var phrases: [Phrase] { store.phrases.filter { $0.scene == scene.id && purchases.allows($0) } }
    private var practicePhrases: [Phrase] {
        SessionPlanner.queue(phrases: phrases.filter { purchases.allows($0) }, states: store.data.reviews, focus: scene.id, now: .now, limit: 6)
    }
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(scene.prompt).font(Typography.meaning)
                PrimaryButton(title: practicePhrases.isEmpty ? "You're up to date" : "Practice this scene") { session = .init(phrases: practicePhrases) }.disabled(practicePhrases.isEmpty)
                NavigationLink { RehearsalView(scene: scene) } label: { Label("Story practice", systemImage: "mic").frame(minHeight: 44) }
                if !purchases.hasFullAccess {
                    ProLockView()
                }
                SectionTitle(title: "Phrases", trailing: "\(phrases.count) phrases")
                LazyVStack(spacing: 0) {
                    ForEach(phrases) { phrase in
                        NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }.buttonStyle(.plain)
                    }
                }
            }
        }.navigationTitle(scene.subtitle).navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(item: $session) { SpeakingSessionView(phrases: $0.phrases) }
            .closesForReviewRequest($session)
    }
}
