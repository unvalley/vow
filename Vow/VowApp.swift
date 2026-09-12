import SwiftUI

@main
struct VowApp: App {
    @State private var purchases = PurchaseStore()
    @State private var store: LearningStore
    init() {
        VoicePractice.reclaimAbandonedRecordings()
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        let testFile = URL.applicationSupportDirectory.appending(path: "Verve-UI-tests/learning.json")
        if args.contains("--reset-ui-tests") { try? FileManager.default.removeItem(at: testFile) }
        _store = State(initialValue: LearningStore(file: args.contains("--ui-tests") ? testFile : nil))
        #else
        _store = State(initialValue: LearningStore())
        #endif
    }
    var body: some SwiftUI.Scene {
        WindowGroup { RootView().environment(store).environment(purchases).task { await purchases.start() } }
    }
}

struct RootView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.scenePhase) private var scenePhase
    @Environment(LearningStore.self) private var store
    @State private var tab = 0
    var body: some View {
        @Bindable var store = store
        TabView(selection: $tab) {
            NavigationStack { TodayView() }.tabItem { Label("Today", systemImage: "sun.max") }.tag(0)
            NavigationStack { LibraryView() }.tabItem { Label("Phrases", systemImage: "rectangle.stack") }.tag(1)
            NavigationStack { ProgressViewScreen() }.tabItem { Label("Practice", systemImage: "chart.xyaxis.line") }.tag(2)
        }.tint(store.data.accentColor.color)
            .environment(\.appAccent, store.data.accentColor)
            .onChange(of: scenePhase) { _, phase in if phase == .active { Task { await purchases.refresh() } } }
            .alert("Progress needs attention", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("Try saving again") { store.errorMessage = nil; store.persist() }
                Button("Dismiss", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
    }
}
