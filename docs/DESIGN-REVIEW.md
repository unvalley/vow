# Native interface review

Skills applied: `design-review`, `make-interfaces-feel-better`, and `swift-review`. Figma-to-SwiftUI guidance was inspected, but no Figma file was part of this task and no Figma transfer was needed.

## Implemented design decisions

| Before | After |
| --- | --- |
| No native app in this blog repository | Independent iOS project with native tab and stack navigation. |
| No visual language | Paper, charcoal, copper, four conversation colors, original Canvas line artwork, and an original app icon. |
| No starting point | Today gives one speaking-practice action, with due reviews or new phrases drawn from actual state. |
| No contextual browse flow | Four scene collections open a practice session, phrase notes, or a story exercise. |
| No production task | A hidden phrase, an attempted reply, a model comparison, a second context, and a self-rating. |
| No input affordance | A 64-point record/stop control, actual recording time and input level, playback, spoken confirmation, and a typed alternative. |
| No long-form practice | Same-message retelling in three optional timed takes, with an untimed setting. |
| No personal phrase collection | Search, bookmarks, dictionary links, and autosaved personal sentences. |
| No progress display | Actual review counts, spoken/typed distinction, seven-day history, and next due dates; no invented scores or streaks. |
| No reading accessibility | Dynamic Type fonts, a single-column collection layout at accessibility sizes, system navigation, VoiceOver labels, and keyboard dismissal. |
| Light-only accent contrast | Adaptive lighter copper for text controls in dark appearance; recording retains a dark red background with a white icon. |
| Secondary copy could become faint against warm paper | Explicit semantic secondary colors retain stronger text contrast in the reviewed light screens. |
| Unbounded decorative motion | Static reading artwork and purpose-specific transitions; Reduce Motion disables press scaling and phase animations. |
| Recording state could outlive a screen | Permission generation guards, background suspension, identity-checked delegates, and recording cleanup on exit. |
| Page transitions could preserve the previous reading position | Practice phase identity resets the reading surface to its top. |

## Review focus

Correctness and accessibility precede visual polish. Check actual launch, reading scale, contrast, search empty state, saved state, input permission fallback, model reveal, session completion, and persistence. Record device/runtime evidence in `VERIFICATION.md`. A successful build alone does not establish these boundaries.

No measured frame-rate claim is made. The 60fps site is a design reference, not a performance result.

## Rendered review

Reviewed native screenshots of Today, scene collections, hidden-prompt retrieval, model comparison, completion, and accessibility-size text. The primary daily action, contextual model, and next step remain distinct. Scene titles wrap naturally; long pages scroll above the native tab bar. The accessibility layout switches collections to one column.

The simulator reported dark appearance when requested, but the captured app still rendered light. Dark color definitions are implemented; dark rendering remains unverified and is not counted as a passed visual check.

## White, black, and blue revision

| Before | After |
| --- | --- |
| Warm paper, copper, and unrelated pastel hues | System white/black surfaces, near-black hero, blue action and artwork tokens, and neutral/blue collection cards. |
| Orange icon and recording tint | Blue icon, blue record/stop state, and blue progress/navigation accents. Recording is also distinguished by its stop icon and elapsed time. |
| Only a flat phrase list and Saved filter | All phrases / By verb / Saved selector; 28 alphabetical verb families with counts and previews. |
| No way to compare look expressions | A dedicated look family with ten meanings, including look for and look into, linking to individual lesson notes. |
| 24 lessons | 80 lessons with 160 distinct scenarios; original lesson IDs preserved. |

The revised color reference is the rendered Apple iPhone and Distinction App pages, linked in `RESEARCH.md`. The blue action color is #005CCC with white text. Secondary text uses an opaque neutral token to retain contrast against white. Layout and type scale remain consistent with the original app.

Final light-theme color calculations: blue action versus white **6.17:1**, secondary text versus white **6.39:1**. Reviewed the rendered home and look family; both requested expressions are visible with distinct meanings. All seven UI flows passed, followed by a focused final family-flow check after the contrast adjustment.

## Vocabulary-inspired reading surface

Inspected the official Vocabulary site and the first iPhone screenshot on its App Store listing. The reference centers one word, its meaning, and a small action row. This revision adapts that hierarchy while keeping Izzy's white/black/blue palette, original curriculum, and speaking practice.

| Before | After |
| --- | --- |
| Today: oversized slogan and dark decorative CTA | TodayView: a centered, dynamically scaled phrase and meaning on a plain reading surface. |
| A homepage scroll mixed practice, onboarding, and collections | One phrase per native horizontal page; 80-page position, swipe, and explicit previous/next controls. |
| Pronunciation and saving required opening the phrase list | Adjacent 48-point listen, bookmark, and details controls on the reading surface. |
| No optional example on the homepage | A Show example control reveals the current phrase's original reply. |
| Daily practice embedded in a decorative panel | A fixed lower Practice speaking action with the actual queue count; empty queues are disabled. |
| Large drawing in each conversation tile, uneven row offsets | Compact aligned text tiles with a category symbol and consistent minimum height. |
| Promotional phrase-library heading | Short Your words heading above existing All phrases / By verb / Saved controls. |
| Large drawings on both completion screens | Shared compact blue checkmark, with the completion text and next action prominent. |
| Promotional paragraph before practice statistics | Actual statistics lead the Practice screen. |
| No prior-preview context for homepage browsing | The set of phrases displayed on Today is passed to practice started there; Came naturally is disabled for those phrases, with a contextual explanation. Viewing and saving do not schedule reviews. |
| Old homepage instructions | README and Japanese guide explain browsing controls and Practice speaking. |
| Primary action text truncated at the largest accessibility size | Button labels wrap vertically; decorative trailing symbols are omitted at accessibility sizes to preserve reading space. |
| A long duration caption crowded the fixed footer at accessibility sizes | The footer shows the actual phrase count without the optional time estimate at accessibility sizes. |

The reading body scrolls independently at large Dynamic Type sizes. Native paging and explicit controls coexist; programmatic page transitions respect Reduce Motion. Playback stops when changing phrase, leaving the screen, or backgrounding.

Final rendered review covered normal Today, an expanded example with its saved state, the four conversation tiles, and the largest accessibility text size. The primary action and phrase-count caption now display without ellipsis at that size, while the phrase body remains scrollable. The full suite passed 10 core and 9 UI tests; focused checks also passed after the accessibility fixes. See `VERIFICATION.md` for exact result bundles and screenshot provenance.

## Ice blue and meaning language

| Before | After |
| --- | --- |
| Flat white Today and PaperPage backgrounds | Shared static ReadingBackground with #F3F7FC base, #DCEBFA edge washes, and a near-white center; adaptive dark tokens. |
| Settings used the system form background | The form shares the ice-blue background while retaining native readable rows. |
| Japanese hint toggle | Settings → Meaning language offers 日本語 / Easy English as an inline picker; no language switch on the reading surface. |
| Original English meaning plus optional Japanese appeared together | Home, all phrase rows (including verb groups), detail, and practice hints/comparisons show the selected explanation language. Examples, prompts, and usage notes remain English. |
| No separate plain-English explanations | 80 original easyEnglish entries, generated reproducibly from scripts/easy_english.py alongside the existing curriculum. |
| Search covered original English and Japanese | Search also finds plain-English explanations in either display mode. |
| Stored Japanese visibility preference | The existing stored key maps to the two language choices, preserving old progress and preferences without a new required JSON field. |
| Tests and guides described the old toggle | Updated guidance; coverage checks old-file compatibility, language persistence, both display choices, search, hints, and comparison. |

The reference supplied by the user showed a near-white center with soft yellow edges. The user then chose ice blue. The implemented gradients borrow the spatial treatment, with no reference imagery copied or background animation. Easy English is editorially simplified text, not a certified CEFR level or an automatic translation service.

Rendered checks confirmed the native settings picker, both meaning displays, English practice comparison, and the ice-blue background at standard and largest text sizes. Core 11 tests and all 10 UI flows have passing evidence across the broad run and final focused language check. The latter waits for native search and dismissal transitions; exact boundaries are recorded in VERIFICATION.md.

## Essential copy and sorting

| Before | After |
| --- | --- |
| Phrases repeated its navigation context with Your words | LibraryView starts with collection filters and the actual result count; empty states say No saved phrases / No matching phrases. |
| No persistent sorting | PhraseSort provides A–Z, Z–A, Unpracticed first, and Review date, with deterministic alphabetic ties. |
| All and Saved used curriculum order; families always used A–Z | A shared toolbar sort menu controls lists, filtered/saved results, group order/previews, and each family’s members. |
| No saved sort key | An optional phraseSort key preserves the existing schema and defaults older data to A–Z. |
| Family repeated a generic Verb family title and a large verb headline | The navigation title is the verb; the body starts with a phrase count and the list. |
| Today included a repeated brand label, time estimate, and empty-queue guidance | Only phrase position, settings, the phrase, browse controls, and the practice action/count remain. |
| Scenes had Conversations plus promotional tile titles; scene detail repeated its tile | One Scenes title, descriptive scene names, and detail content without the repeated tile. |
| Phrase notes included A useful shape, Feel the difference, In your life, and a save caption | The frame and usage contrast stand directly; Your sentence identifies the input; actions use Practice speaking / Dictionary. |
| Settings used Make it yours, Where do you want more ease, and repeated picker labels | Settings, Meaning language, Conversation focus, Story practice, and Privacy; concise timer and data-retention facts. |
| Practice used large rhetorical prompts, an example kicker, repeated comparison advice, and promotional completion copy | The scenario and phrase lead; Hint / Compare reply / Review reply / Done name actions. Completion reports counts, while hint/preview restrictions retain their reason. |
| Voice controls used motivational status and repeated recording advice | Recording / Recording ready states and direct Type a reply / Speak instead controls. |
| Story practice repeated slogans on each take and its completion | Take number, actual prompt, one retelling instruction, timer, phrase hints, and a factual completion count. |
| Progress and learning-method pages included slogans or repeated self-rating disclaimers | Last 7 days / Upcoming reviews / No reviews yet; the learning-method page starts with its substantive explanation and sources. |
| Tests and guides relied on previous labels | Updated native navigation assertions and guides; new ordering, subset, grouping, persistence, old-file, and UI collection-sort coverage. |

Review-date ordering places scheduled items before unpracticed items, then orders dates ascending. Unpracticed first puts entries with no completed review ahead of practiced entries. A group is ordered by its first member under the selected sort, so a group with an earlier review comes first. This changes browsing only; daily practice scheduling is unchanged. Teaching content, sources, privacy facts, state labels, and confirmations with data-loss consequences remain.

The final full run passed all 14 core and 11 native UI tests. Rendered review confirmed Phrases without Your words, the four-option sort menu, descriptive scene tiles, direct practice controls, factual completion, and Settings without the duplicate picker label. Screenshot provenance is recorded in VERIFICATION.md.

## Learning streak

| Before | After |
| --- | --- |
| No streak summary on Today | Compact blue flame/count links to the existing Practice screen, with an accessible day-count label. |
| Practice showed aggregate totals only | Current streak and Best streak precede the existing totals; no motivational headline added. |
| Last 7 days counted phrase replies only | Calendar dates and explicit checkmarks show practice days, including completed stories. Accessibility sizes use three columns and stacked statistics. |
| Story practice stored only a lifetime total | New completions also save timestamps in an optional field, preserving old-file compatibility. Old undated totals are retained but never assigned invented dates. |
| No day-based streak calculation | Distinct local calendar days combine phrase reviews and story completions. Yesterday remains current through today; gaps reset current, not longest. Future activity is excluded. |
| Time-derived display could stay stale across midnight or travel | Today and Practice refresh on appearance, foregrounding, calendar-day notifications, and time-zone changes. |
| No streak documentation or coverage | Guides explain qualifying activity and current-time-zone grouping; tests cover duplicates, gaps, best runs, leap day, both DST transitions, legacy data, persistence, story-only activity, and browsing without credit. |
| Separate statistic accessibility values were unavailable to UI queries | Each streak statistic exposes a combined name and correctly pluralized day count. |
| Checkmark and minus glyph heights shifted calendar dates vertically | A shared scaled status-row height aligns all seven dates. |

Streaks track completed practice days, not English proficiency. The day boundary follows the current device calendar/time zone; historical timestamps are regrouped when that zone changes. The calendar implementation adds/subtracts days rather than treating every day as 86,400 seconds.

All 19 core tests and the four affected native UI flows passed. The daily flow passed again after the calendar alignment fix. Rendered review confirmed the compact Today link, current/best statistics, phrase and story-only activity, aligned calendar dates, and stacked large-text statistics. Exact result bundles and remaining boundaries are recorded in VERIFICATION.md.

## Supplied collection

| Before | After |
| --- | --- |
| 80 expressions in 28 verb groups | 389 expressions in 126 groups; look expands from 10 to 16. |
| CSV only in Downloads | Preserved repository source, deterministic import, stable expression IDs, and a row-by-row manifest. |
| Alternate forms absent from search | Normalized display forms with searchable aliases; supplemental meanings are searchable too. |
| Overlapping entries could replace original lessons | Original fields and IDs retained; 65 entries gain a collapsed More usage section with the supplied meanings and example. |
| New rows have meanings and one example, but no authored two-situation lesson | Example recall hides inflected verbs and particles, keeps objects visible, then invites a personal sentence and a meaning/word-order self-check. |
| Detail and comparison assume authored grammar notes and two model answers | Optional sections render only when content exists; no empty panels or invented grammar notes/model answers. |
| Four original conversation collections | Everyday English provides access to the 309 imported entries. Scene sessions select at most six due/new entries, and long scene lists load lazily. |
| Detail practice could rate a just-viewed phrase as unprompted | Detail practice passes the phrase as previewed, preserving the same rating restriction as Today. |
| Plain phrase rows left their empty central area outside the tappable content | An explicit rectangular content shape makes the entire row open its detail. |

The ice-blue palette and existing navigation are retained. Both meaning languages, saving, notes, verb grouping, sorting, scheduling, and streaks share their existing implementations with imported entries. CSV text is retained as supplied; the import does not assert that a multi-sense definition is a single sense or that new material has undergone the original dictionary audit.

The subsequent `phrasal_verbs_complete_550.csv` contains 601 rows (not 550). It adds 227 source rows without changing the earlier 374: 225 new expressions and two original-lesson supplements. The combined app now contains 614 expressions in 310 verb groups, with 534 example-recall entries and 67 supplemental usages. Existing IDs and the first 389 browsing positions are retained. `log off/out` displays as `log off` with searchable alias `log out`; cloze generation also handles reflexive forms such as `fend for himself` and irregular `spun off`.

Final rendered review inspected the 614-expression list, the new `flesh out` detail in Easy English, imported cloze practice, and the expanded supplemental example for `back up`. The fresh CompleteValidation build passes all 21 core tests and both newest-collection/sorting UI flows. Two further import UI flows have passing evidence in Collection614; source integrity is covered by four Python tests. Detailed evidence and boundaries are recorded in VERIFICATION.md.

## Core images

| Before | After |
| --- | --- |
| Meanings and examples had no spatial diagram | 35 original vector diagrams share one coordinate system, blue subjects and paths, gray references, and hollow starting points. |
| No particle-based browsing | Phrases → Core images opens a searchable gallery; all 614 expressions link to their recognized particles. |
| Similar particles could only be read separately | A comparison places pairs such as in / into and across / through at the same visual scale. |
| Movement could only be implied by an arrow | A manual slider moves the blue subject along the full visible path; static relations omit this control. |
| No bridge from a spatial cue to phrase usage | Short bilingual explanations describe extensions, followed by expressions containing the word. Whole-expression meaning remains explicit. |
| Search placement was initially automatic | An always-visible navigation search drawer makes gallery search discoverable at large accessibility text sizes. |
| Fixed side-by-side layouts would crowd large text | The gallery uses one column and comparisons stack vertically at accessibility sizes. |

The ice-blue palette, serif particle titles, native navigation, saved meaning-language preference, and existing phrase sort are retained. Every diagram is rendered from the same SwiftUI Canvas component. The feature has no automatic motion and awards no streak credit for browsing. Sources, semantic limits, and the visual grammar are recorded in CORE-IMAGES.md; test and screenshot evidence is in VERIFICATION.md.
