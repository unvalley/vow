import SwiftUI

struct PhraseDifficultyLabel: View {
    @Environment(LearningStore.self) private var store
    let difficulty: PhraseDifficulty

    var body: some View {
        Text(difficulty.label(for: store.data.difficultyDisplay))
            .font(.caption).foregroundStyle(Palette.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel("Estimated difficulty: \(difficulty.label(for: store.data.difficultyDisplay))")
    }
}

struct PhraseDifficultyButton: View {
    let phrase: Phrase
    @State private var showsGuide = false

    var body: some View {
        if let difficulty = phrase.difficulty {
            Button { showsGuide = true } label: {
                HStack(spacing: Spacing.xs) {
                    PhraseDifficultyLabel(difficulty: difficulty)
                    Image(systemName: "info.circle").font(.caption).foregroundStyle(Palette.secondary)
                }.frame(minHeight: 44)
            }.buttonStyle(PressStyle())
                .accessibilityIdentifier("phraseDifficulty")
                .accessibilityHint("Shows difficulty levels and exam score references")
                .sheet(isPresented: $showsGuide) {
                    NavigationStack {
                        DifficultyGuideView()
                            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showsGuide = false } } }
                    }
                }
                .closesForReviewRequest($showsGuide)
        }
    }
}

struct DifficultySettingsView: View {
    @Environment(LearningStore.self) private var store

    var body: some View {
        Form {
            Section {
                Picker("Display difficulty as", selection: Binding(get: { store.data.difficultyDisplay }, set: { store.configure(difficultyScale: $0) })) {
                    ForEach(DifficultyScale.allCases, id: \.self) { scale in
                        Text(LocalizedStringKey(scale.title)).tag(scale).accessibilityIdentifier("difficultyScale-\(scale.rawValue)")
                    }
                }.pickerStyle(.inline).labelsHidden()
            } footer: {
                Text("CEFR is the shared level. Add a familiar exam scale if you prefer. This choice is independent of your meaning language.")
            }
            Section { NavigationLink("About difficulty levels") { DifficultyGuideView() } }
        }.scrollContentBackground(.hidden).background { ReadingBackground() }
            .navigationTitle("Difficulty display").navigationBarTitleDisplayMode(.inline)
    }
}

struct DifficultyGuideView: View {
    var body: some View {
        List {
            Section {
                Text("Vow estimates the difficulty of the meaning and usage taught in each phrase. Levels help you choose what to learn; they are not official exam ratings or a prediction of your score.")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier("difficultyIntroduction")
            }
            ForEach(PhraseDifficulty.allCases, id: \.self) { level in
                Section {
                    Text(LocalizedStringKey(level.description)).font(.subheadline)
                    ForEach(DifficultyScale.allCases.filter { $0 != .cefr }, id: \.self) { scale in
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(LocalizedStringKey(scale.title)).font(.caption).foregroundStyle(Palette.secondary)
                            if let reference = level.reference(for: scale) {
                                Text(verbatim: "≈\(reference)").font(.subheadline)
                            } else {
                                Text("No comparison available").font(.subheadline)
                            }
                        }
                    }
                } header: { Text(verbatim: "\(level.rawValue) · ") + Text(LocalizedStringKey(level.title)) }
            }
            Section("Using the references") {
                Text("Exam ranges are broad CEFR references, not direct conversions between tests. IELTS boundaries overlap. TOEFL uses the 1–6 scale introduced on January 21, 2026. EIKEN is shown as approximate grade targets, not CSE scores or predicted passes. 準2級 and 準2級プラス are both grouped under A2; the CEFR level reported depends on the grade taken and your scores.")
                Text("The current phrase collection spans A1–C1. A different meaning of the same phrase may have a different level.")
            }.font(.subheadline)
            Section("Sources · September 2026") {
                Link("IELTS and CEFR", destination: URL(string: "https://ielts.org/organisations/ielts-for-organisations/compare-ielts/ielts-and-the-cefr")!)
                Link("TOEFL iBT score scale", destination: URL(string: "https://www.ets.org/toefl/institutions/ibt/score-scale-update.html")!)
                Link("EIKEN grades", destination: URL(string: "https://www.eiken.or.jp/eiken/result/criteria/")!)
            }
        }.scrollContentBackground(.hidden).background { ReadingBackground() }
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.leading)
            .navigationTitle("Difficulty guide").navigationBarTitleDisplayMode(.inline)
    }
}
