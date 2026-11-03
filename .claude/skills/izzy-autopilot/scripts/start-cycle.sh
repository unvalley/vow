#!/usr/bin/env bash
# Creates the cycle's worktree on branch autopilot/<slug> from local main, with
# an APFS clone of landing/node_modules so the site's checks start warm. When
# the branch already exists (a blocked item picked up again), the worktree is
# made from it instead.
#
# Usage: start-cycle.sh <slug> [--no-node]
# Prints WT=, BRANCH= and BASE= lines.
set -euo pipefail

usage="usage: start-cycle.sh <slug> [--no-node]"
slug=${1:?$usage}
shift
node=1
for arg in "$@"; do
  case $arg in
    --no-node) node=0 ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
done
[[ $slug =~ ^[A-Za-z0-9._-]+$ ]] || { echo "the slug takes letters, digits, '.', '_' and '-'" >&2; exit 2; }

here=$(cd "$(dirname "$0")" && pwd)
common=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)
main=$(dirname "$common")
root=${IZZY_AUTOPILOT_WORKTREES:-/private/tmp/izzy-autopilot}
wt="$root/$slug"
branch="autopilot/$slug"

[[ -d $common/izzy-autopilot.lock ]] || { echo "take the lock first: lock.sh acquire" >&2; exit 1; }
[[ ! -e $wt ]] || { echo "$wt already exists" >&2; exit 1; }
mkdir -p "$root"

if git -C "$main" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$main" worktree add -q "$wt" "$branch"
  echo "resumed $branch"
else
  git -C "$main" worktree add -q -b "$branch" "$wt" refs/heads/main
fi

if (( node )) && [[ -d $main/landing/node_modules && ! -e $wt/landing/node_modules ]]; then
  cp -Rc "$main/landing/node_modules" "$wt/landing/node_modules"
fi

echo "WT=$wt"
echo "BRANCH=$branch"
echo "BASE=$(git -C "$wt" merge-base HEAD refs/heads/main)"
