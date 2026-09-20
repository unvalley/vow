# Today card swipes — 2026-09-12

**Decision: retain the existing page-style TabView.** A horizontal ScrollView
with a zero-spacing LazyHStack, fixed page size, paging targets, and bound scroll
position did not materially improve the measured swipe. The experiment was
reverted. This task adds native measurement coverage, not a claimed swipe fix.

## Actual UI measurement

Environment: Apple M3 Mac, macOS 26.6.2, Xcode 26.5; iPhone 17 Pro Simulator
`5D893C95-B5FF-4B4E-B56A-6A7881397610`, iOS 26.3. Release builds for both variants;
no DEBUG access override and no `-enable-testing` in the app. The same 614-phrase
catalog, starting card, and normal app data were used. The test changes no
bookmarks, examples, language settings, or learning progress.

After launching and warming up with one left/right pair, XCTest measures ten
pairs of real horizontal gestures: `bring up → get across → bring up`. Each
destination must be hittable. Numbers below are **per pair**, not per swipe.
p50 is the median; p95 is nearest-rank, which is the maximum with ten samples.
No samples were discarded.

| Metric | Existing p50 / p95 | Lazy experiment p50 / p95 |
| --- | ---: | ---: |
| Scroll dragging + deceleration duration | 514.65 / 518.67 ms | 515.29 / 517.62 ms |
| App CPU time during test interval | 445.26 / 481.06 ms | 438.50 / 479.50 ms |
| App peak physical footprint | 58.94 / 58.97 MB | 58.19 / 58.35 MB |
| App retired CPU instructions | 1.027 / 1.045 billion | 1.058 / 1.066 billion |
| Whole XCTest interval, including driver | 1568.29 / 1873.46 ms | 1503.72 / 1564.32 ms |

The scroll duration is essentially unchanged; CPU ranges overlap, while retired
instructions increase slightly. The small memory difference does not justify
replacing a working pager. Driver-inclusive clock time is not finger-to-screen
latency and is not used to claim an improvement.

Apple's [scrollingAndDecelerationMetric](https://developer.apple.com/documentation/xctest/xctossignpostmetric/scrollinganddecelerationmetric)
covers scroll dragging and deceleration intervals. Neither that metric nor
`XCTHitchMetric` emitted frame/hitch values on this simulator. Missing values
are **not zero hitches**. Physical-device frame pacing, touch latency, 60/120 fps,
and energy remain unverified.

## Attribution and evidence

A separate 10-second native stack sample was captured during the baseline UI
flow. Of 1,840 main-thread samples, 1,640 were in the run-loop wait. Of the
remaining 200, 133 were under XCTest's main-loop automation block. SwiftUI
paging/layout and Today body work also appear, but this sample does not establish
that all 614 cards are eagerly created or that application code is the dominant
source of a user-visible stall. This is why the automated CPU number is qualified.

- [Raw samples and distributions](performance/2026-09-12/swipe-metrics.json).
- Baseline: `.build/SwipeBaselineRelease.xcresult`, `.build/SwipePerformance/baseline-release.log`.
- Experiment: `.build/SwipeLazyExperiment.xcresult`, `.build/SwipePerformance/lazy-experiment.log`.
- Attribution only: `.build/SwipeSample.xcresult`, `.build/SwipePerformance/baseline-sample.txt`.
  Its instrumented values are not used in the comparison table.
- An earlier attempt with the regular scheme did not build because Release
  excludes `-enable-testing` required by the core test target. The separate
  `IzzyPerformance` scheme selects just `SwipePerformanceTests` and keeps the
  production optimization settings. An xctrace attach attempt did not find the
  short-lived process; no Instruments trace is claimed.
- Original and restored Today source are byte-for-byte identical. The temporary
  alternative remains only in `.build/SwipePerformance/lazy-TodayView.swift`.
- Final restored Release run passed all ten measured left/right pairs in
  `.build/SwipeRestored.xcresult`. The scheme's selected-test configuration was
  exercised without an `-only-testing` command-line filter. Raw restored samples
  are included with the comparison data.

## Repeat on a simulator or connected device

From the repository root, supply the target UDID and a fresh result path:

```sh
xcodegen generate --spec project.yml
xcodebuild test -project Izzy.xcodeproj -scheme IzzyPerformance -configuration Release -destination 'platform=iOS Simulator,id=SIMULATOR_UDID' -derivedDataPath .build/Store -resultBundlePath .build/SwipeMeasurement.xcresult -parallel-testing-enabled NO CODE_SIGNING_ALLOWED=NO
python3 scripts/summarize_swipe_metrics.py path/to/xcodebuild-output.log
```

For a connected iPhone, select that device and use the team's normal signing
configuration instead of disabling signing. The XCTest source is
`IzzyUITests/SwipePerformanceTests.swift`; device hitch metrics are already
requested on iOS 26+. The existing TestFlight build has not been changed.
