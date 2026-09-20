# Izzy design refresh · September 13, 2026

## Reference observations

The reference is **60fps.design**, an interaction gallery, rather than a claim
that the app has been measured at 60 frames per second.

- [Spark · Correct Card Slide](https://60fps.design/shots/spark-correct-card-slide-animation):
  inspected the embedded video at its answer and next-round states. The round
  counter stays in the same place while the comparison cards move, and the
  answer action resets. Adaptation: keep the learning progress in place, move
  only the current prompt, and hide the old answer before another rating is possible.
- [Opal · Code Copied](https://60fps.design/shots/opal-code-copied-text-pop-interaction):
  inspected the embedded video before and after its code changes to COPIED.
  Feedback appears where the user tapped. Adaptation: cross-fade the saved
  bookmark in place and add selection feedback, without a blocking toast.

The app keeps its existing New York vocabulary typography, quiet SF reading
styles, neutral surfaces, seven selectable accents and landscape background.
No reference screenshots, branding or source code were added to the app.

## Changes

| Area | Before | After |
| --- | --- | --- |
| Today | Uppercase scene and difficulty precede the phrase; 24-point gaps | Natural-case scene, then phrase and difficulty; 16-point gaps |
| Today actions | Learning button uses a light surface, with a text-only daily count | Neutral filled 48-point learning button, 4-point progress track; speaking stays secondary |
| Today streak | Flame and an unlabeled numeral | Outline flame and an explicit day unit; accessible streak label retained |
| Answer reveal | Immediate visibility toggle | 200 ms opacity change; reserved layout and hidden accessibility state retained |
| Save | Immediate bookmark replacement | Shared 48-point bookmark button in Today and details; 180 ms cross-fade and selection feedback |
| Phrases | 24-point control gaps; separate count and filter rows; long search prompt | 12-point gaps, count/filter on one row, quieter category links, always-available “Phrase or meaning” search |
| Phrases at large text | Four segmented labels compete for width | Collection menu and vertically arranged count/filter |
| Meaning review | All content and rating actions scroll together | Fixed progress header; neutral prompt card; bottom rating dock at standard text, inline controls at accessibility text |
| Next prompt | Immediate text replacement at the old scroll offset | 240 ms asymmetric offset/fade and reset to top; previous answer/rating controls reset |
| Completion | Static checkmark and explanatory paragraphs | One 240 ms fade/scale, today’s new-expression count, next review time and a clear Done action |
| Daily goal | Several form sections and repeated explanation; color-only selection | Checkmarked presets, selection feedback, shorter estimate/copy and a filled primary save action |
| Stats | Streak numbers, with no quick view of practice days | Seven recent practice-day marks; three columns at accessibility text; neutral daily summary and shared progress track |
| Test harness | No deterministic visual trait override | DEBUG-only dark appearance and motion-policy arguments for repeatable UI checks; production builds keep system traits |

All new animations respect Reduce Motion. There are no repeating timelines,
artificial loading delays, auto-playing decorative effects or network requests
in these view interactions. Saved IDs, review scheduling, daily limits and the
1,000-expression catalog are unchanged by this design pass.

## Verification

- Simulator build and **59 core tests** passed.
- `Phone.xcresult`: **7 UI scenarios passed** (daily-goal setup/resume/completion,
  largest-text goal/reveal, stable Today reveal, review-card reset, idiom
  search/details/speaking/save, empty Stats, recorded Stats at largest text).
- `TraitsPhone.xcresult`: final library layout and final large-text Stats reruns
  passed. This run discovered no dark-review test; it is not dark-mode evidence.
- `DarkPhone.xcresult`: the separately executed dark/reduced-motion/AX5 scenario
  passed, covering reveal, rating, next-prompt scroll reset and the large-text
  collection menu. Dark appearance and AX5 were set explicitly; the DEBUG motion override exercises the same guards as the system Reduce Motion preference.
- Exported screenshots were inspected for the normal Today/library/review,
  goal setup/completion, final Stats at large text, and dark large-text rating,
  next prompt and library. Recorded transition frames show the fixed header,
  progress update and the old answer fading as the next prompt arrives.
- The catalog remains byte-identical to the content expansion:
  `ca0a650e19496135688824610c747ccbc0b37d1c8f73d73fc800d8b4f37d0650`.
- `TabletVerified.xcresult`: the iPad mini portrait review journey passed;
  Today and the answer card/dock screenshots were inspected. The initial run
  was interrupted after a simulator rendering-service fault and unresponsive
  launch requests; a simulator restart restored operation. It is not counted
  as a passing test.
- In total, eight distinct iPhone UI scenarios passed; two were repeated for
  final layout changes, and the review-card scenario also passed on iPad.
- `git diff --check` passed. Current implementation/test hashes are recorded in
  `.build/DesignRefresh/verified-source-hashes.json`.

The evidence covers iPhone portrait in light mode, AX5 light Stats and daily
learning, AX5 dark/reduced-motion review and collection controls, and iPad mini
portrait Today/review. Landscape, device haptics and device frame pacing were
not measured.

All result bundles, logs, captures and the short recording are under
`.build/DesignRefresh/`. [Open the local before/after gallery](../.build/DesignRefresh/review.html).
The gallery's nine image resources loaded successfully in the browser.

## Release boundary

This source change is local. TestFlight build 5 contains the earlier release;
neither the latest 300-idiom expansion nor this design pass has been uploaded.
Physical-device haptics and frame pacing are not established by simulator tests.
