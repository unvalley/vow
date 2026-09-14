# Historical expansion to 700 phrasal verbs — September 13, 2026

The current collection has 800 phrasal verbs and 500 idioms. See the
[latest 1,300-entry expansion](CATALOG-1300.md). This record preserves the earlier
700-entry stage and its validation evidence.

Added 86 distinct expressions after the previous 614, for **700 entries in 335
verb families**. The new batch focuses on everyday routines, travel, digital tasks,
work and relationships. It includes `plug in`, `tidy up`, `stop over`, `fill in for`,
`walk through`, `settle in` and `write up`.

Each addition has an English explanation, Japanese meaning, two different
conversation prompts and model replies, a word-order pattern, a usage note,
an editorial CEFR estimate and a dictionary reference. These use the full
two-context speaking flow, rather than the supplied CSV's single-example cloze.

| Catalog component | Entries | Model examples |
| --- | ---: | ---: |
| Original lessons | 80 | 160 |
| Supplied CSV additions | 534 | 534 |
| New authored lessons | 86 | 172 |
| Supplemental usage on existing lessons | — | 67 |
| Total | 700 | 933 |

The additions span A1 (1), A2 (40), B1 (32) and B2 (13). They add 33 Everyday,
19 Work, 18 Plans, 11 Connection and 5 Perspective lessons. Difficulty is Vow's
editorial learning estimate, not a publisher's classification or exam rating.
The complete catalog's level counts are in `phrase-difficulty.md`.

## Sources and authorship

`scripts/data/editorial-phrases.json` contains the authored lessons and one
dictionary URL per entry. Definitions and examples were checked against Cambridge
Dictionary or Oxford Learner's Dictionaries, with broader verb entries used for
transparent combinations such as `bend down`, `move back` and `reach for`.
The model replies and prompts were written for Vow; dictionary examples are not
imported as teaching text. The collection continues to include prepositional verbs
and transparent verb–particle combinations, as well as idiomatic phrasal verbs.

Reference checks included the taught sense rather than merely a successful HTTP
response. For example, the default Cambridge `pull in` route showed arresting or
attracting someone, so its lesson uses the [Oxford arrival sense](https://www.oxfordlearnersdictionaries.com/definition/english/pull-in).
The same distinction was made for [walk into an unpleasant situation](https://www.oxfordlearnersdictionaries.com/us/definition/english/walk-into)
and [check over](https://www.oxfordlearnersdictionaries.com/definition/english/check-over).
[Cambridge's grammar guidance](https://dictionary.cambridge.org/us/grammar/british-grammar/phrasal-verbs-and-multi-word-)
informed object placement notes. British usage is identified where useful, such
as `queue up` and `pay in`, without assuming a Japanese learner or destination.

This is an editorial content review, not an independent language-teacher review
or a learner study. Existing user-supplied CSV content was preserved, not re-audited.

## Identity and regeneration

New stable IDs use `editorial-` plus the expression. All prior 614 records retain
their exact fields, IDs and order. The generator rejects duplicate expressions,
collisions with existing aliases, duplicate IDs, missing difficulty assignments
and conflicting difficulty metadata. The original CSV import report still
describes its 614-entry stage; this record describes the additional batch.

Run from the repository root:

```sh
python3 scripts/create_catalog.py
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
```

The catalog and existing import report reproduce byte-for-byte. The generated
700-entry catalog SHA-256 is
`5c396a9f843066e88ba7d5924e05167039e2a6e3ebd1d31c6e4f129df5695e01`.

The same frozen 50 IDs remain free. All additions are available with Pro through
Today, search, scenes, verb families, meaning reviews and speaking practice.
Speaking itself has no feature paywall. The archive validator compares bundled
catalog contents with the reviewed source instead of relying only on a fixed count.

## Validation

Six Python checks cover source preservation, ID coverage, duplicate/alias safety,
complete new lessons and supplied cloze behavior. Swift checks cover both review
schedulers for all 86 additions, the free boundary, both languages, particle links,
difficulty, and phrase matching across all 933 examples. Highlighting includes
`bent`, `drove`, `driven`, `knelt` and `leant` as well as existing inflections.
Native UI evidence is recorded in `VERIFICATION.md`.
