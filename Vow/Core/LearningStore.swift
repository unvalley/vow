import Foundation
import Observation

@MainActor @Observable final class LearningStore {
    private(set) var data = LearningData()
    /// Bumped by every `persist()`. Watchers compare this instead of re-listing the fields they
    /// depend on, which cannot go stale when a new field starts mattering.
    private(set) var revision = 0
    private(set) var phrases: [Phrase] = []
    var errorMessage: String?
    private let file: URL
    private var writable = true
    /// True when no progress file existed at launch. Only then may the device language pick the default explanations.
    let isFreshInstall: Bool

    init(file: URL? = nil) {
        self.file = file ?? URL.applicationSupportDirectory.appending(path: "Verve/learning.json")
        do { phrases = try Catalog.load() }
        catch { errorMessage = "The phrase collection couldn't be loaded. Please reinstall the app." }
        isFreshInstall = !FileManager.default.fileExists(atPath: self.file.path)
        if !isFreshInstall {
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
        revision &+= 1
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
    func rateMemory(_ phrase: Phrase, _ rating: MemoryRating, now: Date = .now) {
        var reviews = data.memoryReviews ?? [:]
        reviews[phrase.id] = MemoryScheduler.rate(reviews[phrase.id], rating: rating, now: now)
        data.memoryReviews = reviews
        // One meaning record per phrase per day: rating again the same day updates it rather than adding another.
        let calendar = Calendar.autoupdatingCurrent
        if let index = data.events.lastIndex(where: { $0.phraseID == phrase.id && $0.mode == "memory" && calendar.isDate($0.date, inSameDayAs: now) }) {
            data.events[index] = .init(id: data.events[index].id, phraseID: phrase.id, date: now, rating: rating.eventRating, mode: "memory", memoryRating: rating)
        } else {
            data.events.append(.init(phraseID: phrase.id, date: now, rating: rating.eventRating, mode: "memory", memoryRating: rating))
        }
        persist()
    }
    /// The meaning rating given to a phrase on the calendar day of `now`, if any.
    func memoryRating(for id: String, on now: Date, calendar: Calendar = .autoupdatingCurrent) -> MemoryRating? {
        data.events.last { $0.phraseID == id && $0.mode == "memory" && calendar.isDate($0.date, inSameDayAs: now) }?.memoryRating
    }
    func toggleSaved(_ id: String) {
        if data.saved.contains(id) { data.saved.remove(id) } else { data.saved.insert(id) }
        persist()
    }
    func note(_ text: String, for id: String) { data.notes[id] = text; persist() }
    func configureListening(_ preferences: ListeningPreferences) {
        data.listeningPreferences = preferences
        persist()
    }
    func configureSpeechVoice(_ identifier: String?) {
        data.speechVoiceID = identifier
        persist()
    }
    func configure(meaningLanguage: MeaningLanguage? = nil, sort: PhraseSort? = nil, accent: AppAccent? = nil, theme: AppTheme? = nil, background: TodayBackground? = nil, typeface: PhraseTypeface? = nil, difficultyScale: DifficultyScale? = nil, homeKind: PhraseKindFilter? = nil) {
        if let difficultyScale { data.difficultyScale = difficultyScale }
        if let homeKind { data.homeKind = homeKind }
        if let accent { data.accent = accent }
        if let theme { data.theme = theme }
        if let background { data.todayBackground = background }
        if let typeface { data.phraseTypeface = typeface }
        if let meaningLanguage { data.meaningLanguage = meaningLanguage }
        if let sort { data.phraseSort = sort }
        persist()
    }
    func configureReminders(enabled: Bool? = nil, hour: Int? = nil, minute: Int? = nil) {
        var preferences = data.reminderPreferences
        if let enabled { preferences.enabled = enabled }
        if let hour { preferences.hour = min(23, max(0, hour)) }
        if let minute { preferences.minute = min(59, max(0, minute)) }
        data.reviewReminders = preferences
        persist()
    }
    func configureDailyGoal(_ count: Int) {
        data.dailyNewGoal = min(50, max(1, count))
        persist()
    }
    func finishOnboarding() { data.onboardingDone = true; persist() }
    func skipDailyGoal() { data.dailyGoalSkipped = true; persist() }
    /// First launch only: explanations follow the device language until the learner chooses otherwise in Settings.
    func configureDefaultLanguage(japanese: Bool) {
        guard isFreshInstall else { return }
        data.japaneseHints = japanese
        persist()
    }
    func finishRehearsal(now: Date = .now) {
        data.rehearsalCount += 1
        data.rehearsalDates = (data.rehearsalDates ?? []) + [now]
        persist()
    }
    func streak(now: Date = .now, calendar: Calendar = .autoupdatingCurrent) -> LearningStreak {
        LearningStreak.calculate(dates: data.practiceDates, now: now, calendar: calendar)
    }
}
