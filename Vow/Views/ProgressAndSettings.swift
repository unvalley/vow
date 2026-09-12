import SwiftUI

struct ProgressViewScreen: View {
    @Environment(\.appAccent) private var accent
    @Environment(LearningStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var now = Date.now
    @ScaledMetric(relativeTo: .caption) private var dayStatusHeight = 20.0
    private var calendar: Calendar { .autoupdatingCurrent }
    private var statLayout: AnyLayout {
        typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(alignment: .leading, spacing: Spacing.md)) : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.lg))
    }
    private var days: [Date] { (0..<7).compactMap { calendar.date(byAdding: .day, value: $0 - 6, to: calendar.startOfDay(for: now)) } }
    var body: some View {
        let streak = store.streak(now: now, calendar: calendar)
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                statLayout {
                    stat("\(streak.current)", "Current streak")
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Current streak, \(streak.current) \(streak.current == 1 ? "day" : "days")")
                        .accessibilityIdentifier("currentStreak")
                    stat("\(streak.longest)", "Best streak")
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("Best streak, \(streak.longest) \(streak.longest == 1 ? "day" : "days")")
                        .accessibilityIdentifier("bestStreak")
                }.foregroundStyle(Palette.ink)
                statLayout {
                    stat("\(store.data.events.count)", "Replies reviewed")
                    stat("\(store.data.reviews.count)", "Phrases practiced")
                    stat("\(store.data.rehearsalCount)", "Stories retold")
                }
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    SectionTitle(title: "Last 7 days")
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.xs), count: typeSize.isAccessibilitySize ? 3 : 7), spacing: Spacing.md) {
                        ForEach(days, id: \.self) { day in
                            let active = streak.activeDays.contains(day)
                            VStack(spacing: Spacing.xs) {
                                Text(day.formatted(.dateTime.weekday(.narrow))).font(.caption).foregroundStyle(Palette.secondary)
                                Text(day.formatted(.dateTime.day())).font(.body.monospacedDigit())
                                    .frame(maxWidth: .infinity, minHeight: 44)
                                    .foregroundStyle(active ? accent.onFill : Palette.ink)
                                    .background(active ? accent.fill : Palette.paper, in: RoundedRectangle(cornerRadius: 12))
                                Image(systemName: active ? "checkmark" : "minus").font(.caption)
                                    .foregroundStyle(active ? accent.color : Palette.secondary)
                                    .frame(height: dayStatusHeight)
                            }.accessibilityElement(children: .ignore)
                                .accessibilityLabel("\(day.formatted(.dateTime.month().day())), \(active ? "Practiced" : "No practice")")
                        }
                    }
                }.padding(Spacing.lg).background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
                SectionTitle(title: "Upcoming reviews")
                if store.data.reviews.isEmpty {
                    Text("No reviews yet.").foregroundStyle(Palette.secondary)
                } else {
                    let upcoming = store.phrases.filter { store.data.reviews[$0.id] != nil }.sorted { (store.data.reviews[$0.id]?.due ?? .distantPast) < (store.data.reviews[$1.id]?.due ?? .distantPast) }
                    ForEach(upcoming.prefix(8)) { phrase in
                        HStack(spacing: Spacing.sm) {
                            Text(phrase.phrase).font(Typography.compactPhrase)
                            Spacer()
                            if let date = store.data.reviews[phrase.id]?.due {
                                Text(date <= now ? "Ready now" : date.formatted(.relative(presentation: .named))).font(.caption).foregroundStyle(Palette.secondary)
                            }
                        }.padding(.vertical, Spacing.xxs)
                    }
                }
                if !store.data.events.isEmpty {
                    let spoken = store.data.events.filter { $0.mode == "spoken" }.count
                    Text("\(spoken) spoken · \(store.data.events.count - spoken) typed").font(.caption).foregroundStyle(Palette.secondary).lineSpacing(5)
                }
                NavigationLink { MethodView() } label: { Label("Learning approach", systemImage: "book.closed").frame(minHeight: 44) }
            }
        }.navigationTitle("Practice").navigationBarTitleDisplayMode(.inline)
            .onAppear { now = .now }
            .onChange(of: scenePhase) { _, phase in if phase == .active { now = .now } }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in now = .now }
            .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in now = .now }
    }
    private func stat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) { Text(value).font(Typography.counter); Text(label).font(.caption).foregroundStyle(Palette.secondary) }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SettingsView: View {
    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @State private var purchase = false
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("vow Complete") {
                    Button { purchase = true } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(purchases.hasFullAccess ? "Purchased" : "Unlock all practice")
                            Spacer()
                            Image(systemName: purchases.hasFullAccess ? "checkmark.circle.fill" : "chevron.right")
                        }
                    }.accessibilityIdentifier("completeSettings")
                    Button("Restore purchases") { Task { await purchases.restore(); purchase = true } }
                        .disabled(purchases.isBusy).accessibilityIdentifier("settingsRestore")
                }
                Section("Appearance") {
                    Picker("Accent color", selection: Binding(get: { store.data.accentColor }, set: { store.configure(accent: $0) })) {
                        ForEach(AppAccent.allCases, id: \.self) { choice in
                            Label { Text(choice.title) } icon: {
                                Image(uiImage: UIImage(systemName: "circle.fill")!
                                    .withTintColor(UIColor(choice.fill), renderingMode: .alwaysOriginal))
                            }.tag(choice)
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("accentColor")
                        .accessibilityValue(store.data.accentColor.title)
                }
                Section("Meaning language") {
                    Picker("Explain phrases in", selection: Binding(get: { store.data.meaningLanguage }, set: { store.configure(meaningLanguage: $0) })) {
                        ForEach(MeaningLanguage.allCases, id: \.self) { language in
                            Text(language.title).tag(language)
                        }
                    }.pickerStyle(.inline).labelsHidden().tint(accent.color)
                }
                Section("Conversation focus") {
                    Picker("Conversation focus", selection: Binding(get: { store.data.focus }, set: { store.configure(focus: $0) })) {
                        ForEach(Scene.all) { Text($0.subtitle).tag($0.id) }
                    }.pickerStyle(.inline).labelsHidden().tint(accent.color)
                }
                Section("Story practice") {
                    Toggle("Untimed", isOn: Binding(get: { store.data.gentleMode }, set: { store.configure(gentle: $0) })).tint(accent.color)
                    Text("Timers: 60, 45 and 30 seconds.").font(.caption).foregroundStyle(Palette.secondary)
                }
                Section("Privacy") {
                    NavigationLink("Privacy policy") { PrivacyView() }
                    Text("Recordings stay on this device and are deleted when you leave an exercise. Your progress, saved phrases and notes are stored locally.").font(.subheadline)
                }
                Section {
                    Link("Contact support", destination: URL(string: "mailto:studio@unvalley.me")!)
                    NavigationLink("Learning approach") { MethodView() }
                }
            }.scrollContentBackground(.hidden).background { ReadingBackground() }
                .sheet(isPresented: $purchase) { PurchaseView() }
                .tint(Palette.ink).foregroundStyle(Palette.ink).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { store.finishOnboarding(); dismiss() } } }
        }
    }
}

struct MethodView: View {
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                item("Retrieve before you reveal", "Trying to produce a reply gives you a retrieval opportunity. Reading an example and recognizing it is a different task.", "Karpicke & Roediger, 2008", "https://doi.org/10.1126/science.1152408")
                item("Come back after a gap", "Reviews are spaced using your own recall ratings. The spacing principle has research support; this app’s exact intervals are a simple design choice, not a validated optimum.", "Kim & Webb, 2022", "https://doi.org/10.1111/lang.12479")
                item("Say the same thing again", "Retelling gives you another chance to find language for a familiar message. The 60/45/30-second practice adapts the idea of 4/3/2 speaking tasks; the shorter version has not been independently validated.", "de Jong & Perfetti, 2011", "https://doi.org/10.1111/j.1467-9922.2010.00620.x")
                item("Learn a meaning in a situation", "A phrase can have several meanings. Each entry focuses on one sense, its word order, and its conversational use. Examples and explanations were written for vow; this is not a reproduction of the PHaVE list.", "Garnier & Schmitt, 2015", "https://doi.org/10.1177/1362168814559798")
                Text("This is guided solo practice, not a live conversation partner or an automatic pronunciation assessment. Try one phrase in a real conversation, and notice how the other person responds.").font(.body).foregroundStyle(Palette.secondary)
            }
        }.navigationTitle("Learning approach").navigationBarTitleDisplayMode(.inline)
    }
    private func item(_ title: String, _ body: String, _ source: String, _ url: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).font(.headline)
            Text(body).font(.body).foregroundStyle(Palette.secondary)
            if let link = URL(string: url) { Link(source, destination: link).font(.caption).frame(minHeight: 44) }
        }
    }
}
