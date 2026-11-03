#!/usr/bin/env bash
# Full-page capture of a page at 2x, with animations and transitions frozen, in an
# agent-browser session of its own.
# Avoid `agent-browser set media`: it relaunches the browser and the next
# screenshot hangs.
#
# Usage: capture-web.sh <url> <out.png> [width=1440] [height=900]
set -euo pipefail

usage="usage: capture-web.sh <url> <out.png> [width] [height]"
url=${1:?$usage}
out=${2:?$usage}
width=${3:-1440}
height=${4:-900}
export AGENT_BROWSER_SESSION=${AGENT_BROWSER_SESSION:-izzy-autopilot}

quiet() { agent-browser "$@" > /dev/null; }

quiet set viewport "$width" "$height" 2
quiet open "$url"
quiet wait 1500
quiet eval "(() => {
  const style = document.createElement('style');
  style.textContent = '*,*::before,*::after{animation:none!important;transition:none!important}';
  document.head.appendChild(style);
  return true;
})()"
# Scroll through once so lazy images load, then back to the top.
quiet eval "(async () => {
  const pause = (ms) => new Promise((done) => setTimeout(done, ms));
  for (let y = 0; y < document.documentElement.scrollHeight; y += innerHeight / 2) {
    scrollTo(0, y);
    await pause(150);
  }
  scrollTo(0, 0);
  await pause(600);
  return true;
})()"

mkdir -p "$(dirname "$out")"
quiet screenshot --full "$out"
echo "$out"
