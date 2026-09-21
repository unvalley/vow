# Izzy brand

**Adopted 2026-09-20 — the app icon.** A soft, inflated abstract mark, white on
near-black, built as an Icon Composer document at
[`Izzy/Resources/Izzy.icon`](../Izzy/Resources/Izzy.icon). The shape ships as a
single layer with Icon Composer's own glass off, because the artwork already
carries its light and shadow; iOS renders the dark, clear and tinted versions
from the same document. `Brand/izzy-app-icon-1024.png` is its Default rendition,
exported with `ictool`, and `Brand/izzy-mark.png` is the shape on its own, used
by the website hero. `node scripts/build_brand.mjs` resizes both into the site's
favicon, touch icon and sharing image; it never writes the app icon.

**Wordmark.** Lowercase `izzy` outlined from Figtree Medium
([SIL Open Font License](https://github.com/erikdkennedy/figtree)), in
[`izzy-wordmark.svg`](izzy-wordmark.svg). Adopted 2026-09-21 for a plainer,
quieter name beside the mark; it replaces Outfit Black, and before that the
Archivo italic `vow` outlines. The mark and the wordmark are used together;
neither is placed inside learning screens.

**Not adopted.** Cloud lettering of `izzy` on a blue sky, and the drawn sky that
briefly became Home's default background, were dropped on 2026-09-20 along with
the sky direction. Their renders and generator stay in
[studies/izzy-icon/](studies/izzy-icon/) as a record. The icon rounds that led
here are in [ICON-CANDIDATES.md](ICON-CANDIDATES.md).

Current comparison: [four app interface directions](APP-TASTES.md)
and [learning screens with icons](app-tastes.html).

Broader visual alternatives: [Acid / Play / Zine / Dream](WIDER-TASTES.md)
and [four visual studies](wider-tastes.html).

Latest proposals: [three non-metal brand directions](NONMETAL-PROPOSALS.md)
and [icon / landing comparison](nonmetal-proposals.html). These are alternatives
under consideration, not adopted production changes.

Latest reference research: [21 Wellmade studies and implications for Izzy](WELLMADE-RESEARCH.md).

Next brand direction: [Fuse-led visual exploration](FUSE-DIRECTION.md),
[current study](fuse-direction.html), and [brand definition](REDEFINITION.md).
The wordmark remains the foundation;
the current v-only icon and existing landing are being superseded in that brief.
Production exports below still describe the existing assets.

Adopted on 2026-09-21: **Figtree Medium (500)**, lowercase `izzy`. This is the
current approved wordmark for future brand work. Use the supplied masters, which
contain Figtree’s actual glyphs and kerning.

The letters are set as the font draws them, with no condensing and no added
tracking. Its primary color is graphite `#202020` on soft white `#FAFAF9`. Scale
the finished asset uniformly. The SVG and PDF are drawn at 1000 units per em and
include 24 units of clear space around the outlined letters.

- `izzy-wordmark.svg`: outlined vector master, transparent background.
- `izzy-wordmark.pdf`: outlined vector for design and print workflows.
- `izzy-wordmark-preview.png`: opaque 1200 × 600 preview on soft white.

This decision concerns the wordmark. App reading typography remains New York
for phrases and San Francisco for examples and controls. The app icon and small
web marks use the mark, not a letter. See [brand direction](STRATEGY.md) and
[visual reference](preview.html).
Run `node scripts/build_brand.mjs` for the website wordmark, favicon and social exports.

## Source and license

[Figtree](https://github.com/erikdkennedy/figtree) is designed by Erik Kennedy.
It is available under the
[SIL Open Font License 1.1](https://github.com/google/fonts/blob/main/ofl/figtree/OFL.txt).
The font software itself is not included in this repository. These assets
contain only the rendered wordmark outlines or pixels. The license of the
earlier Archivo letters stays in [licenses/Archivo-OFL.txt](licenses/Archivo-OFL.txt).

Source: the variable TTF `Figtree[wght].ttf` in Google Fonts' repository,
`https://github.com/google/fonts/tree/main/ofl/figtree`.

Approved source SHA-256:
`26ad3db9b31ff7dde67a91ff515d022d2f495cd506590699cf264f0bfe6fb714`.

## Regenerate

Obtain the matching variable TTF under its license and keep it outside tracked
files, for example in `.build/Brand/`. The generator checks the source hash,
sets the weight axis to 500 and shapes the actual `izzy` text with Core Text.

```sh
swift scripts/make_wordmark.swift ".build/Brand/Figtree[wght].ttf" Brand
node scripts/build_brand.mjs
```

Verification: rendered preview inspected for lowercase `izzy`; SVG contains
paths rather than text, and PDF contains no embedded font. All exports use
the same wordmark geometry.
