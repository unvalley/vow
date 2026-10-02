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
                        Text(verbatim: level.examReferences)
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
}

/// The levels Home learns from: every level, or any mix of the levels the plan opens. Each row also says
/// how much of its level has been met, so the screen reads as progress by level.
struct LevelSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @State private var purchase = false

    var body: some View {
        let levels = LevelProgress.levels(phrases: store.phrases, purchased: purchases.hasFullAccess,
                                          kind: store.data.homeKindFilter, memory: store.data.memoryReviews ?? [:])
        let offered = Set(levels.filter { $0.available > 0 }.map(\.level))
        // A level chosen under another plan or kind is not on offer here; the rows show the choice as Home applies it.
        let applied = store.data.homeLevelFilter.applied(to: offered)
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Home shows phrases from the levels you choose.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                VStack(spacing: Spacing.xs) {
                    LevelChoiceRow(code: nil, title: "All levels", references: nil,
                                   learned: levels.reduce(0) { $0 + $1.learned },
                                   available: levels.reduce(0) { $0 + $1.available }, total: levels.reduce(0) { $0 + $1.total },
                                   isSelected: applied.isAll) {
                        store.configure(homeLevels: .all)
                    }.accessibilityIdentifier("levelChoice-all")
                    ForEach(levels) { progress in
                        LevelChoiceRow(code: progress.level.rawValue, title: LocalizedStringKey(progress.level.title),
                                       references: progress.level.examReferences, learned: progress.learned,
                                       available: progress.available, total: progress.total,
                                       isSelected: applied.contains(progress.level)) {
                            // A level the free plan has nothing in opens Pro instead of emptying Home.
                            if progress.available == 0 { purchase = true }
                            else { store.configure(homeLevels: applied.toggling(progress.level, among: offered)) }
                        }.accessibilityIdentifier("levelChoice-\(progress.level.rawValue)")
                    }
                }
                if !purchases.hasFullAccess {
                    ProAppearanceNote(text: "Every level opens in full with Izzy Pro.", identifier: "levelsUnlockPro") { purchase = true }
                }
                NavigationLink { DifficultyGuideView() } label: {
                    HStack(spacing: Spacing.sm) {
                        Text("About difficulty levels").font(Typography.control)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(Palette.secondary)
                    }.frame(minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(RowPressStyle()).accessibilityIdentifier("aboutDifficultyLevels")
            }
        }.foregroundStyle(Palette.ink)
            .navigationTitle("Levels to learn").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $purchase) { PurchaseView(from: "levels") }
            .closesForReviewRequest($purchase)
            .sensoryFeedback(.selection, trigger: applied)
    }
}

/// One choice in the level picker: the level and its exam references on the left, how much of it has been
/// met on the right, and a thin track under both. A level the plan has nothing in shows a lock and its size.
private struct LevelChoiceRow: View {
    @Environment(\.appAccent) private var accent
    let code: String?
    let title: LocalizedStringKey
    let references: String?
    let learned: Int
    let available: Int
    let total: Int
    let isSelected: Bool
    let action: () -> Void
    private var locked: Bool { available == 0 }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                    if let code { Text(verbatim: code).font(Typography.section.monospacedDigit()) }
                    Text(title).font(code == nil ? Typography.section : .subheadline)
                    Spacer(minLength: Spacing.sm)
                    Group {
                        if locked { Text("\(total) phrases") }
                        else { Text(verbatim: "\(learned.formatted()) / \(available.formatted())") }
                    }.font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                    Image(systemName: locked ? "lock.fill" : isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.body).foregroundStyle(isSelected ? accent.mark : Palette.secondary)
                        .accessibilityHidden(true)
                }
                if let references, !references.isEmpty {
                    Text(verbatim: references).font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                        .multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                }
                if !locked {
                    ProgressView(value: Double(learned), total: Double(available)).tint(accent.mark)
                        .accessibilityHidden(true)
                }
            }.padding(Spacing.md).frame(maxWidth: .infinity, alignment: .leading)
                .selectionSurface(isSelected, cornerRadius: Radius.medium)
                .contentShape(RoundedRectangle(cornerRadius: Radius.medium))
        }.buttonStyle(PressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(code.map { Text(verbatim: $0) + Text(verbatim: ", ") + Text(title) } ?? Text(title))
            .accessibilityValue(locked ? Text(verbatim: "Izzy Pro") : Text("\(learned) of \(available) learned"))
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

/// "A2 · B1" or "All levels": the level choice as Home applies it, for the rows that lead to the picker.
struct LevelChoiceSummary: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases

    var body: some View {
        let applied = store.data.homeLevelFilter.applied(phrases: store.phrases, purchased: purchases.hasFullAccess,
                                                         kind: store.data.homeKindFilter)
        if let summary = applied.summary { Text(verbatim: summary) } else { Text("All levels") }
    }
}
