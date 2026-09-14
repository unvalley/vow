import XCTest
@testable import Vow

/// Reproduces the derived collections Home recomputes while rendering: one body evaluation
/// reads the learning queue about eleven times, the speaking queue three times and the daily
/// progress four times, each from scratch, over the whole accessible catalog.
final class TodayDerivationPerformanceTests: XCTestCase {
    private func fixture() throws -> (phrases: [Phrase], memory: [String: MemoryReview], reviews: [String: ReviewState], now: Date) {
        let phrases = try Catalog.load()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        var memory: [String: MemoryReview] = [:]
        var reviews: [String: ReviewState] = [:]
        // A learner a few weeks in: 120 phrases seen, a dozen due, five introduced today.
        for (index, phrase) in phrases.prefix(120).enumerated() {
            let introduced = now.addingTimeInterval(Double(-index) * 86_400 / 4)
            let due = index % 10 == 0 ? now.addingTimeInterval(-3_600) : now.addingTimeInterval(Double(index) * 3_600)
            let state = MemoryReview(due: due, introduced: introduced, lastReviewed: introduced)
            memory[phrase.id] = state
            reviews[phrase.id] = ReviewState(due: state.due, reviews: 1)
        }
        return (phrases, memory, reviews, now)
    }

    func testCatalogLoad() throws {
        measure(metrics: [XCTClockMetric()]) { _ = try? Catalog.load() }
    }

    /// What one Home render costs now: a single derivation.
    func testOneHomeDerivation() throws {
        let f = try fixture()
        measure(metrics: [XCTClockMetric()]) {
            _ = HomeDerivation(phrases: f.phrases, purchased: true, kind: .all, memory: f.memory, reviews: f.reviews,
                               focus: "work", dailyNew: 5, now: f.now, mode: .learning, selectedID: f.phrases[0].id)
        }
    }

    func testOneLearningQueue() throws {
        let f = try fixture()
        measure(metrics: [XCTClockMetric()]) {
            _ = MemoryScheduler.queue(phrases: f.phrases, states: f.memory, focus: "work", now: f.now, limit: f.phrases.count, dailyNewLimit: 5)
        }
    }

    func testOneHomeBodyEquivalent() throws {
        let f = try fixture()
        let kind = PhraseKindFilter.all
        measure(metrics: [XCTClockMetric()]) {
            for _ in 0..<11 {
                let visible = f.phrases.filter { AccessPolicy.allows($0, purchased: true) && kind.allows($0) }
                _ = MemoryScheduler.queue(phrases: visible, states: f.memory, focus: "work", now: f.now, limit: visible.count, dailyNewLimit: 5)
            }
            for _ in 0..<3 {
                let visible = f.phrases.filter { AccessPolicy.allows($0, purchased: true) && kind.allows($0) }
                _ = SessionPlanner.queue(phrases: visible, states: f.reviews, focus: "work", now: f.now)
            }
            for _ in 0..<4 {
                let accessible = f.phrases.filter { AccessPolicy.allows($0, purchased: true) }
                _ = DailyLearningProgress(phrases: accessible, states: f.memory, goal: 5, now: f.now)
            }
        }
    }
}
