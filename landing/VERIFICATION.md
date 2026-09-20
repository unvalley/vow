# Landing page verification

## Deployed 20 September 2026

`npm run deploy` published the site as the `izzy-landing` Worker on the
Cloudflare account in `wrangler.jsonc` (50 files, version
`ed3a7e0e-5076-46a2-be03-3bf46ff9c6d0`). Reachable over HTTPS on the custom
domain and the workers.dev URL: `/`, `/ja/`, `/privacy/`, `/support/` and
`/assets/mark.png` all answer 200, and `/ja/` serves the Japanese title. This
release carries the new mark in the hero, icons resized from the shipped app
icon, the Outfit Black wordmark, and product screenshots recaptured from the
current build. `downloadURL` stays empty: there is still no public download.

# Landing page verification — September 13, 2026

The current refresh uses [Art4's live LP](https://art4.app/en) as a reference.
Both the Japanese and English reference pages were inspected at desktop and
mobile widths. The change is local; the public website has not been updated.

## What changed

- A single-line, shorter hero on ink, carrying Izzy's own
  photograph. Upright current app screens replace the tilted, older trio.
- Four image-led features stay visible: daily goal, contextual examples,
  meaning review and Stats. The old tabbed feature block was removed.
- Three practice previews come directly from the app catalog. Meaning and
  example open together. Next expression closes the answer and keeps keyboard
  focus on the next button. The first preview works without JavaScript.
- The collection now shows 700 phrasal verbs and 400 idioms separately. Plans,
  FAQ and footer are simpler; the release status is plain text and the primary
  pre-release action leads to working practice.
- Responsive WebP variants and local fonts keep the site self-contained. The
  12 superseded screenshot variants were removed from the published assets.

## Checks

- `node landing/scripts/build.mjs` and `node landing/scripts/check.mjs` passed:
  five generated pages, asset links, anchors, ARIA references and catalog count.
- Eight Chromium layout cases passed: English and Japanese at 320, 390, 768 and
  1440 px. No horizontal document overflow; each hero heading remained one line.
- Both locales passed click and keyboard checks for meaning disclosure,
  three-expression cycling, answer reset, retained focus and FAQ disclosure.
- Reduced Motion turns smooth scrolling off. With JavaScript disabled, the first
  expression's native disclosure and all four feature descriptions still work;
  the next-expression control stays hidden.
- Browser checks found no broken loaded images, no JavaScript errors and no
  runtime requests to third-party origins. Public download links remain absent
  while `downloadURL` is empty.
- Fresh iPhone simulator captures verified Today → reveal → next expression
  and Stats → curve comparison → start learning. Two existing UI scenarios
  passed; no app source was changed for this LP task.

## Evidence

- `.build/LP-Art4/review.html`: before/after gallery and local preview links.
- `.build/LP-Art4/layout-results.json`: eight viewport/language results.
- `.build/LP-Art4/interaction-results.json`: interaction results.
- `.build/LP-Art4/source-hashes.json`: hashes before the label reduction below.
- `.build/LP-Art4/Screens.xcresult` and `Stats.xcresult`: app capture results.
- `ASSETS.md`: source captures and photo provenance.

## Boundaries

No website deployment, TestFlight upload, commit or push was performed. Browser
verification used Chromium; Safari/physical-device rendering was not tested in
this pass. The original app learning data and catalog were unchanged. The prior
LP is saved under `.build/LP-Art4/before/landing/`.

## Label reduction follow-up

Removed redundant hero/screenshot captions, practice card labels and counter,
speaking example labels, plan blurbs, repeated taglines and visible footer group
headings in both languages. Collection copy now describes browsing instead of
repeating the counts directly below it. Footer navigation retains accessible
names, and changing expressions still announces the new phrase. Removed unused
copy/style entries and the JavaScript counter update; tightened card spacing.

The five-page build/link check passed again. Chromium checks passed for English
and Japanese at 320, 390, 768 and 1440 px: no horizontal overflow, three-expression
cycling, answer reveal/reset, retained next-button focus and live announcements.
No browser errors were recorded. Desktop and mobile practice, answer and footer
screenshots were inspected. This follow-up remains local and unpublished.

Latest evidence: `.build/LP-Labels/results.json`, `browser-errors.txt`,
`source-hashes.json` and locale/viewport screenshots. The immediate previous
copy/template/styles/script are saved in `.build/LP-Labels/before/`.
