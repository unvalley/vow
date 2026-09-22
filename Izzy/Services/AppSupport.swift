import Foundation

enum AppSupport {
    static let email = "studio@unvalley.me"
    static let emailURL = URL(string: "mailto:studio@unvalley.me")!
    static let supportURL = URL(string: "https://izzy.unvalley.me/support/")!
    static let privacyURL = URL(string: "https://izzy.unvalley.me/privacy/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    /// What sharing links to: the landing page in the app's language, whose social card previews the link.
    static var shareURL: URL {
        URL(string: Bundle.main.preferredLocalizations.first == "ja" ? "https://izzy.unvalley.me/" : "https://izzy.unvalley.me/en/")!
    }

    static var versionDescription: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
