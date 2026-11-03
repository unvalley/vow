---
name: izzy-autopilot
description: Autonomous improvement cycle for Izzy (the iPhone and iPad app, its widgets and the izzy.unvalley.me landing site). Picks the most valuable next change - a feature that completes a flow, a design fix measured against docs/DESIGN-SYSTEM.md, an accessibility, performance, copy or bug fix - builds it test-first in a scratch worktree, proves it with the build, unit tests and before/after simulator captures, gets an independent review, commits it to main and pushes. Taste and product calls become written proposals instead of code. Use this whenever the user wants Izzy improved or extended without naming every change ("Izzyを改善して", "次の改善を自動で", "機能改善を進めておいて", "放置でいい感じにして", "autopilot回して", "/loop で改善し続けて"), asks what the autopilot did or will do next, or answers one of its proposals. Not for releases, TestFlight uploads, landing deploys, App Store Connect, catalog batches or posts.
---

# Izzy autopilot

Each invocation runs one **cycle**: choose one improvement, build it, prove it, land it on
`main`, push, report. It asks no questions. Anything that needs the user's taste or a
product decision is written up as a proposal, and the cycle moves on to something it can
decide on its own.

Arguments (free text after the command):

- nothing: one cycle
- `plan`: orient, discover and choose, write the plan into the backlog, stop before code
- a number `N`: N cycles in a row, each with its own lock, worktree and report
- a focus (`home`, `widget`, `accessibility`, `landing`, `IZ-0012`): discovery and choice stay inside it
- `status`: `python3 -I scripts/status.py show` and a short summary of it; change nothing

To run unattended: `/loop /izzy-autopilot` (self-paced) or a scheduled task on this Mac
that runs `/izzy-autopilot`. A cloud routine cannot run it: Xcode and the simulators are on
this machine. Under `/loop`, start the next cycle soon after a landed one, and wait an hour
or more after `nothing-eligible` or `blocked`: the blocker is usually someone else's work in
progress, which takes time to clear.

## Ground rules

1. **The main checkout belongs to other people.** Other sessions edit and commit in it at
   the same time. Never edit, stage, stash, reset or check out files there. All work
   happens in a worktree from `scripts/start-cycle.sh`. `scripts/sync-main.sh` and
   `scripts/land.sh` are the only things that write to the main checkout: the first only
   fast-forwards it, the second only touches the paths the cycle changed, after proving
   none of them is dirty.
2. **One improvement per cycle**, so it can be reviewed as one story and reverted as one
   unit.
3. **Proof before landing.** A failing test first, green gates for everything the diff
   touches, and for anything visible, before/after captures looked at full size. No proof,
   no landing.
4. **Taste and product calls are the user's.** Spacing off the four-point scale is a
   defect; a new accent colour is an opinion. [references/policy.md](references/policy.md)
   draws the line and holds the user's standing taste rules. Read it before choosing.
5. **Nothing outward-facing beyond main.** Pushing `main` deploys nothing: the site goes out
   with `npm run deploy` and the app with a TestFlight build, and the autopilot does
   neither. Releases, build-number bumps, uploads, deploys, App Store Connect, store
   metadata, emails and posts are never done by the autopilot. When a change only reaches
   people through one of these, put a line in `$STATE/waiting.md` and say so in the report.
6. **UI tests stay off.** The user runs `IzzyUITests` themself. The autopilot never runs
   them, nor any throwaway XCUITest; screens are checked with simctl captures
   ([references/ios.md](references/ios.md)).
7. **Every cycle leaves a trace.** Landed, blocked or abandoned, it appends a log line, so
   the next cycle and the user can see what happened.
8. **The user can always see what is happening.** `$STATE/STATUS.md` says what runs now
   and in which phase, what waits on the user, the last cycles and the next candidates.
   Update it at every phase change with `scripts/status.py`, and keep this session's task
   list showing the cycle's phases. The user may be following from a phone.

## Files

| Path | What it does |
| --- | --- |
| `scripts/lock.sh acquire [note]`, `refresh <token>`, `release <token>`, `status` | One cycle at a time per clone (lock in the git dir, stale after 4 h without a refresh) |
| `scripts/state.sh` | Prints the state directory `<main checkout>/.claude/autopilot/` (git-ignored), creating it from `assets/state/` on first use |
| `scripts/sync-main.sh` | Fast-forwards local `main` to `origin/main` when it is only behind; never merges, rebases or touches a dirty path |
| `scripts/start-cycle.sh <slug> [--no-node]` | Worktree on branch `autopilot/<slug>` from local `main`, with an APFS clone of `landing/node_modules` |
| `scripts/land.sh <worktree> [--no-push]` | Lands the branch on `main` and pushes; exit codes below |
| `scripts/capture-ios.sh <worktree> <out.png> [launch args...]` | Builds the worktree for the autopilot's own simulator, installs, launches with the given arguments and saves a screenshot |
| `python3 -I scripts/status.py now <phase> --item <IZ-id> --note "<日本語で一行>"`, `idle --next "<時刻> 頃"`, `stopped`, `show` | Rewrites `$STATE/STATUS.md`; phases are `choose`, `build`, `verify`, `review`, `land`, `record` |
| `scripts/compare.sh <before> <after> <out>` | Labelled side by side plus a changed-pixel panel; prints the changed pixel count |
| `scripts/capture-web.sh <url> <out.png> [width]` | 2x full-page capture of a landing page with its animations frozen |

References, read when the step calls for them: [policy.md](references/policy.md),
[discovery.md](references/discovery.md), [state.md](references/state.md),
[ios.md](references/ios.md) and [web.md](references/web.md).

Scripts live next to this file; call them by absolute path, since the cycle's shell works
inside the worktree. `MAIN` below is the main checkout (the parent of
`git rev-parse --path-format=absolute --git-common-dir`), `WT` the cycle's worktree,
`STATE` the output of `scripts/state.sh`.

## The cycle

### Status at every step

Each phase below starts with `python3 -I scripts/status.py now <phase> --item <IZ-id> --note
"..."`: the note says in one Japanese line what is happening and, when something runs in
the background, what it is waiting for ("ユニットテストを実行中（約8分）"). Set the session's
task list to the cycle's phases at the start of the cycle and advance it with them.
Anything that now waits on the user (a site deploy, a build to upload, a blocked item they
can unblock) goes in `$STATE/waiting.md` as one `- ` line; remove the line when it is done.
Between cycles: `status.py idle --next "<time> 頃"`; when the loop ends:
`status.py stopped --note "<why>"`.

### 0. Start

1. `scripts/lock.sh acquire "<what this session is>"` prints `TOKEN=...`; keep it for
   `refresh` and `release`. If the lock is held, report by whom and since when, and stop
   without touching the lock. Then `status.py now choose --note "候補を選定中"`.
2. `scripts/sync-main.sh`. Other machines and cloud sessions push to `origin/main`; a cycle
   built on a stale `main` cannot land. If it reports `diverged` or `held`, carry on from
   local `main` and expect land.sh to hold the push.
3. Read `$STATE/log.md` (last 20 lines), `$STATE/proposals.md` and `$STATE/backlog.md`.
   Clear old captures:
   `find "$STATE/captures" -mindepth 1 -maxdepth 1 -type d -mtime +60 -exec rm -rf {} +`.
4. Check the machine, because it changes how verification works:
   - `uptime`: with a load average above about 10, timings are noise; no perf work.
   - `df -h /`: under about 15 GB free, skip simulator builds this cycle (pick a landing,
     catalog-script or core item, or stop).
5. `git -C "$MAIN" status --porcelain`: paths at or under these entries are someone's work
   in progress. A candidate that has to touch one of them is not eligible this cycle. Also
   note what other branches are changing, so a tie goes to the candidate that stays clear
   of them:
   `git -C "$MAIN" for-each-ref --format='%(refname:short)' --sort=-committerdate refs/heads | grep -v -e '^main$' -e '^autopilot/' | head -10`,
   then `git -C "$MAIN" diff --name-only main...<branch>` for each one updated in the last
   two weeks.

### 1. Choose

Follow [discovery.md](references/discovery.md). In short: answered proposals and items the
user wrote into the backlog come first; otherwise score the ready items, running a
discovery pass first when fewer than five are ready or the last pass is over a week old.
Classify the pick with [policy.md](references/policy.md): a taste or product call becomes a
proposal (cheaply, from what you already have) and you pick again.

Write the plan into the item: goal, acceptance criteria someone else could check, the tests
that will prove them, likely files. It should fit in about an hour of building; if it does
not, split it and take the first piece that is useful on its own. A half-built feature
never lands visible to users.

With `plan`, stop here: log `plan-only`, release the lock, report the plan.

### 2. Build

1. `scripts/start-cycle.sh <IZ-id>-<short-slug>` and work only inside the printed `WT`.
   Run `scripts/lock.sh refresh <token>` at each phase so a long build does not look
   abandoned.
2. Capture **before** now, while `WT` still equals `main` (Capture in
   [ios.md](references/ios.md) or [web.md](references/web.md)). Save under
   `$STATE/captures/<IZ-id>/before-<state>.png`. For a new feature, "before" is the screen
   where its entry point will appear.
3. Write the test that encodes an acceptance criterion, run it, and watch it fail for the
   reason you expect. Then implement until it passes. Keep the codebase's own idiom:
   value types and pure derivations in `Izzy/Core` (it is Foundation-only, and the widget
   compiles it), views that read derived values, side effects in `Izzy/Services`.
4. Keep the diff on topic: no drive-by refactors, formatting churn or renames the change
   does not need. They make review harder and widen the chance of colliding with someone
   else's work.

### 3. Verify

1. Run the gates for everything the diff touches (table; exact commands in
   [ios.md](references/ios.md) and [web.md](references/web.md)). Long runs go to the
   background with `> "$STATE/captures/<IZ-id>/<suite>.log" 2>&1`; read the log, not a
   filtered tail.
2. A red you did not expect: run the same test at the base commit before believing it is
   yours. Never weaken, skip or delete a test to get green. Change an expectation only when
   the improvement means to change it, and say so in the commit.
3. Take **after** captures in the same states, then `scripts/compare.sh`. Open the images
   yourself at full size, cropped to the change, in light and dark, English and Japanese
   where the surface has text. Write one sentence per state about what changed. A changed
   pixel count of 0 where you expected a visible change means the capture or the change is
   wrong.
4. What cannot be verified on this machine right now does not land. Mark the item
   `blocked` with the reason, keep the branch, and choose something else next cycle.

| Diff touches | Gates |
| --- | --- |
| `Izzy/Core/` | `swift test` (core package) and the iOS build; the unit tests if a view or service reads what changed |
| `Izzy/Views/`, `Izzy/Services/`, `Izzy/IzzyApp.swift`, `Izzy/Resources/*.xcstrings` | iOS build and `IzzyTests` |
| `IzzyWidget/` | iOS build (it embeds the widget) and `IzzyTests` |
| `Izzy/Resources/phrases.json`, `scripts/data/`, `scripts/*.py` | `python3 scripts/test_collection.py`, `swift test`, and the iOS build when the app reads the changed field |
| `project.yml` or a new or removed Swift file | `xcodegen generate`, then the iOS build and `IzzyTests`; commit the regenerated project |
| `landing/` | `npm --prefix landing run check` and captures at 390 and 1440 wide; it then waits for a deploy |

### 4. Review

Get a second opinion that is not anchored on yours. Spawn a fresh subagent (the `designer`
agent type for visible changes when it exists, otherwise a general-purpose one) and give it
the diff (`git -C "$WT" diff main`), the before/after images, the acceptance criteria and
the paths to references/policy.md and docs/DESIGN-SYSTEM.md. Do not give it your
conclusions. Ask for blocking problems only: bugs, regressions, design-system violations,
an accessibility loss, a taste call that slipped in, copy that breaks the voice rules, a
test that does not really test the criterion. Fix what is real and re-run the affected
gates. If the change turns out to be a taste call, write a proposal, keep the branch, and
do not land.

### 5. Land

1. Commit in `WT` with Conventional Commits in the repository's style (`feat(home): ...`,
   `fix(widget): ...`; lowercase, imperative, no trailing period). The body says why, what
   was measured, and which tokens or rules the change follows. The last line is the trailer
   `Autopilot-Cycle: <IZ-id>`: land.sh uses it to tell the autopilot's commits from other
   people's unpushed work. Leave the author to the repository's git config.
2. `scripts/land.sh "$WT"`:

| Exit | Meaning | Next |
| --- | --- | --- |
| 0 | Landed on `main` and pushed (or `--no-push`). A `DEPLOY=landing` line means the site changed | Record the commit; add the deploy to `waiting.md` |
| 3 | `main` moved and the rebase conflicts | Resolve in `WT` if small, re-run the gates, land again; otherwise mark blocked |
| 4 | `main` moved and the branch was rebased onto it | Re-run the gates for what the diff touches, then land again |
| 5 | A path of the change is dirty in the main checkout | Someone is editing it: keep the branch, mark `blocked: waiting on <paths>`, retry in a later cycle |
| 6 | Landed locally, push held | Origin is ahead, or `main` carries someone else's unpushed commits; report it, never force |
| 7 | The secret scan found something | Stop and report; never land it |
| 8 | A scratch preview route (`--autopilot-preview`) is in the diff | Remove it, commit, land again |
| 10 | A commit is not authored with the repository's noreply address | Amend the author from git config, land again |
| other | Script error | Report the message |

After a successful land the script removes the worktree and the branch. On any other
outcome both stay for the next attempt.

### 6. Record and report

1. Update the backlog item (`landed <sha>`, `blocked ...`, `proposal P-...`), add the ideas
   you found along the way as new items, append the log line ([state.md](references/state.md)).
   An app change waits for the next TestFlight build: keep one `waiting.md` line that
   counts the landed app changes since the last `chore(release)` commit.
2. `scripts/lock.sh release <token>`, also when the cycle failed or was abandoned. Only
   the session that acquired the lock releases it.
3. `status.py idle --next "<time> 頃"` (or `stopped`), so STATUS.md shows the cycle as done.
4. Report in Japanese, briefly: what changed and why, the evidence (gates run, the compare
   image, sent with SendUserFile when that tool exists), the commit, what now needs a
   person (a deploy, a build, a proposal to answer), and what the next cycle will
   probably take.

When a cycle teaches something non-obvious about the codebase, the tools or the user's
taste, save it the way this environment keeps memory, so later cycles start from it.

## When things go wrong

- Three honest attempts at a red gate without progress: abandon. Log what you learned,
  mark the item `blocked` or `dropped`, keep the branch if its work could be reused,
  release the lock.
- An autopilot commit on `main` turns out to be wrong (the user says so, or a later cycle
  finds the regression): the next cycle's change is `git revert <sha>`, landed through the
  same scripts. Reopen the item with the lesson.
- A stale lock (no refresh for 4 h) is taken over by `lock.sh acquire`, which says so. Read
  the log and the leftover `autopilot/*` branches for what the dead cycle was doing.
- Never `--no-verify`, never force-push, never rewrite pushed history.
- The autopilot does not edit this skill. When the skill itself is wrong or missing a
  step, write that up as a proposal so the user can change it.
