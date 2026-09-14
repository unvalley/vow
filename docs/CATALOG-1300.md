# Catalog expansion to 1,300 expressions — September 14, 2026

Added 50 phrasal verbs and 50 idioms: **800 phrasal verbs + 500 idioms**.
The new lessons provide 200 distinct conversation prompts and 200 distinct model
replies. Each has Japanese and easy-English meanings, a usage pattern, a note,
a source URL and an editorial CEFR estimate. The full catalog has 2,133 examples.

Phrasal verbs include everyday requests and routines (`wait for`, `ask for`,
`help out`, `heat up`, `scroll down`, `zoom out`), work verbs (`cover for`,
`clock in`, `follow through`, `head up`, `push for`, `draw on`), planning verbs
(`pencil in`, `map out`, `settle on`, `go through with`, `get over with`) and
opinion or relationship verbs (`believe in`, `think of`, `grow on`, `make of`,
`level with`, `cheer on`). Idioms include `long time no see`, `keep an eye on`,
`touch base`, `in the loop`, `think outside the box`, `on hold`, `by heart`,
`keep in mind`, `the sooner the better`, `once and for all` and `for what it's worth`.
The [reference audit](catalog-1300-references.json) lists all 100 additions.

## Editorial review

Every source URL was requested directly on September 14, 2026 and returned
HTTP 200 (direct Cambridge requests had returned HTTP 403 during the previous
expansion). The definition text of each page was inspected for the taught
sense. The source in each record identifies the taught sense or its containing
headword: `kill time` and `in the loop` use the Cambridge `kill` and `loop`
entries with their phrase blocks, `scroll down` uses the `scroll` verb entry,
`have a sweet tooth` uses `sweet tooth`, and `get out of hand` uses `out of hand`.
Oxford Learner's Dictionaries entries are used where Cambridge has no standalone
page (`sort through`, `the sooner the better`, `sooner rather than later`,
`back on track`) or where its page mixes senses (`stick with`). Redirected
Cambridge slugs are recorded as their final URLs (`make-at-home`,
`be-in-the-mood-for-to-do`, `means-to-an-end`, `bear-keep-in-mind`,
`other-way-round-around`). Per-entry notes are in the audit file.

Prompts, replies, Japanese meanings and teaching notes are authored for Vow.
Notes explain word order, register, regional variants and neighbouring senses:
for example, `pass on` distinguishes relaying a message from the euphemism for
dying, `cover for` mentions the hide-a-mistake sense, and `in the loop` is taught
as the counterpart of the existing `out of the loop`. The phrasal-verb batch again
includes prepositional verbs (`wait for`, `believe in`, `apply for`); the idiom
batch includes fixed conversational phrases (`long time no see`, `take it easy`)
and binomials (`trial and error`, `up and running`). CEFR labels are editorial
learning estimates. The batch adds A1 (2), A2 (16), B1 (35), B2 (40) and C1 (7).

## Compatibility and regeneration

All 1,200 previous entries retain their exact fields, stable IDs and positions.
New lessons occupy positions 1,201–1,300 in `scripts/data/catalog-order.json`:
the 50 phrasal verbs, then the 50 idioms. Generation rejects missing, unknown or
duplicate ordering IDs, incomplete difficulty maps and name/alias collisions in
either authored collection. The frozen digest in `scripts/test_collection.py`
now covers the first 1,200 entries.

The same 100 IDs remain free. All additions use the existing Pro catalog access,
Today, scenes, search, saved items, daily goals, continuous listening and both
review schedulers. There are now 370 verb families: 16 new ones, including
`apply`, `believe`, `clock`, `help`, `jot`, `level`, `pencil`, `scroll` and `weed`.
Idioms remain outside verb families and particle links. Every new example contains its expression or an explicit alias, so
highlighting works without new inflection rules; pronoun and regional variants
are aliases (`pull my leg`, `a piece of my mind`, `bear in mind`, `the other way
round`, `make yourselves at home`, `go way back`, `clock on`).

```sh
python3 scripts/create_catalog.py
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
node landing/scripts/build.mjs
node landing/scripts/check.mjs
```

## Validation

- Nine Python tests passed, including original CSV preservation, complete
  lessons, aliases, difficulty coverage and the frozen prior 1,200-entry digest.
- All 76 Swift package tests passed after updating the count expectations
  (catalog size, idiom and phrasal-verb totals, 686 additions, 370 verb families,
  2,133 highlighted examples, alphabetical last entry `zoom out`). They cover
  catalog search, both schedulers, free access, scene/verb grouping, Stats,
  difficulty and every example highlight.
- Regeneration preserved the catalog and CSV import report byte-for-byte.
- Five landing pages passed local link, anchor, ARIA and catalog-count checks
  with the updated 1,300 copy.
- UI test expectations (`1,300 phrases`, `500 idioms`, `370 verbs`, Explore
  position totals) were updated but not run in a simulator for this change.
- README, support, draft App Store metadata and LP copy use 1,300. Historical
  release records and existing LP screenshot captures remain dated evidence.

Catalog SHA-256:
`c4fb03728704ea17c729149b1e7ec00785a1d4df51e8475df7209a4793f879b5`.

No upload, deployment, commit or push was performed for this expansion.
