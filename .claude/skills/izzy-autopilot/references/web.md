# Landing site (izzy.unvalley.me)

`landing/` is a static site: `landing/scripts/build.mjs` writes `landing/dist/` from
`landing/copy.mjs`, `landing/site.config.mjs` and `landing/public/`, and the
`izzy-landing` Cloudflare Worker serves it. Japanese is the default at `/`, English lives
at `/en/`. `landing/README.md` and `landing/ASSETS.md` describe the design and the
captures it uses.

## Gates

```bash
npm --prefix "$WT/landing" run check > "$LOG" 2>&1   # build, link/anchor/ARIA checks, catalog claim, wrangler dry run
```

Pushing `main` does not deploy the site. A landed landing change reaches visitors only when
the user runs `npm --prefix landing run deploy`; land.sh prints `DEPLOY=landing`, and the
cycle adds that to `waiting.md`.

## Capture

Serve the built site from the worktree and capture it at phone and desktop widths:

```bash
(cd "$WT/landing/dist" && python3 -m http.server 4391 > /dev/null 2>&1 &)
scripts/capture-web.sh http://localhost:4391/ "$STATE/captures/IZ-0020/before-ja-390.png" 390 844
scripts/capture-web.sh http://localhost:4391/en/ "$STATE/captures/IZ-0020/before-en-1440.png" 1440 900
```

Stop the server afterwards (`lsof -ti tcp:4391 | xargs kill`). Use a port of your own:
4321 and 4322 belong to the user's preview configurations.

## Rules

- Light only, system fonts, the wordmark as supplied; no webfonts (`font-src 'self'`).
- Copy follows the same voice as the app, and catalog counts stay open-ended. Headlines
  and marketing copy are proposals; a typo or a broken link is not.
- No analytics, third-party scripts or runtime requests beyond what the site already makes.
- `site.config.mjs`'s `downloadURL` is the user's to set.
