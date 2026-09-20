import Foundation
import Observation
import StoreKit

@MainActor @Observable final class PurchaseStore {
    private(set) var product: Product?
    private(set) var hasFullAccess = false
    private(set) var isChecking = true
    private(set) var isLoading = false
    private(set) var isBusy = false
    private(set) var notice: Notice?
    @ObservationIgnored private var updates: Task<Void, Never>?
    private var refreshVersion = 0
    private var started = false
    private var testAccess = false
    private var entitled = false
    #if DEBUG
    /// Debug builds only: a Settings toggle unlocks Pro on this device while the local StoreKit
    /// test service is unavailable. Release builds never read this key.
    private static let debugUnlockKey = "debug.unlockPro"
    private(set) var debugUnlocked = false
    #endif

    enum Notice: Equatable { case unavailable, failed, pending, cancelled, restored, nothingToRestore, unverified }

    init() {
        #if DEBUG
        // Only the legacy UI suite uses this. App Store builds cannot unlock with arguments.
        let args = ProcessInfo.processInfo.arguments
        if args.contains("--ui-tests"), !args.contains("--free-access"), !args.contains("--store-tests") {
            testAccess = true
            hasFullAccess = true
            isChecking = false
        } else if !args.contains("--ui-tests") {
            debugUnlocked = UserDefaults.standard.bool(forKey: Self.debugUnlockKey)
            hasFullAccess = debugUnlocked
        }
        #endif
    }

    #if DEBUG
    func setDebugUnlocked(_ unlocked: Bool) {
        debugUnlocked = unlocked
        UserDefaults.standard.set(unlocked, forKey: Self.debugUnlockKey)
        hasFullAccess = entitled || unlocked
    }
    #endif

    func start() async {
        guard !started else { return }
        started = true
        guard !testAccess else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard !Task.isCancelled else { return }
                await self?.receive(result)
            }
        }
        await refresh()
        for await result in Transaction.unfinished { await receive(result) }
        await loadProduct()
    }

    /// Returns the entitlement this pass found, even when a newer refresh superseded it and applied its own.
    @discardableResult func refresh() async -> Bool {
        guard !testAccess else { return hasFullAccess }
        refreshVersion += 1
        let version = refreshVersion
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if valid(transaction) { entitled = true }
        }
        guard version == refreshVersion else { return entitled }
        self.entitled = entitled
        hasFullAccess = entitled
        #if DEBUG
        hasFullAccess = entitled || debugUnlocked
        #endif
        // A restore or verification message from before access arrived no longer applies.
        if hasFullAccess, notice == .nothingToRestore || notice == .unverified { notice = nil }
        isChecking = false
        return entitled
    }

    func loadProduct() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            product = try await Product.products(for: [AccessPolicy.productID]).first { $0.type == .nonConsumable }
            if product == nil { notice = .unavailable }
            else if notice == .unavailable { notice = nil }
        } catch { notice = .unavailable }
    }

    func purchase() async {
        guard !isBusy, !isChecking, !hasFullAccess else { return }
        guard let product else { notice = .unavailable; return }
        isBusy = true
        notice = nil
        defer { isBusy = false }
        Analytics.shared.record(.proPurchaseStarted)
        do {
            switch try await product.purchase() {
            case .success(let result):
                await receive(result)
                // `receive` is where a purchase becomes access; anything else is an outcome to count.
                Analytics.shared.record(hasFullAccess ? .proPurchased : .proPurchaseFailed,
                                        hasFullAccess ? [:] : ["reason": "unverified"])
            case .pending:
                notice = .pending
                Analytics.shared.record(.proPurchaseFailed, ["reason": "pending"])
            case .userCancelled:
                notice = .cancelled
                Analytics.shared.record(.proPurchaseFailed, ["reason": "cancelled"])
            @unknown default:
                notice = .failed
                Analytics.shared.record(.proPurchaseFailed, ["reason": "unknown"])
            }
        } catch {
            notice = .failed
            Analytics.shared.record(.proPurchaseFailed, ["reason": "error"])
        }
        Analytics.shared.flush()
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        notice = nil
        defer { isBusy = false }
        do {
            // Explicit user action only: sync may present Apple account authentication.
            try await AppStore.sync()
            let restored = await refresh()
            notice = restored ? .restored : .nothingToRestore
            if restored { Analytics.shared.record(.proRestored) }
        } catch StoreKitError.userCancelled {
            notice = nil
        } catch { notice = .failed }
    }

    private func valid(_ transaction: Transaction) -> Bool {
        transaction.productID == AccessPolicy.productID && transaction.productType == .nonConsumable && transaction.revocationDate == nil && !transaction.isUpgraded
    }
    private func receive(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { notice = .unverified; return }
        guard transaction.productID == AccessPolicy.productID else { return }
        await refresh()
        if hasFullAccess { notice = nil }
        // Entitlement is delivered (or revoked) before acknowledging the transaction.
        await transaction.finish()
    }
    deinit { updates?.cancel() }

    func allows(_ phrase: Phrase) -> Bool { AccessPolicy.allows(phrase, purchased: hasFullAccess) }
}
