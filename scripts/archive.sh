#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/.build/Release"
MODE="${1:-unsigned}"
if [[ "$MODE" != unsigned && "$MODE" != signed ]]; then
  echo 'Usage: scripts/archive.sh [unsigned|signed]' >&2; exit 2
fi
if [[ "$MODE" == signed && -z "${VOW_TEAM_ID:-}" ]]; then
  echo 'Set VOW_TEAM_ID to the Apple Developer team selected for Vow.' >&2; exit 2
fi
mkdir -p "$OUT"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SOURCE="$OUT/$STAMP-source"
mkdir -p "$SOURCE"
# Archive tracked files from one clean revision; never copy local signing material.
if [[ -n "$(git -C "$ROOT" status --porcelain)" ]]; then
  echo 'Commit or set aside local changes before creating a release archive.' >&2; exit 2
fi
git -C "$ROOT" archive HEAD | tar -x -C "$SOURCE"
git -C "$ROOT" rev-parse HEAD > "$SOURCE/source-revision.txt"
xcodegen generate --spec "$SOURCE/project.yml"
python3 - "$SOURCE" <<'PY'
import hashlib,json,sys
from pathlib import Path
root=Path(sys.argv[1])
files={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(root.rglob('*')) if p.is_file()}
(root/'source-manifest.json').write_text(json.dumps(files,indent=2)+'\n')
PY
ARCHIVE="$OUT/Vow-$STAMP-$MODE.xcarchive"
SIGNING=(CODE_SIGNING_ALLOWED=NO)
if [[ "$MODE" == signed ]]; then
  SIGNING=("DEVELOPMENT_TEAM=$VOW_TEAM_ID" CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates)
fi
xcodebuild -project "$SOURCE/Vow.xcodeproj" -scheme Vow -configuration Release -destination 'generic/platform=iOS' -archivePath "$ARCHIVE" -derivedDataPath "$OUT/DerivedData" "${SIGNING[@]}" archive
python3 "$ROOT/scripts/validate_archive.py" "$ARCHIVE" "$MODE"
printf 'Archive: %s\nSource snapshot: %s\n' "$ARCHIVE" "$SOURCE"
