# Review reminders

Settings → Notifications → Review reminders. This is optional and available on
Free and Pro. Default OFF, including existing installations. Enabling it asks
for iOS alert/sound permission; opening the app never prompts automatically.
The time defaults to 19:00 and can be changed. Turning OFF removes pending and
delivered vow review notifications, while retaining the time preference.

## Timing and access

The planner consumes `LearningData.memoryReviews` and its actual SM-2-derived
`due` dates. It schedules one local notification at the first selected wall-clock
time on or after a phrase is due. Cards due on the same reminder day are grouped.
Later reminders count earlier cards that remain due, until app activity replaces
the plan. No learned cards, no allowed cards, or reminders OFF means no requests.
It does not send daily promotional notifications or create new review intervals.
An Again answer still becomes available for review after ten minutes in the app;
the notification waits for the selected reminder time.

The next 32 distinct reminder dates are registered ahead of time, without repeat
triggers. Opening the app, changing a memory rating, changing language/time,
changing purchase access, and observed clock/time-zone changes rebuild the plan.
Daylight-saving gaps use the next valid local time; a repeated hour never creates
a second notification on the same day. Existing dates use the time zone in which
they were scheduled until the app can process a zone change.

Free users only get reminders for accessible free phrases. No server, push token,
background-task entitlement, or network service is involved. This uses the same
SM-2-derived learning schedule as Review, not an individual forgetting-probability
prediction or Anki's FSRS.

## Delivery and lifecycle

The notification center is installed before scenes appear. Tapping a review
notification selects Home, closes any sheet, cover or pushed phrase notes in front
of it, and shows Today's learning at the first card still to do. No banner or
sound interrupts foreground practice.
Notifications revoked in iOS Settings are detected on the next activation; pending
requests are removed and a button opens iOS notification settings. App-level ON
remains the user's preference while OS-level delivery is disabled.

A serialized coalescing worker prevents an in-flight old add from resurrecting
requests after OFF. It removes only identifiers under `vow.memory-review.`;
unrelated requests are preserved. Add failures remove a partial schedule and
show a retry control. Permission failure never switches the preference ON.
Notification text follows the selected Japanese/easy-English explanation language.

The system can delay or suppress presentation for Focus or Scheduled Summary.
Delivery while the app is closed uses already scheduled local notifications.
Dates beyond the 32-request window are replenished on the next app activation.

## Implementation and sources

- `Vow/Core/ReviewReminderPlan.swift`: preferences, access-aware daily batching.
- `Vow/Services/ReviewReminderCenter.swift`: authorization, queue replacement,
  notification content, response delegate.
- `Vow/Views/ReviewReminderSettingsSection.swift`: toggle, time, next date, recovery.
- The optional `reviewReminders` field keeps legacy learning files decodable.

Apple documentation checked September 13, 2026:
[Permission](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications),
[local notification scheduling](https://developer.apple.com/documentation/UserNotifications/scheduling-a-notification-locally-from-your-app).

## Verification — September 13, 2026

- Full iOS unit suite: 53 passed (`.build/ReviewRemindersRetry.xcresult`).
- Final reminder tests plus native UI flow: 11 passed
  (`.build/ReviewReminderFinal.xcresult`). This rerun includes the final DST and
  Today-tab routing changes.
- Native UI verified initial OFF, actual iOS permission opt-in, successful local
  scheduling/next date, persistence across relaunch, and OFF. ON/OFF screenshots
  were inspected from `.build/ReviewReminderUI-attachments/`.
- Unit cases cover SM-2 deadlines, batching, overdue cards, preferred time,
  spring/fall DST, time-zone differences, 32-request bound, legacy persistence,
  denied/revoked permission, revoked access, failure cleanup, language changes,
  and OFF winning over an in-flight asynchronous add. Calendar triggers are
  non-repeating and have a future next trigger date.
- Physical-device delivery, Focus/Scheduled Summary timing, VoiceOver, and an
  actual delivered-notification tap remain unverified. Routing was code-reviewed;
  no synthetic push was counted as proof of a scheduled local notification.
- No App Store/TestFlight upload or repository commit was performed.
