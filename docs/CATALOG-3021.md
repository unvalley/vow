# Catalog expansion to 3,021 expressions — September 21, 2026

Added 324 phrasal verbs and 491 idioms in thirteen reviewed batches:
**1,475 phrasal-verb lessons + 1,546 idiom lessons**, 36 core images. This record
supersedes the [2,206-entry stage](CATALOG-2206.md). Each lesson has Japanese and
easy-English meanings, two authored conversation contexts, a usage pattern, a note,
a dictionary reference and an editorial CEFR estimate. The full catalog has 5,575
highlighted examples.

## How the batches were built

Candidates came from curated lists probed against Cambridge, Collins and Oxford
Learner's Dictionaries in blocks of roughly 200. The probe rejects a candidate whose
URL lands on the dictionary root and requires at least 0.6 content-word overlap
between the candidate and the resolved page title, so an entry that merely redirects
to a related headword is not counted as a reference. Candidates surviving the probe
were then filtered by hand: transparent verb-plus-preposition combinations with no
teaching value beyond their parts, and expressions with no dictionary page of their
own, were left out rather than written up.

Each batch is a file under `scripts/data/batches/` and passes five checks before it
is merged:

```sh
python3 scripts/fill_batch_sources.py <batch> <pool>   # attach probed URLs
python3 scripts/check_batch_names.py <batch>           # collisions, core images, glosses
python3 scripts/check_highlights.py <batch>            # both examples highlight
python3 scripts/check_batch_sources.py <batch>         # every URL returns 200
python3 scripts/add_expressions.py <batch>             # merge into the split sources
```

`check_batch_names.py` reports every problem in a batch at once rather than failing
on the first, which is what made batches of a hundred practical to review.

## Guards added during this expansion

- **Core-image coverage.** `ParticleConcept` holds 36 core images, and `add_expressions.py`
  reports every phrasal-verb lesson whose particle is not one of them. It reports rather
  than refuses: a prepositional verb using `as`, `between`, `towards`, `among` or `beyond`
  is a real lesson, and the phrase detail view simply shows no core-image card for it.
  Seventeen lessons are in that position, listed in the merge output.
- **Stray non-Latin characters.** An English field with a stray CJK or Cyrillic
  character passes every other check, so `add_expressions.py` now rejects any
  codepoint outside the Latin ranges in an English field.
- **Gloss shape.** A gloss must be one to three words and must not repeat the phrase.
- **Highlighting.** `scripts/check_highlights.py` mirrors `PhraseHighlight.swift` in
  Python, so a batch is checked before it reaches Swift. `--catalog` re-checks all
  3,021 lessons after regeneration.

## Kind corrected for thirteen lessons

Thirteen standard phrasal verbs were stored as idiom lessons: `come between`,
`hold forth`, `go beyond`, `come in for`, `rally round`, `read up on`, `rein in`,
`scrape through`, `shore up`, `tie in with`, `win back`, `sweep aside` and
`set forth`. Four of them had been recast by the core-image rule; the rest were
authored that way. Being idioms, they were excluded from verb families, filtered
as idioms on Home, and shown no core image even where the app draws one — `rein in`
teaches `in`, `shore up` teaches `up`.

`scripts/reclassify_lessons.py` gained `--to-phrasal`, the mirror of `--to-idiom`.
It moves the lesson back to `editorial-phrases.json`, rewrites the id from
`idiom-<phrase>` to `editorial-<phrase>`, drops the `kind` key and restores the
look-alike comparison from `--contrast`, which takes `phrase=English|Japanese`. A
comparison was authored for each of the thirteen, since moving to an idiom had
cleared it. None of the thirteen is in the 50 free idiom ids, so free access is
unchanged.

`loom large`, `part company` and `brush with` stay as idioms: their second word is
a noun or an adjective, not a particle.

## What the highlighter required

Idioms match contiguously, so an object inside the expression breaks the match. Such
entries are stored in their `X something Y` form with a fragment alias — `put
something into practice` with `into practice`, `put something on hold` with `put on
hold`. Where only the possessive varies, the inflected form is an alias instead:
`the rot set in`, `play into their hands`, `stick his oar in`, `meet his maker`.

Commas, colons and dashes are matching boundaries, so `all-singing all-dancing`,
`close but no cigar` and `easy come easy go` are stored unpunctuated.

The irregular-verb table grew to 105 entries, extracted into
`scripts/data/irregular-verbs.json` so the Python checker and `PhraseHighlight.swift`
share one table. This stage added `dwell` and `dream` among others. `grind` is
deliberately absent: its past tense `ground` is identical to a common noun, so
`grind down` teaches the base form instead.

## Difficulty and coverage

The 815 additions are A2 (23), B1 (89), B2 (319) and C1 (384). CEFR labels are
editorial learning estimates. Verb families grew to 714; `look` now has 20
expressions. The 36 core images are unchanged.

## Compatibility and regeneration

All 2,206 previous entries retain their exact fields, stable IDs and positions. New
lessons occupy positions 2,207–3,021 in `scripts/data/catalog-order.json`. The frozen
digest in `scripts/test_collection.py` still covers the first 1,200 entries. The same
100 IDs remain free, and all additions use the existing Pro catalog access, Today,
search, saved items, daily goals, continuous listening and both review schedulers.

```sh
python3 scripts/create_catalog.py
python3 scripts/check_highlights.py --catalog
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
node landing/scripts/build.mjs && node landing/scripts/check.mjs
```

## Validation

- Eleven Python tests passed, including original CSV preservation, complete lessons,
  aliases, difficulty coverage and the frozen prior 1,200-entry digest.
- All 111 Swift package tests passed after updating the count expectations (catalog
  size, 1,546 idioms, 1,475 phrasal verbs, 2,407 additions, 714 verb families, 20
  `look` expressions, 5,575 highlighted examples).
- All 3,021 lessons highlight in both examples.
- Five landing pages passed local link, anchor, ARIA and catalog-count checks. The
  hard-coded `1,900+` assertion in `landing/scripts/check.mjs` was replaced by a
  pattern test, so the page's own claim is verified against the live catalog alone.
- Customer-facing copy states an open-ended 3,000以上 / 3,000+ rather than an exact
  count, in the landing pages, draft App Store metadata and screenshot copy. The Pro
  screen, README, support pages and review notes state 3,021 and 5,575.
- UI test expectations (`3,021 phrases`, `1,546 idioms`, `714 verbs`, Explore position
  totals) were updated but not run in a simulator for this change.

Catalog SHA-256:
`8d652dc143c2c495c086bd7753ac0aaa87b26a37d887b2052f6d506d5bcd9ac4`.

No upload, deployment or release was performed for this expansion.
