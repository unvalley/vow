# Home-screen widgets

Added 2026-09-19. A WidgetKit extension (`IzzyWidget`) offers two widgets.

- **Streak** (small, medium) — a figure whose posture reports where today stands, the current
  streak, and one line of text.
- **Expression** (small, medium, Lock Screen rectangular) — one expression to review with its
  meaning, changing through the day.

Both open Home through `izzy://today`. No new persistence fields, no network, no analytics: the widget extension compiles `Izzy/Core` only, which is why the analytics service lives in `Izzy/Services`.

## Sharing

The app's progress file stays where it is, in Application Support. An extension cannot read it, so
the app writes small files into the `group.me.unvalley.izzy` App Group container instead. Both
targets carry that group in `Configuration/Izzy.entitlements` and
`Configuration/IzzyWidget.entitlements`; without it the container is unavailable and the widgets show
their empty state.

Each widget keeps its own file (`WidgetShared.fileName`) and its own reload kind
(`WidgetShared.widgetKind`), so a change to one widget's content never spends the other's reload
budget. Each also declares the shape it writes (`WidgetShared.currentSchema`, 1 unless the kind says
otherwise), and a file at any other version is read as absent: adding a field is a version, not a
migration. `WidgetBridge` writes on the app side: building either file walks the accessible catalog, so
`RootView` compares a cheap `WidgetInput` on each render, and the bridge reloads a widget only when
the file it writes actually changed. A file is read back only at the schema version this build
understands; anything else is treated as absent and rewritten on the app's next run.

`WidgetInput` watches `LearningStore.revision`, bumped by every `persist()`, rather than listing the
fields a snapshot happens to read. Listing them goes stale twice over: a field that starts mattering
has to be added by hand, and a same-day re-rating replaces its event in place, leaving every count
and the last event's date unchanged.

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

## Streak: the layouts

The widget exists to bring the learner back today, so the day's state is what the type scale
follows, and the streak is the reason rather than the instruction. Both sizes read in the same
order: the figure, then what today asks for, then how far the day has got, with the run of days
kept small.

- **Small.** The flame and the count sit in the top leading corner, where Today keeps them. The
  figure takes the middle. Underneath, one line in subheadline medium states where today stands —
  the loudest text on the widget — over the day's progress track.
- **Medium.** The figure holds an 88-point column and the text runs the whole remaining measure
  rather than ending in a spacer: the headline one step larger, the track with its two counts under
  it, and the streak on the base line. The earlier layout set the streak in `largeTitle` beside a
  three-line block; it made the reward the headline and left the right third empty.

The track is the day's introduced / target as a filled capsule. Those two counts were already there
as a sentence; the track is what reads before the sentence does, and a started day never shows an
empty one — below a bar's width the fill keeps a round cap. With the counts from an earlier day
dropped, there is nothing to draw and the track is absent rather than zeroed.

The flame is the outline symbol at natural weight, in ink, as Home sets it; the design system keeps
filled symbols for state and outlines for everything else. That leaves the accent on the figure and
the track alone, which is also what a tinted home screen needs: the figure and the fill are marked
`widgetAccentable()`, so a desaturated widget keeps its color where the app would.

## Streak: what it counts

`CompanionSnapshot` records dates and counts rather than an already-decided mood: the last day with
a qualifying practice (`LearningData.practiceDates`, the same records Stats reads), the streak as of
that day, and the day the counts describe alongside today's introduced / target / remaining. Its `introduced` and `target` are the two counts Home shows, so the
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
the front. Expressions never introduced top up the rest, and are not walked at all once the pool is
full. Ties break on the id so the order is the same on every write. Only 24 are kept, so they are
picked with the same bounded selection (`Array.smallest(_:by:)`) the daily queue uses rather than by
sorting the catalog.

One expression is shown for three hours. It turns on a fixed clock — `phrase(at:)` divides the
epoch by the interval — rather than on a stored position, so every entry in a timeline is
reproducible and a reload part-way through an interval shows the same expression. `turnDates(from:)`
lays out one entry per expression in the pool, which is three days of changes with nothing from the
app in between.

Both sizes set a dictionary entry in the order `PhraseMeaning` uses on every screen of the app: the
expression, then the short English equivalent (look into → investigate) in ink, then the explanation
stepped down to the secondary color. The earlier layout joined the equivalent and the explanation
into one grey line, where the single word worth catching was buried in a block of small type.
Japanese explanations have no equivalent to lead with and take that room instead. Both sizes centre
their block vertically: an expression and two lines leave half a small widget empty either way, and
the middle is where the eye lands.

The example needs room to be read, so it waits for medium, where the width also lets the equivalent
sit beside the expression on a headword line instead of under it. The example carries the
expression marked inside it, as every example in the app does: what a glance teaches is where the
expression lands in a sentence. The app's soft wash behind those words is left off at this size —
it reads as a highlighter over a third of the line — so the mark is the accent and the weight alone.
Marking needs two things the pool did not carry, which is why it is at schema 2: the learner's
accent, and whether each entry is an idiom, since an idiom admits no object between its words while
a phrasal verb does. Aliases stay in the app; an example phrased around an alternative form is
simply left unmarked.

## What is not covered by tests

`IzzyTests/CompanionSnapshotTests.swift` and `IzzyTests/WidgetPhrasePoolTests.swift` cover the mood
derivation across the evening mark and midnight, stale counts, the streak matching `LearningStats`,
the pool's ordering, its language, face, accent and idiom flag, the fixed-clock rotation and
wrap-around, the file round trips, and a file at an earlier schema reading as absent. They run under `swift test` without a simulator.

The rendered widgets themselves are not tested. Placement on a real home screen, the system's own
refresh budget, the tinted rendering mode, and the Lock Screen rectangular size have not been
verified. Layouts and poses were reviewed as rendered images rather than on device, this pass
included; the marked example was reviewed the same way. What has been checked on a simulator is that the
app writes both files into the shared container on launch.
