import StoreKit
import StoreKitTest
import XCTest
@testable import Vow

@MainActor final class PurchaseStoreTests: XCTestCase {
    private func session() throws -> SKTestSession {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "Vow", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.clearTransactions()
        session.disableDialogs = true
        session.storefront = "JPN"
        session.locale = Locale(identifier: "ja_JP")
        return session
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
        XCTAssertEqual(product.price, 900)
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
