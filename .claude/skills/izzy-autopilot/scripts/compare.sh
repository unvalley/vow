#!/usr/bin/env bash
# Labelled before/after picture side by side, plus a third panel that marks
# the pixels that changed when both images are the same size. Prints
# "changed: <pixels>" (or "changed: n/a" when the sizes differ).
#
# Usage: compare.sh <before.png> <after.png> <out.png>
set -euo pipefail

usage="usage: compare.sh <before.png> <after.png> <out.png>"
before=${1:?$usage}
after=${2:?$usage}
out=${3:?$usage}
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

font=/System/Library/Fonts/Helvetica.ttc
[[ -e $font ]] || font=/System/Library/Fonts/Supplemental/Arial.ttf

labelled() {
  magick -background white -fill '#222222' -font "$font" -pointsize 28 label:"$2" "$1" \
    -gravity center -append "$3"
}

labelled "$before" "before" "$tmp/1.png"
labelled "$after" "after" "$tmp/2.png"
panels=("$tmp/1.png" "$tmp/2.png")

if [[ $(magick identify -format '%wx%h' "$before") == $(magick identify -format '%wx%h' "$after") ]]; then
  # AE: count of pixels that differ by more than the fuzz.
  count=$(magick compare -metric AE -fuzz 1% "$before" "$after" "$tmp/diff.png" 2>&1 >/dev/null || true)
  labelled "$tmp/diff.png" "changed pixels" "$tmp/3.png"
  panels+=("$tmp/3.png")
  printf 'changed: %.0f\n' "${count%% *}"
else
  echo "changed: n/a (sizes differ)"
fi

mkdir -p "$(dirname "$out")"
magick "${panels[@]}" -bordercolor white -border 12 -background white -gravity north +append +repage -depth 8 "$out"
echo "$out"
