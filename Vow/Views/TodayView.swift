import SwiftUI

struct PracticeSelection: Identifiable {
    let id = UUID()
    let phrases: [Phrase]
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
    private enum Mode: String, CaseIterable {
        case learning = "Today's learning"
        case explore = "Explore"
    }
    @State private var mode: Mode = .learning
    @State private var learningID = ""
    @State private var learningAnswerOverride: Bool?
    @State private var exploreID = ""
    private var selectedID: String {
        get { mode == .learning ? learningID : exploreID }
        nonmutating set {
            if mode == .learning { learningID = newValue } else { exploreID = newValue }
        }
    }
    private var selection: Binding<String> { Binding(get: { selectedID }, set: { selectedID = $0 }) }
    @State private var previewedIDs: Set<String> = []
    @State private var voice = VoicePractice()
    @State private var now = Date.now
    private let lockID = "vow-pro-locked"
    private var visiblePhrases: [Phrase] { store.phrases.filter { purchases.allows($0) } }
    private var learningPhrases: [Phrase] {
        MemoryScheduler.queue(phrases: visiblePhrases, states: store.data.memoryReviews ?? [:],
                              focus: store.data.focus, now: now, limit: visiblePhrases.count,
                              dailyNewLimit: store.data.newPhrasesPerDay)
    }
    private var browsingPhrases: [Phrase] { mode == .learning ? learningPhrases : visiblePhrases }
    private var showsLock: Bool { mode == .explore && !purchases.hasFullAccess }
    private var pageIDs: [String] { browsingPhrases.map(\.id) + (showsLock ? [lockID] : []) }
    private var speakingPhrases: [Phrase] {
        mode == .learning ? queue : visiblePhrases.filter { $0.id == selectedID }
    }
    private var position: Int { pageIDs.firstIndex(of: selectedID) ?? 0 }
    private var queue: [Phrase] { SessionPlanner.queue(phrases: store.phrases.filter { purchases.allows($0) }, states: store.data.reviews, focus: store.data.focus, now: now) }
    private var progress: DailyLearningProgress {
        DailyLearningProgress(phrases: visiblePhrases, states: store.data.memoryReviews ?? [:],
                              goal: store.data.newPhrasesPerDay, now: now)
    }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                ScrollViewReader { proxy in
                    ScrollView { pageContent.id("homeTop") }
                        .onChange(of: learningID) { _, _ in
                            if mode == .learning {
                                withTransaction(Transaction(animation: nil)) { proxy.scrollTo("homeTop", anchor: .top) }
                            }
                        }
                }
            } else {
                pageContent
            }
        }.frame(maxWidth: 680).frame(maxWidth: .infinity)
            .background { TodayLandscapeBackground(background: store.data.backgroundChoice) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings, onDismiss: openRequestedReview) { SettingsView() }
            .sheet(isPresented: $editingGoal) {
                NavigationStack {
                    DailyGoalView()
                        .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { editingGoal = false } } }
                }
            }
            .fullScreenCover(isPresented: $reviewing) { MemoryReviewView() }
            .fullScreenCover(item: $session, onDismiss: openRequestedReview) { SpeakingSessionView(phrases: $0.phrases, primedIDs: previewedIDs) }
            .onAppear {
                now = .now
                reconcileSelection()
                rememberPreview()
            }
            .onChange(of: reminders.reviewRequest, initial: true) { _, request in
                routeRequestedReview()
            }
            .onChange(of: isActive) { _, active in if active { routeRequestedReview() } }
            .onChange(of: purchases.hasFullAccess) { _, _ in
                reconcileSelection()
                voice.stopPlayback()
            }
            .onChange(of: mode) { _, _ in
                learningAnswerOverride = nil
                reconcileSelection()
                voice.stopPlayback()
                rememberPreview()
            }
            .onChange(of: pageIDs) { _, _ in reconcileSelection() }
            .onChange(of: selectedID) { _, _ in
                learningAnswerOverride = nil
                voice.stopPlayback()
                rememberPreview()
            }
            .onChange(of: store.data.showsAnswerByDefault) { _, _ in learningAnswerOverride = nil }
            .onChange(of: store.data.focus) { _, focus in
                exploreID = visiblePhrases.first { $0.scene == focus }?.id ?? exploreID
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

    private var pageContent: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                let streak = store.streak(now: now)
                NavigationLink { ProgressViewScreen() } label: {
                    Label("\(streak.current) day\(streak.current == 1 ? "" : "s")", systemImage: "flame")
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                }.accessibilityLabel("\(streak.current)-day streak").accessibilityIdentifier("streakSummary")
                Spacer()
                speakingButton
                Button { settings = true } label: {
                    Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
                }.accessibilityLabel("Practice settings").accessibilityIdentifier("practiceSettings")
            }.padding(.leading, Spacing.xl).padding(.trailing, Spacing.md).padding(.top, Spacing.xs)

            modePicker

            if store.phrases.isEmpty {
                ContentUnavailableView("No phrases available", systemImage: "text.book.closed")
            } else if mode == .learning && learningPhrases.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "checkmark.circle").font(.largeTitle)
                    Text("Today's learning complete").font(Typography.control)
                    if let nextDue = visiblePhrases.compactMap({ store.data.memoryReviews?[$0.id]?.due }).min(), nextDue > now {
                        Text("Next review: \(nextDue.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
                            .accessibilityIdentifier("nextMemoryReview")
                    }
                    Button("Explore more expressions") { mode = .explore }
                        .frame(minHeight: 44).accessibilityIdentifier("exploreAfterLearning")
                }.multilineTextAlignment(.center).padding(Spacing.xl)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if typeSize.isAccessibilitySize {
                if let phrase = browsingPhrases.first(where: { $0.id == selectedID }) {
                    FeaturedPhraseView(phrase: phrase, voice: voice, isSelected: true, scrolls: false,
                                       learningAnswer: mode == .learning ? $learningAnswerOverride : nil)
                        .id(phrase.id)
                } else if selectedID == lockID {
                    ProLockView()
                }
            } else {
                TabView(selection: selection) {
                    ForEach(browsingPhrases) { phrase in
                        FeaturedPhraseView(phrase: phrase, voice: voice, isSelected: selectedID == phrase.id,
                                           learningAnswer: mode == .learning ? $learningAnswerOverride : nil).tag(phrase.id)
                    }
                    if showsLock { ProLockView().tag(lockID) }
                }.tabViewStyle(.page(indexDisplayMode: .never)).id(mode)
                    .accessibilityIdentifier("todayCards")
            }

            learningFooter
        }
    }

    private var learningFooter: some View {
        VStack(spacing: Spacing.xs) {
            if mode == .learning, let phrase = learningPhrases.first(where: { $0.id == learningID }) {
                MemoryRatingControls(state: store.data.memoryReviews?[phrase.id], now: now, compact: true) { rating in
                    rateLearning(phrase, rating)
                }
                .disabled(!(learningAnswerOverride ?? store.data.showsAnswerByDefault))
                .padding(.bottom, Spacing.xs)
            }
            let layout = typeSize.isAccessibilitySize
                ? AnyLayout(VStackLayout(spacing: Spacing.xxs))
                : AnyLayout(HStackLayout(spacing: Spacing.xs))
            layout {
                if mode == .learning {
                    Button { editingGoal = true } label: {
                        HStack(spacing: Spacing.xxs) {
                            Text("\(min(progress.introduced, progress.target)) / \(progress.target) new")
                                .font(.caption.monospacedDigit())
                            Image(systemName: "chevron.down").font(.caption2)
                        }.frame(minHeight: 44)
                    }.buttonStyle(.plain)
                        .accessibilityIdentifier("editDailyGoal")
                        .accessibilityLabel("\(min(progress.introduced, progress.target)) / \(progress.target) new")
                        .accessibilityValue("\(progress.dueReviews) reviews due")
                        .accessibilityHint("Change your daily goal")
                    if !typeSize.isAccessibilitySize { Spacer(minLength: 0) }
                }
                if !pageIDs.isEmpty { pageNavigation }
            }

        }.padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.sm)
    }

    private func rateLearning(_ phrase: Phrase, _ rating: MemoryRating) {
        guard mode == .learning, learningID == phrase.id,
              learningAnswerOverride ?? store.data.showsAnswerByDefault,
              learningPhrases.contains(where: { $0.id == phrase.id }) else { return }
        voice.stopPlayback()
        learningAnswerOverride = nil
        store.rateMemory(phrase, rating)
        now = .now
        reconcileSelection()
    }

    private var pageNavigation: some View {
        HStack(spacing: 0) {
            Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                .disabled(position == 0).accessibilityLabel("Previous phrase")
            Text(selectedID == lockID ? "Vow Pro" : "\(position + 1) / \(browsingPhrases.count)")
                .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                .fixedSize(horizontal: true, vertical: false)
                .accessibilityIdentifier("todayPosition")
                .accessibilityLabel(selectedID == lockID ? "Vow Pro" : "Phrase \(position + 1) of \(browsingPhrases.count)")
            Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                .disabled(position >= pageIDs.count - 1).accessibilityLabel("Next phrase")
        }.buttonStyle(.plain)
    }

    private var speakingButton: some View {
        Button {
            voice.stopPlayback()
            session = .init(phrases: speakingPhrases)
        } label: {
            Image(systemName: "waveform").frame(width: 44, height: 44)
        }.buttonStyle(.plain).disabled(speakingPhrases.isEmpty)
            .accessibilityLabel("Practice speaking")
            .accessibilityIdentifier("dailyPractice")
            .accessibilityValue(mode == .explore ? "Current expression" : "\(speakingPhrases.count) phrases")
    }

    private var modePicker: some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: Spacing.xxs))
            : AnyLayout(HStackLayout(spacing: Spacing.xxs))
        return layout {
            ForEach(Mode.allCases, id: \.self) { item in
                Button { mode = item } label: {
                    Text(item.rawValue).font(.subheadline.weight(.medium))
                        .multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, Spacing.xs)
                        .background(mode == item ? Palette.ink : .clear,
                                    in: RoundedRectangle(cornerRadius: typeSize.isAccessibilitySize ? 16 : 100))
                        .foregroundStyle(mode == item ? Palette.paper : Palette.ink)
                }.buttonStyle(.plain)
                    .accessibilityAddTraits(mode == item ? .isSelected : [])
                    .accessibilityIdentifier(item == .learning ? "todayLearningMode" : "todayExploreMode")
            }
        }.padding(Spacing.xxs)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: typeSize.isAccessibilitySize ? 20 : 100))
            .padding(.horizontal, Spacing.xl).padding(.bottom, Spacing.xs)
    }

    private func reconcileSelection() {
        let learningIDs = learningPhrases.map(\.id)
        if !learningIDs.contains(learningID) { learningID = learningIDs.first ?? "" }
        let exploreIDs = visiblePhrases.map(\.id) + (purchases.hasFullAccess ? [] : [lockID])
        if !exploreIDs.contains(exploreID) { exploreID = exploreIDs.first ?? "" }
    }

    private func routeRequestedReview() {
        guard isActive, reminders.reviewRequest != nil else { return }
        voice.stopPlayback()
        if settings { settings = false }
        else if session != nil { session = nil }
        else { openRequestedReview() }
    }

    private func openRequestedReview() {
        guard isActive, reminders.reviewRequest != nil, !settings, session == nil else { return }
        reviewing = true
        reminders.reviewRequest = nil
    }

    private func rememberPreview() {
        if !selectedID.isEmpty && selectedID != lockID { previewedIDs.insert(selectedID) }
    }
    private func step(_ offset: Int) {
        let next = position + offset
        guard pageIDs.indices.contains(next) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedID = pageIDs[next] }
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
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    let isSelected: Bool
    var scrolls = true
    var learningAnswer: Binding<Bool?>?
    @State private var answerOverride: Bool?
    private var showsAnswer: Bool {
        (learningAnswer?.wrappedValue ?? answerOverride) ?? store.data.showsAnswerByDefault
    }
    var body: some View {
        Group {
            if scrolls { ScrollView { content } }
            else { content }
        }.accessibilityHidden(!isSelected)
            .onChange(of: isSelected) { _, _ in answerOverride = nil }
            .onChange(of: store.data.showsAnswerByDefault) { _, _ in answerOverride = nil }
    }

    private var content: some View {
            VStack(spacing: Spacing.md) {
                if learningAnswer == nil, let scene = Scene.all.first(where: { $0.id == phrase.scene }) {
                    NavigationLink { SceneDetailView(scene: scene) } label: {
                        Text(scene.subtitle).font(Typography.context)
                            .foregroundStyle(Palette.secondary)
                            .frame(minHeight: 44)
                    }.accessibilityIdentifier("featuredScene")
                }
                NavigationLink { PhraseDetailView(phrase: phrase) } label: {
                    Text(phrase.phrase).font(Typography.featured(size: wordSize))
                        .tracking(-wordSize * 0.018).fixedSize(horizontal: false, vertical: true).foregroundStyle(Palette.ink)
                        .accessibilityIdentifier("featuredPhrase")
                }.buttonStyle(.plain).accessibilityIdentifier("featuredDetails").accessibilityHint("Opens phrase details")
                PhraseDifficultyButton(phrase: phrase)
                HStack(spacing: Spacing.lg) {
                    Button { voice.speak(phrase.phrase, voiceIdentifier: store.data.speechVoiceID) } label: { Image(systemName: "speaker.wave.2").frame(width: 48, height: 48) }
                        .foregroundStyle(voice.isSpeaking ? accent.color : Palette.ink)
                        .accessibilityLabel("Hear phrase").accessibilityValue(voice.isSpeaking ? "Playing" : "")
                    SavePhraseButton(phraseID: phrase.id, featured: true)
                }.font(.title3).buttonStyle(PressStyle())
                VStack(alignment: .leading, spacing: Spacing.md) {
                    Button(showsAnswer ? "Hide meaning & examples" : "Show meaning & examples") {
                            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                                if let learningAnswer { learningAnswer.wrappedValue = !showsAnswer }
                                else { answerOverride = !showsAnswer }
                            }
                        }
                        .font(Typography.control).frame(maxWidth: .infinity, minHeight: 44)
                        .accessibilityIdentifier("toggleAnswer")
                        .accessibilityValue(showsAnswer ? "Shown" : "Hidden")
                    // Reserve the complete answer's height so revealing it does not move controls.
                    VStack(alignment: .leading, spacing: Spacing.md) {
                        Text(phrase.explanation(in: store.data.meaningLanguage)).font(Typography.meaning)
                            .accessibilityIdentifier("featuredMeaning")
                        PhraseExamples(phrase: phrase, voice: voice)
                    }.opacity(showsAnswer ? 1 : 0)
                        .accessibilityHidden(!showsAnswer).allowsHitTesting(showsAnswer)
                }.multilineTextAlignment(.leading)
                Text(voice.message ?? " ").font(.caption).foregroundStyle(Palette.secondary)
                    .accessibilityHidden(voice.message == nil)
            }.multilineTextAlignment(.center).padding(.horizontal, Spacing.xl).padding(.vertical, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .top)
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
    }
}
