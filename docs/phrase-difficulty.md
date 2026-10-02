# Phrase difficulty

Each of the 1370 catalog entries has an explicit editorial CEFR estimate for the
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
| A1 | Basic actions and routines | get up, sit down | 15 |
| A2 | Everyday activities and simple interactions | look for, take off (flight) | 159 |
| B1 | Familiar experiences, plans and relationships | bring up, put off | 291 |
| B2 | Abstract meanings and more nuanced situations | rule out, stand up (miss a date) | 654 |
| C1 | Less transparent idioms and nuanced/informal usage | gloss over, paper over | 251 |
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

| CEFR | TOEIC L&R total | IELTS overall | TOEFL iBT, 1–6 | EIKEN grade target |
| --- | --- | --- | --- | --- |
| A1 | 120–220 | No comparison | 1–1.5 | 3級 |
| A2 | 225–545 | No comparison | 2–2.5 | 準2級・準2級プラス |
| B1 | 550–780 | 4.0–5.0 | 3–3.5 | 2級 |
| B2 | 785–940 | 5.5–6.5 | 4–4.5 | 準1級 |
| C1 | 945–990 | 7.0–8.0 | 5–5.5 | 1級 |
| C2 | No comparison | 8.5–9.0 | 6 | No comparison |

- [ETS's TOEIC Listening and Reading CEFR mapping](https://www.eu.ets.org/content/dam/ets-org/eu/pdfs/toeic/mapping-cefr-toeic-listening-reading-test.pdf)
  gives separate minimums (Listening 60/110/275/400/490, Reading 60/115/275/385/455 for A1–C1),
  checked September 15, 2026. The totals above add the two minimums; ETS recommends reading the
  sections separately, so the total is a rough reference. There is no TOEIC band for C2.
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
- Settings → Difficulty display offers CEFR (default), TOEIC L&R, EIKEN grades, IELTS and TOEFL iBT.
- The guide lists one row per level (code, name, then every exam reference on one line) and keeps
  sources in a collapsed section; level descriptions and long notes were removed on 2026-09-15.
- Phrases has an exact-level filter intersecting search, saved phrases and free access.
  Opening a filtered verb family preserves the level; clearing to All levels restores all.
- Choosing IELTS at A1/A2, or EIKEN or TOEIC at C2, retains the CEFR label rather than inventing a score.
- Difficulty never changes purchases, the 50-phrase free set, or personalized review intervals.

## Levels to learn (added October 2, 2026)

**Settings → Learning → Levels to learn** chooses the levels Home learns from: every level
(the default) or any mix, such as A2 and B1. The same screen opens from Home → Today's plan,
under Change daily goal. The choice works like Phrases to learn: it narrows both Today's
learning and Explore, the speaking queue, the widgets and the day's counts. New expressions
come only from the chosen levels, and a review that is due in another level waits until that
level is chosen again. The daily goal still counts every introduction.

Each row shows the level, its exam references and how much of it has been met
(`learned / available`), so the screen doubles as progress by level. Levels are listed for the
chosen kind: with Idioms selected, a level that has no idioms is not offered.

- The choice is saved as `homeLevels` in `learning.json`, in level order; a file without the
  key shows every level. Choosing every level on offer is stored as no choice, so a level added
  to the catalog later is included.
- A level the plan has nothing in shows a lock and its size, and opens Izzy Pro when tapped.
  On the free plan the counts are the free set's: 4 at A2, 26 at B1, 66 at B2 and 4 at C1.
- A saved choice can stop matching anything after the kind changes or Pro access ends. Home then
  shows every level rather than an empty day (`PhraseLevelFilter.applied`); the saved choice is
  kept and applies again when its levels are back on offer.
- The Phrases filter is separate: it picks one exact level for browsing and does not change Home.
- The anonymous settings record gains `levels` (`all`, or the chosen codes such as `A2,B1`).
