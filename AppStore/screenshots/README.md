# Izzy store screenshots

[Open the complete preview](preview.html). There are 16 upload-size PNGs: four
frames in Japanese and English for iPhone 6.9-inch (1320 × 2868) and iPad 13-inch
(2064 × 2752). Upload the four `app-store-ja-*` or `app-store-en-*` files for the
matching device and App Store localization, in key order.

| Key | Line | Capture |
| --- | --- | --- |
| `01-home` | 句動詞とイディオムに特化 / Built for phrasal verbs and idioms | Home |
| `02-examples` | 例文とコアイメージで使える英語に / Examples and core images, for real use | the *bring up* page: its meaning, verb family and core image, then its examples |
| `03-review` | 忘却曲線に従った復習ストラテジー / Reviews timed to the forgetting curve | Stats, on sample learning history |
| `04-expressions` | 英単語を超えた表現力を手に入れよう / Go beyond single words | the idioms list, as a free learner sees it |

Every capture in the set shows free content, so no image features an Izzy Pro item
without saying so (App Review Guideline 2.3.2). Stats uses sample learning history,
not measurements from a real learner.

Each frame is ink with a soft grey light behind the screen, one line of copy above it,
and the capture with its corners rounded — no device frame, and no icon or name, which
the store shows beside the images anyway. The background follows the layered-radial
method in [Methods for random gradients](https://justinjay.wang/methods-for-random-gradients/):
radial gradients from one small grey palette, each with its own focal point, scale,
rotation and skew, fading to transparent over ink, with a faint grain. It is seeded by
the frame's key, so a rebuild draws the same background and the two languages of a
frame share one. The line is one size per device and language — the largest at which
every line in that set fits — measured off the rendered pixels.

`raw/` preserves the original simulator PNGs, including the screens the landing page
uses. App text, data, controls and screenshots are not painted over. `captures.json`
records the capture test result, containing run result and original hashes;
`manifest.json` records final PNG hashes, source hashes and access provenance.
`copy.json` holds the frames: each one's key, its line, and which capture it uses.

Both simulators run with an overridden status bar — 9:41, full signal, full
battery — set with `xcrun simctl status_bar <udid> override` before the run, so
the clock does not date the listing. It changes nothing inside the app; iPadOS
still draws its own date beside the time.

Verified capture tests, recaptured on 23 September 2026, after the tab bar
became icons only with a gear for Settings and the phrase rows began showing an
example:

- `.build/shots/Brand.xcresult`: 16 iPhone captures, passed.
- `.build/shots/Pad.xcresult`: 16 iPad captures, passed.

Each run takes eight screens per language, launched as a Japanese and then an
English device so the interface and the explanations match the localization the
image is filed under. The simulators are `Izzy Store iPhone 17 Pro Max` and `Izzy
Store iPad 13`. The idioms list and the *bring up* page launch with
`--free-access`; the idioms list in both devices' captures opens on the free
idioms, *a blessing in disguise* first, which is what a free learner sees.

Regenerate from passing capture tests, then inspect the gallery:

```sh
python3 scripts/import_store_captures.py --phone .build/shots/Brand.xcresult --ipad .build/shots/Pad.xcresult
node scripts/build_store_artwork.mjs
node scripts/check_store_artwork.mjs
```

The scripts require the exact capture test to pass and reject incomplete captures
and changed source images; `check_store_artwork.mjs` also rejects any capture taken
against a different catalog than the one in the repository. The output was checked
against the current 3,020-expression catalog. These images are prepared locally and
have not been uploaded to App Store Connect. Native price-bearing IAP review
screenshots are prepared separately in [review-assets](../review-assets/README.md).
Consumer images are not transaction evidence.
