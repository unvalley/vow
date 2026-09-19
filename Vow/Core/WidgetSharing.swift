import Foundation

/// Something the app writes and a widget reads. Each kind keeps its own file so a change to one
/// widget's content does not spend the other's reload budget.
protocol WidgetShared: Codable, Sendable, Equatable {
    static var fileName: String { get }
    /// The `kind` its widget registers under, so the app can reload that one alone.
    static var widgetKind: String { get }
    /// Read back only at the version this build understands; anything else is treated as absent
    /// and the app rewrites it on its next run.
    var schema: Int { get }
}

/// The App Group container both targets share. Without the group enabled on each, the container is
/// unavailable and the widgets show their empty state.
enum WidgetSharing {
    static let appGroup = "group.me.unvalley.izzy"
    /// Both sides of the tap: the widget opens it, the app matches on it.
    static let todayURL = URL(string: "izzy://today")!

    /// Resolving the container is documented as expensive, so it is looked up once.
    private static let container = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup)

    private static func url<T: WidgetShared>(for type: T.Type) -> URL? {
        container?.appending(path: type.fileName)
    }

    static func read<T: WidgetShared>(_ type: T.Type, from url: URL? = nil) -> T? {
        guard let url = url ?? Self.url(for: type), let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode(T.self, from: data), value.schema == 1 else { return nil }
        return value
    }

    static func write<T: WidgetShared>(_ value: T, to url: URL? = nil) throws {
        guard let url = url ?? Self.url(for: T.self) else { throw CocoaError(.fileNoSuchFile) }
        // A widget reads on its own schedule, so a partial file must never be visible, and it renders
        // while the device is locked, so the file has to stay readable after the first unlock.
        try JSONEncoder().encode(value)
            .write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
