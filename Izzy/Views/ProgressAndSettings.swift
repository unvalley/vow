import SwiftUI

struct SettingsView: View {
    /// Presented as the Settings tab rather than a sheet: no Done button, large title.
    var inTab = false
    @Environment(\.appAccent) private var accent
    @Environment(\.colorScheme) private var scheme
    @Environment(PurchaseStore.self) private var purchases
    @State private var purchase = false
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            Form {
                Section("Izzy Pro") {
                    Button { purchase = true } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(purchases.hasFullAccess ? LocalizedStringKey("Purchased") : LocalizedStringKey("Unlock all phrases"))
                            Spacer()
                            Image(systemName: purchases.hasFullAccess ? "checkmark.circle.fill" : "chevron.right")
                        }
                    }.accessibilityIdentifier("completeSettings")
                    Button("Restore purchases") { Task { await purchases.restore(); purchase = purchases.notice != nil } } // a cancelled sign-in opens nothing
                        .disabled(purchases.isBusy).accessibilityIdentifier("settingsRestore")
                }
                // Intent-based groups: what you learn, reminders, looks, and about.
                Section {
                    // The daily goal is changed from Home's progress count, where it is used; the collection is chosen here.
                    Picker("Phrases to learn", selection: Binding(get: { store.data.homeKindFilter }, set: { store.configure(homeKind: $0) })) {
                        ForEach(PhraseKindFilter.allCases, id: \.self) { Text(LocalizedStringKey($0.title)).tag($0) }
                    }.pickerStyle(.menu).accessibilityIdentifier("phrasesToLearn")
                        .accessibilityValue(Text(LocalizedStringKey(store.data.homeKindFilter.title)))
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
                    NavigationLink("Reading voice") { SpeechSettingsView() }
                        .accessibilityIdentifier("speechSettings")
                    // The interface language is a per-app choice in iOS Settings; the app only links there.
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        Link(destination: url) {
                            LabeledContent("App language") {
                                HStack(spacing: Spacing.xs) {
                                    Text(Locale.current.localizedString(forLanguageCode: Bundle.main.preferredLocalizations.first ?? "en") ?? "")
                                    Image(systemName: "arrow.up.right").font(.caption.weight(.semibold))
                                }
                            }
                        }.accessibilityIdentifier("appLanguage")
                    }
                } header: {
                    Text("Learning")
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
                        LabeledContent("Home background") { Text(LocalizedStringKey(store.data.background(fullAccess: purchases.hasFullAccess).title)) }
                    }.accessibilityIdentifier("todayBackground")
                    NavigationLink { PhraseTypefaceSettingsView() } label: {
                        LabeledContent("Phrase font") { Text(verbatim: store.data.typeface(fullAccess: purchases.hasFullAccess).title) }
                    }.accessibilityIdentifier("phraseTypeface")
                    Picker("Accent color", selection: Binding(get: { store.data.accentColor }, set: { store.configure(accent: $0) })) {
                        ForEach(AppAccent.allCases, id: \.self) { choice in
                            Label { Text(LocalizedStringKey(choice.title)) } icon: {
                                Image(uiImage: choice.swatch(in: scheme))
                            }.tag(choice)
                        }
                    }.pickerStyle(.menu).accessibilityIdentifier("accentColor")
                        .accessibilityValue(Text(LocalizedStringKey(store.data.accentColor.title)))
                }
                Section {
                    Toggle("Share anonymous usage", isOn: Binding(get: { Analytics.shared.isEnabled },
                                                                  set: { Analytics.shared.setEnabled($0) }))
                        .tint(accent.mark).accessibilityIdentifier("shareUsage")
                } header: {
                    Text("Usage data")
                } footer: {
                    Text("Which screens and settings get used, so Izzy can be improved. Sent without an account and with nothing you have written — no phrases, notes or searches.")
                }
                Section {
                    // No preview of our own: the share sheet shows the landing page's social card.
                    ShareLink(item: AppSupport.shareURL) { Text("Share Izzy") }
                        .accessibilityIdentifier("shareIzzy")
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
                }
                #if DEBUG
                Section("Developer") {
                    Toggle("Unlock Pro on this device", isOn: Binding(get: { purchases.debugUnlocked }, set: { purchases.setDebugUnlocked($0) }))
                        .tint(accent.mark).accessibilityIdentifier("debugUnlockPro")
                }
                #endif
            }.scrollContentBackground(.hidden).background { ReadingBackground() }
                .sheet(isPresented: $purchase) { PurchaseView(from: "settings") }
                .closesForReviewRequest($purchase)
                .tint(Palette.ink).foregroundStyle(Palette.ink).navigationTitle("Settings").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    if !inTab { ToolbarItem(placement: .confirmationAction) { Button("Done") { store.finishOnboarding(); dismiss() } } }
                }
        }
    }
}

struct DailyGoalView: View {
    var isInitial = false
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAccent) private var accent
    @State private var count = 5
    /// Set once the stored goal has loaded, so opening the screen does not buzz.
    @State private var loaded = false
    /// Three paces cover the range learners actually pick; older custom values stay valid until changed.
    private let presets = [5, 10, 20]

    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.md) {
                HStack(spacing: Spacing.xs) {
                    ForEach(presets, id: \.self) { option in
                        Button { count = option } label: {
                            // One weight in both states; the surface and color carry the choice.
                            Text("\(option)").font(.title3.monospacedDigit().weight(.medium))
                                .frame(maxWidth: .infinity, minHeight: 48)
                                .selectionSurface(count == option, cornerRadius: Radius.medium)
                        }.buttonStyle(PressStyle())
                            .accessibilityLabel("\(option) new phrases per day")
                            .accessibilityAddTraits(count == option ? [.isSelected] : [])
                            .accessibilityIdentifier("dailyGoal-\(option)")
                    }
                }
                Stepper("Custom: \(count)", value: $count.animation(Motion.snappy), in: 1...50)
                    .font(.subheadline).monospacedDigit().accessibilityIdentifier("dailyGoalCount")
                Text("New expressions per day, phrasal verbs and idioms together. Reviews are added on top.")
                    .font(.footnote).foregroundStyle(Palette.secondary)
                PrimaryButton(title: isInitial ? String(localized: "Set daily goal") : String(localized: "Save daily goal")) {
                    store.configureDailyGoal(count)
                    dismiss()
                }.accessibilityIdentifier("saveDailyGoal")
                if isInitial {
                    Button("Decide later") { store.skipDailyGoal(); dismiss() }
                        .font(Typography.control).frame(maxWidth: .infinity, minHeight: 44).buttonStyle(PressStyle())
                        .accessibilityIdentifier("skipDailyGoal")
                }
            }
        }.foregroundStyle(Palette.ink).tint(accent.color)
            .navigationTitle("Daily learning").navigationBarTitleDisplayMode(.inline)
            .onAppear { count = store.data.newPhrasesPerDay; loaded = true }
            // The trigger only exists once the stored goal has loaded, so loading it is not a "change".
            .sensoryFeedback(.selection, trigger: loaded ? count : nil) { old, _ in old != nil }
    }
}


struct MethodView: View {
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                item("Retrieve before you reveal", "Trying to produce a reply gives you a retrieval opportunity. Reading an example and recognizing it is a different task.", "Karpicke & Roediger, 2008", "https://doi.org/10.1126/science.1152408")
                item("Review the meaning", "In Today, start your daily learning and recall the meaning before revealing the answer. Again brings a phrase back in 10 minutes; Hard, Good and Easy space it farther apart. Each button shows the next interval. Choose 1–50 new phrases a day in Daily learning. Due reviews come first and are counted separately. Meaning reviews and speaking practice keep separate schedules.", "Anki: answer buttons", "https://docs.ankiweb.net/studying.html#answer-buttons")
                item("Intervals that adapt", "Meaning reviews use an SM-2-derived schedule: successful recall lengthens the interval, while difficulty reduces future growth. This is not Anki’s FSRS model or an individual prediction of when you will forget.", "SuperMemo: SM-2 algorithm", "https://super-memory.com/english/ol/sm2.htm")
                item("Come back after a gap", "Reviews are spaced using your own recall ratings. The spacing principle has research support; this app’s exact intervals are a simple design choice, not a validated optimum.", "Kim & Webb, 2022", "https://doi.org/10.1111/lang.12479")
                item("Say the same thing again", "Retelling gives you another chance to find language for a familiar message. The 60/45/30-second practice adapts the idea of 4/3/2 speaking tasks; the shorter version has not been independently validated.", "de Jong & Perfetti, 2011", "https://doi.org/10.1111/j.1467-9922.2010.00620.x")
                item("Learn a meaning in a situation", "A phrase can have several meanings. Each entry focuses on one sense, its word order, and its conversational use. Examples and explanations were written for Izzy; this is not a reproduction of the PHaVE list.", "Garnier & Schmitt, 2015", "https://doi.org/10.1177/1362168814559798")
                Text("This is guided solo practice, not a live conversation partner or an automatic pronunciation assessment. Try one phrase in a real conversation, and notice how the other person responds.").font(.body).foregroundStyle(Palette.secondary)
            }
        }.navigationTitle("Learning approach").navigationBarTitleDisplayMode(.inline)
    }
    private func item(_ title: LocalizedStringKey, _ body: LocalizedStringKey, _ source: String, _ url: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title).font(Typography.section).accessibilityAddTraits(.isHeader)
            Text(body).font(.body).foregroundStyle(Palette.secondary)
            if let link = URL(string: url) { Link(source, destination: link).font(.caption).frame(minHeight: 44) }
        }
    }
}
