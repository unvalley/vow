#!/usr/bin/env bash
# Lands an autopilot branch on main without disturbing anyone's uncommitted
# work where main is checked out, then pushes. Pushing deploys nothing: the
# landing site goes out with `npm run deploy` and the app with a TestFlight
# build, both the owner's. A change to the site prints DEPLOY=landing so the
# cycle can say it waits for one.
#
# Usage: land.sh <worktree> [--no-push]
#
# Exit codes:
#   0  landed (and pushed, unless --no-push)
#   3  main moved and the branch does not rebase cleanly onto it
#   4  main moved and the branch was rebased onto it: re-run the gates, land again
#   5  a path the branch changes is dirty where main is checked out
#   6  landed locally; the push was held or failed
#   7  the secret scan found something
#   8  a scratch preview route (--autopilot-preview) is in the diff
#   10 a commit is not authored with the repository's noreply address
#   1, 2  other errors
set -euo pipefail

usage="usage: land.sh <worktree> [--no-push]"
wt=${1:?$usage}
push=1
case ${2:-} in
  "") ;;
  --no-push) push=0 ;;
  *) echo "$usage" >&2; exit 2 ;;
esac
wt=$(cd "$wt" && pwd)

fail() {
  local code=$1
  shift
  echo "$*" >&2
  exit "$code"
}
git() { command git --literal-pathspecs "$@"; }

branch=$(git -C "$wt" symbolic-ref --short -q HEAD) || fail 2 "$wt is not on a branch"
[[ $branch == autopilot/* ]] || fail 2 "$branch is not an autopilot branch"
[[ -z $(git -C "$wt" status --porcelain) ]] || fail 2 "$wt has uncommitted changes"

common=$(git -C "$wt" rev-parse --path-format=absolute --git-common-dir)
main_root=$(dirname "$common")
[[ -d $common/izzy-autopilot.lock ]] || fail 2 "take the lock first: lock.sh acquire"
old=$(git -C "$wt" rev-parse refs/heads/main)
tip=$(git -C "$wt" rev-parse HEAD)
[[ $tip != "$old" ]] || fail 2 "nothing to land: $branch is at main"
base=$(git -C "$wt" merge-base "$old" "$tip")

# Every commit names its cycle, so a later push can tell them from other people's.
untagged=$(git -C "$wt" log --format='%h %(trailers:key=Autopilot-Cycle,valueonly,separator=%x2C)' "$base..$tip" |
  awk 'NF < 2 { print $1 }')
[[ -z $untagged ]] || fail 2 "commits without an Autopilot-Cycle trailer: $untagged"

# The repository is public: commits carry the noreply address from git config, never a work email.
expected=$(git -C "$wt" config user.email || true)
[[ $expected == *@users.noreply.github.com ]] || fail 10 "git config user.email is '$expected', not a noreply address"
strangers=$(git -C "$wt" log --format='%h %ae %ce' "$base..$tip" | awk -v e="$expected" '$2 != e || $3 != e { print $1 }' | paste -sd ' ' -)
[[ -z $strangers ]] || fail 10 "commits not authored and committed as $expected: $strangers"

changed=()
while IFS= read -r path; do
  changed+=("$path")
done < <(git -C "$wt" diff --name-only --no-renames "$base" "$tip")
(( ${#changed[@]} )) || fail 2 "the branch changes no files"

if git -C "$wt" diff "$base" "$tip" | grep -q -- '--autopilot-preview'; then
  fail 8 "a scratch preview route (--autopilot-preview) is in the diff; it belongs in a copy, never the branch"
fi

if command -v gitleaks >/dev/null; then
  status=0
  gitleaks git --no-banner --redact --exit-code 99 --log-opts="$base..$tip" "$wt" > /dev/null 2>&1 || status=$?
  if (( status == 99 )); then
    fail 7 "gitleaks found a possible secret in $base..$tip; run gitleaks git -v --log-opts=$base..$tip $wt"
  elif (( status != 0 )); then
    fail 2 "gitleaks failed (exit $status)"
  fi
else
  echo "gitleaks is not installed; skipping the secret scan" >&2
fi

# main moved since the branch was made: bring the branch up to date first.
if [[ $base != "$old" ]]; then
  if git -C "$wt" rebase -q refs/heads/main >/dev/null 2>&1; then
    echo "main moved; rebased $branch onto $(git -C "$wt" rev-parse --short "$old"). Re-run the gates, then land again."
    exit 4
  fi
  git -C "$wt" rebase --abort || true
  fail 3 "main moved and $branch does not rebase cleanly onto it"
fi

# Where main is checked out, if anywhere.
checkout=$(git -C "$wt" worktree list --porcelain |
  awk '/^worktree / { w = substr($0, 10) } $0 == "branch refs/heads/main" { print w }')

if [[ -n $checkout ]]; then
  [[ ! -e $(git -C "$checkout" rev-parse --path-format=absolute --git-path index.lock) ]] ||
    fail 2 "another git command holds $checkout's index; try again shortly"
  [[ $(git -C "$checkout" rev-parse HEAD) == "$old" ]] || fail 2 "$checkout is not at main"
  dirty=$(git -C "$checkout" diff --name-only --no-renames HEAD)
  overlap=()
  for path in "${changed[@]}"; do
    if grep -qxF -- "$path" <<<"$dirty"; then
      overlap+=("$path")
    elif ! git -C "$checkout" cat-file -e "$old:$path" 2>/dev/null &&
      [[ -e $checkout/$path || -L $checkout/$path ]]; then
      overlap+=("$path") # untracked or ignored there, and the branch adds it
    fi
  done
  (( ${#overlap[@]} == 0 )) || fail 5 "$(printf 'dirty in %s:\n' "$checkout"; printf '  %s\n' "${overlap[@]}")"
fi

# Push only autopilot commits, and only on top of what origin already has.
hold=""
if (( push )); then
  if ! git -C "$wt" fetch -q origin main; then
    hold="could not fetch origin"
  elif ! git -C "$wt" merge-base --is-ancestor refs/remotes/origin/main "$old"; then
    hold="origin/main has commits that local main lacks"
  else
    foreign=$(git -C "$wt" log --format='%h %(trailers:key=Autopilot-Cycle,valueonly,separator=%x2C)' \
      "refs/remotes/origin/main..$old" | awk 'NF < 2 { print $1 }' | paste -sd ' ' -)
    [[ -z $foreign ]] || hold="local main has unpushed commits that are not the autopilot's: $foreign"
  fi
fi

# Puts the given commit's version of the changed paths into the checkout's
# index and working tree.
sync_checkout() {
  local commit=$1
  local present=() absent=() path
  for path in "${changed[@]}"; do
    if git -C "$wt" cat-file -e "$commit:$path" 2>/dev/null; then present+=("$path"); else absent+=("$path"); fi
  done
  if (( ${#present[@]} )); then git -C "$checkout" checkout -q "$commit" -- "${present[@]}"; fi
  if (( ${#absent[@]} )); then git -C "$checkout" rm -q -f --ignore-unmatch -- "${absent[@]}"; fi
}

# Content first, then the ref: a commit someone makes in between picks up
# finished work rather than reverting it.
if [[ -n $checkout ]]; then
  sync_checkout "$tip"
fi
if ! git -C "$wt" update-ref -m "autopilot: land $branch" refs/heads/main "$tip" "$old"; then
  if [[ -n $checkout ]]; then
    sync_checkout "$old"
  fi
  fail 2 "main moved while landing; run land.sh again"
fi
if [[ -n $checkout ]]; then
  leftover=$(git -C "$checkout" status --porcelain -- "${changed[@]}")
  [[ -z $leftover ]] || fail 2 "landed, but $checkout still differs on: $leftover"
fi
echo "landed $branch on main: $(git -C "$wt" rev-parse --short "$old")..$(git -C "$wt" rev-parse --short "$tip"), files changed: ${#changed[@]}"
for path in "${changed[@]}"; do
  if [[ $path == landing/* ]]; then
    echo "DEPLOY=landing"
    break
  fi
done

# The branch is main's history now; -D because -d compares with the checkout's
# HEAD, which may be detached elsewhere.
git -C "$main_root" worktree remove --force "$wt"
git -C "$main_root" branch -q -D "$branch"

if (( push )); then
  if [[ -n $hold ]]; then
    echo "push held: $hold" >&2
    exit 6
  fi
  git -C "$main_root" push -q origin refs/heads/main:refs/heads/main || fail 6 "landed locally; the push failed"
  echo "pushed main to origin"
fi
