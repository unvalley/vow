# Phrases search performance — 2026-09-12

Today card gestures were investigated separately in [Swipe performance](SWIPE-PERFORMANCE.md).
That experiment did not establish an improvement and was reverted; the search
optimization described here remains in place.

Phrases now creates one `LibraryResults` value per view update. The empty state,
count, and rows consume that value. By verb searches each phrase once, then
groups the complete families of the matching verbs. A search for `look into`
still exposes `look for` and the other members of `look`. Verb detail also shares
one sorted array between its count and rows.

There is no persistent cache or asynchronous state to invalidate. Saved phrases,
review ordering, and search input are read again on the next update. Search
matching, localized comparison, sort rules, persistence, and purchase access
are unchanged. The `LibraryResults` signpost records an interval without search
text or other user content.

## Measurement

- Apple M3, macOS 26.6.2 (25G83), Apple Swift 6.3.2; `swiftc -O -g` for both binaries.
- Bundled catalog: 614 phrases, 310 verbs. Catalog SHA-256:
  `41cc83b8c98acc08bd1c62896933b7b9fae71dcc47fa95b0e9342d296d3e7d58`.
- Warm in-memory data; JSON loading and process startup are outside the interval.
- Eight queries, two collections, 100 samples per combination and version.
  Five batches of 20 measured samples, with 10 warm-ups before each batch.
  Baseline/after process order alternates between batches. No compiler or test
  run was started during the final comparison; other host activity was uncontrolled.
- p50 is the median; p95 is nearest-rank (95th of 100 sorted samples). No outliers
  were removed. Noticeable scheduling noise remains in the tails.
- The baseline models the original view's result requests: All phrases evaluates
  `filtered` for empty state, count, and rows; By verb evaluates `filtered` for
  empty state, then `groups` for count and rows. These counts come from the source,
  not an Instruments count of SwiftUI updates. The after binary invokes the same
  `LibraryResults` initializer used by the new view. Result counts are compared
  in every batch; correctness tests compare complete ordered IDs.
- Initial attribution measured the filter alone at p50 9.35 ms for `look`, versus
  9.93 ms for one filtered/sorted result. Repeating the search was the main cost.

Duration of result generation in milliseconds:

| Query / collection | Before p50 | After p50 | Before p95 | After p95 |
| --- | ---: | ---: | ---: | ---: |
| Empty / All phrases | 5.45 | 1.85 | 20.70 | 11.48 |
| Empty / By verb | 6.58 | 3.76 | 26.85 | 16.44 |
| `look` / All phrases | 40.14 | 10.75 | 66.65 | 29.65 |
| `look` / By verb | 41.29 | 11.88 | 137.32 | 29.82 |
| `調べ` / All phrases | 53.15 | 16.79 | 161.01 | 33.42 |
| `調べ` / By verb | 62.28 | 19.73 | 126.27 | 46.68 |
| No match / All phrases | 14.56 | 11.22 | 30.23 | 23.34 |
| No match / By verb | 13.37 | 12.64 | 47.08 | 39.76 |

Keep the change: result-bearing searches consistently avoid repeated filtering
and sorting. The no-match path already performed one search before the change;
its apparent improvement should be treated as noise, not an algorithmic gain.
An intermediate version grouped the catalog even for no-match searches. It was
replaced with an early empty result before this final comparison.

These numbers describe synchronous result generation on a Mac. They do not
measure keyboard-to-screen latency, layout, GPU work, scrolling FPS, cold launch,
or physical iPhone performance. No 60 fps, battery, or memory reduction claim is
made. Temporary arrays and verb sets are bounded by the 614-phrase catalog;
no index is retained across updates. Native behavior checks are listed below.

[Raw samples](performance/2026-09-12/samples.csv) and
[all query summaries](performance/2026-09-12/summary.json) are retained with the
source. Local initial attribution and intermediate runs are in `.build/Performance`.
The original view snapshot has SHA-256
`55c3fa34fe53e302bd40ce4eab402ec55ad472973c699bae375074d0e6bc6fbc`
and matches the source used for TestFlight build 1.

## Reproduce

Run from the repository root. Both variants use the same unchanged matching and sorting
code. The baseline branch in the benchmark preserves the original request pattern.

```sh
mkdir -p .build/Performance
swiftc -O -g -parse-as-library Vow/Core/Models.swift Vow/Core/ParticleConcept.swift scripts/benchmark_library.swift -o .build/Performance/baseline-view
swiftc -O -g -D OPTIMIZED_LIBRARY -parse-as-library Vow/Core/Models.swift Vow/Core/ParticleConcept.swift Vow/Core/LibraryResults.swift scripts/benchmark_library.swift -o .build/Performance/after-view
python3 scripts/compare_library_benchmarks.py .build/Performance/baseline-view .build/Performance/after-view Verve/Resources/phrases.json .build/Performance/new-comparison
swift test -c release --scratch-path .build/SwiftPackage
```

`new-comparison` must not exist, protecting previous samples. For native traces,
record the `LibraryResults` Points of Interest interval together with SwiftUI
or Time Profiler while searching and changing collections. This interval covers
result preparation only. `LibraryResultsTests.testLibraryResultsPerformance`
also records XCTest clock, CPU, and memory metrics without a flaky time threshold.

## Validation

- Release Swift Package: **27 tests passed**, zero failures. Existing curriculum,
  persistence, scheduling, streak, and sorting tests all pass. Three new tests
  cover projection parity, state changes, and clock/CPU/memory measurement.
  Log: `.build/Performance/core-tests.log`.
- iPhone 17 Pro Simulator, iOS 26.3: **four UI tests passed**, zero failures, in
  `.build/PerformanceUI.xcresult`. They exercise aliases and Japanese/Easy English,
  all 614 phrases and 310 groups, search/save/note persistence across relaunch,
  sorting across collections, and full verb-family navigation. These behavior
  tests use Debug fixtures; their timings are not the Release benchmark.
  Log: `.build/Performance/ui-tests.log`.
- Reviewed native screenshot attachments for the complete library and the
  scrolled look family; labels, meanings, and navigation remain legible.
  Attachments: `.build/Performance/ui-attachments`.
- iOS device Release build passed with signing disabled. Product:
  `.build/PerformanceRelease/Build/Products/Release-iphoneos/Verve.app`.
  Log: `.build/Performance/ios-release-build.log`. This is a local unsigned app,
  not a new distribution archive or IPA.
- The optimization has not been uploaded to TestFlight; its existing build 1
  remains the earlier source. No purchase or physical-device claim is added by
  this validation.

## Home render derivations (2026-09-15)

Home derived its learning queue, speaking queue and daily progress through
computed properties that each re-filtered and re-sorted the catalog. One body
evaluation read them about eighteen times. `HomeDerivation` now computes them
once per render, and both schedulers pick their few needed phrases with a
bounded selection instead of sorting every unseen phrase.

Measured with `VowTests/TodayDerivationPerformanceTests` (Release,
`ENABLE_TESTABILITY=YES`, iPhone 17 Pro simulator, 1,300 phrases, 120 seen,
5 clock samples each; wall-clock averages, relative standard deviation under 5%
unless noted). The two runs were taken on different machine load, so compare
within a run:

| Run | Catalog.load | One learning queue | One render, old shape (18 reads) | One render, `HomeDerivation` |
| --- | --- | --- | --- | --- |
| Before | 13.4 ms | 1.7 ms | 32.3 ms | — |
| After derivation only | 23.2 ms | 2.7 ms | 44.1 ms | 7.7 ms |
| After bounded selection | 20.8 ms | 1.9 ms (rsd 13%) | 40.0 ms | 5.2 ms |

Within the last run a Home render costs 5.2 ms instead of 40 ms (about 7.7×
less), below the 16.7 ms frame budget the old shape exceeded on every state
change. Not yet measured: the paged `TabView` in Explore still builds a view
for every visible phrase; that is the next experiment if swiping feels heavy.
