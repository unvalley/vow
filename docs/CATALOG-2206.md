# Catalog expansion to 2,206 expressions — September 21, 2026

Superseded by the [3,020-entry stage](CATALOG-3020.md). This record preserves the
2,206-entry stage and its validation evidence.

Added **244 expressions**: 156 phrasal and prepositional verbs and 88 idioms,
for **1,151 phrasal verbs + 1,055 idioms** in 559 verb families. The catalog now
holds 3,945 examples, all with authored Japanese meanings.

This is the second stage of the expansion toward roughly 4,000 expressions. The
first stage is recorded in [CATALOG-1962.md](CATALOG-1962.md); the tooling
described there was reused unchanged apart from the two additions below.

## What was added

| Batch | Kind | Entries |
| --- | --- | ---: |
| `phrasal-2026-09-21-j` | phrasal verbs | 91 |
| `idioms-2026-09-21-k` | idioms | 85 |
| `phrasal-2026-09-21-l` | phrasal verbs | 69 |

The additions span A2 (6), B1 (30), B2 (104) and C1 (104). Phrasal verbs cover
particles that were thin in the catalog (`off`, `out`, `up`, `round`, `onto`) and
prepositional verbs with no lesson (`hinge on`, `pander to`, `prey on`,
`inquire into`, `lean towards`). Idioms add animal, body, weather and
card-playing families, proverbs (`a leopard can't change its spots`,
`absence makes the heart grow fonder`) and workplace vocabulary
(`bells and whistles`, `blue-sky thinking`, `crunch time`, `a catch-22`).

## Core images and classification

Three verb-initial entries drafted as phrasal verbs were reclassified as idioms
before the catalog was regenerated, because they have no core-image particle:
`hold forth`, `loom large` and `part company`. `lean towards` was dropped for the
same reason, matching the treatment of `count towards` in the previous stage.

`scripts/add_expressions.py` now rejects a `phrasal` lesson whose phrase has no
core-image particle, reading the particle list from `ParticleConcept.swift`
rather than a hard-coded copy. The previous stage found this class of mistake
only after merging; it is now caught before. `scripts/reclassify_lessons.py`
performs the move or removal and keeps every catalog position and split-file
order intact.

`scripts/fill_batch_sources.py` fills each lesson's `source` from the probed
candidate pool by matching on the phrase, so URLs are never retyped by hand.

## Highlighting

`PhraseHighlight.swift` gained `fling` (flung) and `light` (lit), which the new
lessons need. `grind` was deliberately **not** added: its past form `ground` is
identical to a common noun, so `grind down` teaches the base form instead. All
3,945 examples highlight.

Three examples were rewritten because a comma inside an expression blocks
matching: `all-singing all-dancing`, `close but no cigar` and
`easy come easy go` are stored unpunctuated, and each lesson's note records that
they are usually written with a comma.

## References

Every source URL was requested on September 21, 2026 and returned HTTP 200 after
following redirects. All 244 use Cambridge Dictionary. Where Cambridge has no
standalone page, the containing headword is recorded (`heat` for `feel the heat`,
`foot`, `cropper`, `narrow`). Dictionary definitions and examples were not
imported as teaching content.

## Compatibility and regeneration

All 1,962 previous entries keep their fields, stable IDs and positions, except
the four reclassified or removed above; the frozen 1,200-entry digest is
unchanged. The split sources stay in catalog order.

The same 100 free IDs remain free. Core images remain at 36, and every
phrasal-verb lesson still links to at least one.

```sh
python3 scripts/check_batch_names.py scripts/data/batches/<batch>.json
python3 scripts/fill_batch_sources.py scripts/data/batches/<batch>.json <pool>.json
python3 scripts/check_highlights.py scripts/data/batches/<batch>.json
python3 scripts/check_batch_sources.py scripts/data/batches/<batch>.json --rewrite
python3 scripts/add_expressions.py scripts/data/batches/<batch>.json
python3 scripts/create_catalog.py
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
```

## Validation

- Eleven Python tests passed, including the frozen prior 1,200-entry digest,
  distinct idiom contexts and gloss shape.
- All 111 Swift package tests passed. Two expectations changed because the data
  changed, not the code: the `look` family grew to 19 with `look on`, and the
  alphabetically first phrase is now `a bad apple`.
- UI test expectations (`2,206 phrases`, `1,055 idioms`, `559 verbs`, Explore
  position totals) were updated but not run in a simulator.
- Customer-facing copy still claims 1,900+ / 1,900以上, which remains true and
  within the range `landing/scripts/check.mjs` accepts. The Pro screen, README
  and store notes state 2,206, 1,151, 1,055 and 3,945.

Catalog SHA-256:
`b680fb7e7d3e0687c3cdbc64cb97a1e9fe3b6ba1c1d8bbe1ac13e93a2fab461d`.

No upload, deployment or push of the app was performed for this expansion.
