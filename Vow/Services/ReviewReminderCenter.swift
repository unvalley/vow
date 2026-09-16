import Foundation
import Observation
import UserNotifications

@MainActor protocol ReviewNotificationClient {
    func settings() async -> UNAuthorizationStatus
    func requestPermission() async throws -> Bool
    func pending() async -> [UNNotificationRequest]
    func deliveredIDs() async -> [String]
    func removePending(_ ids: [String])
    func removeDelivered(_ ids: [String])
    func add(_ request: UNNotificationRequest) async throws
}

@MainActor final class SystemReviewNotificationClient: ReviewNotificationClient {
    private let center = UNUserNotificationCenter.current()
    func settings() async -> UNAuthorizationStatus { await center.notificationSettings().authorizationStatus }
    func requestPermission() async throws -> Bool { try await center.requestAuthorization(options: [.alert, .sound]) }
    func pending() async -> [UNNotificationRequest] { await center.pendingNotificationRequests() }
    func deliveredIDs() async -> [String] { await center.deliveredNotifications().map(\.request.identifier) }
    func removePending(_ ids: [String]) { center.removePendingNotificationRequests(withIdentifiers: ids) }
    func removeDelivered(_ ids: [String]) { center.removeDeliveredNotifications(withIdentifiers: ids) }
    func add(_ request: UNNotificationRequest) async throws { try await center.add(request) }
}

@MainActor @Observable final class ReviewReminderCenter {
    nonisolated static let prefix = "vow.memory-review."
    private(set) var authorization: UNAuthorizationStatus = .notDetermined
    /// False until the system has been asked once, so `.notDetermined` isn't mistaken for a real answer at launch.
    private(set) var hasCheckedAuthorization = false
    private(set) var isRequestingPermission = false
    private(set) var nextReminder: Date?
    private(set) var errorMessage: String?
    /// A new value for every notification tap. It is never cleared, so every screen that reacts to the
    /// change sees it, whichever runs first.
    private(set) var reviewRequest: UUID?
    @ObservationIgnored private let client: any ReviewNotificationClient
    @ObservationIgnored private var queued: ReviewReminderInput?
    @ObservationIgnored private var latest: ReviewReminderInput?
    @ObservationIgnored private var worker: Task<Void, Never>?
    @ObservationIgnored private var delegate: ReviewNotificationDelegate?

    init(client: any ReviewNotificationClient = SystemReviewNotificationClient()) {
        self.client = client
    }

    func installDelegate() {
        let delegate = ReviewNotificationDelegate { [weak self] in self?.reviewRequest = UUID() }
        self.delegate = delegate
        UNUserNotificationCenter.current().delegate = delegate
    }

    var isAuthorized: Bool { [.authorized, .provisional, .ephemeral].contains(authorization) }

    /// Called only by the user's ON action, never during launch or background refresh.
    func requestPermission() async -> Bool {
        guard !isRequestingPermission else { return false }
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        errorMessage = nil
        do {
            authorization = await client.settings()
            hasCheckedAuthorization = true
            if authorization == .notDetermined { _ = try await client.requestPermission() }
            authorization = await client.settings()
            return isAuthorized
        } catch {
            errorMessage = String(localized: "Notification permission couldn't be requested. Please try again.")
            return false
        }
    }

    /// A single worker serializes all remove/add operations. A newer OFF, rating, or
    /// permission change always runs after an in-flight add and removes stale requests.
    func update(_ input: ReviewReminderInput) {
        latest = input
        queued = input
        guard worker == nil else { return }
        worker = Task { [weak self] in
            guard let self else { return }
            while let input = self.queued {
                self.queued = nil
                await self.replace(input)
            }
            self.worker = nil
        }
    }

    func retry() { if let latest { update(latest) } }

    func waitUntilIdle() async { await worker?.value }

    private func replace(_ input: ReviewReminderInput) async {
        authorization = await client.settings()
        hasCheckedAuthorization = true
        let pending = await client.pending().filter { $0.identifier.hasPrefix(Self.prefix) }
        let delivered = await client.deliveredIDs().filter { $0.hasPrefix(Self.prefix) }
        // Opening/using vow makes old delivered prompts unnecessary.
        client.removeDelivered(delivered)
        errorMessage = nil
        nextReminder = nil
        guard input.preferences.enabled, isAuthorized else {
            client.removePending(pending.map(\.identifier))
            return
        }
        let plan = ReviewReminderPlan.make(input, now: .now)
        let requests = plan.map { Self.request(for: $0, japanese: input.japanese) }
        let wanted = Set(requests.map(\.identifier))
        client.removePending(pending.filter { !wanted.contains($0.identifier) }.map(\.identifier))
        do {
            for request in requests {
                // Replacing the same identifier is atomic in UNUserNotificationCenter.
                try await client.add(request)
                if queued != nil { return }
            }
            nextReminder = plan.first?.date
        } catch {
            // Do not leave a partially updated, misleading review schedule behind.
            let stale = await client.pending().filter { $0.identifier.hasPrefix(Self.prefix) }
            client.removePending(stale.map(\.identifier))
            errorMessage = String(localized: "Reminders couldn't be scheduled. Please try again.")
        }
    }

    static func request(for reminder: ReviewReminder, japanese: Bool, calendar: Calendar = .autoupdatingCurrent) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = japanese ? "思い出す時間です" : "A little time to remember"
        content.body = japanese
            ? "\(reminder.count)個の表現が復習のタイミングです。少しずつ、確かめましょう。"
            : "\(reminder.count) \(reminder.count == 1 ? "phrase is" : "phrases are") ready for review. Take a moment to recall them."
        content.sound = .default
        content.threadIdentifier = "vow-memory-reviews"
        content.userInfo = ["destination": "memory-review"]
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: reminder.date)
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: prefix + String(Int(reminder.date.timeIntervalSince1970)), content: content, trigger: trigger)
    }
}

private final class ReviewNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    private let openReview: @MainActor @Sendable () -> Void
    init(openReview: @escaping @MainActor @Sendable () -> Void) { self.openReview = openReview }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // No banner or sound interrupts someone already practicing in the app.
        completionHandler([])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.actionIdentifier == UNNotificationDefaultActionIdentifier,
           response.notification.request.identifier.hasPrefix(ReviewReminderCenter.prefix) {
            Task { @MainActor in openReview() }
        }
        completionHandler()
    }
}
