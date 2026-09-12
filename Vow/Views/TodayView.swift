import SwiftUI

struct PracticeSelection: Identifiable {
    let id = UUID()
    let phrases: [Phrase]
}

struct TodayView: View {
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
            HStack {
                let streak = store.streak(now: now)
                NavigationLink { ProgressViewScreen() } label: {
                    Label("\(streak.current)", systemImage: "flame.fill")
                        .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                }.accessibilityLabel("\(streak.current)-day streak").accessibilityIdentifier("streakSummary")
                Spacer()
                Text("\(store.phrases.isEmpty ? 0 : position + 1) / \(store.phrases.count)")
                    .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                    .accessibilityLabel("Phrase \(position + 1) of \(store.phrases.count)")
                Button { settings = true } label: {
                    Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
                }.accessibilityLabel("Practice settings")
            }.padding(.leading, 28).padding(.trailing, 16).padding(.top, 8)

            if store.phrases.isEmpty {
                ContentUnavailableView("No phrases available", systemImage: "text.book.closed")
            } else {
                TabView(selection: $selectedID) {
                    ForEach(store.phrases) { phrase in
                        FeaturedPhraseView(phrase: phrase, voice: voice).tag(phrase.id)
                    }
                }.tabViewStyle(.page(indexDisplayMode: .never))
            }

            HStack {
                Button { step(-1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .disabled(position == 0).accessibilityLabel("Previous phrase")
                Spacer()
                Text(Scene.all.first { $0.id == store.phrases.first(where: { $0.id == selectedID })?.scene }?.subtitle ?? "Conversation")
                    .font(.caption).foregroundStyle(Palette.secondary).multilineTextAlignment(.center)
                Spacer()
                Button { step(1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .disabled(position >= store.phrases.count - 1).accessibilityLabel("Next phrase")
            }.padding(.horizontal, 24)

            VStack(spacing: 10) {
                PrimaryButton(title: queue.isEmpty ? "You're up to date" : "Practice speaking", symbol: "waveform") {
                    voice.stopPlayback()
                    session = .init(phrases: queue)
                }.disabled(queue.isEmpty).accessibilityIdentifier("dailyPractice")
                if !queue.isEmpty {
                    Text("\(queue.count) phrases").font(.caption).foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }.padding(.horizontal, 28).padding(.top, 10).padding(.bottom, 16)
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
    @ScaledMetric(relativeTo: .largeTitle) private var wordSize = 48.0
    let phrase: Phrase
    @Bindable var voice: VoicePractice
    @State private var showsExample = false
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 24) {
                    Text(phrase.phrase).font(.system(size: wordSize, weight: .regular, design: .serif))
                        .tracking(-1).fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("featuredPhrase")
                    VStack(spacing: 12) {
                        Text(phrase.explanation(in: store.data.meaningLanguage)).font(.title3).lineSpacing(4)
                    }
                    HStack(spacing: 24) {
                        Button { voice.speak(phrase.phrase) } label: { Image(systemName: "speaker.wave.2").frame(width: 48, height: 48) }
                            .accessibilityLabel("Hear phrase")
                        Button { store.toggleSaved(phrase.id) } label: {
                            Image(systemName: store.data.saved.contains(phrase.id) ? "bookmark.fill" : "bookmark").frame(width: 48, height: 48)
                        }.accessibilityLabel(store.data.saved.contains(phrase.id) ? "Unsave featured phrase" : "Save featured phrase")
                        NavigationLink { PhraseDetailView(phrase: phrase) } label: { Image(systemName: "info.circle").frame(width: 48, height: 48) }
                            .accessibilityLabel("Phrase details")
                    }.font(.title3).buttonStyle(PressStyle()).foregroundStyle(Palette.accent)
                    Button(showsExample ? "Hide example" : "Show example") { showsExample.toggle() }
                        .font(.subheadline).frame(minHeight: 44)
                    if showsExample {
                        Text("“\(phrase.reply)”").font(.system(.title3, design: .serif)).lineSpacing(5)
                            .accessibilityIdentifier("featuredExample")
                    }
                    if let message = voice.message { Text(message).font(.caption).foregroundStyle(Palette.secondary) }
                }.multilineTextAlignment(.center).padding(.horizontal, 32).padding(.vertical, 28)
                    .frame(maxWidth: .infinity).frame(minHeight: geometry.size.height)
            }
        }
    }
}

struct ScenesView: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: 24) {
                (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 14)) : AnyLayout(HStackLayout(alignment: .top, spacing: 14))) {
                    VStack(spacing: 14) { tile(0); tile(2) }
                    VStack(spacing: 14) { tile(1); tile(3) }
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
            VStack(alignment: .leading, spacing: 24) {
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
