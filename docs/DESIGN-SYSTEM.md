# Layout and appearance

The reading canvas is white (#FAFAFA) with graphite text (#202020). Dark appearance uses #141414 and #F2F2F2. Neutral surfaces are #F0F0F0 / #252525; secondary text is #686868 / #A5A5A5. Since 2026-09-15 every neutral has no hue (OKLCH chroma 0); the earlier values leaned warm.

Blue (#3759C3 / #A2BCFC) is the default when no accent preference was stored. Explicitly selected colors, including Black, are preserved. Settings offers Black, Blue, Green, Yellow, Pink, Orange, and Purple.

## Color roles

- Normal navigation, settings, phrase-family chips, playback at rest, page arrows, and primary action buttons are neutral. The selected tab retains the accent.
- Accent indicates saved phrases, active playback, practiced days, selected settings, progress, completion, and diagram movement. Color always accompanies a shape, label, or native selection state.
- `AppAccent.color` is for readable text and marks; `fill` and `onFill` form a selection-surface pair. Yellow uses a vivid fill with dark text, rather than turning the whole theme into mustard. `soft` is for subtle selected backgrounds.
- Recording has its own red token, independent of accent preferences. Primary button strength comes from a neutral solid surface, not the chosen hue.
- The neutral geometry in core images stays neutral; routes and moving subjects carry accent.

## Emphasis levels

Ink is loud on this canvas, so a solid ink fill means one thing: the action that moves the learner forward. Everything else steps down a level. The components in `Vow/Views/DesignSystem.swift` encode the levels so screens do not restate colors.

| Level | Look | Component | Used for |
| --- | --- | --- | --- |
| Primary | ink fill, paper text | `PrimaryButton` | Continue / Get started, Set daily goal, Unlock for the listed price, Compare reply. At most one per screen. |
| Selected | accent `soft` fill, accent text | `selectionSurface(true)` | The chosen option among peers: Today's mode switch, daily-goal tiles, background tiles, the selected tab. |
| Secondary | surface fill, ink text | `SecondaryButton`, `selectionSurface(false)` | Supporting actions and options at rest: Unlock every phrase with Pro, rating buttons, unselected tiles, the practice record button (44 pt, `Radius.medium`; recording color and its 12% fill only while recording). |
| Tertiary | no fill, ink text in `Typography.control` | plain `Button` or `Link` | Inline actions and links: Explore Pro, Restore purchases, Show meaning & examples. |

Icons follow the same rule: decorative symbols are outline variants in `Palette.secondary`; a filled symbol only reports state (saved bookmark, selected check, playing audio). Navigation chrome stays neutral through `tint(Palette.ink)`. Before 2026-09-14, Today's mode switch and the onboarding Pro icon used ink fills; they now sit at the Selected and decorative levels.

## Typography

`Typography` in `Vow/Views/DesignSystem.swift` pairs native New York vocabulary with SF reading styles:

- New York (SwiftUI serif): Today’s focal phrase, phrase details, verb families, phrase rows, and editorial titles. These restore the original vocabulary typography at the user’s request.
- San Francisco (SwiftUI default): definitions, examples, section labels, navigation, and statistics. Japanese uses the system language fallback.
- Today uses the original 48-point display phrase scaled with Dynamic Type and tracking of -0.018 em. Other serif roles use semantic largeTitle/title/title2/title3 styles.
- Definitions and full-sentence examples use body with loose leading. Section labels and primary action labels use subheadline medium.
- Today’s scene context uses caption medium in natural casing. The phrase precedes its difficulty metadata. Numerical counters use monospaced digits.
- No custom font files or fixed-height text boxes are used. Minimum-scale shrinking is limited to two one-line headlines: the onboarding title (down to 80%) and Today's featured phrase (down to 55%), both wrapping only at accessibility sizes.

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
- Uploaded as TestFlight 1.0.0 (3); see [release status](../AppStore/TESTFLIGHT.md) for processing and distribution evidence.

## Backgrounds and vocabulary — 2026-09-13

Vocabulary uses the original New York styles. Home offers eight backgrounds through Appearance settings: Mountains, Ocean, Monet’s Water Lilies, Misty Forest, Alpine Lake, White Dunes, Misty Hills and Clouds. The picker uses uniform 4:3 thumbnails and aligned captions in an adaptive grid. Theme supports Light, Dark and System (the default), persisted across launches and applied at the app root. Photo and painting sources, rights, and rendering are documented in [Today backgrounds](today-landscape.md).


## Recall, Stats and Pro — 2026-09-13

| Before | After |
| --- | --- |
| Examples heading with a trailing Show button | Centered Show Examples / Hide Examples; example space remains reserved |
| Today meaning always visible | Tap to show/hide; Settings → Today chooses its default visibility independently from examples |
| Practice tab with history, weekly grid and upcoming reviews | Stats contains only Current Streak and Best |
| All phrases browsable; twenty free speaking lessons | Fifty fixed phrases across browsing and learning; Pro lock in Today and Phrases |
| vow Complete purchase copy | Vow Pro; existing lifetime product ID and price retained |
| Speaking-only spaced practice | Additional meaning cards with Again, Hard, Good and Easy, next intervals, due-first ordering and five new phrases a day |

The new review screen uses the original New York phrase type, neutral surfaces, tabular interval labels, 44-point minimum controls, and a single column of ratings at accessibility text sizes. Pro locks use a centered lock symbol, short explanation and neutral filled button. See [review and access contracts](spaced-reviews.md).


## Example highlights — 2026-09-13

`PhraseExampleText` renders a single attributed text element. The target phrasal verb uses the selected accent's text color, its soft background and semibold weight; the rest of the sentence keeps its original font. Today, phrase details (including More usage), meaning-review answers and Speaking model replies share this treatment. Retrieval prompts and user-written replies are not highlighted.

Matching preserves source text and handles word boundaries, case, regular/irregular forms, aliases, reflexive forms, repeated occurrences and separated objects. In “brought it up”, only “brought” and “up” are highlighted. Matching is bounded within a clause; it is not a general grammatical parser.

## Daily learning and unified answers

| Before | After |
| --- | --- |
| Five new meaning-review cards per day, fixed in the scheduler | First-use goal confirmation; presets and a 1–50 stepper; editable from Today and Settings |
| A generic Review entry point | Daily new-expression progress and due-review count, a start/continue action, and a completion screen |
| Separate meaning and example reveal controls and defaults | One Show meaning & examples / Hide meaning & examples button and one default switch; hidden answer space stays reserved |

The goal editor uses adaptive options and native Form scrolling. Dynamic counts
use monospaced digits and actions keep at least 44-point hit areas. The daily
session always hides its answer first, regardless of the browsing preference.
See [daily-learning.md](daily-learning.md) for counting, migration and references.

## Reference-led refinement — 2026-09-13

See [the design refresh record](design-refresh-2026-09-13.md) for the observed
60fps references, implementation decisions, and current verification evidence.

- Today uses a neutral filled learning action and an accent progress track.
  Speaking remains secondary. Scene context is quieter; the phrase comes before
  difficulty metadata. The answer reveal fades without moving the footer.
- Library controls use 12-point group spacing. The result count and difficulty
  menu share a row; accessibility text uses a vertical layout and a collection
  menu instead of four squeezed segments.
- Meaning review keeps its progress header in place. The prompt/answer is a
  28-point-radius neutral card; standard text gets a bottom answer dock, while
  accessibility text keeps all controls in the scroll view. A new prompt resets
  the scroll position and hides the previous answer.
- LearningProgressTrack animates changed values for 240 ms. Saving cross-fades
  its bookmark for 180 ms with selection feedback. Card changes use a 16-point
  entry and 8-point exit over 240 ms. Completion fades/scales once over 240 ms.
  Reduce Motion disables these animations. No looping or delayed animations run.
- Daily goal presets have a visible selection checkmark and tactile feedback.
  The primary save action is filled; forecast and explanatory copy are shorter.
- Stats shows seven recent practice days from the existing activity projection;
  at accessibility sizes the days reflow to three columns. Today's summary uses
  a neutral surface, reserving accent for progress and completed days.

## Accent lightness (2026-09-15)

Accents are derived in OKLCH so every choice reads with the same strength. Light appearance uses L 0.50, dark uses L 0.80; each accent keeps its hue, and chroma is the lesser of 0.17 (light) / 0.12 (dark) and 95% of the sRGB maximum for that hue and lightness. Accent text measures at least 4.5:1 on paper and on its own 12% soft fill over paper or surface (the selection pills). Green's low chroma ceiling puts it a step darker (L 0.48) to hold that on surface.

| Accent | Light | Dark |
| --- | --- | --- |
| Blue | #3759C3 | #A2BCFC |
| Green | #10703E (L 0.48) | #7CD49A |
| Yellow | #7C5E0E (fill #F3CF4A) | #E0B85C |
| Pink | #A72A68 | #FB9DC2 |
| Orange | #A53E0E | #FCA584 |
| Purple | #7245B5 | #C7AEFC |

## Details that make the interface feel better (2026-09-15)

Adapted from Jakub Krehel's writing (jakub.kr) for SwiftUI.

- **Radius.** Four values: `Radius.small` 12 (cells, today mark), `Radius.medium` 18 (inputs, rating cells, option tiles, links), `Radius.large` 24 (cards and buttons), and a full pill. Nested shapes are concentric (outer = inner + padding), as in Home's mode switch at accessibility sizes (12 + 4 = 16).
- **Motion.** `Motion.snappy` (spring 0.3 s, no bounce) for changes the learner caused; `Motion.entrance` (0.5 s) only for rare entrances; `Motion.reducedFade` (0.15 s fade) replaces movement under Reduce Motion. Exits are quieter than entrances (shorter move plus a 4 pt blur). Selection pills slide with `matchedGeometryEffect`; the content they switch (Home's deck, the Phrases list) swaps at once, since animating it would lay out both versions together. Symbols swap with `.symbolEffect(.replace)`. Paging, rating and mode switching never stagger.
- **Staggered entrances.** `staggeredEntrance(_:)` (8 pt rise out of a 6 pt blur, 80 ms apart) is limited to completion states, onboarding pages and the purchase screen.
- **Numbers.** Counts use monospaced digits; counts that change in place use `.numericText()`. Plurals come from the string catalog (`%lld days`), never from `== 1 ? "" : "s"`.
- **Press and hit areas.** Every tappable control has feedback: `PressStyle` (0.96, opacity 0.8) for controls, `RowPressStyle` (a surface wash) for full-width rows. Controls drawn smaller than 44 pt extend their touch area with `hitArea(_:)`, or `hitArea(vertical:)` for segments that touch; grid cells claim half of the gap so taps between cells land.
- **Disabled.** `PressStyle` dims disabled controls to `DisabledStyle.opacity` (0.45). The rating grid opts out so the chosen answer stays bright during its pause.
- **Weights.** Selected options keep the same font weight as unselected ones; color and the pill carry selection, so labels never change width.
- **Optical alignment.** `PrimaryButton` and the dictionary link sit tighter on their icon side; the play triangle moves 1 pt right.
- **Images.** Image edges get a 1 pt `Palette.outline` (pure black or white at 10%).
- **Haptics.** Selection on rating taps, saving and goal changes (not when the goal screen opens); start/stop on recording.
- **Transitions.** Tapping a phrase on Home or in the Phrases list zooms into Phrase notes on iOS 18 and later.
- **Empty states.** Say why the list is empty and offer the next step (Browse all phrases, Clear search).
