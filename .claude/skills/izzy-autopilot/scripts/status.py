#!/usr/bin/env python3
"""Keeps <state>/STATUS.md: what the autopilot is doing right now, what waits on
the user, the last cycles and the next candidates, readable at a glance.

Usage (run with python3 -I):
  status.py now <phase> [--item IZ-0016] [--note "..."]   a cycle moved to <phase>
  status.py idle [--next "03:10 頃"]                        between cycles
  status.py stopped [--note "..."]                          the loop ended
  status.py render                                          rebuild from the state files
  status.py show                                            print STATUS.md

Phases: choose, build, verify, review, land, record. The "now" record lives in
<state>/now.json; open proposals, the log and the backlog are read from their files.
<state>/waiting.md holds anything else that waits on the user (a deploy, a PR to merge),
one "- " line each, written by the cycle that created it.
"""

import argparse
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path

PHASES = {
    "choose": "選定中",
    "build": "実装中",
    "verify": "検証中",
    "review": "レビュー中",
    "land": "反映中",
    "record": "記録中",
    "idle": "待機中",
    "stopped": "停止",
}


def state_dir() -> Path:
    here = Path(__file__).resolve().parent
    out = subprocess.run(
        [str(here / "state.sh")], capture_output=True, text=True, check=True
    )
    return Path(out.stdout.strip())


def now_text() -> str:
    return datetime.now().strftime("%Y-%m-%d %H:%M")


def minutes_since(stamp: str) -> int | None:
    try:
        then = datetime.strptime(stamp, "%Y-%m-%d %H:%M")
    except (TypeError, ValueError):
        return None
    return int((datetime.now() - then).total_seconds() // 60)


def item_title(backlog: str, item: str) -> str:
    pattern = re.compile(rf"^### {re.escape(item)} ·.*?\n\*\*Title\*\* (.+)$", re.M | re.S)
    match = pattern.search(backlog)
    if not match:
        return ""
    return match.group(1).split("\n")[0].strip()


def items(backlog: str) -> list[dict]:
    found = []
    for match in re.finditer(r"^### (IZ-\d+) · ([^\n]+)\n\*\*Title\*\* ([^\n]+)", backlog, re.M):
        parts = [part.strip() for part in match.group(2).split(" · ")]
        found.append({
            "id": match.group(1),
            "status": parts[0] if parts else "",
            "where": " · ".join(parts[1:]),
            "title": match.group(3).strip(),
        })
    return found


def open_proposals(proposals: str) -> list[str]:
    return [
        f"{m.group(1)} {m.group(3).strip()}"
        for m in re.finditer(r"^### (P-\d+) · (open) · [^\n]*? · [^\n]*? · ([^\n]+)$", proposals, re.M)
    ]


def render(state: Path) -> str:
    now = json.loads((state / "now.json").read_text()) if (state / "now.json").exists() else {}
    backlog = (state / "backlog.md").read_text() if (state / "backlog.md").exists() else ""
    proposals = (state / "proposals.md").read_text() if (state / "proposals.md").exists() else ""
    log_lines = [
        line for line in ((state / "log.md").read_text().splitlines() if (state / "log.md").exists() else [])
        if re.match(r"^\d{4}-\d{2}-\d{2} ", line)
    ]
    waiting_file = state / "waiting.md"
    waiting = [
        line for line in (waiting_file.read_text().splitlines() if waiting_file.exists() else [])
        if line.startswith("- ")
    ]

    lines = ["# Izzy autopilot の状況", "", f"更新 {now.get('updated', now_text())}", "", "## いま", ""]
    phase = now.get("phase", "idle")
    label = PHASES.get(phase, phase)
    if phase in ("idle", "stopped"):
        lines.append(f"**{label}**" + (f" · 次のサイクルは {now['next']}" if now.get("next") else ""))
        if now.get("note"):
            lines.append(now["note"])
    else:
        item = now.get("item", "")
        title = item_title(backlog, item) if item else ""
        lines.append(f"**{label}** · {item} {title}".rstrip())
        elapsed = minutes_since(now.get("started", ""))
        detail = f"サイクル開始 {now.get('started', '?')}" + (f"（{elapsed} 分経過）" if elapsed is not None else "")
        lines.append(detail)
        if now.get("note"):
            lines.append(now["note"])

    lines += ["", "## あなた待ち", ""]
    asks = [f"- 提案に回答: {p}" for p in open_proposals(proposals)] + waiting
    lines += asks or ["- なし"]

    lines += ["", "## 最近のサイクル", ""]
    lines += [f"- {line}" for line in log_lines[-5:]] or ["- まだなし"]

    ready = [i for i in items(backlog) if i["status"] == "ready" and i["id"] != now.get("item")]
    blocked = [i for i in items(backlog) if i["status"].startswith("blocked")]
    lines += ["", "## 次の候補", ""]
    lines += [f"- {i['id']} · {i['where']} · {i['title']}" for i in ready[:5]] or ["- なし"]
    if blocked:
        lines += ["", f"保留中 {len(blocked)} 件: " + ", ".join(i["id"] for i in blocked)]

    lines += ["", "詳細: backlog.md / proposals.md / log.md（このフォルダ）", ""]
    text = "\n".join(lines)
    (state / "STATUS.md").write_text(text)
    return text


def main() -> None:
    parser = argparse.ArgumentParser()
    sub = parser.add_subparsers(dest="command", required=True)
    now_cmd = sub.add_parser("now")
    now_cmd.add_argument("phase", choices=[p for p in PHASES if p not in ("idle", "stopped")])
    now_cmd.add_argument("--item", default=None)
    now_cmd.add_argument("--note", default="")
    idle_cmd = sub.add_parser("idle")
    idle_cmd.add_argument("--next", default="")
    idle_cmd.add_argument("--note", default="")
    stopped_cmd = sub.add_parser("stopped")
    stopped_cmd.add_argument("--note", default="")
    sub.add_parser("render")
    sub.add_parser("show")
    args = parser.parse_args()

    state = state_dir()
    path = state / "now.json"
    current = json.loads(path.read_text()) if path.exists() else {}
    stamp = now_text()
    if args.command == "now":
        if args.phase == "choose" or current.get("phase") in (None, "idle", "stopped"):
            current = {"started": stamp}
        current.update(phase=args.phase, updated=stamp, note=args.note)
        if args.item:
            current["item"] = args.item
    elif args.command in ("idle", "stopped"):
        current = {"phase": args.command, "updated": stamp, "note": args.note}
        if args.command == "idle":
            current["next"] = args.next
    if args.command in ("now", "idle", "stopped"):
        path.write_text(json.dumps(current, ensure_ascii=False, indent=2) + "\n")
    text = render(state)
    if args.command == "show":
        print(text)


if __name__ == "__main__":
    main()
