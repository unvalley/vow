# Catalog expansion to 3,548 expressions — October 2, 2026

Added 91 phrasal and prepositional verbs and 437 idioms in twelve reviewed batches:
**1,553 phrasal-verb lessons + 1,995 idiom lessons**, 36 core images. This record
supersedes the [3,020-entry stage](CATALOG-3020.md). Each lesson has Japanese and
easy-English meanings, two authored conversation contexts, a usage pattern, a note,
a dictionary reference and an editorial CEFR estimate. The full catalog has 6,629
highlighted examples.

## Why this stage

The catalog was thin where learners start. Before this stage it held 15 lessons at A1,
203 at A2 and 471 at B1, against 2,331 at B2 and C1. Levels to learn (see
[phrase difficulty](phrase-difficulty.md)) lets a learner study one level at a time, and
a level with fifteen lessons is not a course. This stage therefore collects everyday set
phrases and verb + preposition pairs rather than more advanced idioms.

| Level | Before | Added | Now |
| --- | ---: | ---: | ---: |
| A1 | 15 | 28 | 43 |
| A2 | 203 | 171 | 374 |
| B1 | 471 | 251 | 722 |
| B2 | 1,423 | 76 | 1,499 |
| C1 | 908 | 2 | 910 |

The additions are the fixed phrases Japanese learners know as 英熟語: prepositional
phrases (`at least`, `in fact`, `on time`, `by accident`), verb + noun expressions
(`take place`, `make sure`, `pay attention`, `change your mind`), conversational formulas
(`no problem`, `how come`, `you're welcome`, `it depends`), paired words
(`little by little`, `sooner or later`, `ups and downs`) and a few proverbs. Each is stored
as an idiom lesson. The 91 phrasal-verb lessons are mostly everyday combinations
(`cut up`, `tidy away`, `ring back`) and verbs whose preposition is a known trap
(`listen to`, `depend on`, `participate in`).

## How the batches were built

1. **Pool.** About 2,170 candidates were written out and compared with every phrase and
   alias in the catalog; 1,616 were new. Plain grammar (`be going to`, `a lot of`) and free
   combinations (`turn left`, `take a taxi`) were removed by hand, leaving 736.
2. **Probe.** Each candidate was looked up in Cambridge, then Oxford Learner's, then
   Merriam-Webster, with `scripts/probe_candidates.py`, which this stage adds to the repository. A page counted only if its headword is the expression itself, allowing
   for object slots, optional parts in brackets and slash alternatives. The earlier
   0.6 word-overlap rule let search redirects through (`take a seat` → `take a back seat`,
   `go to bed` → `go to bed with someone`), so the rule was tightened to a headword match,
   and a hyphenated headword (the adjective `in-person`) no longer counts for the phrase.
   583 candidates had a page of their own.
3. **Review of the probe.** Entries whose page teaches another sense, points at an
   expression the catalog already has, or duplicates one in content were dropped; eight
   near-duplicates were merged into one lesson with an alias (`right away` / `straight away`).
   536 went to authoring, each with its page's definitions so the lesson teaches a sense
   the page lists.
4. **Authoring.** Twelve batches, `scripts/data/batches/mixed-2026-10-02-a.json` to `-l.json`.
   Every lesson passed `check_batch_names.py` and `check_highlights.py` before review.
5. **Review of the batches.** Three batches were read in full and the other nine in a
   condensed form (meanings, both examples with their Japanese, and the usage notes). Eight lessons were dropped as near-duplicates of existing ones (`do wonders` beside
   `work wonders`, `by word of mouth` beside `word of mouth`, `drop in on`, `miss out on`,
   `give in to`, `look in on`, `get away from`, `have the last word`), 46 levels were
   corrected, two phrases were renamed to the form their page teaches
   (`feel sorry for yourself`, `keep someone busy`), and one mistranslation was fixed.
   528 lessons were merged.

## Sources

457 lessons cite Cambridge Dictionary, 66 Merriam-Webster and 5 Oxford Learner's
Dictionaries. Every one of the 528 URLs returned HTTP 200 to the probe, with the expression
as the page's headword. `check_batch_sources.py` did not give a clean pass afterwards:
Merriam-Webster answers that script's requests with 403, and by then the probe and the
checks had sent enough requests that Cambridge began answering 429. The probe's responses
are therefore the evidence for this stage. The kept probe now sends one request at a time
with a pause and caches every answer, and it reproduces all 736 outcomes of this stage from
that cache.

Where a page lists several senses, the lesson teaches one and mentions the others in its
note. Some pages carry only a narrow sense, and the lesson follows the page:
`in the future` teaches "from now on", `take care` teaches "be careful",
`search for` teaches looking for a missing person, `ask about` teaches asking for news of
someone, and `make it` teaches "be very successful".

## What the highlighter required

- Possessives and pronouns that vary are aliases: `change my mind`, `do my best`,
  `hold my breath`, `lose my temper`, `keep me company`.
- Idioms with an object inside are stored in their `X something Y` form with the fixed
  fragment as an alias: `take something for granted` with `for granted`,
  `take something into account` with `into account`.
- Proverbs are stored without their comma (`no pain no gain`, `out of sight out of mind`),
  like `easy come easy go`.
- `say` and `learn` joined the irregular-verb table in both
  `scripts/data/irregular-verbs.json` and `PhraseHighlight.swift` (`said`, `learnt`).

## What else changed

- **A–Z ignores case.** `I think so`, `I'm afraid so` and five other phrases contain a
  capital. The Phrases sort compared raw strings, which put a capital I ahead of every
  lowercase phrase; `PhraseSort` now folds case, so they file under i.
- **Unique prompts.** Three new prompts repeated an existing one and were reworded, so the
  1,995 idioms keep 3,990 distinct prompts and 3,990 distinct model replies.
- **Pronunciations.** `offence` was added to the override words, eleven lessons name the
  reading of a heteronym (`live`, `read`, `lead`, `tears`, `record`, `excuse`, the noun `use`),
  and `go sightseeing` carries its stress on the first syllable.

## Compatibility and regeneration

All 3,020 previous entries retain their exact fields, stable IDs and positions. New lessons
occupy positions 3,021–3,548 in `scripts/data/catalog-order.json`. The frozen digest in
`scripts/test_collection.py` still covers the first 1,200 entries. The same 100 IDs remain
free, and all additions use the existing Pro catalog access, Today, search, saved items,
daily goals, continuous listening and both review schedulers. Every new phrasal verb links
to a core image. Verb families grew to 734; `look` still has 20 expressions.

```sh
python3 scripts/create_catalog.py
python3 scripts/build_pronunciations.py && python3 scripts/create_catalog.py
python3 scripts/check_highlights.py --catalog
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
node landing/scripts/build.mjs && node landing/scripts/check.mjs
```

## Validation

- Twelve Python tests passed after updating the count expectations (1,995 idioms,
  939 editorial phrasal verbs, 3,990 distinct prompts and replies, 3,548 lessons).
- All 123 Swift package tests passed after updating the count expectations (catalog size,
  1,995 idioms, 1,553 phrasal verbs, 2,934 additions, 734 verb families, 6,629 highlighted
  examples, 3,014 two-context lessons).
- All 3,548 lessons highlight in both examples.
- Five landing pages passed local link, anchor, ARIA and catalog-count checks. The claim
  stays 3,000以上 / 3,000+, which holds until the catalog reaches 4,000.
- The app builds for the simulator. UI test expectations (`3,548 phrases`, `1,995 idioms`,
  `734 verbs`, Explore position totals) were updated but not run.

Catalog SHA-256:
`7fd88b9fcdb4b95bbfa68282d71ef9199e5bd9a043cb174ce7aec26286015538`.

No upload, deployment or release was performed for this expansion. Build 29, already in
TestFlight, carries the 3,020-entry catalog.
