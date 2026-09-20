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

**Wordmark.** Lowercase `izzy` outlined from Outfit Black
([SIL Open Font License](https://github.com/googlefonts/outfit)), in
[`izzy-wordmark.svg`](izzy-wordmark.svg). It replaces the earlier Archivo italic
`vow` outlines. The mark and the wordmark are used together; neither is placed
inside learning screens.

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

Adopted on 2026-09-13: **Archivo Regular Italic (400)**, lowercase `Izzy`,
at **85% width**. This is the current approved wordmark for future brand work.
Use the supplied masters, which contain Archivo’s actual italic glyphs.

Following the request for narrower letters, the shaped wordmark is condensed
to **85% of its original width**, keeping its original height. This horizontal
transform is applied to the complete word once; it does not edit the font file.
Its primary color is graphite `#202020` on soft white `#FAFAF9`. Scale the
finished asset uniformly. The SVG and PDF include 32 points of clear space
around the outlined letters at their native size.

- `izzy-wordmark.svg`: outlined vector master, transparent background.
- `izzy-wordmark.pdf`: outlined vector for design and print workflows.
- `izzy-wordmark-preview.png`: opaque 1200 × 600 preview on soft white.

This decision concerns the wordmark. App reading typography remains New York
for phrases and San Francisco for examples and controls. The app icon and small web marks now use the first letter of this approved
outline. See [brand direction](STRATEGY.md) and [visual reference](preview.html).
Run `node scripts/build_brand.mjs` for icon, favicon and social exports.

## Source and license

[Archivo](https://www.fontshare.com/fonts/archivo) is designed by Héctor Gatti
and published by Omnibus-Type. It is available under the
[SIL Open Font License 1.1](https://github.com/Omnibus-Type/Archivo/blob/master/OFL.txt).
A copy of the upstream license is preserved in [licenses/Archivo-OFL.txt](licenses/Archivo-OFL.txt).
The font software itself is not included in this repository. These assets
contain only the rendered wordmark outlines or pixels.

Source: the Regular Italic TTF linked by Fontshare's official CSS API,
`https://api.fontshare.com/v2/css?f[]=archivo@401&display=swap`.

Approved source SHA-256:
`edd7f2cd765aecca123a2354ef91b783d2f8ec69075966c53a06ebbda0d01cdf`.

## Regenerate

Obtain the matching Regular Italic TTF directly from Fontshare under its license and
keep it outside tracked files, for example in `.build/Brand/`. The generator
checks the source hash and shapes the actual `Izzy` text with Core Text.

```sh
swift scripts/make_wordmark.swift .build/Brand/Archivo-Italic.ttf Brand
```

Verification: rendered preview inspected for lowercase `Izzy`; SVG contains
paths rather than text, and PDF contains no embedded font. All exports use
the same wordmark geometry, including the 85% width treatment.
