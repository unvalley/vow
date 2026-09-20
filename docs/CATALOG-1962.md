# Catalog expansion to 1,962 expressions — September 21, 2026

Added **592 expressions**: 467 idioms and 125 phrasal and prepositional verbs, for
**995 phrasal verbs + 967 idioms**. Each addition has Japanese and easy-English
meanings, two authored conversation contexts, a usage pattern, a usage note in
both languages, a one-to-three-word gloss, a Cambridge Dictionary reference and
an editorial CEFR estimate. The full catalog now has 3,457 examples, all with
authored Japanese meanings.

This is the first stage of a larger expansion toward roughly 4,000 expressions.
The tooling below is built to be run again for the remaining batches.

## What was added

| Batch | Kind | Entries |
| --- | --- | ---: |
| `idioms-2026-09-21-a` | idioms | 50 |
| `idioms-2026-09-21-b` | idioms | 60 |
| `idioms-2026-09-21-c` | idioms, 1 phrasal | 60 |
| `idioms-2026-09-21-d` | idioms | 59 |
| `idioms-2026-09-21-e` | idioms | 65 |
| `idioms-2026-09-21-f` | idioms | 78 |
| `phrasal-2026-09-21-g` | phrasal verbs | 71 |
| `idioms-2026-09-21-h` | idioms | 79 |
| `phrasal-2026-09-21-i` | phrasal verbs | 71 |

Seventeen verb-initial entries first drafted as phrasal verbs were reclassified
as idioms before merging, because they have no particle and so cannot link to a
core image: `sound the alarm`, `wear thin`, `strike gold`, `take root`,
`take liberties`, `work wonders`, `wipe the slate clean`, `think twice`,
`lose your touch`, `cook the books`, `cut a deal`, `give it your best shot`,
`the powers that be`, `without a hitch`, `under your belt`, `wait and see` and
`come between`. `count towards` was dropped for the same reason: it is a
transparent prepositional verb that fits neither category.

The additions span A2 (15), B1 (61), B2 (347) and C1 (169), and cover Work (193),
Perspective (136), Connection (106), Everyday life (88) and Plans (69). CEFR
labels are Izzy's editorial learning estimates, not a publisher's classification
or an exam rating.

Coverage includes body-part, animal, food, colour, weather, money and time idiom
families, discourse markers (`by all accounts`, `for the most part`,
`be that as it may`), and prepositional verbs that had no lesson
(`adhere to`, `allude to`, `contend with`, `defer to`, `dispense with`).

## Tooling added

Four scripts make the next batch repeatable. Each is read-only against the
catalog until `add_expressions.py` runs.

| Script | Purpose |
| --- | --- |
| `scripts/add_expressions.py` | Merges a self-contained batch file into the six split source files |
| `scripts/check_batch_sources.py` | Resolves every dictionary URL in a batch and records the final URL |
| `scripts/check_batch_names.py` | Reports every name in a batch that already exists, all at once |
| `scripts/check_highlights.py` | Mirrors `PhraseHighlight` so example mismatches surface without a build |

A batch file carries one lesson per entry with its own Japanese example meanings,
gloss and usage note, so it can be reviewed as a unit. `add_expressions.py` fans
those fields out into `idioms.json`, `editorial-phrases.json`,
`catalog-order.json`, `phrase-difficulty.json`, `glosses.json`,
`example-translations.json` and `usage-notes-ja.json`, and rejects a batch with a
duplicate name or ID, an unknown scene or difficulty, a gloss longer than three
words, a mismatched contrast pair, a conflicting Japanese example meaning, or a
Japanese character left in an English field.

`scripts/data/irregular-verbs.json` is extracted from `PhraseHighlight.swift` so
the Python checker and the app share one table.

## Highlighting

`PhraseHighlight.swift` gained sixteen irregular verbs that the new lessons need:
`bite`, `dig`, `rise`, `fight`, `dive`, `sweep`, `stink`, `swim`, `ring`, `sing`,
`hide`, `freeze`, `choose`, `forget`, `lose`, `meet`, `feed`, `lead` and `spend`.
These also improve highlighting for existing lessons. All 3,457 examples in the
catalog highlight, verified by `check_highlights.py --catalog` and by the Swift
test that walks every example.

Idioms match without gaps, so an example has to contain the expression, or one of
its aliases, contiguously with only the first word inflected. Aliases carry the
possessive and regional variants a learner will actually meet
(`keep my head` / `keep her head`, `show your true colors` / `show your true
colours`, `rub me the wrong way` for American English).

## References

Every source URL was requested on September 21, 2026 and returned HTTP 200, and
each was resolved through its redirects so the recorded URL is the page a reader
lands on. All 592 use Cambridge Dictionary. Where Cambridge has no standalone
page, the containing headword is recorded (`kick` for `kick yourself`, `track`
for `lose track of time`, `bind` for `in a bind`, `cut-it` for `cut the mustard`,
`groundwork`, `runaround`, `retrospect`, `vain`, `handle`, `sake`, `seed`,
`ground`, `beat`, `burn`). Definitions and examples from dictionaries were not
imported as teaching content; prompts, replies, Japanese meanings and teaching
notes are authored for Izzy.

This is an editorial content review, not an independent language-teacher review
or a learner study.

## Compatibility and regeneration

All 1,370 previous entries retain their exact fields, stable IDs and positions;
the frozen digest over the first 1,200 entries in `scripts/test_collection.py` is
unchanged. New lessons occupy positions 1,371–1,962. The split source files are
stored in catalog order.

The same 100 free IDs remain free. All additions use the existing Pro catalog
access, Today, search, saved items, daily goals, continuous listening and both
review schedulers. There are now 471 verb families and 967 idioms; idioms have no
verb-family or particle-image link. Core images remain at 36, and every
phrasal-verb lesson still links to at least one.

```sh
python3 scripts/check_batch_names.py scripts/data/batches/<batch>.json
python3 scripts/check_highlights.py scripts/data/batches/<batch>.json
python3 scripts/check_batch_sources.py scripts/data/batches/<batch>.json --rewrite
python3 scripts/add_expressions.py scripts/data/batches/<batch>.json
python3 scripts/create_catalog.py
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
node landing/scripts/build.mjs && node landing/scripts/check.mjs
```

## Validation

- Eleven Python tests passed, including original CSV preservation, complete
  lessons, aliases, difficulty coverage, gloss shape and the frozen prior
  1,200-entry digest.
- All 111 Swift package tests passed after updating the count expectations.
  They cover catalog search, both schedulers, free access, verb grouping,
  core-image coverage, bilingual comparisons, Stats, difficulty and every
  example highlight.
  `LearningTests.testTheDefaultAccentIsBlackAndFollowsTheTheme` does not compile
  under SwiftPM, because `Color.luminance(in:)` lives in `Izzy/Views`, which the
  package target excludes. That is unrelated to this expansion and predates it;
  the suite was run with those two assertions temporarily removed and the file
  was then restored unchanged apart from the count updates. It still builds and
  runs under the Xcode test target.
- Five landing pages passed local link, anchor, ARIA and catalog-count checks.
  The pages now claim 1,900+ / 1,900以上, and `landing/scripts/check.mjs` reads
  the claim back out of the built page instead of hard-coding a range, so the
  check keeps working as the catalog grows.
- UI test expectations (`1,962 phrases`, `967 idioms`, `471 verbs`, Explore
  position totals) were updated but not run in a simulator for this change.
- README, support, draft App Store metadata, screenshot copy and the Pro screen
  use 1,962, 995, 967 and 3,457. Customer-facing copy stays open-ended at
  1,900+. Historical release records keep their dated figures.

Catalog SHA-256:
`b0268c1544a15e5ee435da1dbb82a78162741764e3e33e07fc8622afae03a268`.

No upload, deployment, commit or push was performed for this expansion.
