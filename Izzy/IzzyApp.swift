import SwiftUI

@main
struct IzzyApp: App {
    @State private var purchases = PurchaseStore()
    @State private var listening = ListeningPlayer()
    @State private var reminders: ReviewReminderCenter
    @State private var store: LearningStore
    init() {
        let reminderCenter = ReviewReminderCenter()
        reminderCenter.installDelegate()
        _reminders = State(initialValue: reminderCenter)
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        let testFile = URL.applicationSupportDirectory.appending(path: "Izzy-UI-tests/learning.json")
        if args.contains("--reset-ui-tests") { try? FileManager.default.removeItem(at: testFile) }
        let learningStore = LearningStore(file: args.contains("--ui-tests") ? testFile : nil)
        // The UI-test store keeps its Japanese default unless a test opts into the device language.
        if !args.contains("--ui-tests") || args.contains("--locale-language") {
            learningStore.configureDefaultLanguage(japanese: Self.prefersJapanese)
        }
        if args.contains("--ui-tests"), !args.contains("--choose-daily-goal"), !args.contains("--show-onboarding"), learningStore.data.dailyNewGoal == nil {
            learningStore.configureDailyGoal(5)
        }
        if args.contains("--ui-tests"), args.contains("--reset-ui-tests"), args.contains("--stats-fixture") {
            Self.seedStats(in: learningStore)
        }
        _store = State(initialValue: learningStore)
        #else
        let learningStore = LearningStore()
        learningStore.configureDefaultLanguage(japanese: Self.prefersJapanese)
        _store = State(initialValue: learningStore)
        #endif
    }
    /// Japanese devices start with Japanese explanations; every other language starts with Easy English.
    private static var prefersJapanese: Bool { Bundle.main.preferredLocalizations.first == "ja" }
    #if DEBUG
    /// Test-only records in the isolated UI-test store; never touches real progress.
    private static func seedStats(in store: LearningStore) {
        let now = Date.now
        let calendar = Calendar.current
        let phrases = Array(store.phrases.prefix(10))
        guard phrases.count == 10 else { return }
        func date(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now)! }
        for offset in -6...0 {
            let phrase = phrases[offset + 6]
            store.rateMemory(phrase, .good, now: date(offset))
            if offset.isMultiple(of: 2) { store.rate(phrase, .effort, mode: "spoken", now: date(offset)) }
        }
        for offset in [-40, -39, -33, -18] { store.rateMemory(phrases[7], .good, now: date(offset)) }
        store.rateMemory(phrases[8], .easy, now: date(-2))
        if let idiom = store.phrases.first(where: \.isIdiom) { store.rateMemory(idiom, .good, now: now) }
        store.finishRehearsal(now: date(-3))
        store.finishRehearsal(now: date(-1))
    }
    #endif
    private var preferredColorScheme: ColorScheme? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--design-dark") { return .dark }
        #endif
        return store.data.themeChoice.colorScheme
    }
    var body: some SwiftUI.Scene {
        WindowGroup {
            RootView().environment(listening).environment(store).environment(purchases).environment(reminders)
                .task { await purchases.start() }
                .preferredColorScheme(preferredColorScheme)
        }
    }
}

struct RootView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.scenePhase) private var scenePhase
    @Environment(LearningStore.self) private var store
    @Environment(ReviewReminderCenter.self) private var reminders
    @Environment(ListeningPlayer.self) private var listening
    @State private var listeningDetails = false
    @State private var tab = 0
    private var reminderInput: ReviewReminderInput {
        .init(preferences: store.data.reminderPreferences,
              reviews: store.data.memoryReviews ?? [:],
              allowedIDs: Set(store.phrases.filter { purchases.allows($0) }.map(\.id)),
              japanese: store.data.meaningLanguage == .japanese)
    }
    var body: some View {
        Group {
            if store.data.needsOnboarding && !choosingDailyGoal {
                OnboardingView()
            } else {
                mainTabs
            }
        }
        .environment(\.appAccent, store.data.accentColor)
            .environment(\.phraseTypeface, store.data.typeface(fullAccess: purchases.hasFullAccess))
            .onOpenURL { if $0 == WidgetSharing.todayURL { tab = 0 } }
            // A cold launch never crosses into .active, so the first open is recorded here.
            .task { openedApp() }
    }
    /// One open per foreground, with the configuration it ran under recorded once a day
    /// so retention can be read against the settings someone actually chose.
    private func openedApp() {
        Analytics.shared.record(.appOpen)
        Analytics.shared.recordSettings(Analytics.settingsProperties(store.data, fullAccess: purchases.hasFullAccess))
        Analytics.shared.flush()
    }
    private var choosingDailyGoal: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("--choose-daily-goal")
        #else
        false
        #endif
    }
    /// Tabs show only their icon. The tab button reads its name from the image, so the image carries it.
    private static func tabIcon(_ symbol: String, _ name: String.LocalizationValue) -> Image {
        let image = UIImage(systemName: symbol) ?? UIImage()
        image.accessibilityLabel = String(localized: name)
        return Image(uiImage: image)
    }
    private var mainTabs: some View {
        TabView(selection: $tab) {
            NavigationStack { TodayView() }.safeAreaInset(edge: .bottom, spacing: 0) { ListeningMiniPlayer { listeningDetails = true } }.tint(Palette.ink).tabItem { Self.tabIcon("house.fill", "Home") }.tag(0)
            NavigationStack { LibraryView() }.safeAreaInset(edge: .bottom, spacing: 0) { ListeningMiniPlayer { listeningDetails = true } }.tint(Palette.ink).tabItem { Self.tabIcon("rectangle.stack.fill", "Phrases") }.tag(1)
            SettingsView(inTab: true).safeAreaInset(edge: .bottom, spacing: 0) { ListeningMiniPlayer { listeningDetails = true } }.tint(Palette.ink).tabItem { Self.tabIcon("gearshape.fill", "Settings") }.tag(2)
        }.tint(store.data.accentColor.color)
            .environment(\.appAccent, store.data.accentColor)
            .environment(\.phraseTypeface, store.data.typeface(fullAccess: purchases.hasFullAccess))
            .sheet(isPresented: Binding(get: { store.data.needsDailyGoal }, set: { _ in })) {
                NavigationStack { DailyGoalView(isInitial: true) }.interactiveDismissDisabled()
            }
            .sheet(isPresented: $listeningDetails) { ListeningView() }
            .onChange(of: purchases.hasFullAccess) { _, _ in
                listening.restrict(to: Set(store.phrases.filter { purchases.allows($0) }.map(\.id)))
            }
            .onChange(of: reminderInput, initial: true) { _, input in reminders.update(input) }
            .onChange(of: WidgetInput(store: store, purchased: purchases.hasFullAccess), initial: true) { _, _ in
                WidgetBridge.update(store: store, purchased: purchases.hasFullAccess)
            }
            .onChange(of: reminders.reviewRequest) { _, request in if request != nil { tab = 0 } }
            .closesForReviewRequest($listeningDetails)
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    reminders.update(reminderInput)
                    Task { await purchases.refresh() }
                    openedApp()
                }
                // Leaving the foreground is the moment a session's events are complete.
                if phase == .background { Analytics.shared.flush() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in reminders.update(reminderInput) }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in reminders.update(reminderInput) }
            .alert("Progress needs attention", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("Try saving again") { store.errorMessage = nil; store.persist() }
                Button("Dismiss", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
    }
}
