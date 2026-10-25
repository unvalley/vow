# Izzy Pro: where it is offered and how

Izzy Pro stays a one-time purchase. This note records where the free plan meets Pro, what each
place says, and the time-limited trial. Every figure on these screens comes from the catalog
(`CatalogFacts`, `AccessPolicy`) or the learner's own reviews (`ProOffer`); none is typed into copy.

## The level check

Onboarding's third page (of four) is an optional level check (`LevelCheck`, `LevelCheckView`): eight
meaning questions, a phrasal verb and an idiom at each level from A2 to C1, easiest first, with four
meanings in the learner's explanation language and a “Not sure” that keeps guesses out of the result.
It recommends the first level with a miss and the one above it (none known at A2 starts at A1; all
known works at B2 and C1), says how many expressions those levels hold and how many are free, and
“Learn at these levels” sets Home's levels. The Pro page that follows speaks of those levels. Skip is
always one tap. Analytics records `level_check` with `step` (finished, allLevels, skipped, abandoned)
and the chosen levels.

The free idioms keep twenty well-known ones and spread the rest from A2 to C1, so every level a learner
can choose has at least five free expressions (`ProOfferTests`).

## The moments

At the default five new expressions a day the free plan lasts twenty days, and most people leave a
learning app in its first few. So Home's completion offers one next step from the first finished day,
chosen by `CompletionNextStep` in this order:

1. the end of the free plan, or Pro reviews waiting (free plan only);
2. a review reminder at the next five-minute mark after the day was finished, asked in the app before
   iOS asks (`completionReminder`). Never an earlier minute: reminders fire at the first chosen time on
   or after a review is due, so an earlier one would skip the next day;
3. the 7-day trial, with the next Pro expressions (`completionTrial`), once the trial product exists.

“Not now” puts the reminder or the trial off for seven days. A refusal in iOS Settings is not asked
about again. UI tests see the reminder and trial cards only with `--completion-steps`.

| Place (`from` / `place`) | When it appears | What it says |
|---|---|---|
| `completionTrial` | Home's completion, after the reminder is settled, while the trial is available | Every expression in Izzy Pro, free for 7 days; the next Pro expressions |
| `freeComplete` | Home's completion, once the free plan has introduced every expression Home's filters show | You've learned every free expression; the next Pro expressions at your levels; one button to Pro |
| `proReviewsWaiting` | Home's completion on the free plan when Pro expressions were met before (an ended trial, a refund) | Reviews for *n* Pro expressions are waiting |
| `search` | Phrases search on the free plan | Pro matches listed by name and level under **In Izzy Pro**, not "No matching phrases"; a tap opens Pro led by that phrase |
| `verbGroup` | A verb family on the free plan | *n* more *look* phrases with Izzy Pro |
| `phrase` | A Pro phrase opened from elsewhere | The phrase itself above the lock |
| `explore`, `home`, `library`, `levels`, `background`, `font`, `savedLimit`, `noteLimit`, `settings`, `onboarding` | Unchanged | — |

Reviews never stop on the free plan; only new expressions run out. That is why the free plan's end
is shown on Home's completion rather than as an interruption.

## The purchase screen

- Leads with the tapped phrase when there is one (“Learn *get the hang of* with Izzy Pro”).
- Shows the learner's free-plan progress (*learned / free total*) and any Pro reviews waiting.
- Shows the next three Pro expressions Home would introduce at the learner's kind, levels and focus,
  with their meanings: the same order `MemoryScheduler.queue` uses (`ProOfferTests` checks this).
- Keeps the free/Pro comparison, the one-purchase promises and the free-plan footnote.
- The trial or price button is pinned to the bottom, so it never scrolls out of reach.

## The 7-day trial

App Review Guideline 3.1.1 lets an app without subscriptions offer a time-based trial as a ¥0
non-consumable named “XX-day Trial”. Izzy's is `me.unvalley.izzy.pro.trial` (`AccessPolicy.trialProductID`).

- It appears only when StoreKit returns that product, so builds behave exactly as before until it
  exists in App Store Connect. The local `Configuration/Izzy.storekit` includes it for testing.
- Access runs `AccessPolicy.trialDays` from the Apple-signed purchase date, so reinstalling or
  restoring on another device never extends it, and owning it means one trial per Apple Account.
- Before it starts, the screen states the length, that the learner returns to the free plan with
  its expression count, that nothing is charged, and the one-time price that keeps Pro (3.1.1).
- Buying stays available during the trial. `PurchaseStore.isPurchased` separates a purchase from
  the trial; `hasFullAccess` covers both. A restore that finds only a trial reports nothing to restore.
- When it ends, Pro expressions met during it keep their history; their reviews resume with Pro.

Analytics adds `pro_trial_started`, and `pro_screen_opened` carries `offer: trial` when the trial is
on offer. The worker's event list in `landing/worker/index.js` must be deployed before builds send it.

## Trial-ending notice

For learners who turned review reminders on, one local notice at their reminder time on the day before
the trial ends says that it ends and that buying keeps the reviews for what they learned. It never asks
for notification permission, is removed when the trial is bought or over, and opens Izzy Pro when tapped
(`ReviewReminderCenter.updateTrialNotice`, `AccessPolicy.trialNotice`).

## Rating prompt

After the last card of the day, Home asks for an App Store rating when the streak is at least 3 days,
at least 15 expressions have been met, and 120 days have passed since the last ask (`RatingPrompt`).
iOS limits the sheet to three times a year on its own. UI tests never see it.

## Setting up the trial in App Store Connect

1. In-App Purchases → Non-Consumable, Product ID `me.unvalley.izzy.pro.trial`,
   reference name `Izzy Pro 7-day Trial`, price ¥0 (Free), Japan, Family Sharing off.
2. Display names: ja `7日間の無料体験`, en-US `7-day Trial`. Descriptions as in `Configuration/Izzy.storekit`.
3. Review screenshot: the purchase screen with the trial button and its terms.
4. Review notes: “Izzy Pro 7-day Trial is a free non-consumable that unlocks Pro for 7 days from its
   purchase date, as Guideline 3.1.1 describes. The terms are shown above the button before it starts.
   Nothing is charged when it ends; the app returns to the free plan.”
5. Submit it with the build that ships this code.
