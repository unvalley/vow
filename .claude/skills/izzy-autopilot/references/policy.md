# What lands on its own, and what becomes a proposal

The test: could a careful reviewer who does not know the user's taste agree that the change
is right by checking it against something written down? `docs/DESIGN-SYSTEM.md`, the
tokens in `Izzy/Views/DesignTokens.swift`, Apple's Human Interface Guidelines, WCAG, a
failing test, a measurement, the app's existing screens, or a decision already recorded (an
answered proposal, the backlog, project memory, `docs/*.md`). If yes, the autopilot builds
and lands it. If the change rests on preference or on a business decision, it becomes a
proposal.

## Lands automatically

**Features**

- Ideas the user has already approved: answered proposals, the backlog's "From the user"
  section, and work a `docs/` record names as left to do for a feature the user asked for.
- Completing an existing flow: missing empty, loading and error states; VoiceOver labels,
  traits and actions for controls that exist; Dynamic Type layouts that break; undo for
  something destructive; search and filter gaps; the widget showing data the app already
  has; a deep link for a screen the app already has.
- iPad: a screen that works on iPhone but breaks, clips or wastes the width on iPad.
- Reading features built from editorial data already in `phrases.json` (glosses, IPA,
  difficulty, examples, related phrases, core images) with the existing components.

**Design, measured against a written rule**

- Gaps and insets off the four-point `Spacing` scale; radii outside `Radius`; nested shapes
  that are not concentric; type set outside `Typography` roles; neighbours in a row with
  different heights.
- The design system's rules: no shadows or borders in the app (depth is `surface` on
  `paper`); at most one `PrimaryButton` per screen; accent marks state, never decoration;
  colour is never the only signal; motion uses `Motion.snappy` / `Motion.entrance`
  springs without bounce, nothing loops, Reduce Motion gets the short fade.
- Clipped or truncated text whose full text cannot be reached; English or Japanese
  overflow; Japanese line breaking.
- Dark-mode defects. Contrast below WCAG AA (4.5:1 for text, 3:1 for large text and
  controls). Hit targets under 44 pt. Dynamic Type and accessibility-size breakage.
  Missing labels, traits or focus order.
- Two places meant to be one surface that disagree (Home's card and the phrase detail, the
  widget and Home's counts, the iPhone and iPad versions of a screen).

**Quality**

- Bugs and crashes, each with a test that reproduces it.
- Performance, with before and after numbers and a guard test that fails if the cause
  comes back (`TodayDerivationPerformanceTests` is the pattern).
- Stale tests broken by an earlier change.
- Landing technical quality that a check can prove: broken links, image sizes, layout
  shift, structured data, `npm run check` failures.
- Copy that is wrong: a typo, a term used two ways, a missing or broken Japanese string, a
  sentence that contradicts what the app does, a hard-coded plural.

## Becomes a proposal

**Taste**

- Colour, accent and palette; a new visual effect or look; type roles (face, size,
  weight); iconography, the app icon, the mark and the wordmark; motion style;
  reorganising an existing screen; removing, hiding or merging an element; headlines,
  marketing and landing copy; Home's backgrounds.

**Product and business**

- Pricing, the trial's length and behaviour, purchase and rating prompts, what is free and
  what is Pro, onboarding order, App Store metadata, screenshots and review notes, legal
  pages and what they describe (privacy, data collected, terms).
- New analytics events or any new data that leaves the device; new network endpoints,
  third-party services or SDKs; a new runtime dependency. (Developer tooling that never
  ships in the app can land.)
- Catalog content: adding, removing or rewriting expressions, meanings or examples.
  Catalog batches have their own workflow (`scripts/add_expressions.py`, `docs/CATALOG-*.md`).
- Notifications: what is sent, when, and how permission is asked.
- Learning behaviour: scheduler intervals, the daily goal's rules, what counts for a
  streak.
- Work on another branch's feature (`feat/icloud-sync` and the like) unless that branch's
  owner left it to the autopilot.
- Anything that reverses a decision the user made. Check proposals, the log and memory.

**Out of scope, not even a proposal**: releases and build-number bumps, archives and
TestFlight uploads, `npm run deploy` and Cloudflare settings, App Store Connect, the
analytics endpoint's database, emails, posts, and running `IzzyUITests`.

When in doubt, it is a proposal. A wrong proposal costs the user one line of reading; a
wrong landing costs a revert and their trust in the autopilot.

## The user's standing taste rules

From the user's past feedback. Follow them in every change, features included. Newer
feedback in the project memory (entries of type `feedback`) wins over this list.

- Write nothing that is not needed, anywhere: UI, store copy, privacy policy, docs. Describe
  only what the app does; never add a line about what it does not do.
- Catalog counts in copy are open-ended ("3,000+ expressions", "3,000以上"), never exact.
- The expressive, inflated, tilted taste belongs to the icon and the mark alone. The
  wordmark stays Figtree Medium and the landing page stays in system fonts.
- A reference app gives the idea, never the look. Re-express a borrowed mechanism with
  Izzy's tokens and assets, and compare it with the reference side by side before
  proposing it.
- Sentence case, no emoji, no exclamation marks, no streak threats; the app says *you*,
  never *we* or *I*.
- Edit `Localizable.xcstrings` and `InfoPlist.xcstrings` textually, in place. A JSON
  rewrite reorders every key and buries the change.
- Commits are authored with the repository's noreply address from git config, never a work
  email.
- A terse verdict from the user is about one element. Do not widen it into a redesign.
- No personal names, paths with names, or contact data in code, tests, docs or commits
  beyond what the repository already publishes (the support address).

## Writing a proposal

The format is in [state.md](state.md). Make each one easy to answer from a phone:

- Two to four options that look clearly different, each with a picture. When it is cheap,
  render the option for real (build it in the cycle's worktree, capture it, keep the
  branch); otherwise a mockup is fine. Name the option you would choose and why, in one
  line.
- Say what happens on each answer ("A: lands as IZ-0031 in the next cycle; B: closed").
- At most one proposal with fresh renders per cycle; others are text with the captures you
  already have. A few good proposals beat a long queue.
- A proposal's code never lands on `main` before its answer.
