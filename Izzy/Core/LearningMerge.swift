import Foundation

/// Merges the learning data on this device with the copy in iCloud, against `base`: the copy this
/// device last saw there. A field changed on one side takes that side's value. A field changed on
/// both is merged where it can be — reviews per phrase, events by ID, saved phrases as a set — and
/// otherwise keeps this device's value, because the device that loses the race to upload is the
/// one that merges, and the other then takes the result unchanged.
///
/// With no base (this device has never synced, or its account changed) the settings come from the
/// copy with more history, so a fresh install picks up the learner's choices instead of the defaults
/// it set for itself.
enum LearningMerge {
    /// Written with every upload. A new field or enum case in `LearningData` means handling it here
    /// and bumping this, so an older build stops syncing instead of dropping what it can't read.
    static let format = 1

    static func merge(base: LearningData?, local: LearningData, remote: LearningData) -> LearningData {
        let hasBase = base != nil
        let settingsSource: LearningData? = hasBase ? nil : (local.events.count > remote.events.count ? local : remote)
        let base = base ?? LearningData()
        if local == base || local == remote { return remote.keepingDeviceSettings(of: local) }
        if remote == base { return local }
        var merged = local
        func take<Value: Equatable>(_ field: WritableKeyPath<LearningData, Value>) {
            merged[keyPath: field] = settingsSource?[keyPath: field] ?? choose(base[keyPath: field], local[keyPath: field], remote[keyPath: field])
        }
        take(\.focus)
        take(\.japaneseHints)
        take(\.theme)
        take(\.accent)
        take(\.todayBackground)
        take(\.phraseTypeface)
        take(\.dailyNewGoal)
        take(\.dailyGoalSkipped)
        take(\.difficultyScale)
        take(\.phraseSort)
        take(\.homeKind)
        take(\.listeningPreferences)
        take(\.reviewReminders)
        // Voices are installed per device, so the choice stays with this one.
        merged.speechVoiceID = local.speechVoiceID
        merged.onboardingDone = local.onboardingDone || remote.onboardingDone
        merged.reviews = entries(base.reviews, local.reviews, remote.reviews) { local, remote in
            (remote.lastReviewed ?? .distantPast) > (local.lastReviewed ?? .distantPast) ? remote : local
        }
        let memory = entries(base.memoryReviews ?? [:], local.memoryReviews ?? [:], remote.memoryReviews ?? [:]) { local, remote in
            remote.lastReviewed > local.lastReviewed ? remote : local
        }
        merged.memoryReviews = memory.isEmpty && local.memoryReviews == nil && remote.memoryReviews == nil ? nil : memory
        merged.saved = base.saved.intersection(local.saved).intersection(remote.saved)
            .union(local.saved.subtracting(base.saved)).union(remote.saved.subtracting(base.saved))
        // Both sides wrote a different note: keep both rather than lose either.
        merged.notes = entries(base.notes, local.notes, remote.notes) { local, remote in
            if local.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return remote }
            if remote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return local }
            return local + "\n\n" + remote
        }
        merged.events = events(base.events, local.events, remote.events)
        if local.rehearsalDates != nil || remote.rehearsalDates != nil {
            merged.rehearsalDates = Set(local.rehearsalDates ?? []).union(remote.rehearsalDates ?? []).sorted()
        }
        // Without a base both sides may hold the same stories, so adding them would count twice.
        merged.rehearsalCount = hasBase
            ? max(local.rehearsalCount, remote.rehearsalCount, local.rehearsalCount + remote.rehearsalCount - base.rehearsalCount)
            : max(local.rehearsalCount, remote.rehearsalCount)
        return merged
    }

    private static func choose<Value: Equatable>(_ base: Value, _ local: Value, _ remote: Value) -> Value {
        if local == base { return remote }
        if remote == base { return local }
        return local
    }

    /// Each key follows the rule for a single field; `resolve` settles a key changed on both sides.
    /// A key removed on one side and changed on the other keeps the change.
    private static func entries<Key: Hashable, Value: Equatable>(_ base: [Key: Value], _ local: [Key: Value], _ remote: [Key: Value],
                                                                 resolve: (Value, Value) -> Value) -> [Key: Value] {
        if local == base { return remote }
        if remote == base { return local }
        var merged = local
        for key in Set(base.keys).union(local.keys).union(remote.keys) {
            let (old, mine, theirs) = (base[key], local[key], remote[key])
            if mine == old { merged[key] = theirs }
            else if theirs == old { merged[key] = mine }
            else if let mine, let theirs { merged[key] = resolve(mine, theirs) }
            else { merged[key] = mine ?? theirs }
        }
        return merged
    }

    /// Events are merged by ID; a meaning rating changed the same day keeps its ID and moves to the later time.
    private static func events(_ base: [PracticeEvent], _ local: [PracticeEvent], _ remote: [PracticeEvent]) -> [PracticeEvent] {
        if local == base || local == remote { return remote }
        if remote == base { return local }
        func byID(_ events: [PracticeEvent]) -> [UUID: PracticeEvent] {
            Dictionary(events.map { ($0.id, $0) }, uniquingKeysWith: { $1 })
        }
        return entries(byID(base), byID(local), byID(remote)) { local, remote in remote.date > local.date ? remote : local }
            .values.sorted { ($0.date, $0.id.uuidString) < ($1.date, $1.id.uuidString) }
    }
}

private extension LearningData {
    func keepingDeviceSettings(of local: LearningData) -> LearningData {
        var data = self
        data.speechVoiceID = local.speechVoiceID
        return data
    }
}
