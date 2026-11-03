#!/usr/bin/env bash
# Prints the autopilot's state directory, <main checkout>/.claude/autopilot,
# creating it from assets/state on first use. It lives outside every worktree,
# so all cycles share it, and it is git-ignored.
#
# Usage: state.sh
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
templates="$here/../assets/state"
common=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)
state="$(dirname "$common")/.claude/autopilot"

mkdir -p "$state/captures" "$state/proposals"
for file in backlog.md proposals.md log.md; do
  [[ -e $state/$file ]] || cp "$templates/$file" "$state/$file"
done
# Ignored state never shows up as anyone's work in progress.
git -C "$(dirname "$common")" check-ignore -q "$state/log.md" ||
  echo "warning: $state is not git-ignored; .gitignore should ignore /.claude/autopilot/" >&2
echo "$state"
