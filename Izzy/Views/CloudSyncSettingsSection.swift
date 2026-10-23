import SwiftUI

struct CloudSyncSettingsSection: View {
    @Environment(CloudSync.self) private var sync
    @Environment(\.appAccent) private var accent

    var body: some View {
        Section {
            Toggle("Sync with iCloud", isOn: Binding(get: { sync.isEnabled }, set: { sync.setEnabled($0) }))
                .tint(accent.color).accessibilityIdentifier("iCloudSync")
            if let detail {
                Text(detail).font(.subheadline).foregroundStyle(Palette.secondary)
                    .accessibilityIdentifier("iCloudSyncStatus")
            }
        } header: {
            Text("iCloud")
        } footer: {
            Text("Your learning history, saved phrases and notes are saved to iCloud and stay the same on every device signed in to your Apple Account.")
        }
    }

    private var detail: LocalizedStringKey? {
        guard sync.isEnabled else { return nil }
        switch sync.status {
        case .off: return nil
        case .syncing: return "Syncing…"
        case .synced: return sync.lastSynced.map { "Last synced \($0.formatted(.relative(presentation: .named)))" }
        case .noAccount: return "Sign in to iCloud in the Settings app to sync."
        case .unavailable: return "iCloud isn't available right now."
        case .storageFull: return "Your iCloud storage is full."
        case .needsUpdate: return "Update Izzy to keep syncing."
        case .failed: return "Couldn't sync. Izzy will try again."
        }
    }
}
