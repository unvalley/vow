import SwiftUI

struct PracticeSelection: Identifiable {
    let id = UUID()
    let phrases: [Phrase]
}

struct TodayView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(PurchaseStore.self) private var purchases
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var session: PracticeSelection?
    @State private var settings = false
    @State private var selectedID = ""
    @State private var previewedIDs: Set<String> = []
    @State private var voice = VoicePractice()
    @State private var now = Date.now
    private var position: Int { store.phrases.firstIndex { $0.id == selectedID } ?? 0 }
    private var queue: [Phrase] { SessionPlanner.queue(phrases: store.phrases.filter { purchases.allows($0) }, states: store.data.reviews, focus: store.data.focus, now: now) }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: Spacing.sm) {
                let streak = store.streak(now: now)
                NavigationLink { ProgressViewScreen() } label: {
                    Label("\(streak.current)", systemImage: "flame.fill")
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                }.accessibilityLabel("\(streak.current)-day streak").accessibilityIdentifier("streakSummary")
                Spacer()
                Button { settings = true } label: {
                    Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
                }.accessibilityLabel("Practice settings")
            }.padding(.leading, Spacing.xl).padding(.trailing, Spacing.md).padding(.top, Spacing.xs)

            if store.phrases.isEmpty {
                ContentUnavailableView("No phrases available", systemImage: "text.book.closed")
            } else {
                TabView(selection: $selectedID) {
                    ForEach(store.phrases) { phrase in
                        FeaturedPhraseView(phrase: phrase, voice: voice).tag(phrase.id)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
            }

            HStack(spacing: Spacing.sm) {
                Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .disabled(position == 0).accessibilityLabel("Previous phrase")
                Spacer()
                Text("\(position + 1) / \(store.phrases.count)")
                    .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                    .accessibilityLabel("Phrase \(position + 1) of \(store.phrases.count)")
                Spacer()
                Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(position >= store.phrases.count - 1).accessibilityLabel("Next phrase")
            }.padding(.horizontal, Spacing.lg)

            Button {
                voice.stopPlayback()
                session = .init(phrases: queue)
            } label: {
                Group {
                    if typeSize.isAccessibilitySize {
                        Text(queue.isEmpty ? "You're up to date" : "Practice speaking")
                            .font(.subheadline.weight(.medium)).multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        HStack(spacing: Spacing.xs) {
                            Label(queue.isEmpty ? "You're up to date" : "Practice speaking", systemImage: "waveform")
                                .font(.subheadline.weight(.medium))
                            if !queue.isEmpty { Text("· \(queue.count) phrases").font(.caption).foregroundStyle(Palette.secondary) }
                        }
                    }
                }.frame(maxWidth: .infinity, minHeight: 44)
            }.buttonStyle(.plain).disabled(queue.isEmpty).accessibilityIdentifier("dailyPractice")
                .accessibilityValue("\(queue.count) phrases")
                .padding(.horizontal, Spacing.lg).padding(.bottom, Spacing.xs)
        }.frame(maxWidth: 680).frame(maxWidth: .infinity).background { ReadingBackground() }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $settings) { SettingsView() }
            .fullScreenCover(item: $session) { PracticeAccessView(phrases: $0.phrases, primedIDs: previewedIDs) }
            .onAppear {
                now = .now
                if selectedID.isEmpty { selectedID = store.phrases.first?.id ?? "" }
                rememberPreview()
            }
            .onChange(of: selectedID) { _, _ in voice.stopPlayback(); rememberPreview() }
            .onChange(of: store.data.focus) { _, focus in
                selectedID = store.phrases.first { $0.scene == focus }?.id ?? selectedID
            }
            .onChange(of: scenePhase) { _, value in
                if value == .active { now = .now } else { voice.stopPlayback() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in now = .now }
            .onChange(of: session == nil) { _, value in if value { now = .now } }
            .onDisappear { voice.clear() }
    }

    private func rememberPreview() {
        if !selectedID.isEmpty { previewedIDs.insert(selectedID) }
    }
    private func step(_ offset: Int) {
        let next = position + offset
        guard store.phrases.indices.contains(next) else { return }
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) { selectedID = store.phrases[next].id }
    }
}

private struct FeaturedPhraseView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = 48.0
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    @State private var showsExample = false
    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                if let scene = Scene.all.first(where: { $0.id == phrase.scene }) {
                    NavigationLink { SceneDetailView(scene: scene) } label: {
                        Text("Scene · \(scene.subtitle)").font(.caption).foregroundStyle(Palette.secondary)
                            .frame(minHeight: 44)
                    }.accessibilityIdentifier("featuredScene")
                }
                NavigationLink { PhraseDetailView(phrase: phrase) } label: {
                    Text(phrase.phrase).font(.system(size: wordSize, weight: .regular, design: .serif))
                        .tracking(-1).fixedSize(horizontal: false, vertical: true).foregroundStyle(Palette.ink)
                        .accessibilityIdentifier("featuredPhrase")
                }.buttonStyle(.plain).accessibilityIdentifier("featuredDetails").accessibilityHint("Opens phrase details")
                Text(phrase.explanation(in: store.data.meaningLanguage)).font(.title3).lineSpacing(4)
                PhraseConnections(phrase: phrase)
                HStack(spacing: Spacing.lg) {
                    Button { voice.speak(phrase.phrase) } label: { Image(systemName: "speaker.wave.2").frame(width: 48, height: 48) }
                        .accessibilityLabel("Hear phrase")
                    Button { store.toggleSaved(phrase.id) } label: {
                        Image(systemName: store.data.saved.contains(phrase.id) ? "bookmark.fill" : "bookmark").frame(width: 48, height: 48)
                    }.accessibilityLabel(store.data.saved.contains(phrase.id) ? "Unsave featured phrase" : "Save featured phrase")
                }.font(.title3).buttonStyle(PressStyle()).foregroundStyle(accent.color)
                VStack(alignment: .leading, spacing: Spacing.md) {
                    HStack(spacing: Spacing.sm) {
                        Text(phrase.examples.count > 1 ? "Examples" : "Example").font(.subheadline.weight(.semibold))
                        Spacer()
                        Button(showsExample ? "Hide" : "Show") { showsExample.toggle() }
                            .font(.subheadline).frame(minHeight: 44)
                            .accessibilityLabel(showsExample ? "Hide examples" : "Show examples")
                    }
                    // Opacity preserves the full intrinsic height at every Dynamic Type size.
                    // Hidden examples are also removed from accessibility and hit testing.
                    PhraseExamples(phrase: phrase)
                        .opacity(showsExample ? 1 : 0)
                        .accessibilityHidden(!showsExample).allowsHitTesting(showsExample)
                }.multilineTextAlignment(.leading)
                Text(voice.message ?? " ").font(.caption).foregroundStyle(Palette.secondary)
                    .accessibilityHidden(voice.message == nil)
            }.multilineTextAlignment(.center).padding(.horizontal, Spacing.xl).padding(.vertical, Spacing.lg)
                .frame(maxWidth: .infinity, alignment: .top)
        }
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
    @State private var purchase = false
    @Environment(LearningStore.self) private var store
    let scene: Scene
    @State private var session: PracticeSelection?
    var phrases: [Phrase] { store.phrases.filter { $0.scene == scene.id } }
    private var practicePhrases: [Phrase] {
        SessionPlanner.queue(phrases: phrases.filter { purchases.allows($0) }, states: store.data.reviews, focus: scene.id, now: .now, limit: 6)
    }
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(scene.prompt).font(.title3).lineSpacing(4)
                PrimaryButton(title: practicePhrases.isEmpty ? "You're up to date" : "Practice this scene") { session = .init(phrases: practicePhrases) }.disabled(practicePhrases.isEmpty)
                NavigationLink { StoryAccessView(scene: scene) } label: { Label("Story practice", systemImage: "mic").frame(minHeight: 44) }
                if !purchases.hasFullAccess {
                    Button("Unlock all practice") { purchase = true }.frame(minHeight: 44).accessibilityIdentifier("unlockScene")
                }
                SectionTitle(title: "Phrases", trailing: "\(phrases.count) phrases")
                LazyVStack(spacing: 0) {
                    ForEach(phrases) { phrase in
                        NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }.buttonStyle(.plain)
                    }
                }
            }
        }.navigationTitle(scene.subtitle).navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $purchase) { PurchaseView() }
            .fullScreenCover(item: $session) { PracticeAccessView(phrases: $0.phrases) }
    }
}
