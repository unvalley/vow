# Home-screen widgets

Added 2026-09-19. A WidgetKit extension (`VowWidget`) offers two widgets.

- **Streak** (small, medium) — a figure whose posture reports where today stands, the current
  streak, and one line of text.
- **Expression** (small, medium, Lock Screen rectangular) — one expression to review with its
  meaning, changing through the day.

Both open Home through `izzy://today`. No new persistence fields, no network, no analytics.

## Sharing

The app's progress file stays where it is, in Application Support. An extension cannot read it, so
the app writes small files into the `group.me.unvalley.izzy` App Group container instead. Both
targets carry that group in `Configuration/Vow.entitlements` and
`Configuration/VowWidget.entitlements`; without it the container is unavailable and the widgets show
their empty state.

Each widget keeps its own file (`WidgetShared.fileName`) and its own reload kind
(`WidgetShared.widgetKind`), so a change to one widget's content never spends the other's reload
budget. `WidgetBridge` writes on the app side: building either file walks the accessible catalog, so
`RootView` compares a cheap `CompanionInput` on each render, and the bridge reloads a widget only
when the file it writes actually changed. A file is read back only at the schema version this build
understands; anything else is treated as absent and rewritten on the app's next run.

Ratings change both files, so a heavy review session asks for many reloads. The system coalesces
them; the files themselves are always current, so the next refresh is correct either way.

## Streak: the figure

The figure is a bold lowercase `i` — one stem and one dot — drawn as a `Shape`, not an exported
asset, so it needs no font file and stays sharp at any size. The brand's icon work settles its
character on tilt, bounce and inflation rather than on symbols that have to mean something
(`Brand/ICON-CANDIDATES.md`), so the widget draws no face: a pose is the whole vocabulary.

Each pose sets four numbers — how far the stem leans from its foot, how far the dot lifts off it,
how far the dot drifts off the stem's axis, and whether the stem squashes or stretches.

| Pose | When | How it stands |
| --- | --- | --- |
| `celebrating` | Nothing left in today's deck | Stem squashed and leaning forward, dot thrown high and ahead |
| `working` | Practised today, cards still to go | Leaning in, dot just off the stem |
| `resting` | Nothing today yet, before 18:00, streak alive | Upright, settled back a few degrees |
| `urging` | Nothing today, from 18:00, streak alive | Leaning back off balance, dot trailing |
| `lapsed` | The streak has ended | Toppled to 27°, and the accent drains to the secondary grey |
| `fresh` | Nothing practised yet at all | Plain upright |

Sideways, each pose is centred on what it actually occupies, so leaning never pushes the figure off
its box. Vertically the foot keeps one height for every pose, so a lifted dot rises instead of
sliding the stem down to meet it, and a toppled one really does sit lower. Poses interpolate
(`animatableData`), so a change between timeline entries reads as the figure moving rather than
swapping. Colour is the learner's chosen accent, from the same `AppAccent` the app uses.

## Streak: what it counts

`CompanionSnapshot` records dates and counts rather than an already-decided mood: the last day with
a qualifying practice, the streak as of that day, and the day the counts describe alongside today's
introduced / target / remaining. Its `introduced` and `target` are the two counts Home shows, so the
widget never disagrees with the screen behind it. Counts from an earlier day are dropped rather than
repeated, so crossing midnight without opening the app reports an empty new day instead of
yesterday's numbers.

The widget derives the pose for each entry with `status(now:)`, so it changes on its own at 18:00
and at midnight while the app is closed; `refreshDates(from:)` asks for an entry at each of those
marks for the next two days.

The streak is the same one Stats shows, from the same records: one completed phrase review or one
completed three-take story qualifies, repeated practice on a day counts once, and yesterday's streak
stays current until today ends. A lapse resets the current streak and leaves the best alone. The
widget shows zero rather than hiding it — a streak that has ended is the thing it is reporting.

## Expression: what it shows

The catalog is 1.7 MB and 1,370 entries, which has no place in an extension given a few tens of
megabytes to render in. So the app writes a `WidgetPhrasePool` of 24 expressions, each already
resolved to the learner's explanation language and carrying their chosen phrase face; the extension
never sees `Phrase`, `Catalog` or the language setting.

The pool is ordered by soonest review first, so what is closest to being forgotten comes round most
often. A phrase answered today has the shortest interval of all, which puts the newly learned near
the front. Expressions never introduced follow, in catalog order. Ties break on the id so the order
is the same on every write.

One expression is shown for three hours. It turns on a fixed clock — `phrase(at:)` divides the
epoch by the interval — rather than on a stored position, so every entry in a timeline is
reproducible and a reload part-way through an interval shows the same expression. `turnDates(from:)`
lays out one entry per expression in the pool, which is three days of changes with nothing from the
app in between.

Small shows the expression and its meaning; the example needs room to be read, so it waits for
medium. English explanations lead with their short equivalent (look into → investigate) as they do
everywhere in the app; Japanese ones are already terse and stand alone. Both sizes centre their
block vertically: an expression and two lines leave half a small widget empty either way, and the
middle is where the eye lands.

## What is not covered by tests

`VowTests/CompanionSnapshotTests.swift` and `VowTests/WidgetPhrasePoolTests.swift` cover the mood
derivation across the evening mark and midnight, stale counts, the streak matching `LearningStats`,
the pool's ordering, its language and face, the fixed-clock rotation and wrap-around, and the file
round trips. They run under `swift test` without a simulator.

The rendered widgets themselves are not tested. Placement on a real home screen, the system's own
refresh budget, and the Lock Screen rectangular size have not been verified. Layouts and poses were
reviewed as rendered images rather than on device. What has been checked on a simulator is that the
app writes both files into the shared container on launch.
