import Foundation

/// A one-minute placement for the levels Home learns from: meaning questions at each level from A2 to C1,
/// easiest first, one phrasal verb and one idiom at each. It recommends the first level with a miss and the
/// one above it, the band where most of the learner's new expressions are, and claims nothing it cannot
/// back, such as a score or a vocabulary size.
struct LevelCheck: Sendable {
    struct Question: Identifiable, Sendable {
        let phrase: Phrase
        let level: PhraseDifficulty
        /// Four meanings in the learner's explanation language; one is the phrase's own.
        let choices: [String]
        let answer: Int
        var id: String { phrase.id }
    }

    static let levels: [PhraseDifficulty] = [.a2, .b1, .b2, .c1]
    let questions: [Question]

    init(phrases: [Phrase], language: MeaningLanguage, using generator: inout some RandomNumberGenerator) {
        func meaning(_ phrase: Phrase) -> String {
            language == .japanese ? phrase.japanese : (phrase.lead(in: .easyEnglish) ?? phrase.easyEnglish)
        }
        var questions: [Question] = []
        for level in Self.levels {
            for idiom in [false, true] {
                let pool = phrases.filter { $0.difficulty == level && $0.isIdiom == idiom && !meaning($0).isEmpty }
                guard let target = pool.randomElement(using: &generator) else { continue }
                var choices = [meaning(target)]
                for other in pool.shuffled(using: &generator) where choices.count < 4 {
                    let text = meaning(other)
                    if other.baseVerb != target.baseVerb, !choices.contains(text) { choices.append(text) }
                }
                guard choices.count == 4 else { continue }
                choices.shuffle(using: &generator)
                questions.append(Question(phrase: target, level: level, choices: choices,
                                          answer: choices.firstIndex(of: meaning(target)) ?? 0))
            }
        }
        self.questions = questions
    }

    /// The levels to learn from the right answers per level. A learner who knows none of the easiest starts
    /// from A1; one who knows everything works at the top two.
    static func recommendation(correct: [PhraseDifficulty: Int], asked: [PhraseDifficulty: Int]) -> Set<PhraseDifficulty> {
        guard let gap = levels.first(where: { (correct[$0] ?? 0) < (asked[$0] ?? 0) }) else { return [.b2, .c1] }
        if gap == .a2, (correct[.a2] ?? 0) == 0 { return [.a1, .a2] }
        guard let index = levels.firstIndex(of: gap), index + 1 < levels.count else { return [.b2, .c1] }
        return [gap, levels[index + 1]]
    }
}
