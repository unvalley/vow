#!/usr/bin/env bash
# Brings local main up to origin/main when it is only behind, so a cycle starts
# from what other machines and cloud sessions have pushed. It fast-forwards and
# nothing else: where main is checked out, git refuses the fast-forward if it
# would touch a file someone has changed there, and this script then leaves it.
#
# Usage: sync-main.sh
# Prints one of: up-to-date, fast-forwarded <old>..<new>, ahead (local main has
# commits origin lacks), diverged, held (<why>), offline.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
common=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)
main_root=$(dirname "$common")
git() { command git -C "$main_root" "$@"; }

git fetch -q origin main 2>/dev/null || { echo "offline"; exit 0; }
local_main=$(git rev-parse refs/heads/main)
remote_main=$(git rev-parse refs/remotes/origin/main)

if [[ $local_main == "$remote_main" ]]; then
  echo "up-to-date"
  exit 0
fi
if git merge-base --is-ancestor "$remote_main" "$local_main"; then
  echo "ahead"
  exit 0
fi
if ! git merge-base --is-ancestor "$local_main" "$remote_main"; then
  echo "diverged"
  exit 0
fi

checkout=$(git worktree list --porcelain |
  awk '/^worktree / { w = substr($0, 10) } $0 == "branch refs/heads/main" { print w }')
if [[ -z $checkout ]]; then
  git update-ref -m "autopilot: fast-forward main" refs/heads/main "$remote_main" "$local_main"
elif [[ -e $(command git -C "$checkout" rev-parse --path-format=absolute --git-path index.lock) ]]; then
  echo "held (another git command holds $checkout's index)"
  exit 0
elif ! command git -C "$checkout" merge -q --ff-only refs/remotes/origin/main 2>/dev/null; then
  echo "held (the fast-forward would touch files changed in $checkout)"
  exit 0
fi
echo "fast-forwarded $(git rev-parse --short "$local_main")..$(git rev-parse --short "$remote_main")"
