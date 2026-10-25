import Foundation
import Observation
import StoreKit

@MainActor @Observable final class PurchaseStore {
    private(set) var product: Product?
    /// The ¥0 time-limited trial, present only once it is set up in App Store Connect.
    private(set) var trialProduct: Product?
    private(set) var hasFullAccess = false
    /// When this Apple Account's trial ends or ended; nil until a trial is started.
    private(set) var trialEnds: Date?
    /// Pro is open because of the trial, not a purchase.
    private(set) var isTrialing = false
    private(set) var isChecking = true
    private(set) var isLoading = false
    private(set) var isBusy = false
    private(set) var notice: Notice?
    @ObservationIgnored private var updates: Task<Void, Never>?
    /// Closes the trial at its end while the app is open; a later launch or foreground refresh also would.
    @ObservationIgnored private var trialExpiry: Task<Void, Never>?
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

    /// Bought Pro, as opposed to trying it; debug and UI-test unlocks count as bought.
    var isPurchased: Bool { hasFullAccess && !isTrialing }
    /// The trial is offered once per Apple Account, never beside a purchase.
    var canStartTrial: Bool { trialProduct != nil && trialEnds == nil && !hasFullAccess && !isChecking }

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
        hasFullAccess = entitled || isTrialing || unlocked
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

    /// Returns the purchase this pass found, even when a newer refresh superseded it and applied its own.
    /// A trial is not a purchase, so restoring one reports nothing to restore.
    @discardableResult func refresh(now: Date = .now) async -> Bool {
        guard !testAccess else { return hasFullAccess }
        refreshVersion += 1
        let version = refreshVersion
        var entitled = false
        var trialStart: Date?
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if valid(transaction) { entitled = true }
            if transaction.productID == AccessPolicy.trialProductID, transaction.revocationDate == nil {
                trialStart = transaction.purchaseDate
            }
        }
        guard version == refreshVersion else { return entitled }
        self.entitled = entitled
        trialEnds = trialStart.map { AccessPolicy.trialEnd(startedAt: $0) }
        isTrialing = !entitled && trialEnds.map { now < $0 } == true
        hasFullAccess = entitled || isTrialing
        #if DEBUG
        hasFullAccess = entitled || isTrialing || debugUnlocked
        #endif
        scheduleTrialExpiry(now: now)
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
            let products = try await Product.products(for: [AccessPolicy.productID, AccessPolicy.trialProductID])
            product = products.first { $0.id == AccessPolicy.productID && $0.type == .nonConsumable }
            trialProduct = products.first { $0.id == AccessPolicy.trialProductID && $0.type == .nonConsumable }
            if product == nil { notice = .unavailable }
            else if notice == .unavailable { notice = nil }
        } catch { notice = .unavailable }
    }

    /// Buying stays open during the trial: that is when most people decide.
    func purchase() async {
        guard !isBusy, !isChecking, !isPurchased else { return }
        guard let product else { notice = .unavailable; return }
        isBusy = true
        notice = nil
        defer { isBusy = false }
        Analytics.shared.record(.proPurchaseStarted, isTrialing ? ["during": "trial"] : [:])
        do {
            switch try await product.purchase() {
            case .success(let result):
                await receive(result)
                // `receive` is where a purchase becomes access; anything else is an outcome to count.
                Analytics.shared.record(isPurchased ? .proPurchased : .proPurchaseFailed,
                                        isPurchased ? [:] : ["reason": "unverified"])
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

    /// Starts the one free trial. The purchase sheet Apple shows says ¥0; the screen that offers this
    /// has already said how long it lasts, what closes when it ends, and that nothing is charged.
    func startTrial() async {
        guard !isBusy, canStartTrial, let trialProduct else { return }
        isBusy = true
        notice = nil
        defer { isBusy = false }
        do {
            switch try await trialProduct.purchase() {
            case .success(let result):
                await receive(result)
                if isTrialing { Analytics.shared.record(.proTrialStarted) }
            case .pending: notice = .pending
            case .userCancelled: notice = .cancelled
            @unknown default: notice = .failed
            }
        } catch { notice = .failed }
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
    private func scheduleTrialExpiry(now: Date) {
        trialExpiry?.cancel()
        guard isTrialing, let trialEnds else { return }
        let wait = trialEnds.timeIntervalSince(now)
        trialExpiry = Task { [weak self] in
            try? await Task.sleep(for: .seconds(wait))
            guard !Task.isCancelled else { return }
            await self?.refresh()
        }
    }
    private func receive(_ result: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = result else { notice = .unverified; return }
        guard transaction.productID == AccessPolicy.productID || transaction.productID == AccessPolicy.trialProductID else { return }
        await refresh()
        if hasFullAccess { notice = nil }
        // Entitlement is delivered (or revoked) before acknowledging the transaction.
        await transaction.finish()
    }
    deinit {
        updates?.cancel()
        trialExpiry?.cancel()
    }

    func allows(_ phrase: Phrase) -> Bool { AccessPolicy.allows(phrase, purchased: hasFullAccess) }
}
