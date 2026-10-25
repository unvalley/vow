import SwiftUI

/// The onboarding's level check: an invitation, eight meaning questions, then the levels it recommends.
/// The onboarding owns the stage, so its title, text and next button follow along; choosing the levels is
/// that next button, and skipping is always one tap away.
struct LevelCheckView: View {
    enum Stage: Equatable {
        case invitation, asking
        case result(Set<PhraseDifficulty>, correct: [PhraseDifficulty: Int], asked: [PhraseDifficulty: Int])
    }

    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @Binding var stage: Stage
    @State private var check: LevelCheck?
    @State private var index = 0
    /// The current question has been answered; its answer shows for a moment before the next one.
    @State private var answered = false
    /// The choice made, nil for “not sure”.
    @State private var picked: Int?
    @State private var correct: [PhraseDifficulty: Int] = [:]
    @State private var asked: [PhraseDifficulty: Int] = [:]
    private var japanese: Bool { store.data.meaningLanguage == .japanese }

    var body: some View {
        switch stage {
        case .invitation: invitation
        case .asking: if let check, check.questions.indices.contains(index) { question(check.questions[index], of: check.questions.count) }
        case .result(_, let correct, let asked): result(correct, asked: asked)
        }
    }

    private var invitation: some View {
        VStack(alignment: .leading, spacing: Spacing.lg) {
            PrimaryButton(title: japanese ? "チェックを始める" : "Start the check") { start() }
                .accessibilityIdentifier("levelCheckStart")
            Text(japanese ? "結果は、設定の「学ぶレベル」でいつでも変えられます。" : "You can change the result any time in Settings under Levels to learn.")
                .font(.footnote).foregroundStyle(Palette.secondary).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }

    private func question(_ question: LevelCheck.Question, of total: Int) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            Text(verbatim: "\(index + 1) / \(total)").font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary)
                .accessibilityLabel(japanese ? "全\(total)問中\(index + 1)問目" : "Question \(index + 1) of \(total)")
            Text(question.phrase.phrase).phraseFont(.largeTitle).lineLimit(1).minimumScaleFactor(0.6)
                .accessibilityIdentifier("levelCheckPhrase")
            VStack(spacing: Spacing.xs) {
                ForEach(Array(question.choices.enumerated()), id: \.offset) { choice, text in
                    Button { answer(choice, for: question) } label: {
                        HStack(spacing: Spacing.sm) {
                            Text(text).font(.subheadline).multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if answered, choice == question.answer {
                                Image(systemName: "checkmark").accessibilityLabel(japanese ? "正解" : "Correct")
                            } else if answered, picked == choice {
                                Image(systemName: "xmark").accessibilityLabel(japanese ? "不正解" : "Incorrect")
                            }
                        }.padding(Spacing.md).frame(minHeight: 48)
                            .selectionSurface(answered && choice == question.answer, cornerRadius: Radius.medium)
                            .opacity(answered && choice != question.answer && picked != choice ? 0.5 : 1)
                    }.buttonStyle(PressStyle()).disabled(answered)
                        .accessibilityIdentifier("levelCheckChoice-\(choice)")
                }
            }
            Button(japanese ? "わからない" : "Not sure") { answer(nil, for: question) }
                .font(Typography.control).frame(minHeight: 44).buttonStyle(PressStyle()).disabled(answered)
                .accessibilityIdentifier("levelCheckNotSure")
        }.frame(maxWidth: .infinity, alignment: .leading)
            .id(question.id)
            .sensoryFeedback(.selection, trigger: index)
    }

    /// How each level went, as dots; the onboarding's title and text name the recommendation.
    private func result(_ correct: [PhraseDifficulty: Int], asked: [PhraseDifficulty: Int]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            ForEach(LevelCheck.levels, id: \.self) { level in
                let right = correct[level] ?? 0, total = asked[level] ?? 0
                HStack(spacing: Spacing.md) {
                    Text(verbatim: level.rawValue).font(Typography.section.monospacedDigit()).frame(width: 36, alignment: .leading)
                    HStack(spacing: Spacing.xs) {
                        ForEach(0..<max(total, 1), id: \.self) { dot in
                            Image(systemName: dot < right ? "circle.fill" : "circle")
                                .foregroundStyle(dot < right ? accent.mark : Palette.secondary)
                        }
                    }.font(.caption)
                    Spacer(minLength: 0)
                }.accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(verbatim: level.rawValue))
                    .accessibilityValue(japanese ? "\(total)問中\(right)問正解" : "\(right) of \(total) right")
            }
        }.padding(Spacing.lg).frame(maxWidth: .infinity, alignment: .leading)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
            .accessibilityIdentifier("levelCheckResult")
    }

    private func start() {
        var generator = SystemRandomNumberGenerator()
        let made = LevelCheck(phrases: store.phrases, language: store.data.meaningLanguage, using: &generator)
        check = made
        index = 0
        answered = false
        correct = [:]
        asked = [:]
        stage = made.questions.isEmpty ? .result([], correct: [:], asked: [:]) : .asking
    }

    private func answer(_ choice: Int?, for question: LevelCheck.Question) {
        guard !answered, let check else { return }
        answered = true
        picked = choice
        asked[question.level, default: 0] += 1
        if choice == question.answer { correct[question.level, default: 0] += 1 }
        // Long enough to see the right answer, short enough that eight questions take about a minute.
        let pause: Duration = reduceMotion ? .milliseconds(600) : .milliseconds(choice == question.answer ? 500 : 900)
        Task { @MainActor in
            try? await Task.sleep(for: pause)
            answered = false
            picked = nil
            if index + 1 < check.questions.count {
                index += 1
            } else {
                stage = .result(LevelCheck.recommendation(correct: correct, asked: asked), correct: correct, asked: asked)
            }
        }
    }
}
