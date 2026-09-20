# Supplied phrase collection

This record describes the 614-entry CSV import stage. The app now has 1370 entries
after subsequent [authored expansions](CATALOG-1370.md); the original source
files and this import's mappings are unchanged.

12 September 2026

Source: `scripts/data/phrasal_verbs_complete_550.csv`, copied byte-for-byte from the user's supplied file. SHA-256: `521efbb433811e8d3e6a634f84f60de6a23887240e0c1c5946fdfaf9953c3c91`.

Despite its filename, this file contains **601 rows**, including all 374 rows from the earlier `phrasal_verbs_list_extended.csv` unchanged. The new file adds 227 source rows: 225 new expressions and two supplements to original lessons (`drift apart`, `think through`). The previous source is retained and validated during regeneration. All 389 previously assembled expressions keep their IDs and browsing order; 225 append after them.

## Result

| Item | Count |
| --- | ---: |
| Source rows | 601 |
| New expressions | 534 |
| Existing expressions supplemented | 67 |
| Total expressions | 614 |
| Verb families | 310 |
| Expressions beginning with look | 16 |

Every source row has a mapping in `collection-import.json`. Japanese and English meanings and example sentences are retained. This is a user-supplied collection, not an independent dictionary audit. Some entries contain multiple meanings or are prepositional verbs; the import does not claim that each example demonstrates every listed meaning.

## Identity and normalization

Existing 80 lesson IDs, order, and authored fields remain intact. Supplemental usage is an optional field and does not replace the taught sense or its contexts. New IDs use `collection-` plus the normalized expression, so changing CSV row order does not renumber progress records. Duplicate normalized expressions, missing cells, or unexpected headers fail generation.

| Source label | Display | Search alias |
| --- | --- | --- |
| cut back (on) | cut back on | cut back |
| drop by / in | drop by | drop in |
| get about / around | get around | get about |
| hang around / about | hang around | hang about |
| run out (of) | run out of | run out |
| log off/out | log off | log out |

`run out of` supplements its existing lesson. Existing distinct forms such as `look back` / `look back on` and `get round to` / `get around to` remain separate searchable expressions.

## Practice

The 534 new entries use the supplied sentence for a cloze prompt. Generation hides the verb and particles, including inflected and separated forms: `He finally asked her out.` becomes `He finally ____ her ____.` It preserves intervening objects and fails if it cannot find the phrase in the sentence.

The user compares the original example, makes a different sentence about a real or imagined situation, checks its intended meaning and word order, then self-rates the first attempt. The app does not fabricate a second situation/model answer or use the generic practice instruction as teaching content. Original lessons keep their two authored conversation contexts and usage notes.

Imported entries are available through Today, Phrases, verb families, and Everyday English. Scene practice selects at most six due/new entries instead of starting a 534-entry session. A completed review uses the existing scheduling and streak pipeline. Opening practice from phrase detail marks it previewed, just as the Today workflow does.

All optional fields decode when absent, and the progress-file schema is unchanged. Existing dictionary links refer to original authored lessons; no unverified dictionary URLs are generated for new entries.

## Reproduce

From the repository root:

```sh
python3 scripts/create_catalog.py
python3 scripts/test_collection.py
swift test --scratch-path .build/SwiftPackage --jobs 2
```

`create_catalog.py` regenerates `Izzy/Resources/phrases.json` and `docs/collection-import.json` from repository sources, then appends the authored expansion. It never reads Downloads during regeneration.
