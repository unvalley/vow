# Phrase difficulty

Each of the 1300 catalog entries has an explicit editorial CEFR estimate for the
meaning/use taught in its main example. This is a learning aid, not an official
CEFR vocabulary list, exam-item calibration, learner assessment or score forecast.
Assignments have not been validated with learner performance data or an external
language assessor. Review them when changing an entry's meaning or example.

The source of truth for regeneration is `scripts/data/phrase-difficulty.json`,
keyed by stable lesson IDs. `create_catalog.py` requires exact ID coverage and
copies levels into the bundled `phrases.json`. No runtime inference from a phrase's
length, position, translation language or purchase status is used. Older entries
without metadata still decode and do not receive a fabricated level.

## Editorial rubric

Consider the taught sense, everyday familiarity, semantic transparency and the
context/register required to use it. Spelling alone does not determine difficulty.
For entries with several senses, prioritize the actual lesson example; supplemental
dictionary usage can sit at a different level. These are initial editorial judgments.

| Level | Focus | Examples | Entries |
| --- | --- | --- | ---: |
| A1 | Basic actions and routines | get up, sit down | 14 |
| A2 | Everyday activities and simple interactions | look for, take off (flight) | 147 |
| B1 | Familiar experiences, plans and relationships | bring up, put off | 281 |
| B2 | Abstract meanings and more nuanced situations | rule out, stand up (miss a date) | 620 |
| C1 | Less transparent idioms and nuanced/informal usage | gloss over, paper over | 238 |
| C2 | Supported as a reference level; no current assignments | — | 0 |

For example, the catalog's **stand up** example is “He stood me up on our first
date.” Its B2 estimate concerns that idiomatic sense, not rising to one's feet.
Similarly **pay for** teaches consequences of mistakes, not a simple purchase.
The [English Profile introduction](https://www.englishprofile.org/images/pdf/theenglishprofilebooklet.pdf)
explains why individual meanings matter. Its vocabulary dataset was not imported
or used as a source of ratings for these entries.

## Exam references (checked September 13, 2026)

CEFR is always retained; the optional display scale is independently chosen by the
user, never inferred from nationality or meaning language. The UI uses an approximate
marker for exam bands and provides a guide with sources. These are broad CEFR
references for overall language proficiency, not direct test-to-test conversions.

| CEFR | IELTS overall | TOEFL iBT, 1–6 | EIKEN grade target |
| --- | --- | --- | --- |
| A1 | No comparison | 1–1.5 | 3級 |
| A2 | No comparison | 2–2.5 | 準2級・準2級プラス |
| B1 | 4.0–5.0 | 3–3.5 | 2級 |
| B2 | 5.5–6.5 | 4–4.5 | 準1級 |
| C1 | 7.0–8.0 | 5–5.5 | 1級 |
| C2 | 8.5–9.0 | 6 | No comparison |

- [IELTS comparison table](https://ielts.org/news-and-insights/finding-the-right-english-proficiency-test-for-you)
  supplies the broad ranges. [IELTS's CEFR guidance](https://ielts.org/organisations/ielts-for-organisations/compare-ielts/ielts-and-the-cefr)
  explains overlapping boundaries, including 6.5/7 and 8/8.5, and warns against exact equivalence.
- [ETS score-scale guide](https://www.ets.org/toefl/institutions/ibt/score-scale-update.html)
  supplies the 1–6 scale effective January 21, 2026. This display is explicitly
  labeled 1–6 in settings and the guide, so it is not mistaken for the prior 0–120 scale.
- [EIKEN grade criteria](https://www.eiken.or.jp/eiken/result/criteria/) and the
  [2026 EIKEN brochure](https://www.eiken.or.jp/association/brochure/eiken-brochure.pdf)
  inform the approximate grade targets. 準2級プラス bridges 準2級 and 2級 and is grouped
  with 準2級 at A2. These are editorial learning references, not CSE conversions or
  predicted passes. Reported CEFR bands overlap and depend on the grade and score;
  there is no EIKEN grade target for C2.

## UI and behavior

- Home and phrase details show a tappable difficulty label opening the reference guide.
- Shared phrase rows show the same label, including scenes and verb families.
- Settings → Difficulty display offers CEFR (default), IELTS, TOEFL iBT and EIKEN grades.
- Phrases has an exact-level filter intersecting search, saved phrases and free access.
  Opening a filtered verb family preserves the level; clearing to All levels restores all.
- Choosing IELTS at A1/A2 or EIKEN at C2 retains the CEFR label rather than inventing a score.
- Difficulty never changes purchases, the 50-phrase free set, or personalized review intervals.
