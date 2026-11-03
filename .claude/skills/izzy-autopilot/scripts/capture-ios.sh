#!/usr/bin/env bash
# Builds a checkout of Izzy for the autopilot's own simulator, installs it,
# launches it in the isolated UI-test store and saves a screenshot. The
# simulators are named "Izzy Autopilot" (iPhone 17 Pro) and "Izzy Autopilot
# iPad" (iPad Air 13-inch) and are created on first use, so other sessions'
# simulators are never touched.
#
# Usage: capture-ios.sh <checkout> <out.png> [--ipad] [--no-build] [--dark]
#          [--en | --ja] [--ax <content size>] [--wait <seconds>] [-- <app arguments>...]
# --ax takes a simctl content size such as accessibility-extra-extra-extra-large.
set -euo pipefail

usage="usage: capture-ios.sh <checkout> <out.png> [--ipad] [--no-build] [--dark] [--en|--ja] [--ax <size>] [--wait <s>] [-- <app args>]"
checkout=${1:?$usage}
out=${2:?$usage}
shift 2
device="Izzy Autopilot"
type="com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
build=1
appearance=light
language=ja
size=large
wait=4
app_args=()
while (( $# )); do
  case $1 in
    --ipad) device="Izzy Autopilot iPad"; type="com.apple.CoreSimulator.SimDeviceType.iPad-Air-13-inch-M4" ;;
    --no-build) build=0 ;;
    --dark) appearance=dark ;;
    --en) language=en ;;
    --ja) language=ja ;;
    --ax) shift; size=${1:?$usage} ;;
    --wait) shift; wait=${1:?$usage} ;;
    --) shift; app_args=("$@"); break ;;
    *) echo "$usage" >&2; exit 2 ;;
  esac
  shift
done
checkout=$(cd "$checkout" && pwd)
here=$(cd "$(dirname "$0")" && pwd)
state=$("$here/state.sh")
derived="$state/DerivedData"
app="$derived/Build/Products/Debug-iphonesimulator/Izzy.app"

udid=$(xcrun simctl list devices available | sed -n "s/^ *$device (\([0-9A-F-]*\)).*/\1/p" | head -1)
[[ -n $udid ]] || udid=$(xcrun simctl create "$device" "$type")
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" > /dev/null

if (( build )); then
  log="$state/capture-build.log"
  if ! xcodebuild -project "$checkout/Izzy.xcodeproj" -scheme Izzy -configuration Debug \
    -destination "platform=iOS Simulator,id=$udid" -derivedDataPath "$derived" \
    CODE_SIGNING_ALLOWED=NO build > "$log" 2>&1; then
    echo "build failed; see $log" >&2
    exit 1
  fi
fi
[[ -d $app ]] || { echo "no build at $app; run without --no-build" >&2; exit 1; }

xcrun simctl ui "$udid" appearance "$appearance"
xcrun simctl ui "$udid" content_size "$size"
xcrun simctl status_bar "$udid" override --time 9:41 --batteryState charged --batteryLevel 100 \
  --cellularBars 4 --wifiBars 3 > /dev/null 2>&1 || true
xcrun simctl install "$udid" "$app"
locale=$([[ $language == ja ]] && echo ja_JP || echo en_US)
xcrun simctl launch --terminate-running-process "$udid" me.unvalley.izzy \
  --ui-tests --reset-ui-tests "${app_args[@]+"${app_args[@]}"}" \
  -AppleLanguages "($language)" -AppleLocale "$locale" > /dev/null
sleep "$wait"
mkdir -p "$(dirname "$out")"
xcrun simctl io "$udid" screenshot "$out" > /dev/null 2>&1
echo "$out"
echo "UDID=$udid"
