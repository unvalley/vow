import Foundation

enum AppSupport {
    static let email = "studio@unvalley.me"
    static let emailURL = URL(string: "mailto:studio@unvalley.me")!
    static let supportURL = URL(string: "https://izzy.unvalley.me/support/")!
    static let privacyURL = URL(string: "https://izzy.unvalley.me/privacy/")!
    static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!

    static var versionDescription: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "—"
        let build = info["CFBundleVersion"] as? String ?? "—"
        return "\(version) (\(build))"
    }
}
