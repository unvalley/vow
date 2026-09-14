import SwiftUI

struct SettingsView: View {
    @Environment(\.appAccent) private var accent
    @Environment(PurchaseStore.self) private var purchases
    @State private var purchase = false
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Vow Pro") {
                    Button { purchase = true } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(purchases.hasFullAccess ? LocalizedStringKey("Purchased") : LocalizedStringKey("Unlock all phrases"))
                            Spacer()
                            Image(systemName: purchases.hasFullAccess ? "checkmark.circle.fill" : "chevron.right")
                        }
                    }.accessibilityIdentifier("completeSettings")
                    Button("Restore purchases") { Task { await purchases.restore(); purchase = true } }
                        .disabled(purchases.isBusy).accessibilityIdentifier("settingsRestore")
                }
                // Six intent-based groups: what you learn, how you practice, reminders, looks, and about.
                Section {
                    NavigationLink { DailyGoalView() } label: {
                        LabeledContent("Daily learning") { Text("\(store.data.newPhrasesPerDay) new / day") }
                    }.accessibilityIdentifier("dailyGoalSettings")
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("Explain phrases in").font(.subheadline).foregroundStyle(Palette.secondary)
                        Picker("Explain phrases in", selection: Binding(get: { store.data.meaningLanguage }, set: { store.configure(meaningLanguage: $0) })) {
                            ForEach(MeaningLanguage.allCases, id: \.self) { language in
                                Text(LocalizedStringKey(language.title)).tag(language)
                            }
                        }.pickerStyle(.segmented).labelsHidden()
                    }.padding(.vertical, Spacing.xxs)
                    NavigationLink { DifficultySettingsView() } label: {
                        LabeledContent("Difficulty display") { Text(LocalizedStringKey(store.data.difficultyDisplay.title)) }
                    }.accessibilityIdentifier("difficultySettings")
                    Toggle("Show meaning & examples by default", isOn: Binding(get: { store.data.showsAnswerByDefault }, set: { store.configure(showAnswerByDefault: $0) }))
                        .tint(accent.color).accessibilityIdentifier("defaultAnswer")
                } header: {
                    Text("Learning")
                } footer: {
                    Text("You can still tap to show or hide it on Today.")
                }
                Section {
                    Picker("Conversation focus", selection: Binding(get: { store.data.focus }, set: { store.configure(focus: $0) })) {
                        ForEach(Scene.all) { Text(LocalizedStringKey($0.subtitle)).tag($0.id) }
                    }.pickerStyle(.menu).accessibilityIdentifier("conversationFocus")
                        .accessibilityValue(Text(LocalizedStringKey(Scene.all.first { $0.id == store.data.focus }?.subtitle ?? "")))
                    NavigationLink("Reading voice") { SpeechSettingsView() }
                        .accessibilityIdentifier("speechSettings")
                    Toggle("Untimed story practice", isOn: Binding(get: { store.data.gentleMode }, set: { store.configure(gentle: $0) })).tint(accent.color)
                } header: {
                    Text("Practice")
                } footer: {
                    Text("Timers: 60, 45 and 30 seconds.")
                }
                ReviewReminderSettingsSection()
                Section("Appearance") {
                    Picker("Theme", selection: Binding(get: { store.data.themeChoice }, set: { store.configure(theme: $0) })) {
                        ForEach(AppTheme.allCases, id: \.self) { choice in
                            Text(LocalizedStringKey(choice.title)).tag(choice)
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("appTheme")
                        .accessibilityValue(Text(LocalizedStringKey(store.data.themeChoice.title)))
                    NavigationLink { TodayBackgroundSettingsView() } label: {
                        LabeledContent("Today background") { Text(LocalizedStringKey(store.data.backgroundChoice.title)) }
                    }.accessibilityIdentifier("todayBackground")
                    Picker("Accent color", selection: Binding(get: { store.data.accentColor }, set: { store.configure(accent: $0) })) {
                        ForEach(AppAccent.allCases, id: \.self) { choice in
                            Label { Text(LocalizedStringKey(choice.title)) } icon: {
                                Image(uiImage: UIImage(systemName: "circle.fill")!
                                    .withTintColor(UIColor(choice.fill), renderingMode: .alwaysOriginal))
                            }.tag(choice)
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("accentColor")
                        .accessibilityValue(Text(LocalizedStringKey(store.data.accentColor.title)))
                }
                Section {
                    NavigationLink("Privacy policy") { PrivacyView() }
                    Link("Terms of use", destination: AppSupport.termsURL)
                        .accessibilityIdentifier("settingsTerms")
                    NavigationLink("Contact support") { SupportView() }
                        .accessibilityIdentifier("contactSupport")
                    NavigationLink("Learning approach") { MethodView() }
                    LabeledContent("Version", value: AppSupport.versionDescription)
                        .accessibilityIdentifier("appVersion")
                } header: {
                    Text("About")
                } footer: {
                    Text("Recordings stay on this device and are deleted when you leave an exercise. Your progress, saved phrases and notes are stored locally.")
                }
            }.scrollContentBackground(.hidden).background { ReadingBackground() }
                .sheet(isPresented: $purchase) { PurchaseView() }
                .tint(Palette.ink).foregroundStyle(Palette.ink).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { store.finishOnboarding(); dismiss() } } }
        }
    }
}

struct DailyGoalView: View {
    var isInitial = false
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAccent) private var accent
    @State private var count = 5
    /// Three paces cover the range learners actually pick; older custom values stay valid until changed.
    private let presets = [5, 10, 20]

    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    ForEach(presets, id: \.self) { option in
                        Button { count = option } label: {
                            Text("\(option)").font(.title3.monospacedDigit().weight(count == option ? .semibold : .regular))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .selectionSurface(count == option)
                        }.buttonStyle(PressStyle())
                            .accessibilityLabel("\(option) new phrases per day")
                            .accessibilityAddTraits(count == option ? [.isSelected] : [])
                            .accessibilityIdentifier("dailyGoal-\(option)")
                    }
                }
                Text("New expressions per day, phrasal verbs and idioms together. Reviews are added on top.")
                    .font(.footnote).foregroundStyle(Palette.secondary)
                PrimaryButton(title: isInitial ? String(localized: "Set daily goal") : String(localized: "Save daily goal")) {
                    store.configureDailyGoal(count)
                    dismiss()
                }.accessibilityIdentifier("saveDailyGoal")
            }
        }.foregroundStyle(Palette.ink).tint(accent.color)
            .navigationTitle("Daily learning").navigationBarTitleDisplayMode(.inline)
            .onAppear { count = store.data.newPhrasesPerDay }
            .sensoryFeedback(.selection, trigger: count)
    }
}


struct MethodView: View {
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                item("Retrieve before you reveal", "Trying to produce a reply gives you a retrieval opportunity. Reading an example and recognizing it is a different task.", "Karpicke & Roediger, 2008", "https://doi.org/10.1126/science.1152408")
                item("Review the meaning", "In Today, start your daily learning and recall the meaning before revealing the answer. Again brings a phrase back in 10 minutes; Hard, Good and Easy space it farther apart. Each button shows the next interval. Choose 5, 10 or 20 new phrases a day in Daily learning. Due reviews come first and are counted separately. Meaning reviews and speaking practice keep separate schedules.", "Anki: answer buttons", "https://docs.ankiweb.net/studying.html#answer-buttons")
                item("Intervals that adapt", "Meaning reviews use an SM-2-derived schedule: successful recall lengthens the interval, while difficulty reduces future growth. This is not Anki’s FSRS model or an individual prediction of when you will forget.", "SuperMemo: SM-2 algorithm", "https://super-memory.com/english/ol/sm2.htm")
                item("Come back after a gap", "Reviews are spaced using your own recall ratings. The spacing principle has research support; this app’s exact intervals are a simple design choice, not a validated optimum.", "Kim & Webb, 2022", "https://doi.org/10.1111/lang.12479")
                item("Say the same thing again", "Retelling gives you another chance to find language for a familiar message. The 60/45/30-second practice adapts the idea of 4/3/2 speaking tasks; the shorter version has not been independently validated.", "de Jong & Perfetti, 2011", "https://doi.org/10.1111/j.1467-9922.2010.00620.x")
                item("Learn a meaning in a situation", "A phrase can have several meanings. Each entry focuses on one sense, its word order, and its conversational use. Examples and explanations were written for vow; this is not a reproduction of the PHaVE list.", "Garnier & Schmitt, 2015", "https://doi.org/10.1177/1362168814559798")
                Text("This is guided solo practice, not a live conversation partner or an automatic pronunciation assessment. Try one phrase in a real conversation, and notice how the other person responds.").font(.body).foregroundStyle(Palette.secondary)
            }
        }.navigationTitle("Learning approach").navigationBarTitleDisplayMode(.inline)
    }
    private func item(_ title: LocalizedStringKey, _ body: LocalizedStringKey, _ source: String, _ url: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).font(.headline)
            Text(body).font(.body).foregroundStyle(Palette.secondary)
            if let link = URL(string: url) { Link(source, destination: link).font(.caption).frame(minHeight: 44) }
        }
    }
}
