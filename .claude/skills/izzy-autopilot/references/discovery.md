# Finding and choosing the next improvement

## Sources, in order

1. **Answers.** Proposals in `proposals.md` with `Answer:` filled in become ready items
   ("approved by the user on <date>"). Entries under "From the user" in `backlog.md` become
   items too; leave a pointer to the item id beside the user's words.
2. **Breakage.** Crash and hang reports (`~/Library/Logs/DiagnosticReports/Izzy*.ips`,
   `IzzyWidget*.ips`). A report counts only when it is newer than the last commit that
   touched the crashing code, and the project memory does not record it as fixed. Red
   tests on `main`: in a normal cycle, when the log shows `swift test` or `IzzyTests` has
   not run for a week, run it in the background while you do the rest. A `plan` run runs
   no suites.
3. **Design audit** of one surface, the least recently audited one in the Coverage table.
4. **Features**: recorded ideas, the product goals below, gaps between iPhone and iPad,
   between the app and the widgets.
5. **Performance and code health**, when they block one of the above or a measurement shows
   a user-visible cost (`docs/PERFORMANCE.md`, `docs/SWIPE-PERFORMANCE.md`).

A discovery pass is a small part of a cycle (about ten minutes): at most ten new items, not
an exhaustive audit. Further findings go in as one-line `idea` items. For wide reading,
spawn Explore subagents in parallel with one narrow question each ("which Izzy screens have
no empty state?", "which icon-only buttons in Izzy/Views have no accessibilityLabel?") and
keep their conclusions, not their file dumps. Check each claim an agent makes at the
`file:line` it cites before writing the item as `ready`; an unchecked claim stays an `idea`.

## Auditing one surface

1. Capture it in its main states ([ios.md](ios.md), Capture): light and dark, English and
   Japanese, on the iPhone simulator and, where the screen differs, the iPad one. Also at
   an accessibility text size.
2. Go through `docs/DESIGN-SYSTEM.md` and the Design System section of `README.md` against
   the captures and the code. Count spacing literals that are not tokens:
   `rg -n --pcre2 '\.padding\((\.[a-zA-Z]+, )?[0-9]|spacing: [0-9]' Izzy/Views IzzyWidget`
   (drawing coordinates and sizes are separate from the scale; only gaps and insets count).
3. Check the states people actually reach: a fresh install, the free plan
   (`--free-access`), a finished day, a lapsed streak, an empty Saved list, a search with no
   result, a very long phrase or Japanese meaning.
4. Accessibility: labels on icon-only buttons, VoiceOver reading order, contrast, Dynamic
   Type at accessibility sizes, Reduce Motion, Increase Contrast, Differentiate Without
   Color.
5. Write each finding as an item with its evidence: the capture, `file:line`, the rule it
   breaks. Then update the Coverage table's date for that surface.

## Features

- **Recorded ideas.** Open lines in `docs/*.md` (VERIFICATION's "Remaining boundaries",
  PERFORMANCE's "Not yet measured", follow-ups in feature records), the project memory, and
  the local-only records in the main checkout: `Brand/MARKETING.md` (strategy and the
  decisions left to the user) and `AppStore/READINESS.md`. Those last two are git-ignored,
  so read them from `$MAIN`, never from the worktree.
- **Product goals** (late 2026): Izzy is a free download with one Pro purchase and a 7-day
  trial. What matters: a first day that ends in a finished deck, a daily habit that holds
  (streak, reminders, widgets), and the free plan showing clearly what Pro adds. Prefer
  features that serve these, built from what the app already knows.
- **Debug-only prototypes** on `main` (code behind `#if DEBUG` that a commit calls a
  prototype, such as today's learning as a pack): finishing or shipping one is a product
  call, so it becomes a proposal, not a feature item.

A feature item names who benefits and the moment they would notice it. If you cannot say
both, the item is not ready.

## Scoring

Give each ready item 1-3 on:

- **Value**: 3 if many learners meet it in a core flow (Home, a review, the daily goal,
  the widget), 1 if it is an edge.
- **Confidence**: 3 if a test and a capture can prove it, 1 if it mostly needs judgement.
- **Cost**: 1 if small and local, 3 if it touches shared model code, persistence or the
  scheduler.

When the user has written priorities at the top of "From the user", an item in one of
those areas gets one more Value point (cap 3).

Priority = Value x Confidence / Cost. Ties go to items the user wrote or approved, then to
items that touch nothing another branch is changing, then to a surface the last two cycles
did not touch, then to the smaller diff.

Not eligible this cycle: it needs a path that is dirty in the main checkout; it is blocked
and its blocker has not changed; policy makes it a proposal; it needs a machine resource
the start-of-cycle check ruled out. Write the good ones that wait on a dirty path as
`blocked: waiting on <paths>`.

When nothing is eligible, log `nothing-eligible` with the reason, release the lock and say
what would unblock the top items.

## Writing an item

Format in [state.md](state.md). Acceptance criteria describe something observable: "at
AX3 the rating row wraps to two lines and every label stays readable", "the widget's count
equals Home's for a deck with two reviews left, in `CompanionSnapshotTests`". Never "looks
better".
