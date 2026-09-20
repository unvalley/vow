# Meaning reviews and free access

Today has one Show meaning & examples / Hide meaning & examples control. Settings → Today sets one default for both, initially hidden. Legacy separate preferences become a single visible answer if either was enabled; an explicit new choice takes precedence. Tapping on Today overrides only the current phrase, and changing phrases restores the saved default. These preferences never reveal answers in the daily recall session. Stats retains the shared calendar-based streak.

See [daily learning](daily-learning.md) for goal selection, progress counting and resuming.

## Review flow

Home → Today’s learning → recall the meaning → Show meaning & examples → Again / Hard / Good / Easy. The answer includes the lesson's examples and each rating displays the next interval. Due cards precede fresh cards, with the user’s chosen 1–50 new introductions per local calendar day. New-card allowance persists across sessions and app launches. Forgotten cards become due in ten minutes and are picked up on re-entry or by the active screen's 30-second refresh. Closing a card before rating creates no review.

The meaning schedule is stored in the optional `LearningData.memoryReviews` field. Old data decodes unchanged. Speaking production continues to use its existing schedule: recognizing a meaning and producing a reply are different tasks. Both append to the existing activity history; no learning progress is discarded on purchase or refund.

## Scheduling

`MemoryScheduler` uses SM-2-derived intervals, with a four-button adaptation. Good begins at one day, then six days, then the previous interval multiplied by the card's ease. Hard increases more slowly and reduces ease; Easy starts at four days and expands faster. Again resets repetitions and schedules ten minutes, followed by a one-day Good interval. Ease is bounded to 1.3–3.0 and intervals to 36,500 days. Correct answers before the due time do not extend the schedule.

This is not Anki's FSRS model and does not estimate an individual's forgetting probability. No model training, account or network service is required.

References checked September 13, 2026: [Anki answer buttons](https://docs.ankiweb.net/studying.html#answer-buttons), [SuperMemo SM-2](https://super-memory.com/english/ol/sm2.htm).

## Optional review notifications

Settings → Notifications adds an opt-in Review reminders toggle and a local time picker
(default 19:00). Notifications follow the memory review due dates, grouped by due day;
OFF cancels pending reminders. Permission handling, access filtering, daylight saving,
queue replacement, and verification are documented in [review-reminders.md](review-reminders.md).

## Access

The original fifty phrasal-verb IDs are frozen in `AccessPolicy.freePhraseIDs`; fifty fixed idioms are listed in `freeIdiomIDs`. Their union, `freeIDs`, determines access independently of sorting or catalog additions. Free access includes browsing, saved expressions, notes, meaning reviews, continuous listening and speaking practice for those hundred expressions, all core diagrams and all five story scenes. Speaking is free and uses expressions available in the catalog; it does not wait for a purchase check or open a paywall. Izzy Pro unlocks all 1,370 expressions for browsing and meaning reviews.

Home → Explore shows 100 free expressions (50 phrasal verbs and 50 idioms) followed by a Pro lock card. Phrases inserts its Pro card after ten expression rows, or three verb groups, while leaving the first screen for browsing. Search, verb groups, scenes, diagram-linked phrases and story hints all filter before rendering. Phrase details also check access so a revoked entitlement cannot leave a paid detail open. Review queues only draw from allowed phrases.

Izzy Pro is the non-consumable `me.unvalley.izzy.pro`. The rename moved the product ID off `verve`, so no earlier purchase unlocks it; see [RENAME.md](RENAME.md). There is no subscription. StoreKit remains the source of entitlement and localized pricing.

## Verification boundaries

The macOS core suite passes 33 tests, including interval progression, difficulty, relearning, early-review protection, limits, midnight replenishment, access filtering and persistence with legacy data. Nine native UI flows have passing evidence, including the free boundary, Pro rendering, reveal/reset, language, spaced-review persistence, largest text, and existing speaking practice. Exact result bundles and remaining boundaries are recorded in `docs/VERIFICATION.md`.

Local StoreKit integration still cannot obtain a Product, matching the pre-existing service failure documented in `AppStore/READINESS.md`. Purchase, restore, approval and refund transactions remain unverified. Debug-only Pro rendering tests are not transaction evidence. Local listing drafts were updated; App Store Connect metadata was not changed.
