# vow — Brand direction

Adopted implementation direction, September 13, 2026.

## Promise

**英語を、自分の言葉に。**

**Make English your own.**

vow is a personal place to practise the expressions you want to use in everyday
conversation. It is for learners who often recognise a phrase before they can
produce it. The product helps them choose a small daily amount, recall it, say
something of their own and return to it later.

The name is always lowercase **vow**. Its meaning suggests a small commitment
one makes to oneself. Product copy does not turn this into a pledge ceremony,
a streak threat or a promise of fluency by a deadline.

## Reference observations and decisions

Inspected the live [Cosmos homepage](https://www.cosmos.so/) on September 13,
2026: a short, centred statement; a strongly contrasting download action;
large imagery around a quiet neutral field; product content carries the colour.
Later sections connect concrete tasks to short headings.

For vow, use that restraint and focus, with actual expressions and actual app
screens carrying the story. Keep the already approved Archivo italic wordmark,
New York phrase typography and landscape backgrounds. Cosmos's orbiting cards,
circular symbol, photography and wording are not part of vow's identity.

[Art4](https://art4.app/en) informs the product demonstration: show the app early,
connect each feature to a visible action and state the purchase model plainly.
The existing vow landing composition already implements this direction.

## Identity system

- Wordmark: supplied outlined Archivo Regular Italic, 85% horizontal width.
  Its geometry and licensing remain as recorded in [README](README.md).
- App symbol: the first **v** from that same outlined wordmark, scaled uniformly.
  A soft-white letter on graphite connects the Home Screen to the landing wordmark.
  Do not add a separate motif or redraw the letter with a different font.
- App icon: opaque 1024 × 1024 square; the operating system supplies the mask.
  No baked corner radius, transparent border, caption or tiny decorative detail.
- Small uses: the v symbol for favicon and touch icon. Full wordmark for web
  navigation and store presentation. Never insert the logo into every lesson.
- Clear space: at least one stem width around the wordmark; use the supplied
  master padding. Minimum visible wordmark width 60 CSS points. The symbol is
  designed to remain recognisable at 16, 32 and 60 pixels.

## Colour and typography

| Role | Value | Application |
| --- | --- | --- |
| Paper | `#FAFAF9` | Landing and presentation canvas |
| Graphite | `#202020` | Wordmark, headings, primary actions, icon background |
| Secondary text | `#636764` | Supporting copy on paper |
| Surface | `#F0F1EE` | Quiet grouping behind supporting content |
| Rule | `#E1E3DF` | Separation; never the only interactive affordance |
| Focus / example accent | `#3155D9` | Web focus ring and relevant phrase highlight |

The app keeps semantic light/dark colours and the learner's accent setting.
Brand colours must not override Dynamic Type, system appearance or contrast.
New York / the system serif distinguishes the English expression. San Francisco
supports examples and controls. The web uses system sans and Georgia for phrase
examples, avoiding extra font downloads. Archivo is an outlined logo, not a
third reading font.

## Voice

Use a short invitation followed by a concrete action. Japanese should sound like
one person helping another practise; English should be direct and easy to read.
Keep real labels such as Daily goal, Saved and Restore purchases. Remove section
labels that merely announce the following heading. Avoid repeated instructions
about an obvious interface, exaggerated outcomes and invented social proof.

| Context | Japanese | English |
| --- | --- | --- |
| Main promise | 英語を、自分の言葉に。 | Make English your own. |
| Product descriptor | 句動詞とイディオムを、毎日の会話へ。 | Phrasal verbs and idioms for everyday English. |
| Daily practice | 今日は、いくつ覚えよう。 | A little practice, every day. |
| Recall | 意味を思い出して、確かめる。 | Recall it. Then check. |
| Speaking | 次は、自分の言葉で。 | Then, say it your way. |
| Purchase | 一度の購入で、すべての表現を。 | One purchase. The whole collection. |

The actual catalogue is 750 phrasal-verb lessons and 450 idioms. Fifty fixed
lessons, diagrams and Speaking are free. A non-consumable purchase unlocks the
whole catalogue and its spaced reviews. Do not imply all 1,200 lessons are free,
a paid speaking feature, pronunciation scoring or scientifically measured
personal forgetting curves. Store screenshots with full catalogue access are
identified as Pro in presentation copy.

## Photography and product presentation

Use the app's existing licensed landscapes as a quiet setting. Retain its
source records in `docs/today-landscape.md`. The phrase must remain legible.
Do not add unrelated aspirational travel images or generated screenshots.

Store sequence: daily practice → idiom collection → meaning and examples →
recall → daily goal → core images → progress. Each frame has one short headline,
optional essential qualification and one large, unmodified app capture. Use the
same structure for Japanese and English, iPhone and iPad. Keep actual app labels,
including English navigation in Japanese explanation mode. Sample progress in
captures is marked in provenance as test data, not a real learner testimonial.

## Learning screen hierarchy

The expression is the centre of Today. Today's learning and Explore share the
same card; separate verb/particle links belong in the detail screen. Meaning
and examples open together from one control.

The learning footer has two rows: progress with compact paging, then one primary
learning action. The progress count also opens the daily-goal editor. Speaking
is a labelled-for-accessibility waveform button in the upper toolbar. Explore
only needs paging below its card. Omit redundant progress tracks, zero-review
labels and a second full-width action. Larger accessibility text may stack the
controls; minimum 44-point touch targets and semantic labels take priority.

## Delivery and maintenance

`node scripts/build_brand.mjs` exports the icon, web identity and social artwork
from the approved vector. `Brand/preview.html` is the visual reference for small
icon sizes, colour and copy. App Store capture provenance belongs in
`AppStore/screenshots/manifest.json`; public submission readiness belongs in
`AppStore/READINESS.md`. Brand production does not establish Apple processing,
public availability, copyright clearance or physical-device purchase evidence.
