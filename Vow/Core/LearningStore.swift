import Foundation
import Observation

@MainActor @Observable final class LearningStore {
    private(set) var data = LearningData()
    private(set) var phrases: [Phrase] = []
    var errorMessage: String?
    private let file: URL
    private var writable = true

    init(file: URL? = nil) {
        self.file = file ?? URL.applicationSupportDirectory.appending(path: "Verve/learning.json")
        do { phrases = try Catalog.load() }
        catch { errorMessage = "The phrase collection couldn't be loaded. Please reinstall the app." }
        if FileManager.default.fileExists(atPath: self.file.path) {
            do {
                let loaded = try JSONDecoder().decode(LearningData.self, from: Data(contentsOf: self.file))
                guard loaded.schema == 1 else { throw CocoaError(.coderReadCorrupt) }
                data = loaded
            } catch {
                writable = false
                errorMessage = "Your saved progress couldn't be read. It has been preserved. New progress won't be saved until the file is recovered."
            }
        }
    }

    func persist() {
        guard writable else { return }
        do {
            try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            let encoded = try JSONEncoder().encode(data)
            try encoded.write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch { errorMessage = "Your latest changes couldn't be saved. Free some storage and try again." }
    }

    func rate(_ phrase: Phrase, _ rating: RecallRating, mode: String, now: Date = .now) {
        data.reviews[phrase.id] = Scheduler.review(data.reviews[phrase.id] ?? ReviewState(), rating: rating, now: now)
        data.events.append(.init(phraseID: phrase.id, date: now, rating: rating, mode: mode))
        persist()
    }
    func toggleSaved(_ id: String) {
        if data.saved.contains(id) { data.saved.remove(id) } else { data.saved.insert(id) }
        persist()
    }
    func note(_ text: String, for id: String) { data.notes[id] = text; persist() }
    func configure(focus: String? = nil, japanese: Bool? = nil, gentle: Bool? = nil, meaningLanguage: MeaningLanguage? = nil, sort: PhraseSort? = nil, accent: AppAccent? = nil) {
        if let accent { data.accent = accent }
        if let focus { data.focus = focus }
        if let japanese { data.japaneseHints = japanese }
        if let meaningLanguage { data.meaningLanguage = meaningLanguage }
        if let sort { data.phraseSort = sort }
        if let gentle { data.gentleMode = gentle }
        persist()
    }
    func finishOnboarding() { data.onboardingDone = true; persist() }
    func finishRehearsal(now: Date = .now) {
        data.rehearsalCount += 1
        data.rehearsalDates = (data.rehearsalDates ?? []) + [now]
        persist()
    }
    func streak(now: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> LearningStreak {
        LearningStreak.calculate(dates: data.events.map(\.date) + (data.rehearsalDates ?? []), now: now, calendar: calendar)
    }
    func dailyQueue(now: Date = .now) -> [Phrase] { SessionPlanner.queue(phrases: phrases, states: data.reviews, focus: data.focus, now: now) }
    func dueCount(now: Date = .now) -> Int { data.reviews.values.filter { $0.due <= now }.count }
    var todayCount: Int { data.events.filter { Calendar.current.isDateInToday($0.date) }.count }
}
