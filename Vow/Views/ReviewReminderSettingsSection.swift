import SwiftUI

struct ReviewReminderSettingsSection: View {
    @Environment(LearningStore.self) private var store
    @Environment(ReviewReminderCenter.self) private var reminders
    @Environment(\.appAccent) private var accent
    private var preferences: ReviewReminderPreferences { store.data.reminderPreferences }
    private var time: Binding<Date> {
        Binding {
            Calendar.current.date(bySettingHour: preferences.safeHour, minute: preferences.safeMinute, second: 0, of: .now) ?? .now
        } set: { date in
            let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
            store.configureReminders(hour: parts.hour, minute: parts.minute)
        }
    }

    var body: some View {
        Section {
            Toggle("Review reminders", isOn: Binding(get: { preferences.enabled }, set: { enabled in
                if enabled {
                    Task {
                        if await reminders.requestPermission() {
                            store.configureReminders(enabled: true)
                            reminders.retry()
                        }
                    }
                } else {
                    store.configureReminders(enabled: false)
                }
            }))
            .tint(accent.color)
            .disabled(reminders.isRequestingPermission)
            .accessibilityIdentifier("reviewReminders")

            if preferences.enabled {
                DatePicker("Reminder time", selection: time, displayedComponents: .hourAndMinute)
                    .accessibilityIdentifier("reviewReminderTime")
            }
            if reminders.authorization == .denied {
                Text("Notifications are disabled in iOS Settings.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                Button("Open notification settings") {
                    guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
                    UIApplication.shared.open(url)
                }.accessibilityIdentifier("openNotificationSettings")
            } else if preferences.enabled, reminders.hasCheckedAuthorization, reminders.authorization == .notDetermined {
                // Reminders were turned on elsewhere (a restored backup) but this device never asked for permission.
                Button("Allow notifications") {
                    Task { if await reminders.requestPermission() { reminders.retry() } }
                }.disabled(reminders.isRequestingPermission).accessibilityIdentifier("allowNotifications")
            } else if preferences.enabled {
                if let next = reminders.nextReminder {
                    LabeledContent("Next reminder", value: next.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                        .accessibilityIdentifier("nextReviewReminder")
                } else {
                    Text("A reminder will be scheduled when a learned phrase is due for review.")
                        .font(.subheadline).foregroundStyle(Palette.secondary)
                }
            }
            if let error = reminders.errorMessage {
                Text(error).font(.subheadline).foregroundStyle(Palette.secondary)
                Button("Try again") {
                    Task {
                        if await reminders.requestPermission() {
                            store.configureReminders(enabled: true)
                            reminders.retry()
                        }
                    }
                }
            }
        } header: {
            Text("Notifications")
        } footer: {
            Text("Notifies you at the first chosen time after a review is due, at most once a day. Turning this off cancels scheduled reminders.")
        }
    }
}

/// A review opened from a notification needs the whole screen, so sheets and covers anywhere in the app
/// close when one arrives; Home opens the review once nothing is presented any more.
private struct ClosesForReviewRequest: ViewModifier {
    @Environment(ReviewReminderCenter.self) private var reminders
    let close: () -> Void
    func body(content: Content) -> some View {
        content.onChange(of: reminders.reviewRequest) { _, request in if request != nil { close() } }
    }
}

extension View {
    func closesForReviewRequest(_ isPresented: Binding<Bool>) -> some View {
        modifier(ClosesForReviewRequest { isPresented.wrappedValue = false })
    }
    func closesForReviewRequest<Item>(_ item: Binding<Item?>) -> some View {
        modifier(ClosesForReviewRequest { item.wrappedValue = nil })
    }
}

@MainActor enum ScreenPresentation {
    /// True while any sheet or cover is on screen, including one on its way out; a new cover can't appear then.
    static var isCovered: Bool {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows).contains { $0.isKeyWindow && $0.rootViewController?.presentedViewController != nil }
    }
}
