import SwiftUI

struct MemoryReviewView: View {
    var initialPhraseID: String? = nil
    @State private var didSelectInitialPhrase = false
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @Environment(\.appAccent) private var accent
    @State private var now = Date.now
    @State private var selectedID: String?
    @State private var revealed = false
    @State private var voice = VoicePractice()

    private var available: [Phrase] { store.phrases.filter { purchases.allows($0) } }
    private var states: [String: MemoryReview] { store.data.memoryReviews ?? [:] }
    private var queue: [Phrase] {
        MemoryScheduler.queue(phrases: available, states: states, focus: store.data.focus, now: now, limit: available.count,
                              dailyNewLimit: store.data.newPhrasesPerDay)
    }
    private var progress: DailyLearningProgress {
        DailyLearningProgress(phrases: available, states: states, goal: store.data.newPhrasesPerDay, now: now)
    }
    private var phrase: Phrase? { available.first { $0.id == selectedID } }
    private var nextDue: Date? { available.compactMap { states[$0.id]?.due }.min() }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("\(min(progress.introduced, progress.target)) / \(progress.target) new · \(progress.dueReviews) reviews due")
                        .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                        .accessibilityIdentifier("sessionDailyProgress")
                    LearningProgressTrack(completed: progress.introduced, total: progress.target)
                }.padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.md)
                    .frame(maxWidth: 680)
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: Spacing.lg) {
                            Color.clear.frame(height: 0).id("cardTop")
                            if let phrase {
                                VStack(alignment: .leading, spacing: Spacing.lg) {
                                    Text(states[phrase.id] == nil ? "New phrase" : "Due for review")
                                        .font(Typography.context).foregroundStyle(Palette.secondary)
                                    Text(phrase.phrase).font(Typography.phrase)
                                        .fixedSize(horizontal: false, vertical: true)
                                        .accessibilityIdentifier("memoryPhrase")
                                    if revealed {
                                        VStack(alignment: .leading, spacing: Spacing.md) {
                                            Text(phrase.explanation(in: store.data.meaningLanguage))
                                                .font(Typography.meaning).accessibilityIdentifier("memoryMeaning")
                                            PhraseExamples(phrase: phrase)
                                            Button("Listen", systemImage: "speaker.wave.2") { voice.speak(phrase.phrase) }
                                                .font(Typography.control).frame(minHeight: 44)
                                        }.transition(.opacity)
                                    } else {
                                        Text("Recall the meaning.")
                                            .font(.subheadline).foregroundStyle(Palette.secondary)
                                    }
                                }.padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 28))
                                    .id(phrase.id)
                                    .transition(reduceMotion ? .opacity : .asymmetric(
                                        insertion: .opacity.combined(with: .offset(x: 16)),
                                        removal: .opacity.combined(with: .offset(x: -8))))
                                if typeSize.isAccessibilitySize { controls(for: phrase) }
                            } else {
                                completion
                            }
                        }.padding(.horizontal, Spacing.lg).padding(.bottom, Spacing.lg)
                            .frame(maxWidth: 680).frame(maxWidth: .infinity)
                    }
                    .onChange(of: selectedID) { _, _ in
                        // Each new prompt starts at its heading, even after a long answer.
                        withTransaction(Transaction(animation: nil)) { proxy.scrollTo("cardTop", anchor: .top) }
                    }
                }
            }
            .background { ReadingBackground() }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let phrase, !typeSize.isAccessibilitySize {
                    controls(for: phrase)
                        .padding(Spacing.lg).frame(maxWidth: 680).frame(maxWidth: .infinity)
                        .background(Palette.paper)
                }
            }
            .navigationTitle("Today's learning").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }.accessibilityIdentifier("closeMemory")
                }
            }
        }
        .onAppear {
            if !didSelectInitialPhrase {
                now = .now
                selectedID = queue.first(where: { $0.id == initialPhraseID })?.id
                didSelectInitialPhrase = true
            }
            refresh()
        }
        .onChange(of: purchases.hasFullAccess) { _, _ in
            voice.stopPlayback()
            if phrase == nil { selectedID = nil; revealed = false; refresh() }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { refresh() } else { voice.stopPlayback() }
        }
        .onReceive(Timer.publish(every: 30, on: .main, in: .common).autoconnect()) { _ in refresh() }
        .onDisappear { voice.clear() }
    }

    @ViewBuilder private func controls(for phrase: Phrase) -> some View {
        VStack(spacing: Spacing.sm) {
            if revealed {
                Text("How well did you remember?")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.sm), count: typeSize.isAccessibilitySize ? 1 : 2), spacing: Spacing.sm) {
                    ForEach(MemoryRating.allCases, id: \.self) { rating in
                        let next = MemoryScheduler.review(states[phrase.id], rating: rating, now: now)
                        Button { rate(phrase, rating) } label: {
                            HStack(spacing: Spacing.xs) {
                                Text(rating.title).font(Typography.control)
                                Spacer(minLength: 0)
                                Text(MemoryScheduler.intervalLabel(until: next.due, now: now))
                                    .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                            }.padding(.horizontal, Spacing.md).padding(.vertical, Spacing.sm)
                                .frame(maxWidth: .infinity, minHeight: 52)
                                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(PressStyle()).accessibilityIdentifier("memoryRate-\(rating.rawValue)")
                    }
                }
            } else {
                PrimaryButton(title: "Show meaning & examples") {
                    now = .now
                    withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) { revealed = true }
                }.accessibilityIdentifier("revealMemory")
            }
        }
    }

    private var completion: some View {
        VStack(spacing: Spacing.lg) {
            CompletionMark()
            Text("Today's learning complete").font(Typography.phrase)
            Text("\(progress.introduced) new expressions today")
                .font(.title3.monospacedDigit()).foregroundStyle(accent.color)
            if let nextDue, nextDue > now {
                Text("Next review: \(nextDue.formatted(.dateTime.month(.abbreviated).day().hour().minute()))")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                    .accessibilityIdentifier("nextMemoryReview")
            }
            Text(progress.unseen == 0 ? "Keep returning for your reviews." : "Your next new expressions arrive tomorrow.")
                .font(.subheadline).foregroundStyle(Palette.secondary)
            PrimaryButton(title: "Done", symbol: "checkmark") { dismiss() }
                .accessibilityIdentifier("finishMemory")
        }.multilineTextAlignment(.center).padding(.vertical, Spacing.xl)
    }

    private func rate(_ phrase: Phrase, _ rating: MemoryRating) {
        guard revealed, selectedID == phrase.id, purchases.allows(phrase) else { return }
        voice.stopPlayback()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) {
            revealed = false
            store.rateMemory(phrase, rating)
            now = .now
            selectedID = queue.first?.id
        }
    }

    private func refresh() {
        now = .now
        // Keep the current card stable when another review becomes due.
        if selectedID == nil { selectedID = queue.first?.id; revealed = false }
    }
}
