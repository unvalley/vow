# Catalog expansion to 1,370 expressions — September 17, 2026

Added 70 phrasal verbs and one core image: **870 phrasal verbs + 500 idioms**,
**36 core images**. The batch targets the particles whose core images had the
fewest linked expressions. Each lesson has Japanese and easy-English meanings,
two authored conversation contexts, a usage pattern, a note, a source URL and an
editorial CEFR estimate. The full catalog has 2,273 examples, all with authored
Japanese meanings.

The additions are prepositional and particle verbs that learner dictionaries list
as standard entries. By particle: `against` (`come up against`, `be up against`,
`advise against`, `hold against`, `count against`, `guard against`), `aside`
(`cast aside`, `push aside`, `leave aside`, `take aside`), `of` (`get rid of`,
`take care of`, `make fun of`, `make sense of`, `let go of`, `take advantage of`,
`approve of`, `dispose of`, `keep track of`, `steer clear of`, `consist of`),
`from` (`stem from`, `recover from`, `refrain from`, `benefit from`, `tell from`,
`stay away from`), `under` (`come under`, `fall under`, `be snowed under`,
`buckle under`), `past` (`get past`, `put past`), `at` (`laugh at`, `stare at`,
`glance at`, `hint at`, `arrive at`, `pick at`, `have a go at`), `ahead` /
`forward` / `behind` (`plan ahead`, `press ahead`, `forge ahead`, `pull ahead`,
`push forward`, `step forward`, `stay behind`, `lag behind`, `put behind`),
`apart` / `together` (`set apart`, `pull apart`, `throw together`,
`band together`), `to` (`see to`, `get used to`, `amount to`, `resort to`,
`be up to`, `belong to`, `refer to`, `object to`), `on to` (`hold on to`, alias
`hold onto`), `about` (`see about`), `like` (`look like`), `with` (`side with`,
`part with`, `cope with`), `for` (`be in for`, `watch out for`) and `by`
(`stick by`). The [reference audit](catalog-1370-references.json) lists all 70.

## New core image: past

`past` is the 36th core image: the path goes beside a reference and continues
beyond it (そばを通って先へ). It is drawn in the shared 320 × 180 grammar with a
gray obstacle and a blue path that dips around it and carries on to the arrow.
Its comparison pair is `by`, and `by` now compares with `past` instead of
`through`, so the pair reads as "beside" versus "beside and beyond". `get past`
and `put past` link to it. The concept lives in `ParticleConcept.swift`, the
sketch in `ParticleImagesView.swift`; store copy, the Pro screen, support pages,
LP copy and `CORE-IMAGES.md` now say 36. The diagram was not checked in a
simulator for this change.

## Core image coverage

Linked expressions per core image, before and after, for the images this batch
targets (Pro catalog). The free selection is unchanged, so the 13 images with no
free expression remain as they were, and `past` has no free expression either.

| Core image | Before | After |
| --- | ---: | ---: |
| against | 3 | 9 |
| aside | 4 | 8 |
| of | 9 | 20 |
| from | 4 | 10 |
| under | 1 | 5 |
| past | — | 2 |
| at | 7 | 14 |
| ahead | 4 | 8 |
| behind | 3 | 6 |
| forward | 4 | 6 |
| apart | 7 | 9 |
| together | 6 | 8 |
| like | 1 | 2 |
| about | 4 | 5 |
| to | 21 | 30 |
| with | 22 | 25 |
| by | 10 | 11 |

`onto` and `aback` still have one expression each. `run past` was considered and
left out because the existing `run by` lesson teaches the same sense; `walk past`
and `look past` have no dictionary page and were not added.

## Editorial review

Every source URL was requested directly on September 17, 2026 and returned
HTTP 200. Cambridge Dictionary pages are used where a standalone phrasal-verb
page exists. Where Cambridge redirects to a combined entry, the final URL is
recorded (`cast-aside-away-off`, `press-ahead-on`, `not-put-it-past-to-do`).
Where Cambridge has no page for the phrase, the containing headword is recorded
(`up-against`, `make-sense`, `tell`, `plan`, `snowed-under`) or an Oxford
Learner's Dictionaries entry is used (`recover`, `refrain_1`, `benefit_2`,
`stare_1`, `glance_1`, `hold-on-to`). Each of these has a note in the audit file.

Prompts, replies, Japanese meanings and teaching notes are authored for Vow.
Notes cover word order (`hold it against him`, `put it behind me`, `wouldn't put
it past her`), the -ing pattern after `advise against`, `refrain from`,
`resort to`, `object to` and `get used to`, register (`dispose of`,
`refrain from` and `leave aside` are formal; `steer clear of`, `have a go at` and
`be snowed under` are informal), regional notes (`have a go at`, `leave aside`,
`benefitted`), and neighbouring senses (`take advantage of` a situation versus a
person, `come under` pressure versus a category, `be up to` versus `it's up to
you`, `set apart` versus reserving time). Comparisons pair the new lessons with
each other and with existing ones: `come up against` / `run up against`,
`push aside` / `brush aside`, `stay away from` / `steer clear of`, `stare at` /
`glance at`, `hold on to` / `hold on`, `see about` / `see to`, `forge ahead` /
`press ahead`, `pull ahead` / `get ahead`, `throw together` / `put together`,
`look like` / `feel like`.

Four lessons are taught with a form of `be` (`be up against`, `be snowed under`,
`be up to`, `be in for`). Their examples use `am`, `are` and `is` as separate
words so highlighting and the cloze rules match the verb. CEFR labels are
editorial learning estimates. The batch adds A1 (1), A2 (12), B1 (10), B2 (34)
and C1 (13).

## Compatibility and regeneration

All 1,300 previous entries retain their exact fields, stable IDs and positions.
New lessons occupy positions 1,301–1,370 in `scripts/data/catalog-order.json`,
grouped by particle. Generation rejects missing, unknown or duplicate ordering
IDs, incomplete difficulty maps and name/alias collisions. The frozen digest in
`scripts/test_collection.py` still covers the first 1,200 entries.

The same 100 IDs remain free. All additions use the existing Pro catalog access,
Today, search, saved items, daily goals, continuous listening and both review
schedulers. There are now 399 verb families: 29 new ones, including `advise`,
`approve`, `arrive`, `band`, `be`, `belong`, `benefit`, `consist`, `cope`,
`dispose`, `forge`, `glance`, `guard`, `hint`, `lag`, `laugh`, `object`, `refer`,
`refrain`, `resort`, `side`, `stare`, `steer` and `stem`; `look` grows to 18
expressions. Every new example contains its expression or an alias, so
highlighting works without new inflection rules.

```sh
python3 scripts/create_catalog.py
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
node landing/scripts/build.mjs
node landing/scripts/check.mjs
```

## Validation

- Eleven Python tests passed, including original CSV preservation, complete
  lessons, aliases, difficulty coverage and the frozen prior 1,200-entry digest.
- All 92 Swift package tests passed after updating the count expectations
  (catalog size, phrasal-verb total, 756 additions, 399 verb families, 18 `look`
  expressions, 36 core images, 2,273 highlighted examples). They cover catalog
  search, both schedulers, free access, verb grouping, core-image coverage and
  bilingual comparisons, Stats, difficulty and every example highlight.
- Five landing pages passed local link, anchor, ARIA and catalog-count checks
  with the updated 1,370 / 870 / 36 copy (`npm ci` was run in `landing/`).
- UI test expectations (`1,370 phrases`, `399 verbs`, Explore position totals)
  were updated but not run in a simulator for this change.
- README, support, draft App Store metadata, screenshot copy, the Pro screen and
  LP copy use 1,370, 870 and 36. Historical release records remain dated evidence.

Catalog SHA-256:
`a4e314c52b89f6d6e4556d6337911ebb821ad783c2333f85f502505f827738f5`.

No upload, deployment, commit or push was performed for this expansion.
