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

    func refresh() async {
        guard !testAccess else { return }
        refreshVersion += 1
        let version = refreshVersion
        var entitled = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if valid(transaction) { entitled = true }
        }
        guard version == refreshVersion else { return }
        self.entitled = entitled
        hasFullAccess = entitled
        #if DEBUG
        hasFullAccess = entitled || debugUnlocked
        #endif
        isChecking = false
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
        do {
            switch try await product.purchase() {
            case .success(let result): await receive(result)
            case .pending: notice = .pending
            case .userCancelled: notice = .cancelled
            @unknown default: notice = .failed
            }
        } catch { notice = .failed }
    }

    func restore() async {
        guard !isBusy else { return }
        isBusy = true
        notice = nil
        defer { isBusy = false }
        do {
            // Explicit user action only: sync may present Apple account authentication.
            try await AppStore.sync()
            await refresh()
            notice = hasFullAccess ? .restored : .nothingToRestore
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
