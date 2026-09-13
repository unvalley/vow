# Catalog expansion to 1,200 expressions — September 13, 2026

Added 50 phrasal verbs and 50 idioms: **750 phrasal verbs + 450 idioms**.
The new lessons provide 200 distinct conversation prompts and 200 distinct model
replies. Each has Japanese and easy-English meanings, a usage pattern, a note,
a source URL and an editorial CEFR estimate. The full catalog has 1,933 examples.

Examples include `shop around`, `own up`, `fall back on`, `creep up on`,
`a clean slate`, `a no-brainer`, `out of the loop` and `on the dot`.
The [reference audit](catalog-1200-references.json) lists all 100 additions.

## Editorial review

Dictionary sense text was checked through indexed search results. Direct
Cambridge requests returned HTTP 403. Sources include Cambridge, Oxford,
Merriam-Webster, Collins and Dictionary.com. The source in each record identifies
the taught sense or its containing headword; for example, `gobble up` is covered
under `gobble`, while `press on` uses the continuation entry, `press on/ahead`.
`rope in` uses Cambridge's bilingual entry, including its English definition.

Prompts, replies, translations and teaching notes are authored for Vow. Notes
explain word order, register and alternate senses. The phrasal-verb collection
also includes transparent verb-particle combinations; the idiom collection
includes fixed phrases and figurative noun phrases. CEFR labels are editorial
learning estimates, not copied dictionary levels or externally validated ratings.

## Compatibility and regeneration

All 1,100 previous entries retain their exact fields, stable IDs and positions.
New lessons occupy positions 1,101–1,200. `scripts/data/catalog-order.json`
records the learning order independently of authored source grouping, so growing
the phrasal-verb source does not move old idioms. Generation rejects missing,
unknown or duplicate ordering IDs, incomplete difficulty maps and name/alias
collisions in either authored collection.

The same 50 IDs remain free. All additions use the existing Pro catalog access,
Today, scenes, search, saved items, daily goals and both review schedulers.
There are now 354 verb families. Idioms remain outside verb families and particle
links. Highlighting recognizes `crept` and `won`; idiom wording variants and
possessives are explicit aliases instead of new lessons.

```sh
python3 scripts/create_catalog.py
python3 -m unittest discover -s scripts -p test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
node landing/scripts/build.mjs
node landing/scripts/check.mjs
```

## Validation

- Eight Python tests passed, including original CSV preservation, complete
  lessons, aliases, difficulty coverage and the frozen prior 1,100-entry digest.
- All 59 Swift tests passed. They cover catalog search, both schedulers, free
  access, scene/verb grouping, Stats, difficulty and all 1,933 example highlights.
- Regeneration preserved the catalog and CSV import report byte-for-byte.
- Five landing pages passed local link, anchor, ARIA and catalog-count checks.
- One iPhone simulator scenario passed for both new lesson kinds: search
  `creep up on` and the alias `a feather in our cap`, inspect Japanese meaning
  and both examples, save, relaunch and find the lesson in Saved. Evidence:
  `.build/Catalog-1200/Catalog-Verified.xcresult` and `ui-verified.log`.
  Both exported detail screenshots in `screens/` were visually inspected.
- Current README, support, draft App Store metadata and LP copy use 1,200.
  Historical release records and existing LP screenshot captures remain dated
  evidence, rather than being relabeled as new screenshots.

Catalog SHA-256:
`c6b3af30803ea52592e27cafb5324ffcf5ef8727a7b53b25ef610e3bb2824618`.
Local evidence is under `.build/Catalog-1200/`: `baseline.json`,
`verification.json`, `swift-test.log`, and the native UI result/log.

The catalog implementation itself did not upload or deploy. A subsequent explicit
release request uploaded this catalog in TestFlight **1.0.0 (6)** at 14:25:38 JST
on September 13, 2026. Apple reported processing; processing completion and
Internal-group distribution remain unverified because the browser session expired.
See [release evidence](../AppStore/TESTFLIGHT.md). No website deployment, commit
or push was performed.
