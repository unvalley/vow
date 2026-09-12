# Layout and appearance

The reading canvas is soft white (#FAFAF9) with graphite text (#202020). Dark appearance uses #141414 and #F2F2F0. Neutral surfaces are #F0F0ED / #252525; secondary text is #686866 / #A5A5A0.

Blue (#3155D9 / #91A8FF) is the default when no accent preference was stored. Explicitly selected colors, including Black, are preserved. Settings offers Black, Blue, Green, Yellow, Pink, Orange, and Purple.

## Color roles

- Normal navigation, settings, phrase-family chips, playback at rest, page arrows, and primary action buttons are neutral. The selected tab retains the accent.
- Accent indicates saved phrases, active playback, practiced days, selected settings, progress, completion, and diagram movement. Color always accompanies a shape, label, or native selection state.
- `AppAccent.color` is for readable text and marks; `fill` and `onFill` form a selection-surface pair. Yellow uses a vivid fill with dark text, rather than turning the whole theme into mustard. `soft` is for subtle selected backgrounds.
- Recording has its own red token, independent of accent preferences. Primary button strength comes from a neutral solid surface, not the chosen hue.
- The neutral geometry in core images stays neutral; routes and moving subjects carry accent.

## Typography

`Typography` in `Vow/Views/DesignSystem.swift` defines roles using native system fonts, without bundled font files:

- New York (SwiftUI serif): featured phrase, phrase detail, verb families, phrase rows, and editorial titles.
- San Francisco (SwiftUI default): definitions, examples, section labels, navigation, and statistics. Japanese uses the system language fallback.
- Today uses a 48-point display phrase scaled with Dynamic Type and restrained tracking of -0.018 em. Other serif roles use semantic largeTitle/title/title2/title3 styles.
- Definitions use title3 with loose leading; full-sentence examples use body with loose leading. Examples are intentionally quieter than the phrase being learned.
- Section labels use subheadline semibold; metadata uses caption. Context labels retain normal casing and natural letter spacing. Only numerical counters use monospaced digits. The speaking timer also scales, and stacks vertically at accessibility text sizes.
- Native text styles retain optical sizing and accessibility scaling. No fixed-height text boxes or minimum-scale shrinking are introduced.

References: [DD Button](https://devouringdetails.com/system/button), [Contrasting Aesthetics](https://rauno.me/craft/contrasting-aesthetics), [Novelty](https://rauno.me/craft/novelty), and [Apple Typography](https://developer.apple.com/design/human-interface-guidelines/typography). These principles are adapted to daily language practice; color values are original to vow.

## Spacing

`Spacing` in `Vow/Views/DesignSystem.swift` is the source for gaps and padding throughout the app:

| Token | Points | Use |
| --- | ---: | --- |
| xxs | 4 | Small text separation |
| xs | 8 | Closely related controls |
| sm | 12 | Label and icon groups |
| md | 16 | Related content |
| lg | 24 | Sections and page insets |
| xl | 32 | Reading insets and larger separation |
| xxl | 48 | Major separation |
| hero | 64 | Large composition spacing |

Zero is used for continuous rows. Typography, 44/48-point touch targets, corner radii, and diagram geometry are separate from layout spacing. Reading columns retain the 680-point maximum width. Large Dynamic Type uses vertical arrangements when horizontal links do not fit.

## Today

- The phrase is a navigation link to its notes; there is no separate info button.
- A labelled Scene link opens the phrase's conversation category. Previous/next controls surround the phrase index.
- Verb-family and particle links share a compact component with phrase details.
- Practice speaking is a secondary text action.
- Examples are explicitly labelled and occupy their intrinsic layout height even while hidden. Hidden text cannot be tapped or read by VoiceOver. Showing examples does not shift the phrase or footer.
- Distinct lesson reply/transfer examples are shown together. The 80 original lessons contain both; imported entries with one supplied example show one. Supplemental usage remains separately labelled in phrase details to avoid conflating senses.

## Contrast and diagrams

Measured contrast minima across all seven accents on the neutral surface: 4.66:1 in light mode and 6.75:1 in dark mode. Secondary text is 4.89:1 / 6.20:1; yellow fill with its dark label is 10.73:1. Text and state marks use the readable accent token; filled selections must use its paired foreground. Verify both against the actual light/dark surface, rather than assuming all hues support white labels. Settings shows a text name and native selection indicator alongside each swatch.

Diagrams share a 320 × 180 drawing space. Motion strokes are 4 units wide with 18-unit arrow wings; reference outlines remain 2 units wide. The moving marker travels continuously along the route with 32 drawing units reserved before the arrowhead, keeping the direction cue unobstructed even on short routes. Reduced Motion needs no special animation treatment: diagram movement is controlled by the user's slider.

## Validation — 2026-09-12

- 28 core tests passed, including legacy preference decoding, color persistence alongside learning history, and distinct example projection.
- Native iPhone UI checks passed for stable show/hide coordinates, phrase/verb navigation, saved browsing, color selection and relaunch, core-image movement/comparison, and maximum Dynamic Type layout.
- Rendered screenshots confirmed the color menu swatches, clearer arrowheads, two visible examples, and the simplified practice action. Maximum Dynamic Type uses the full button width for its text.
- Simulator appearance requests reported dark but the captured app remained light. The result bundle named `TodayDarkAccessibility.xcresult` verifies navigation/layout only; it is not dark-rendering evidence. Dark rendering and physical-device verification remain unconfirmed.

## Validation — 2026-09-13

- 28 core tests passed, including decoding old data with the new default and preserving explicit accent preferences.
- Four native iPhone UI tests passed: example layout stability, accent persistence, saved-phrase browsing, and maximum Dynamic Type navigation.
- The final source builds for the iOS simulator. Rendered Today screens confirm neutral resting controls, an accent selected tab, and SF examples beneath New York phrases.
- Contrast calculations cover all seven accents on the light and dark neutral surfaces. The simulator still rendered light after a dark-appearance request; dark rendering and physical-device checks remain unverified.
- No TestFlight upload was performed for this design revision.
