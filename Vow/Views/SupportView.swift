import SwiftUI

struct SupportView: View {
    @State private var copiedEmail = false
    @State private var resetCopied: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                Link("Open support website", destination: AppSupport.supportURL)
                    .accessibilityIdentifier("supportWebsite")
                Link("Email support", destination: AppSupport.emailURL)
                    .accessibilityIdentifier("supportEmail")
                Text(AppSupport.email).textSelection(.enabled)
                Button {
                    UIPasteboard.general.string = AppSupport.email
                    withAnimation(Motion.snappy) { copiedEmail = true }
                    // The confirmation reverts, so a second copy confirms again.
                    resetCopied?.cancel()
                    resetCopied = Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        guard !Task.isCancelled else { return }
                        withAnimation(Motion.snappy) { copiedEmail = false }
                    }
                } label: {
                    Label {
                        Text(copiedEmail ? LocalizedStringKey("Email address copied") : LocalizedStringKey("Copy email address"))
                    } icon: {
                        Image(systemName: copiedEmail ? "checkmark" : "doc.on.doc").contentTransition(.symbolEffect(.replace))
                    }
                }.accessibilityIdentifier("copySupportEmail")
            } footer: {
                Text("If no email app is set up, copy the address and contact us from your preferred service. Include the app version and what happened; please do not send passwords or payment details.")
            }
            Section("Purchases") {
                Text("To restore Vow Pro, use Restore purchases in Settings or on the purchase screen with the Apple Account used for the original purchase. Restoring purchases does not transfer learning history.")
                Text("If the price is unavailable, check your connection and use Reload price on the purchase screen. The free collection remains available.")
            }
            Section("Microphone") {
                Text("Recording is optional. You can speak without recording or type a reply. Microphone access can be changed in iOS Settings.")
            }
            Section("Your data") {
                Text("Learning history, saved phrases and notes stay on this device. Deleting the app removes its local data. A device backup may restore it. There is no app account to delete.")
                NavigationLink("Privacy policy") { PrivacyView() }
            }
            Section {
                LabeledContent("Version", value: AppSupport.versionDescription)
                    .accessibilityIdentifier("supportVersion")
            }
        }.scrollContentBackground(.hidden).background { ReadingBackground() }
            .foregroundStyle(Palette.ink).tint(Palette.ink)
            .navigationTitle("Help & support").navigationBarTitleDisplayMode(.inline)
    }
}
