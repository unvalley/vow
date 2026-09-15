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
    /// Exams in the order Japanese learners reach for them; CEFR is the level itself.
    private let scales: [DifficultyScale] = [.toeic, .eiken, .ielts, .toefl]

    var body: some View {
        List {
            Section {
                Text("Levels estimate how hard each taught meaning is. Exam scores are rough references, not conversions.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityIdentifier("difficultyIntroduction")
            }
            // One row per level: the level and its name, then every exam reference on one line.
            Section {
                ForEach(PhraseDifficulty.allCases, id: \.self) { level in
                    VStack(alignment: .leading, spacing: Spacing.xxs) {
                        HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                            Text(verbatim: level.rawValue).font(Typography.section.monospacedDigit())
                            Text(LocalizedStringKey(level.title)).font(.subheadline)
                        }
                        Text(verbatim: references(for: level))
                            .font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }.padding(.vertical, Spacing.xxs)
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("difficultyLevel-\(level.rawValue)")
                }
            }
            Section {
                DisclosureGroup("Sources") {
                    Text("TOEIC adds ETS's Listening and Reading minimums. EIKEN shows approximate grades. The collection spans A1–C1.")
                        .font(.caption).foregroundStyle(Palette.secondary)
                    Link("TOEIC and CEFR (ETS)", destination: URL(string: "https://www.eu.ets.org/content/dam/ets-org/eu/pdfs/toeic/mapping-cefr-toeic-listening-reading-test.pdf")!)
                    Link("EIKEN grades", destination: URL(string: "https://www.eiken.or.jp/eiken/result/criteria/")!)
                    Link("IELTS and CEFR", destination: URL(string: "https://ielts.org/organisations/ielts-for-organisations/compare-ielts/ielts-and-the-cefr")!)
                    Link("TOEFL iBT score scale", destination: URL(string: "https://www.ets.org/toefl/institutions/ibt/score-scale-update.html")!)
                }.font(.subheadline)
            }
        }.scrollContentBackground(.hidden).background { ReadingBackground() }
            .foregroundStyle(Palette.ink)
            .multilineTextAlignment(.leading)
            .navigationTitle("Difficulty guide").navigationBarTitleDisplayMode(.inline)
    }

    /// "TOEIC 550–780 · 英検 2級 · IELTS 4.0–5.0 · TOEFL 3–3.5"; exams without a band for the level are left out.
    private func references(for level: PhraseDifficulty) -> String {
        scales.compactMap { scale in level.reference(for: scale).map { "\(scale.shortTitle) \($0)" } }
            .joined(separator: " · ")
    }
}
