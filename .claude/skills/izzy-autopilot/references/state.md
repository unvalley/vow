# State files

`scripts/state.sh` prints `<main checkout>/.claude/autopilot/` and creates it from
`assets/state/` on first use. It sits in the main checkout, outside every worktree, so all
cycles share it; it is git-ignored, so writing it never collides with anyone's commits. The
user reads and edits these files directly.

```
.claude/autopilot/
├── STATUS.md         rendered by scripts/status.py: now, waiting on you, recent, next
├── now.json          the running cycle's phase, item, note and start time
├── waiting.md        "- " lines for what waits on the user besides proposals
├── backlog.md        items, the user's own requests, coverage
├── proposals.md      decisions waiting for the user
├── log.md            one line per cycle
├── DerivedData/      the autopilot's own Xcode build products, shared by cycles
├── captures/<IZ-id>/ before-*, after-*, compare-* images and suite logs
└── proposals/<P-id>/ renders and mockups for a proposal
```

## backlog.md

Sections, in this order: `## From the user` (free-form; the user writes here), `## Items`,
`## Coverage`, `## Done`.

An item:

```markdown
### IZ-0012 · ready · ios · a11y
**Title** The rating row keeps every label readable at accessibility text sizes
**Why** At AX3 "Again / Hard / Good / Easy" truncate to "Ag…" (captures/IZ-0012/before-ax3.png);
DESIGN-SYSTEM.md "Typography" says rows stack at accessibility sizes.
**Plan** (written when the item is chosen) Test-first steps, each naming the test and the
change; what is out of scope.
**Acceptance** At AX3 and AX5 the four labels are whole; default size unchanged.
**Proof** New MemoryRatingLayoutTests; before/after at default, AX3, AX5.
**Touches** Izzy/Views/MemoryRatingControls.swift
**Score** V3 C3 K1 = 9
**History** 2026-11-02 ready · 2026-11-03 landed 1a2b3c4d
```

- Kinds: `feature`, `design`, `a11y`, `perf`, `bug`, `copy`, `web`, `health`.
- Where: `ios`, `ipad`, `widget`, `core`, `catalog`, `landing`.
- Statuses: `idea` (one line, not yet specified), `ready`, `in-progress (autopilot/<slug>)`,
  `blocked: <reason>`, `proposal P-####`, `landed <sha>`, `dropped: <reason>`.
- An item chosen by a `plan` run stays `ready` with its Plan filled in, and its History says
  "chosen by a plan run". The next cycle builds it unless an answer, a user item or new
  breakage outranks it.
- Ids count up (`IZ-0001`, ...) and are never reused. Landed and dropped items older than a
  month move to `## Done`.

Coverage is a table of surface x device with the date of the last audit: `<date>
captures` when captures were looked at, `<date> code` when only the code was read. A
`code` audit does not count as audited for choosing the next surface.

## proposals.md

```markdown
### P-0004 · open · ios · taste · 完了画面の見出しの大きさ
**Context** Completion uses `phrase` (34 pt) while onboarding titles use `display-phrase` (captures ...).
**Options**
- **A** 両方 `phrase`: proposals/P-0004/a.png
- **B** 両方 `display-phrase`: proposals/P-0004/b.png
- **C** いまのまま
**Recommendation** A: one role for one kind of title.
**On answer** A or B: lands as a new item in the next cycle (branch autopilot/p-0004-a kept). C: closed.
**Answer:**
```

The user fills in `**Answer:**` (or tells any session, which writes it here). Statuses:
`open`, `answered`, `done` (with the item it became), `withdrawn` (with the reason). Write
proposals in Japanese; the rest of the state files can stay in English.

## log.md

One line per cycle, newest last, stamped with the cycle's start time and ending with its
duration:

```
2026-11-02 14:05 · IZ-0012 · landed 1a2b3c4d · ios a11y · gates: iOS build, IzzyTests · 52 min
2026-11-02 15:10 · IZ-0015 · blocked (waiting on Izzy/Views/TodayView.swift) · ios feature · 20 min
2026-11-02 15:30 · — · nothing-eligible (3 items blocked on dirty paths) · 4 min
```

Outcomes: `landed <sha>`, `landed locally <sha>, push held (<why>)`, `blocked (...)`,
`proposal P-####`, `abandoned (...)`, `plan-only`, `nothing-eligible (...)`.
