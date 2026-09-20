#if !SWIFT_PACKAGE
import XCTest
import UserNotifications
@testable import Izzy

@MainActor private final class FakeReviewNotifications: ReviewNotificationClient {
    var authorization: UNAuthorizationStatus = .authorized
    var requests: [String: UNNotificationRequest] = [:]
    var delivered: [String] = []
    var permissionRequests = 0
    var failAdds = false
    var suspendNextAdd = false
    var suspended: CheckedContinuation<Void, Never>?
    func settings() async -> UNAuthorizationStatus { authorization }
    func requestPermission() async throws -> Bool { permissionRequests += 1; authorization = .authorized; return true }
    func pending() async -> [UNNotificationRequest] { Array(requests.values) }
    func deliveredIDs() async -> [String] { delivered }
    func removePending(_ ids: [String]) { for id in ids { requests[id] = nil } }
    func removeDelivered(_ ids: [String]) { delivered.removeAll { ids.contains($0) } }
    func add(_ request: UNNotificationRequest) async throws {
        if suspendNextAdd {
            suspendNextAdd = false
            await withCheckedContinuation { suspended = $0 }
        }
        if failAdds { throw CocoaError(.fileWriteUnknown) }
        requests[request.identifier] = request
    }
}

@MainActor final class ReviewReminderCenterTests: XCTestCase {
    private func input(enabled: Bool = true) -> ReviewReminderInput {
        let due = Date.now.addingTimeInterval(86_400)
        return .init(preferences: .init(enabled: enabled),
                     reviews: ["free": .init(due: due, introduced: .now, lastReviewed: .now)],
                     allowedIDs: ["free"], japanese: false)
    }
    func testScheduleThenOffCancelsOnlyOwnedNotifications() async throws {
        let client = FakeReviewNotifications()
        let center = ReviewReminderCenter(client: client)
        let unrelated = UNNotificationRequest(identifier: "unrelated", content: UNMutableNotificationContent(), trigger: nil)
        client.requests[unrelated.identifier] = unrelated
        client.delivered = [ReviewReminderCenter.prefix + "old", "unrelated"]
        center.update(input())
        await center.waitUntilIdle()
        XCTAssertNotNil(center.nextReminder)
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.permissionRequests, 0)
        XCTAssertEqual(client.delivered, ["unrelated"])
        let request = try XCTUnwrap(client.requests.values.first { $0.identifier != "unrelated" })
        XCTAssertEqual(request.content.userInfo["destination"] as? String, "memory-review")
        let trigger = try XCTUnwrap(request.trigger as? UNCalendarNotificationTrigger)
        XCTAssertFalse(trigger.repeats)
        XCTAssertGreaterThan(try XCTUnwrap(trigger.nextTriggerDate()), Date.now)
        center.update(input(enabled: false))
        await center.waitUntilIdle()
        XCTAssertEqual(Set(client.requests.keys), ["unrelated"])
        XCTAssertNil(center.nextReminder)
    }
    func testRevokedPermissionAndAccessRemoveExistingRequestsWithoutPrompt() async {
        let client = FakeReviewNotifications()
        let center = ReviewReminderCenter(client: client)
        center.update(input()); await center.waitUntilIdle()
        client.authorization = .denied
        center.update(input()); await center.waitUntilIdle()
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertEqual(center.authorization, .denied)
        XCTAssertEqual(client.permissionRequests, 0)
        client.authorization = .authorized
        center.update(input()); await center.waitUntilIdle()
        var revoked = input(); revoked.allowedIDs = []
        center.update(revoked); await center.waitUntilIdle()
        XCTAssertTrue(client.requests.isEmpty)
    }
    func testNewOffWinsOverInFlightAdd() async {
        let client = FakeReviewNotifications()
        let center = ReviewReminderCenter(client: client)
        client.suspendNextAdd = true
        center.update(input())
        while client.suspended == nil { await Task.yield() }
        center.update(input(enabled: false))
        client.suspended?.resume()
        await center.waitUntilIdle()
        XCTAssertTrue(client.requests.isEmpty)
        XCTAssertNil(center.nextReminder)
    }
    func testFailureIsVisibleAndPermissionOnlyRequestedExplicitly() async {
        let client = FakeReviewNotifications()
        client.authorization = .notDetermined
        let center = ReviewReminderCenter(client: client)
        center.update(input()); await center.waitUntilIdle()
        XCTAssertEqual(client.permissionRequests, 0)
        let authorized = await center.requestPermission()
        XCTAssertTrue(authorized)
        XCTAssertEqual(client.permissionRequests, 1)
        client.failAdds = true
        center.update(input()); await center.waitUntilIdle()
        XCTAssertNotNil(center.errorMessage)
        XCTAssertNil(center.nextReminder)
        XCTAssertTrue(client.requests.isEmpty)
    }
    func testChangedReviewReplacesOldDueDateAndLanguage() async {
        let client = FakeReviewNotifications()
        let center = ReviewReminderCenter(client: client)
        var state = input()
        center.update(state); await center.waitUntilIdle()
        let previous = center.nextReminder
        state.reviews["free"]!.due = Date.now.addingTimeInterval(6 * 86_400)
        state.japanese = true
        center.update(state); await center.waitUntilIdle()
        XCTAssertEqual(client.requests.count, 1)
        XCTAssertNotEqual(previous, center.nextReminder)
        XCTAssertEqual(client.requests.values.first?.content.title, "思い出す時間です")
    }
}
#endif
