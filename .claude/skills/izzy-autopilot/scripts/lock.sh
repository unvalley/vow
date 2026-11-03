#!/usr/bin/env bash
# One autopilot cycle at a time per clone. The lock is a directory in the git
# common dir, so the main checkout and every worktree share it. `acquire`
# prints a token; `refresh` and `release` need it, so a session that failed to
# acquire can never release someone else's lock. A lock whose directory has not
# been touched for IZZY_AUTOPILOT_STALE_MINUTES (240) is stale and is taken over
# by the next `acquire`.
#
# Usage: lock.sh acquire [note] | refresh <token> | release <token> | status
#        lock.sh release --force   (by hand, for a lock nobody will release)
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
common=$(git -C "$here" rev-parse --path-format=absolute --git-common-dir)
lock="$common/izzy-autopilot.lock"
stale_minutes=${IZZY_AUTOPILOT_STALE_MINUTES:-240}

describe() {
  grep -v '^token:' "$lock/info" 2>/dev/null || true
  echo "last refresh: $(stat -f '%Sm' -t '%Y-%m-%d %H:%M' "$lock")"
}
is_stale() { [[ -n $(find "$lock" -maxdepth 0 -mmin +"$stale_minutes" 2>/dev/null) ]]; }
holder_token() { sed -n 's/^token: //p' "$lock/info" 2>/dev/null; }
take() {
  local token
  token="$(date +%s)-$$-$RANDOM"
  printf 'started: %s\nnote: %s\ntoken: %s\n' "$(date '+%Y-%m-%d %H:%M')" "$1" "$token" > "$lock/info"
  touch "$lock"
  echo "acquired"
  echo "TOKEN=$token"
}
require_token() {
  [[ -d $lock ]] || { echo "the lock is not held" >&2; exit 1; }
  [[ -n ${1:-} && $1 == "$(holder_token)" ]] || { echo "the lock belongs to another session:" >&2; describe >&2; exit 1; }
}

case "${1:-status}" in
  acquire)
    if mkdir "$lock" 2>/dev/null; then
      take "${2:-}"
    elif is_stale; then
      echo "taking over a stale lock:"
      describe
      take "${2:-}"
    else
      echo "held:"
      describe
      exit 1
    fi
    ;;
  refresh)
    require_token "${2:-}"
    touch "$lock"
    echo "refreshed"
    ;;
  release)
    if [[ ${2:-} == --force ]]; then
      rm -rf "$lock"
      echo "released (forced)"
    else
      require_token "${2:-}"
      rm -rf "$lock"
      echo "released"
    fi
    ;;
  status)
    if [[ ! -d $lock ]]; then
      echo "free"
    elif is_stale; then
      echo "stale:"
      describe
    else
      echo "held:"
      describe
    fi
    ;;
  *)
    echo "usage: lock.sh acquire [note] | refresh <token> | release <token> | status" >&2
    exit 2
    ;;
esac
