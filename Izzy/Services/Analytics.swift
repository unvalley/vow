import Foundation
import UIKit

/// Izzy's own measurement, posted to `izzy.unvalley.me/e` and stored in a database this
/// project owns. Nothing is handed to a third party and no SDK is linked.
///
/// What leaves the device is a closed list of event names, a handful of enumerated
/// settings values, and an install identifier the app makes on first launch. That
/// identifier lives in this app's own defaults rather than the Keychain, so deleting
/// Izzy ends it — a reinstall is a new install here, which is the point. No account,
/// no advertising identifier, no location, and nothing a person typed: notes, searches
/// and phrases never reach this file. The endpoint enforces the same list again, so the
/// claim holds even if a later build got careless.
///
/// Sending is off in Debug builds and under UI tests unless `--analytics-live` asks for
/// it, so development never lands in the same table as customers.
@MainActor @Observable final class Analytics {
    static let shared = Analytics()

    enum Event: String {
        case appOpen = "app_open"
        case goalCompleted = "goal_completed"
        case settings
        case phraseLearned = "phrase_learned"
        case phraseReviewed = "phrase_reviewed"
        case listeningStarted = "listening_started"
        case practiceOpened = "practice_opened"
        case coreImagesOpened = "core_images_opened"
        case statsOpened = "stats_opened"
        case searchUsed = "search_used"
        case proLockShown = "pro_lock_shown"
        case proScreenOpened = "pro_screen_opened"
        case proPurchaseStarted = "pro_purchase_started"
        case proPurchased = "pro_purchased"
        case proPurchaseFailed = "pro_purchase_failed"
        case proRestored = "pro_restored"
    }

    private struct Queued: Codable {
        let n: String
        let t: Int
        let p: [String: String]
    }

    private static let endpoint = URL(string: "https://izzy.unvalley.me/e")!
    private static let installKey = "analytics.install"
    private static let enabledKey = "analytics.enabled"
    /// Enough to survive a few offline days; past this the oldest events go, because a
    /// month-old queue is not worth the disk or the upload.
    private static let queueLimit = 500
    private static let batchSize = 20
    private static let minimumInterval: TimeInterval = 30

    private let defaults: UserDefaults
    private let file: URL
    private let session: URLSession
    private var queue: [Queued] = []
    private var sending = false
    private var lastSend = Date.distantPast
    /// Sent once per day rather than on every launch: it describes a configuration, not an event.
    private var settingsSentOn: Date?

    private(set) var isEnabled: Bool

    init(defaults: UserDefaults = .standard,
         file: URL = URL.applicationSupportDirectory.appending(path: "Izzy/analytics.json")) {
        self.defaults = defaults
        self.file = file
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 15
        configuration.waitsForConnectivity = false
        configuration.allowsExpensiveNetworkAccess = true
        configuration.allowsConstrainedNetworkAccess = false // never on someone's Low Data Mode
        session = URLSession(configuration: configuration)
        // Absent means on: the toggle in Settings turns it off, and the first launch has
        // nothing stored yet.
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        queue = (try? JSONDecoder().decode([Queued].self, from: Data(contentsOf: file))) ?? []
    }

    /// Stable for as long as the app is installed, and meaningless off the device.
    private var installID: String {
        if let existing = defaults.string(forKey: Self.installKey) { return existing }
        let fresh = UUID().uuidString
        defaults.set(fresh, forKey: Self.installKey)
        return fresh
    }

    private var sends: Bool {
        guard isEnabled else { return false }
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--analytics-live") { return true }
        if arguments.contains("--ui-tests") { return false }
        #if DEBUG
        return false
        #else
        return true
        #endif
    }

    func setEnabled(_ enabled: Bool) {
        guard enabled != isEnabled else { return }
        isEnabled = enabled
        defaults.set(enabled, forKey: Self.enabledKey)
        // Turning it off drops what has not been sent; keeping it would be a promise broken later.
        if !enabled {
            queue.removeAll()
            settingsSentOn = nil
            try? FileManager.default.removeItem(at: file)
        }
    }

    func record(_ event: Event, _ properties: [String: String] = [:]) {
        // Nothing is queued when nothing will be sent, so a Debug run leaves no file behind.
        guard sends else { return }
        queue.append(Queued(n: event.rawValue, t: Int(Date.now.timeIntervalSince1970), p: properties))
        if queue.count > Self.queueLimit { queue.removeFirst(queue.count - Self.queueLimit) }
        save()
        if queue.count >= Self.batchSize { Task { await send() } }
    }

    /// The configuration someone is actually running, recorded once a day so it can be
    /// read alongside whether they came back.
    func recordSettings(_ properties: [String: String], now: Date = .now) {
        guard sends else { return }
        let calendar = Calendar.autoupdatingCurrent
        if let sent = settingsSentOn, calendar.isDate(sent, inSameDayAs: now) { return }
        settingsSentOn = now
        record(.settings, properties)
    }

    /// Called when the app leaves the foreground and when it comes back, so a session's
    /// events do not wait for the next twenty.
    func flush() { Task { await send(force: true) } }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(queue) else { return }
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? encoded.write(to: file, options: .atomic)
    }

    private func send(force: Bool = false) async {
        guard sends, !sending, !queue.isEmpty else { return }
        guard force || Date.now.timeIntervalSince(lastSend) >= Self.minimumInterval else { return }
        sending = true
        defer { sending = false }
        let batch = Array(queue.prefix(100))
        let body: [String: Any] = [
            "install": installID,
            "app": AppSupport.versionDescription,
            "os": UIDevice.current.systemVersion,
            "device": UIDevice.current.userInterfaceIdiom == .pad ? "iPad" : "iPhone",
            "lang": Bundle.main.preferredLocalizations.first ?? "en",
            "events": batch.map { ["n": $0.n, "t": $0.t, "p": $0.p] },
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: body) else {
            queue.removeFirst(batch.count) // unencodable, so retrying cannot help
            save()
            return
        }
        var request = URLRequest(url: Self.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        lastSend = .now
        do {
            let (_, response) = try await session.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            // 2xx took them; 4xx means this batch will never be accepted, so stop carrying it.
            // Anything else is the server's problem and the batch waits for the next flush.
            guard (200..<300).contains(status) || (400..<500).contains(status) else { return }
            queue.removeFirst(batch.count)
            save()
        } catch {
            // Offline. The queue is on disk and goes out with a later flush.
        }
    }
}

extension Analytics {
    /// The enumerated settings values, and only those: every one is a case name the app
    /// already ships, so nothing here can carry text a person wrote.
    static func settingsProperties(_ data: LearningData, fullAccess: Bool) -> [String: String] {
        [
            "goal": data.dailyNewGoal.map(String.init) ?? "unset",
            "meaning": data.meaningLanguage == .japanese ? "ja" : "en",
            "kind": data.homeKindFilter.rawValue,
            "theme": data.themeChoice.rawValue,
            "bg": data.background(fullAccess: fullAccess).rawValue,
            "font": data.typeface(fullAccess: fullAccess).rawValue,
        ]
    }
}
