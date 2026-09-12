# Core images

Original SwiftUI vector diagrams for 35 prepositions and particles. Open **Phrases → Core images**, or use the small particle links in any phrase detail. The current 614 expressions all have at least one matching image. Compound expressions retain their word order: `put up with` links to `up` and `with`; `run out of` links to `out` and `of`. Object words such as `it` and `oneself` are not treated as particles. `upon` maps to `on`, and `round` maps to `around`.

## Shared visual grammar

- A filled blue dot represents the subject under consideration.
- A hollow blue dot marks the start of a movement.
- Gray outlines, lines, and circles provide the reference: a boundary, surface, target, or another entity.
- A blue path and arrow show movement. Static relations have no movement slider.
- Every diagram uses the same 320 × 180 coordinate space, line weights, dot sizes, and app color tokens. Vector drawing remains sharp at different sizes. No copied illustrations or generated raster assets are used.

Moving diagrams have a manual slider. Its position changes the subject's position along the path; it does not change a definition or the user's progress. There is no autoplay or timer. The full path remains visible, allowing the starting point, intermediate positions, and endpoint to be compared. Paired comparison screens use the same diagram component and scale; large accessibility text sizes stack the cards vertically.

Meanings and short explanations use **Settings → Meaning language**. Native text provides the conceptual description for accessibility; the decorative Canvas is hidden from VoiceOver, while the slider has a localized accessible name and percentage. Browsing images does not count as practice or alter streaks.

## Teaching scope and sources

The drawings are original editorial memory cues, not definitions that uniquely determine every phrasal verb. Spatial meanings offer useful starting points; idiomatic expressions must still be learned with their complete wording and context. The related-phrase list deliberately says “Phrases with this word”: token membership does not assert that every listed sense is explained by the sketch.

The distinction between multi-word verbs, particles, and prepositions follows the framing in [Cambridge English Grammar Today](https://dictionary.cambridge.org/grammar/british-grammar/phrasal-verbs). We call the destination “Core images” and include both prepositions and adverbial particles instead of labeling every second word a preposition.

The design is informed by image-schema approaches to spatial and extended meanings, including [Lindstromberg, English Prepositions Explained](https://benjamins.com/catalog/z.157). This is a reference to the approach, not a reproduction of that book's images or a claim to have audited every chapter. The publisher listing was available in search; direct access was restricted.

[A principled Cognitive Linguistics account of English phrasal verbs with up and out](https://www.cambridge.org/core/journals/language-and-cognition/article/principled-cognitive-linguistics-account-of-english-phrasal-verbs-with-up-and-out/BFC34113FA07418EFBAF90A997BE52A0) examines interactions between verb and particle meanings. It supports treating the complete expression as important; it is not evidence that these particular diagrams improve learning outcomes. No effectiveness claim is made for this implementation.

## Implementation

`Verve/Core/ParticleConcept.swift` stores bilingual concepts, contrast pairs, aliases, and exact-token matching. `Verve/Views/ParticleImagesView.swift` contains the shared vector renderer, gallery, detail, slider, and paired comparison. `LibraryView.swift` provides gallery and phrase entry points. Existing catalog IDs, meanings, examples, sort settings, and progress data are unchanged.
