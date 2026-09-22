import CloudKit
import Observation
import UIKit

/// Keeps the learning data in the learner's private iCloud database, as one record holding the
/// whole file, so it follows them to a new device and between an iPhone and an iPad. CKSyncEngine
/// decides when to fetch and send; every copy that arrives is merged with this device's data by
/// `LearningMerge` against the last copy this device saw, which is kept beside the learning file.
@MainActor @Observable final class CloudSync {
    enum Status: Equatable {
        case off, syncing, synced, noAccount, unavailable, storageFull, needsUpdate, failed
    }

    private(set) var isEnabled: Bool
    private(set) var status: Status = .off
    private(set) var lastSynced: Date?

    static let containerID = "iCloud.me.unvalley.izzy"
    private static let enabledKey = "cloudSync.enabled"
    private static let zoneID = CKRecordZone.ID(zoneName: "Learning")
    private static let recordID = CKRecord.ID(recordName: "learning", zoneID: zoneID)
    private static let recordType = "Learning"

    private let store: LearningStore
    /// False in unit and UI tests, which run without the iCloud entitlement.
    private let isAvailable: Bool
    private let defaults: UserDefaults
    private let stateFile: URL
    private let baseFile: URL
    private var container: CKContainer?
    private var engine: CKSyncEngine?
    private var state: SavedState
    /// This device's data as of the server copy it last saw: the common ancestor for every merge.
    private var base: LearningData?
    /// Each upload's data, oldest first, so the one the server accepts becomes the base.
    private var outgoing: [(file: URL, data: LearningData)] = []
    /// Set when iCloud holds a copy written by a newer build: nothing is sent until this one is updated.
    private var heldForUpdate = false

    private struct SavedState: Codable {
        var engine: CKSyncEngine.State.Serialization?
        /// The last server copy's system fields, which carry the change tag an upload must match.
        var recordFields: Data?
        var lastSynced: Date?
    }

    init(store: LearningStore, isAvailable: Bool, defaults: UserDefaults = .standard,
         folder: URL = URL.applicationSupportDirectory.appending(path: "Izzy")) {
        self.store = store
        self.isAvailable = isAvailable
        self.defaults = defaults
        stateFile = folder.appending(path: "sync-state.json")
        baseFile = folder.appending(path: "sync-base.json")
        // Absent means on: a new install syncs unless it is turned off in Settings.
        isEnabled = defaults.object(forKey: Self.enabledKey) as? Bool ?? true
        state = (try? JSONDecoder().decode(SavedState.self, from: Data(contentsOf: stateFile))) ?? SavedState()
        base = try? JSONDecoder().decode(LearningData.self, from: Data(contentsOf: baseFile))
        lastSynced = state.lastSynced
    }

    func start() {
        guard isAvailable, isEnabled, engine == nil, store.canSave else { return }
        let container = CKContainer(identifier: Self.containerID)
        self.container = container
        let engine = CKSyncEngine(.init(database: container.privateCloudDatabase, stateSerialization: state.engine, delegate: self))
        self.engine = engine
        if state.engine == nil { engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))]) }
        // Anything changed while sync was off; skipped when it matches the server copy.
        engine.state.add(pendingRecordZoneChanges: [.saveRecord(Self.recordID)])
        store.didSave = { [weak self] in self?.upload() }
        status = .syncing
        Task { await checkAccount() }
    }

    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        defaults.set(enabled, forKey: Self.enabledKey)
        if enabled { start() } else { stop() }
    }

    /// On returning to the foreground, in case a push was missed.
    func fetch() {
        guard let engine else { return }
        Task { try? await engine.fetchChanges() }
    }

    /// On leaving the foreground, so a review just made reaches iCloud now rather than at the next launch.
    func sendPending() {
        guard let engine, !engine.state.pendingRecordZoneChanges.isEmpty else { return }
        let time = BackgroundTime()
        Task {
            try? await engine.sendChanges()
            time.end()
        }
    }

    /// Turning sync off keeps what this device knows of the server copy, so turning it back on
    /// merges the changes made meanwhile against it.
    private func stop() {
        store.didSave = nil
        let engine = engine
        self.engine = nil
        status = .off
        Task { await engine?.cancelOperations() }
    }

    private func upload() {
        engine?.state.add(pendingRecordZoneChanges: [.saveRecord(Self.recordID)])
    }

    private func checkAccount() async {
        guard let container, let account = try? await container.accountStatus() else { return }
        switch account {
        case .available: if status == .noAccount || status == .unavailable { status = .syncing }
        case .noAccount: status = .noAccount
        default: status = .unavailable
        }
    }

    // MARK: Server copies

    private func receive(_ record: CKRecord) {
        guard let remote = decode(record) else { return }
        let merged = LearningMerge.merge(base: base, local: store.data, remote: remote)
        state.recordFields = Self.systemFields(of: record)
        saveState()
        setBase(remote)
        store.replace(with: merged)
        if merged != remote { upload() }
    }

    private func decode(_ record: CKRecord) -> LearningData? {
        guard (record["format"] as? Int ?? 0) <= LearningMerge.format else {
            heldForUpdate = true
            status = .needsUpdate
            return nil
        }
        guard let file = (record["data"] as? CKAsset)?.fileURL,
              let compressed = try? Data(contentsOf: file),
              let json = try? (compressed as NSData).decompressed(using: .lzfse) as Data,
              let data = try? JSONDecoder().decode(LearningData.self, from: json), data.schema == 1 else {
            status = .failed
            return nil
        }
        return data
    }

    private func makeRecord() -> CKRecord? {
        let record = state.recordFields.flatMap(Self.record(fromSystemFields:)) ?? CKRecord(recordType: Self.recordType, recordID: Self.recordID)
        let data = store.data
        do {
            let compressed = try (JSONEncoder().encode(data) as NSData).compressed(using: .lzfse) as Data
            let file = FileManager.default.temporaryDirectory.appending(path: "learning-\(UUID().uuidString).lzfse")
            try compressed.write(to: file)
            outgoing.append((file, data))
            record["data"] = CKAsset(fileURL: file)
            record["format"] = LearningMerge.format
            return record
        } catch {
            status = .failed
            return nil
        }
    }

    private func sent(_ changes: CKSyncEngine.Event.SentRecordZoneChanges) {
        for record in changes.savedRecords where record.recordID == Self.recordID {
            if let upload = takeOutgoing() { setBase(upload.data) }
            state.recordFields = Self.systemFields(of: record)
            saveState()
        }
        for failure in changes.failedRecordSaves where failure.record.recordID == Self.recordID {
            _ = takeOutgoing()
            switch failure.error.code {
            case .serverRecordChanged:
                // Another device uploaded first: merge with its copy, which comes with the error.
                if let server = failure.error.serverRecord { receive(server) }
            case .zoneNotFound:
                forgetServerCopy()
                engine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
                upload()
            case .unknownItem:
                forgetServerCopy()
                upload()
            case .quotaExceeded:
                status = .storageFull
            case .networkFailure, .networkUnavailable, .zoneBusy, .serviceUnavailable, .notAuthenticated, .operationCancelled, .requestRateLimited:
                break // CKSyncEngine retries these itself.
            default:
                status = .failed
            }
        }
    }

    private func takeOutgoing() -> (file: URL, data: LearningData)? {
        guard !outgoing.isEmpty else { return nil }
        let upload = outgoing.removeFirst()
        try? FileManager.default.removeItem(at: upload.file)
        return upload
    }

    private func zoneDeleted(_ reason: CKDatabase.DatabaseChange.Deletion.Reason) {
        forgetServerCopy()
        switch reason {
        case .purged:
            // Deleted from iCloud storage in the Settings app: stop here too, keeping this device's copy.
            state = SavedState()
            saveState()
            setEnabled(false)
        case .deleted, .encryptedDataReset:
            engine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
            upload()
        @unknown default:
            break
        }
    }

    private func accountChanged(_ change: CKSyncEngine.Event.AccountChange.ChangeType) {
        // A different account's copy has no common ancestor with this device's data.
        forgetServerCopy()
        switch change {
        case .signIn, .switchAccounts:
            engine?.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: Self.zoneID))])
            upload()
            status = .syncing
        case .signOut:
            status = .noAccount
        @unknown default:
            break
        }
    }

    // MARK: Saved state

    private func forgetServerCopy() {
        state.recordFields = nil
        saveState()
        base = nil
        try? FileManager.default.removeItem(at: baseFile)
    }

    private func setBase(_ data: LearningData) {
        base = data
        write(data, to: baseFile)
    }

    private func saveState() { write(state, to: stateFile) }

    private func write(_ value: some Encodable, to file: URL) {
        try? FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? JSONEncoder().encode(value).write(to: file, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }

    private func settle() {
        guard status == .syncing else { return }
        status = .synced
        lastSynced = .now
        state.lastSynced = lastSynced
        saveState()
    }

    private static func systemFields(of record: CKRecord) -> Data {
        let coder = NSKeyedArchiver(requiringSecureCoding: true)
        record.encodeSystemFields(with: coder)
        coder.finishEncoding()
        return coder.encodedData
    }

    private static func record(fromSystemFields data: Data) -> CKRecord? {
        guard let coder = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        coder.requiresSecureCoding = true
        defer { coder.finishDecoding() }
        return CKRecord(coder: coder)
    }
}

extension CloudSync: CKSyncEngineDelegate {
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        // A turned-off engine can still deliver what was already under way.
        guard syncEngine === engine else { return }
        switch event {
        case .stateUpdate(let update):
            state.engine = update.stateSerialization
            saveState()
        case .accountChange(let change):
            accountChanged(change.changeType)
        case .fetchedDatabaseChanges(let changes):
            for deletion in changes.deletions where deletion.zoneID == Self.zoneID { zoneDeleted(deletion.reason) }
        case .fetchedRecordZoneChanges(let changes):
            for modification in changes.modifications where modification.record.recordID == Self.recordID { receive(modification.record) }
            if changes.deletions.contains(where: { $0.recordID == Self.recordID }) {
                forgetServerCopy()
                upload()
            }
        case .sentDatabaseChanges(let changes):
            if !changes.failedZoneSaves.isEmpty { status = .failed }
        case .sentRecordZoneChanges(let changes):
            sent(changes)
        case .willFetchChanges, .willSendChanges:
            if !heldForUpdate { status = .syncing }
        case .didFetchChanges, .didSendChanges:
            settle()
        case .willFetchRecordZoneChanges, .didFetchRecordZoneChanges:
            break
        @unknown default:
            break
        }
    }

    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext, syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? {
        guard syncEngine === engine else { return nil }
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        let save = CKSyncEngine.PendingRecordZoneChange.saveRecord(Self.recordID)
        // Only the one record is ever stored; anything else is dropped rather than retried forever.
        let unknown = pending.filter { $0 != save }
        if !unknown.isEmpty { syncEngine.state.remove(pendingRecordZoneChanges: unknown) }
        guard pending.contains(save) else { return nil }
        if heldForUpdate || (state.recordFields != nil && base == store.data) {
            syncEngine.state.remove(pendingRecordZoneChanges: [save])
            return nil
        }
        guard let record = makeRecord() else { return nil }
        return CKSyncEngine.RecordZoneChangeBatch(recordsToSave: [record])
    }
}

/// Asks iOS for time to finish a send after the app leaves the foreground.
@MainActor private final class BackgroundTime {
    private var id = UIBackgroundTaskIdentifier.invalid

    init() {
        id = UIApplication.shared.beginBackgroundTask(withName: "iCloud sync") { [weak self] in self?.end() }
    }

    func end() {
        guard id != .invalid else { return }
        UIApplication.shared.endBackgroundTask(id)
        id = .invalid
    }
}
