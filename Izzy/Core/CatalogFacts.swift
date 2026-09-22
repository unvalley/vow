import Foundation

/// Every number the app states about its catalog and plans, read from the catalog itself so no copy
/// needs editing when expressions, examples, backgrounds or fonts are added.
/// Full-collection figures are shown open-ended through `openEnded` (3,000以上 / 3,000+), matching the
/// store and landing copy; free-plan figures are exact because the free set is fixed.
struct CatalogFacts: Sendable {
    let expressions: Int
    let freeExpressions: Int
    let freePhrasalVerbs: Int
    let freeIdioms: Int
    /// Example sentences with an authored meaning, as the phrase screens show them.
    let examples: Int
    let freeExamples: Int
    let coreImages = ParticleConcept.all.count
    let backgrounds = TodayBackground.allCases.count
    let freeBackgrounds = TodayBackground.allCases.filter(\.isFree).count
    let fonts = PhraseTypeface.allCases.count
    let freeFonts = PhraseTypeface.allCases.filter(\.isFree).count

    init(phrases: [Phrase]) {
        let free = phrases.filter { AccessPolicy.allows($0, purchased: false) }
        expressions = phrases.count
        freeExpressions = free.count
        freeIdioms = free.filter(\.isIdiom).count
        freePhrasalVerbs = free.count - freeIdioms
        examples = phrases.reduce(0) { $0 + ($1.exampleTranslations?.count ?? 0) }
        freeExamples = free.reduce(0) { $0 + ($1.exampleTranslations?.count ?? 0) }
    }

    /// A count rounded down to a figure that stays true as the catalog grows: thousands from 1,000,
    /// hundreds from 100, exact below. Shown with 以上 / +.
    static func openEnded(_ count: Int) -> Int {
        let step = count >= 1_000 ? 1_000 : count >= 100 ? 100 : 1
        return count / step * step
    }
}
