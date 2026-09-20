# Stats: streak, today and the review schedule

Since 2026-09-14 Stats is a sheet opened from the flame on Today; there is no
Stats tab. It shows the current/best streak, the last seven days as check marks,
today's new-expression goal with a learning shortcut, and seven days of scheduled
meaning reviews. The activity bar chart with its three counts, the collection
breakdown and the forgetting-curve illustration were removed, and on 2026-09-17 so
was the code behind them (`ForgettingIllustration` and the activity, schedule and
collection counts in `LearningStats`); the sections below that describe them are
retained as history. All records stay in the existing local
store; this view introduces no new persistence fields. It records `stats_opened` through the app's own analytics.

## The month calendar (2026-09-15)

Each day is a 36 pt tile inside a 44 pt target. The tile's fill is how much was practiced that day, in
five steps like a contribution graph (0 / 1–2 / 3–5 / 6–9 / 10+ at 0.05 ink, then accent at 0.18, 0.36,
0.60, 0.85); the day number sits on top in whichever of ink or paper keeps 4.5:1 on that fill. A day with
reviews still to come is outlined in the accent at 35% instead of filled, and today is outlined at full
strength, so fill always means "practiced" and never competes with what is due. Counts were removed from
the cells. VoiceOver reads one sentence per day (date, then practiced count, reviews due, or not
practiced) with the level as its value. Today's goal and due count live on Home, so Stats keeps only the
streaks, the month and the next review.

## What the numbers mean

- Today's goal uses the same `DailyLearningProgress` policy as Today and meaning
  practice. On Home, the remaining new and due counts follow the phrasal verb /
  idiom filter; introductions always count across every expression. Multiple answers to one expression do not introduce it twice. The
  daily introduction count retains work completed before an access change.
- Activity counts each saved memory answer, speaking-practice reply (including
  typed replies), and completed story. A meaning answer is kept once per
  expression per day: answering again that day replaces the day's record, even
  when the schedule treats it as a new review. Speaking replies count again. Browsing,
  saving and revealing without answering create no activity. The bars total
  these practice actions; the three counts below show their breakdown.
- Seven-day buckets use the current local calendar and include today. Future
  events are excluded; daylight-saving days need not be 24 hours long. Old story
  totals with no dates are not assigned invented dates. Activity from past Pro
  access remains visible even if catalog access later changes.
- Collection progress uses meaning-review states in the currently accessible
  catalog, not views or speaking events. Each phrase counts once. Not started,
  building a memory, and longer intervals partition that catalog. Longer
  intervals means a current interval of at least 21 days with successful
  repetitions; this descriptive threshold is not a mastery assessment.
- The schedule contains current due dates for accessible meaning-review states.
  Today's bar includes overdue cards and cards due later today. The separate
  “due now” number includes only cards already due. No projected new cards or
  unrecorded future repeat reviews are added. Reviewing changes this schedule.
- The screen refreshes after answers, on appearance/foregrounding, at local day
  and time-zone changes, and every minute while the app is active.

## Forgetting curve

The comparison is explicitly labeled **An illustration, not your measured
recall**. Users can toggle spaced reviews over a dashed no-review curve. The
vertical dimension is qualitative recall ease; no percentage, predicted
individual retention, or universal forgetting rate is displayed.

`ForgettingIllustration` provides separate, declining segments over 30 days with
example reviews at days 1, 7 and 22. Those days also illustrate the initial
on-time Good path of the existing scheduler. Exponential drawing scales of
2, 4, 8 and 16 were chosen for a readable schematic, not fitted to learner data
or extracted as numerical research results. Segments are separated at review
points rather than smoothed through an artificial dip or overshoot. The
comparison never changes anyone's review schedule.

The educational premise is supported by [The science of effective learning with
spacing and retrieval practice](https://doi.org/10.1038/s44159-022-00089-1).
The link is available below the figure; the reference supports spacing and
retrieval practice, not the schematic's numerical shape. Current records contain
latest review states and coarse historical ratings, not measured retention
probabilities, so a personalized forgetting curve would require additional
modeling and validation.

## Accessibility and layout

Swift Charts supplies real activity and schedule charts with labeled data marks
and integer count ticks. The illustrative curve has a plain-language accessible
summary that changes with its toggle. A dashed line, solid line and review dots
distinguish the paths without relying on color alone. The layout uses semantic
text styles, vertical metric grids at accessibility sizes, scrollable content,
and the app's adaptive palette. Accessibility sizes show fewer date ticks so
labels have room without reducing the plotted data; endpoint labels face inward
to avoid clipping. No entrance or curve animation is required.

## Validation

`LearningStatsTests` covers local-day/DST boundaries, future events, undated
legacy stories, repeats versus introductions, access changes, overdue and later
today, forecast boundaries, interval partitions and illustration segment resets.
The full Swift package suite passes with 58 tests.

`StatsUITests` exercises the empty state, curve toggle, starting a real meaning
review from Stats, live progress after an answer, and populated statistics at
the largest Dynamic Type size. The `--stats-fixture` seed is compiled only in
Debug and requires both `--ui-tests` and `--reset-ui-tests`; it writes only the
isolated UI-test store.

On 2026-09-13, both UI tests passed on the iOS 26.3 simulator in
`.build/Stats-Verified-Retry-UI.xcresult`. Attachments are exported to
`.build/Stats-Verified-attachments`. A preceding verification run stalled during
test-runner launch with a simulator `server died` error; restarting the dedicated
simulator allowed the tests to complete. This is simulator validation, not a
physical-device or VoiceOver session.

After the final bar-axis alignment adjustment, the populated/large-text test
passed again in `.build/Stats-Axes-UI.xcresult`. Visual inspection confirmed
readable 13/16/19 schedule ticks without truncation and 0/14/30-day curve ticks
at the largest text size. Normal-size comparison and empty-state captures were
also inspected. No app release or device installation was performed.
