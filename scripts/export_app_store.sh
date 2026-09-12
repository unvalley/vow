#!/bin/bash
set -euo pipefail
if [[ $# -ne 1 || -z "${VOW_TEAM_ID:-}" ]]; then
  echo 'Usage: VOW_TEAM_ID=... scripts/export_app_store.sh /path/to/signed.xcarchive' >&2; exit 2
fi
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
python3 "$ROOT/scripts/validate_archive.py" "$1" signed
OPTIONS="$(mktemp -t verve-export).plist"
trap 'rm -f "$OPTIONS"' EXIT
python3 - "$OPTIONS" "$VOW_TEAM_ID" <<'PY'
import plistlib,sys
with open(sys.argv[1],'wb') as f:
 plistlib.dump({'method':'app-store-connect','destination':'export','teamID':sys.argv[2],'signingStyle':'automatic','uploadSymbols':True},f)
PY
xcodebuild -exportArchive -archivePath "$1" -exportPath "$ROOT/.build/AppStoreExport" -exportOptionsPlist "$OPTIONS"
echo 'Exported locally. No upload was performed.'
