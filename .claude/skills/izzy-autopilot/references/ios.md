# iOS

## Simulators of your own

Other sessions drive simulators too, and the `Izzy Store …` devices belong to the store
screenshot workflow. `scripts/capture-ios.sh` creates and uses `Izzy Autopilot` (iPhone 17
Pro) and, with `--ipad`, `Izzy Autopilot iPad` (iPad Air 13-inch). To get the iPhone's id
for a test run:

```bash
udid=$(xcrun simctl list devices available | sed -n 's/.*Izzy Autopilot (\([0-9A-F-]*\)).*/\1/p' | head -1)
[ -n "$udid" ] || udid=$(xcrun simctl create "Izzy Autopilot" "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
xcrun simctl boot "$udid" 2>/dev/null || true
```

A simulator that has run for days gets slow; `xcrun simctl shutdown` and boot it again
before believing a strange failure. Shut both down at the end of the cycle.

## Gates

Run in `$WT`. Build products go to `$STATE/DerivedData`, shared by every cycle, so the
SDK module cache stays warm.

```bash
# Core package (Izzy/Core and phrases.json), on the Mac itself: a minute or two.
swift test --scratch-path .build/SwiftPackage --jobs 4 > "$LOG" 2>&1
# iOS build, app and widget.
xcodebuild -project Izzy.xcodeproj -scheme Izzy -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath "$STATE/DerivedData" \
  CODE_SIGNING_ALLOWED=NO build > "$LOG" 2>&1
# Unit tests (IzzyTests, which also holds AppearanceTests).
xcodebuild -project Izzy.xcodeproj -scheme Izzy -configuration Debug \
  -destination "platform=iOS Simulator,id=$udid" -derivedDataPath "$STATE/DerivedData" \
  -parallel-testing-enabled NO -only-testing:IzzyTests CODE_SIGNING_ALLOWED=NO test > "$LOG" 2>&1
# Catalog and its scripts.
python3 scripts/test_collection.py > "$LOG" 2>&1
```

Never `-only-testing:IzzyUITests`, the `IzzyPerformance` scheme or the `IzzyStore`
scheme's UI tests: the user runs UI tests themself. `IzzyStoreTests` (StoreKit) only when
`PurchaseStore` or the store configuration changed.

A new or removed Swift file: `xcodegen generate` in `$WT` (the project is generated from
`project.yml`, which scans folders), then commit `Izzy.xcodeproj` with the change.

## Design reference

`docs/DESIGN-SYSTEM.md` (layout and appearance, with dated decisions) and the tokens in
`Izzy/Views/DesignTokens.swift`: `Palette`, `Typography`, `Spacing` (4, 8, 12, 16, 24, 32),
`Radius` (12, 18, 24), `Motion`, and `AppAccent`'s `color` / `fill` / `mark` / `soft`.
Shared components live in `Izzy/Views/DesignSystem.swift` (`PrimaryButton`,
`SecondaryButton` and the rest). The Design System section of `README.md` lists the
SF Symbols each place uses.

## Capture

```bash
scripts/capture-ios.sh "$WT" "$STATE/captures/IZ-0012/before-home-ja.png"
scripts/capture-ios.sh "$WT" "$STATE/captures/IZ-0012/before-home-dark-ja.png" --no-build --dark
scripts/capture-ios.sh "$WT" "$STATE/captures/IZ-0012/before-home-ax3-en.png" --no-build --en --ax accessibility-extra-extra-extra-large
scripts/capture-ios.sh "$WT" "$STATE/captures/IZ-0012/before-stats.png" --no-build -- --stats-fixture
```

The script builds `$WT` (unless `--no-build`), installs it on the autopilot simulator,
sets appearance, language and text size, launches with `--ui-tests --reset-ui-tests` (an
isolated store with Pro unlocked and the daily goal set to five) plus whatever follows
`--`, waits for the first frame and saves the screenshot.

- App launch arguments (`Izzy/IzzyApp.swift`, Debug builds only): `--free-access` (free
  plan), `--stats-fixture` (a week of practice), `--pack-fixture`,
  `--free-finished-fixture`, `--show-onboarding`, `--choose-daily-goal`, `--design-dark`,
  `--design-reduce-motion`, `--locale-language` (follow the device language instead of the
  test store's Japanese default).
- The `izzy://today` link opens Home: `xcrun simctl openurl "$udid" izzy://today`.
- A screen no argument reaches: copy the worktree (`rsync -a --exclude .build "$WT/"
  "$STATE/preview/<IZ-id>/"`), patch `RootView` in `Izzy/IzzyApp.swift` *there* to present
  the screen when `--autopilot-preview-<name>` is passed, and run capture-ios.sh on that
  copy. Never put the route in `$WT`; land.sh refuses a diff that contains it.
- When the user is at the machine, the iOS Simulator tool can tap and swipe too; an
  unattended run cannot answer its access prompt, so do not depend on it.
- Before and after: capture the worktree before editing for "before", after editing for
  "after", with the same arguments.

## Traps

- `Izzy/Core` is compiled into the widget and into the Swift package: keep it
  Foundation-only, no SwiftUI or UIKit.
- `AppearanceTests` is in the Xcode test target only; `swift test` does not see it.
- `Localizable.xcstrings` and `InfoPlist.xcstrings`: add or change entries textually in
  place, with both `en` and `ja`; never round-trip the file through a JSON library.
  Plurals come from the catalog (`%lld days`), never from string building.
- Only one `sheet` and one `fullScreenCover` per view chain actually presents. Add a new
  presentation as a case of the existing destination rather than a second modifier.
- Changing `ForEach` data inside `withAnimation` can crash on SwiftUI's render thread
  under Swift 6. Set data outside the animation.
- Crash reports: `~/Library/Logs/DiagnosticReports/Izzy*.ips`.
