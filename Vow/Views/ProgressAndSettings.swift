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
                            Text(purchases.hasFullAccess ? "Purchased" : "Unlock all phrases")
                            Spacer()
                            Image(systemName: purchases.hasFullAccess ? "checkmark.circle.fill" : "chevron.right")
                        }
                    }.accessibilityIdentifier("completeSettings")
                    Button("Restore purchases") { Task { await purchases.restore(); purchase = true } }
                        .disabled(purchases.isBusy).accessibilityIdentifier("settingsRestore")
                }
                Section("Appearance") {
                    NavigationLink { TodayBackgroundSettingsView() } label: {
                        LabeledContent("Today background", value: store.data.backgroundChoice.title)
                    }.accessibilityIdentifier("todayBackground")
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
                Section("Learning plan") {
                    NavigationLink { DailyGoalView() } label: {
                        LabeledContent("Daily learning", value: "\(store.data.newPhrasesPerDay) new / day")
                    }.accessibilityIdentifier("dailyGoalSettings")
                }
                Section {
                    Toggle("Show meaning & examples by default", isOn: Binding(get: { store.data.showsAnswerByDefault }, set: { store.configure(showAnswerByDefault: $0) }))
                        .accessibilityIdentifier("defaultAnswer")
                } header: {
                    Text("Today")
                } footer: {
                    Text("Choose what appears when you open a phrase. You can still tap to show or hide it on Today.")
                }
                ReviewReminderSettingsSection()
                Section("Difficulty") {
                    NavigationLink { DifficultySettingsView() } label: {
                        LabeledContent("Difficulty display", value: store.data.difficultyDisplay.title)
                    }.accessibilityIdentifier("difficultySettings")
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

struct DailyGoalView: View {
    var isInitial = false
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appAccent) private var accent
    @State private var count = 5
    private var unseen: Int {
        store.phrases.filter { purchases.allows($0) && store.data.memoryReviews?[$0.id] == nil }.count
    }

    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Your daily pace").font(Typography.phrase)
                Text("New expressions per day")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 84))], spacing: Spacing.sm) {
                    ForEach([3, 5, 10, 15, 20], id: \.self) { option in
                        Button { count = option } label: {
                            VStack(spacing: Spacing.xs) {
                                Text("\(option)").font(.title.monospacedDigit())
                                Image(systemName: count == option ? "checkmark.circle.fill" : "circle")
                                    .font(.caption).accessibilityHidden(true)
                            }.padding(.vertical, Spacing.md)
                                .frame(maxWidth: .infinity, minHeight: 80)
                                .background(count == option ? accent.soft : Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                        }.buttonStyle(PressStyle()).foregroundStyle(count == option ? accent.color : Palette.ink)
                            .accessibilityLabel("\(option) new phrases per day")
                            .accessibilityAddTraits(count == option ? [.isSelected] : [])
                            .accessibilityIdentifier("dailyGoal-\(option)")
                    }
                }
                Stepper("New phrases per day: \(count)", value: $count, in: 1...50)
                    .font(.subheadline).monospacedDigit().accessibilityIdentifier("dailyGoalCount")
                Text("Phrasal verbs and idioms share this goal. Due reviews are added separately.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                Divider()
                if unseen > 0 {
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text("About \((unseen + count - 1) / count) \((unseen + count - 1) / count == 1 ? "day" : "days")")
                            .font(.title2.monospacedDigit())
                        Text("For a first pass through your \(unseen) remaining expressions. Reviews continue after that.")
                            .font(.subheadline).foregroundStyle(Palette.secondary)
                    }
                } else {
                    Text("You've studied every available expression. Your due reviews will keep appearing each day.")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                }
                PrimaryButton(title: isInitial ? "Set daily goal" : "Save daily goal") {
                    store.configureDailyGoal(count)
                    dismiss()
                }.accessibilityIdentifier("saveDailyGoal")
                Text("Change your pace anytime. Your progress stays with you.")
                    .font(.caption).foregroundStyle(Palette.secondary)
            }
        }.foregroundStyle(Palette.ink).tint(accent.color)
            .navigationTitle("Daily learning").navigationBarTitleDisplayMode(.inline)
            .onAppear { count = store.data.newPhrasesPerDay }
            .sensoryFeedback(.selection, trigger: count)
    }
}

private struct TodayBackgroundSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    private var selected: TodayBackground { store.data.backgroundChoice }

    var body: some View {
        List {
            Section {
                ForEach(TodayBackground.allCases, id: \.self) { choice in
                    Button { store.configure(background: choice) } label: {
                        HStack(spacing: Spacing.md) {
                            Image(choice.imageName).resizable().scaledToFit()
                                .frame(width: 64, height: 64)
                                .accessibilityHidden(true)
                            Text(choice.title).foregroundStyle(Palette.ink)
                            Spacer()
                            Image(systemName: selected == choice ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected == choice ? accent.color : Palette.secondary)
                                .accessibilityHidden(true)
                        }.padding(.vertical, Spacing.xxs)
                    }.accessibilityIdentifier("background-\(choice.rawValue)")
                        .accessibilityAddTraits(selected == choice ? [.isSelected] : [])
                }
            } footer: {
                Text("Shown softly behind your daily phrases.")
            }

            Section {
                Image(selected.imageName).resizable().scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: 240)
                    .accessibilityLabel(selected.title)
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text(selected.credit).font(.subheadline).foregroundStyle(Palette.ink)
                    Link("View source", destination: selected.sourceURL)
                        .font(.subheadline).frame(minHeight: 44)
                }
            }
        }
        .scrollContentBackground(.hidden).background { ReadingBackground() }
        .navigationTitle("Today background").navigationBarTitleDisplayMode(.inline)
    }
}

private extension TodayBackground {
    var credit: String {
        switch self {
        case .mountains: "Photo by m wrona · Unsplash"
        case .ocean: "Photo by Hannah Reding · Unsplash"
        case .waterLilies: "Claude Monet, Water Lilies, 1906\nArt Institute of Chicago"
        }
    }

    var sourceURL: URL {
        switch self {
        case .mountains: URL(string: "https://unsplash.com/photos/JG7KBXn-_Mc")!
        case .ocean: URL(string: "https://unsplash.com/photos/yVl4V7dUS2Y")!
        case .waterLilies: URL(string: "https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Water_Lilies_-_1906,_Ryerson.jpg")!
        }
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
