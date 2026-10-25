import StoreKit
import StoreKitTest
import XCTest
@testable import Izzy

@MainActor final class PurchaseStoreTests: XCTestCase {
    private func session() throws -> SKTestSession {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Izzy", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.storefront = "JPN"
        session.locale = Locale(identifier: "ja_JP")
        // StoreKitTest setters may only log failures when the test service is
        // unavailable. Do not continue into a real Apple account dialog.
        return try XCTUnwrap(session.disableDialogs ? session : nil,
                             "StoreKit test configuration was not applied. Run in a working Xcode StoreKit environment; no purchase was attempted.")
    }

    func testPurchaseRelaunchRestoreAndRefund() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = PurchaseStore()
        await store.start()
        XCTAssertFalse(store.hasFullAccess)
        XCTAssertFalse(store.isChecking)
        let product = try XCTUnwrap(store.product)
        XCTAssertEqual(product.id, AccessPolicy.productID)
        XCTAssertEqual(product.price, 1_900)
        XCTAssertEqual(product.type, .nonConsumable)
        await store.purchase()
        XCTAssertTrue(store.hasFullAccess)
        let relaunched = PurchaseStore()
        await relaunched.start()
        XCTAssertTrue(relaunched.hasFullAccess)
        await relaunched.restore()
        XCTAssertEqual(relaunched.notice, .restored)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.refundTransaction(identifier: transaction.identifier)
        for _ in 0..<30 {
            if !store.hasFullAccess && !relaunched.hasFullAccess { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertFalse(store.hasFullAccess, "Transaction updates must revoke access without relaunch.")
        XCTAssertFalse(relaunched.hasFullAccess)
        await relaunched.restore()
        XCTAssertEqual(relaunched.notice, .nothingToRestore)
    }

    func testTheTrialOpensProOnceAndBuyingStaysOpen() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        let store = PurchaseStore()
        await store.start()
        XCTAssertEqual(store.trialProduct?.price, 0)
        XCTAssertTrue(store.canStartTrial)
        let started = Date.now
        await store.startTrial()
        XCTAssertTrue(store.hasFullAccess)
        XCTAssertTrue(store.isTrialing)
        XCTAssertFalse(store.isPurchased)
        XCTAssertFalse(store.canStartTrial, "one trial per Apple Account")
        let ends = try XCTUnwrap(store.trialEnds)
        XCTAssertEqual(ends.timeIntervalSince(started), TimeInterval(AccessPolicy.trialDays) * 86_400, accuracy: 60)

        // A trial restored on another device keeps its original dates, and is not a purchase to restore.
        let relaunched = PurchaseStore()
        await relaunched.start()
        XCTAssertTrue(relaunched.isTrialing)
        XCTAssertEqual(relaunched.trialEnds, store.trialEnds)
        let purchasedAfterTrial = await relaunched.refresh(now: ends.addingTimeInterval(1))
        XCTAssertFalse(purchasedAfterTrial)
        XCTAssertFalse(relaunched.hasFullAccess, "an ended trial opens nothing")
        XCTAssertFalse(relaunched.isTrialing)
        XCTAssertFalse(relaunched.canStartTrial, "an ended trial is not offered again")

        await store.purchase()
        XCTAssertTrue(store.isPurchased)
        XCTAssertFalse(store.isTrialing)
    }

    func testPendingPurchaseUnlocksOnlyAfterApproval() async throws {
        let session = try session()
        defer { session.clearTransactions() }
        session.askToBuyEnabled = true
        let store = PurchaseStore()
        await store.start()
        await store.purchase()
        XCTAssertFalse(store.hasFullAccess)
        XCTAssertEqual(store.notice, .pending)
        let transaction = try XCTUnwrap(session.allTransactions().first)
        try session.approveAskToBuyTransaction(identifier: transaction.identifier)
        for _ in 0..<30 {
            if store.hasFullAccess { break }
            try await Task.sleep(for: .milliseconds(100))
        }
        XCTAssertTrue(store.hasFullAccess)
    }
}
