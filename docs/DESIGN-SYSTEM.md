# Layout and appearance

The canvas and text use semantic system white/black colors, including their dark-mode counterparts. Neutral surfaces separate content. Accent color is reserved for controls, links, selected states, and diagram movement.

Settings → Appearance → Accent color offers Black (default), Blue, Green, Yellow, Pink, Orange, and Purple. The optional stored preference preserves compatibility with existing progress files. A shared SwiftUI environment value updates screens and sheets without recreating navigation or resetting practice.

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

Accent text against white and white text on filled buttons have contrast ratios from 5.85:1 to 17.93:1. Dark-mode accent text against #1C1C1E ranges from 8.06:1 to 15.61:1. The preference has a text name and native selection indicator in addition to its color swatch.

Diagrams share a 320 × 180 drawing space. Motion strokes are 4 units wide with 18-unit arrow wings; reference outlines remain 2 units wide. The moving marker travels continuously along the route with 32 drawing units reserved before the arrowhead, keeping the direction cue unobstructed even on short routes. Reduced Motion needs no special animation treatment: diagram movement is controlled by the user's slider.

## Validation — 2026-09-12

- 28 core tests passed, including legacy preference decoding, color persistence alongside learning history, and distinct example projection.
- Native iPhone UI checks passed for stable show/hide coordinates, phrase/verb navigation, saved browsing, color selection and relaunch, core-image movement/comparison, and maximum Dynamic Type layout.
- Rendered screenshots confirmed the color menu swatches, clearer arrowheads, two visible examples, and the simplified practice action. Maximum Dynamic Type uses the full button width for its text.
- Simulator appearance requests reported dark but the captured app remained light. The result bundle named `TodayDarkAccessibility.xcresult` verifies navigation/layout only; it is not dark-rendering evidence. Dark rendering and physical-device verification remain unconfirmed.
