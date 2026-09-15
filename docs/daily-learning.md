# Daily learning and a single answer reveal

## Reference

Distinction's [App Store editorial](https://apps.apple.com/jp/iphone/story/id1683050039)
describes choosing the number of new words per day and seeing an estimated
completion period. Its official [study-mode guide](https://www.youtube.com/watch?v=d3DUkidMrm4)
distinguishes new words from words to review. Vow adopts the new-expression goal
and separate review count. It retains its own content, navigation and scheduler.
The source checks were made September 13, 2026; the video describes an earlier
version, not an inspection of the current installed Distinction app.

## Flow

On a fresh install, a three-page introduction (phrases, spaced reviews, Vow Pro)
comes first and is never shown again; installs that already saved a goal skip it.
Then, as on upgrades without a saved goal, the user confirms a daily
new-expression goal. The presets are 5, 10 and 20, and a stepper allows any
number from 1 to 50. Five is the initial
selection, not an automatically confirmed goal; Decide later keeps five as the
working pace and the sheet does not return. The
same editor is available through Home → progress count and Settings → Learning → Daily learning.

Home switches between **Today's learning** and **Explore**. Today's learning
pages through currently due reviews and the remaining new-expression allowance.
Explore pages through the entire accessible catalog (1,300 expressions with Pro;
the fixed 50-expression collection plus the Pro card otherwise). Each mode keeps
its own browsing position while the view is alive. Switching modes, revealing an
answer and swiping never rate an expression or consume the daily allowance.
Explore also shows the rating row once the answer sheet has been opened; rating
there records the memory review and moves to the next card. Changing the answer
later the same day (in Explore or Phrase notes) replaces the earlier answer: the
schedule is recomputed from where the day started, and the interval under each
button stays the same after a tap. Once Again's ten minutes have passed, the next
answer counts as a new review.

The daily progress and goal editor appear in Today's learning. The info button
between the speaker and bookmark opens the meaning and examples in a sheet from
the bottom. In Today's learning, “How well did you remember?” and the four
icon-and-text ratings stay under the card; they unlock once the sheet has been
opened for that phrase, and rating updates the persisted schedule and advances
the queue immediately. There is no
Start/Continue learning step and no scene link on Explore (Scenes live under
Phrases).
After completion, Home shows the next review time and an Explore action. Increasing
the goal immediately refills the day's queue. Both browsing and recall include
all due items and the full remaining allowance.
Explore's speaking action uses the expression currently displayed; Today's
learning retains the separate speaking-practice queue. Stats and notification-driven
reviews use the same ratings and scheduler in their review screen.

A new expression counts once, when first rated in meaning recall, including an
Again rating. Revealing, swiping, saving or speaking practice does not consume
this allowance. A repeat rating on the same expression cannot add another new
introduction. Completion means finishing today's available introductions and
currently due reviews, not mastering those expressions. A forgotten expression
can become due again ten minutes later.

Closing and restarting recomputes the remaining queue from persisted review
states; already introduced expressions are not assigned as new again. A change
in the goal applies immediately to the remaining allowance without changing
history. The local calendar day resets the allowance. If fewer unseen expressions
remain than the goal, the progress denominator reflects the smaller available
batch; if none remain, the completion screen explains that only reviews remain.
Introductions keep counting after access is revoked, preventing another free
allowance from being created; queues still contain only accessible expressions.

## Answer sheet

Since 2026-09-14 the answer is a sheet, not an inline reveal: Home shows only the
phrase, its difficulty and three actions (hear, meaning & examples, save). Opening
the sheet counts as seeing the answer for the current learning phrase; moving to
another phrase resets that. The former Settings switch for showing the answer by
default is gone (`todayShowsAnswer` still decodes but is unused). The separate
Stats/notification review screen always starts with answers hidden.

`todayShowsAnswer` and `dailyNewGoal` are optional fields. Old separate visibility
keys still decode: either old preference being true makes the unified default
visible unless a new explicit choice overrides it. Existing saved expressions,
notes, review states and IDs are preserved. Unconfigured legacy goal data uses
five only as a safe calculation fallback while the setup screen asks for a choice.

## Verification

The 53 Swift package tests pass, including daily quota changes, restart continuity,
repeat-rating deduplication, due/new separation, midnight rollover, collection
exhaustion, access changes, preference migration and the existing scheduler suite.

At accessibility text sizes, Today uses one vertically scrolling reading surface
instead of keeping the bottom controls fixed around a small phrase viewport.
Previous/next buttons remain available; ordinary text sizes retain swipe paging.
Goal options appear before explanatory text so the choice is reachable immediately.

Four distinct iPhone simulator UI scenarios passed: goal setup/resume/completion/
change, unified default persistence, stable normal-size reveal controls, and goal
selection plus readable meaning/examples at the largest Dynamic Type size. The
initial large-type check exposed offscreen goal options; moving the options first
fixed that. Screenshot review also prompted the full-page scrolling layout so
fixed controls no longer consume the reading area at large sizes. Final large-type
and normal-size checks passed in `.build/DailyLearning-Accessible-UI.xcresult`;
goal journey checks passed in `.build/DailyLearning-Verified-UI.xcresult`, and
preference persistence in `.build/DailyLearning-UI.xcresult`.

Screenshots are in the corresponding `*-attachments/` directories and were
visually inspected. Both landing languages passed their build/link/ARIA checks.
Physical-device and VoiceOver interaction were not tested in this change.

## Today modes — build 8

`Today-Modes-Phone-Verified.xcresult` passes four UI tests: real horizontal
swiping and independent positions, selected-expression recall and removal after
rating, completion/Explore/goal refill, a 22-expression goal with the free
50-expression Explore collection, and paging at the largest text size with
reduced motion. `Today-Modes-Pad-Verified.xcresult` passes the three Pro scenarios.
Both bundles are under `.build/BrandRelease/`. Actual normal and large-type
screens were inspected on both device sizes. No physical-device or VoiceOver
interaction is claimed.

The same production source passed 64 iOS unit tests and the existing unified
answer preference UI test in `Today-Modes-Pad-Final.xcresult`. That containing
run failed three initial Today test-driver assertions; follow-up runs above pass
after using the accessible button identifier, accepting the localized `1,200`
count and waiting for modal presentation before tapping. The free-goal test used
the stepper's `dailyGoalCount-Increment` identifier until the stepper was removed
on 2026-09-14; it now selects the 20 preset directly. The source of
the production app was unchanged by these test corrections.

Build 8's archived source remains immutable at `.build/Release/build8-source`.
The corrected test drivers and screenshot import validation are recorded
separately in `.build/Release/build8-validation-source/validation-source.json`.
Exact archive/IPA inspection verifies all production files still match and
accepts only those explicitly hashed validation-tool changes.

### Accessibility follow-up — build 9

Final visual inspection exposed word-level wrapping in the horizontal switch at
maximum iPhone text size despite passing interaction tests. Build 9 stacks the
mode buttons vertically at accessibility sizes, using their full available width.
`Today-Accessible-Phone.xcresult` passes normal selected-card recall and largest-type
paging; `Today-Accessible-Pad-Verified.xcresult` passes largest-type paging. Both
corrected screens were visually inspected before upload. An earlier iPad
`test-without-building` run executed stale test code and failed the old comma
assertion; rebuilding for that destination produced the current passing result.
Normal store images were captured for build 8 and retain the same normal layout.

## Simpler Today footer — build 11

The footer groups the daily progress/goal button and compact page controls into
one row above Start learning or Continue learning. It omits the progress track,
visible review-due count, separate Daily goal label and secondary speaking row.
The review count remains available in the progress button's accessibility value
and in Stats. At accessibility text sizes, progress and paging stack vertically.
Explore only shows centered paging controls in its footer.

Practice speaking is now a 44-point waveform button in the upper toolbar, with
an explicit accessibility label and the same session behavior. Progress is a
native button: tapping it opens the existing daily-goal editor.

Five iPhone UI tests pass in `Today-Simple-Footer-Verified.xcresult`, covering
mode positions/selected recall, completion/refill, free access with a goal above
20, largest text/reduced motion, and the moved speaking entry with typed reply.
Final Today, Explore and largest-text screenshots were visually inspected. The
first run exposed an accessibility container that hid the goal button; it was
removed before the final source was frozen and archived.

## Home refinement verification — September 13, 2026

The footer tab is Home. Today's learning now rates directly on the page, with
Again / Hard / Good / Easy icons, text and scheduler intervals. Ratings are disabled
until meaning/examples are visible. Scene links remain in Explore. Accessibility
sizes use a single column of ratings and return to the top after a rating changes
the selected expression. The difficulty guide uses left-aligned text and an unboxed
introduction; EIKEN references use approximate grades (see `phrase-difficulty.md`).

- Debug simulator build succeeded, including the final scalable icon spacing.
- 72 unit tests passed. The EIKEN grade references, persistence and scheduler tests
  are included in `.build/home-refinement/Home.xcresult`.
- Eight UI scenarios passed: answer reset after rating; persisted daily limit;
  saved default-answer behavior; difficulty selection/filter persistence; largest
  difficulty-guide text; EIKEN grades after relaunch; completion and increased goal;
  a goal of 20 with the free Explore boundary.
- Screenshots in `.build/home-refinement/screenshots/` were inspected for the
  normal Home ratings and the left-aligned, unboxed guide introduction.
- The largest-text Home test reached its automation timeout after rating. The
  following swipe test could not terminate the app. A process sample found the
  app's main thread waiting in its run loop, not a demonstrated application loop.
  These two scenarios are not claimed as passed.
- The focused retry (`verified.log`) built successfully but could not start tests.
  A fresh iOS 26.3 simulator also could not be discovered by Xcode (`fresh.log`);
  its destination list contained only generic placeholders. Final largest-text
  rating/advance, selected swipe, Japanese Home, Stats review controls and stable
  example layout still need their focused UI rerun. The test source is updated.
- No archive, upload or App Store submission was performed for this refinement.
