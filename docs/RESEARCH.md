# Verve — research and product decisions

Research checked 12 September 2026. Built for an advanced English learner who understands more than they can readily say. This is a working native iOS app, with a deliberately bounded curriculum of 80 meanings across four conversation settings.

## The need

The user's stated bottleneck is speaking, not a lack of beginner grammar. The product hypothesis is an availability gap: a learner recognizes a phrase but cannot readily choose, inflect, and place it while managing a social interaction. This is a hypothesis for this user, not a diagnosis or a claim about all Japanese learners.

Liao & Fukuya studied Chinese learners at intermediate and advanced levels. Proficiency, verb type, and test format affected avoidance; their study does not justify assuming the same cause for this Japanese advanced learner. It does support distinguishing recognition from productive use and treating figurative meanings carefully. [Paper, 2004](https://doi.org/10.1111/j.1467-9922.2004.00254.x).

Speaking also involves register and relationships. The curriculum therefore practices raising a difficult topic, declining an offer without sounding cold, clarifying intention, and disagreeing with a reason. Phrasal verbs are useful options, not inherently better than single-word alternatives. A different natural reply is not marked wrong.

## Evidence to interaction

| Evidence | Product decision | Boundary |
| --- | --- | --- |
| Repeated retrieval improved delayed vocabulary recall after initial learning. [Karpicke & Roediger, 2008](https://doi.org/10.1126/science.1152408) | Show a situation before a target phrase. Ask for a spoken or typed attempt, then reveal a model. | Word-pair retention is not itself conversational transfer. |
| A meta-analysis of 48 L2 experiments found benefits from spaced practice; optimal timing depended on conditions. [Kim & Webb, 2022](https://doi.org/10.1111/lang.12479) | Save due dates from explicit recall ratings; prioritize due items over fresh material. | Our 10-minute, 1-day, expanding schedule is a transparent heuristic, not FSRS and not a validated optimum. |
| Repeated speeches under the 4/3/2 procedure produced retained fluency gains in a small ESL study. [de Jong & Perfetti, 2011](https://sites.pitt.edu/~perfetti/PDF/de%20Jong%20Language%20Learning.pdf) | Optional three takes of the same message, 60/45/30 seconds, with an untimed setting. | The shorter adaptation is a design hypothesis. Do not claim equivalent experimental evidence. |
| PHaVE organizes high-frequency phrasal verbs by meaning sense rather than headword alone. [Garnier & Schmitt, 2015](https://doi.org/10.1177/1362168814559798) | One sense per entry, word-order frame, contrast, two different contexts. | This app is not the PHaVE list. Its examples, prompts, Japanese notes, and explanations are original. |
| English multiword verbs vary in separability and pronoun placement. [British Council grammar](https://learnenglish.britishcouncil.org/free-resources/grammar/b1-b2/phrasal-verbs) | Contrast “bring it up” with “go over it”; record a reusable sentence shape. | Introductory verb level does not establish a user's productive fluency. |

## The learning loop

1. **Retrieve:** infer a useful reply from an English situation; phrase hidden. A requested hint reveals the phrase and meaning, and prevents a “came naturally” rating for that attempt.
2. **Notice:** compare with an original model. Listen at normal or slower speed, compare your own recording or text, and inspect word order and register.
3. **Transfer:** use the same meaning in a different situation. The model is not displayed during production.
4. **Reflect:** self-rate initial recall. The app does not equate a recording, a typed answer, or a matching string with correct English.
5. **Space:** revisit later. A “not yet” item is also appended once after the other items; that immediate retry never increases its spaced-repetition interval.

The guided scene practice and phrase detail allow deliberate extra practice before a due date. Successful early practice records an event but preserves the existing due date and interval; a lapse brings the phrase back in 10 minutes. The daily practice queue only selects due or unpracticed items; the Today browsing surface can display the whole curriculum. Spoken and typed review counts are labeled separately. Progress starts at zero and comes entirely from saved activity.

## Reference-led visual design

Visited both reference sites and inspected their rendered screens. Cosmos's homepage uses open neutral space, bold simple hierarchy, floating visual objects, a restrained navigation, and content as the focal point. [Cosmos](https://www.cosmos.so/). Collection-oriented navigation also reflects its own introduction to the product. [Cosmos introduction](https://help.cosmos.so/en/articles/11846092-intro-to-cosmos).

On 60fps, examined the Monogram tap-and-hold microphone example and its state sequence: input affordance, recording feedback, completion feedback, and a return to content. [Specific reference](https://60fps.design/shots/monogram-tap-and-hold-mic-liquid-blur-pulse-interaction).

The initial version translated those references into an original paper/charcoal/copper palette, four pastel conversation collections, custom line drawings rendered in SwiftUI Canvas, serif editorial headings, restrained touch feedback, and an explicit microphone/stop state. No reference site's images, logos, or assets are copied. Holding is replaced with accessible tap-to-start/tap-to-stop. Reading screens do not run perpetual decorative animations. System Reduce Motion disables scale and phase animations. There is no claim of measured 60 fps performance.

## Privacy and operating model

- SwiftUI, Observation, Foundation, AVFoundation. iOS 17+. No external package or server.
- Audio recording is opt-in per exercise, requested only after tapping Record. No speech recognition or transcript upload.
- Temporary recordings are discarded on exercise exit; progress stores no audio.
- Text mode works when microphone access is denied or the learner cannot speak aloud.
- AVSpeechSynthesizer supplies system English speech; pronunciation is not automatically assessed.
- Review state, bookmarks, settings, and personal sentences persist in an atomic local JSON file. Corrupt or newer-schema data is preserved rather than overwritten.
- No account, analytics, subscriptions, push notifications, or background microphone use.

## What would test the product hypothesis next

Use the app for one week, then elicit unrehearsed replies to different scenarios without showing the phrase. Compare with a short baseline recording in the same type of situation, looking at time to begin a meaningful reply, hesitation, appropriate sense, and word order. Self-ratings and app completion do not establish a causal learning effect. A live partner or teacher can supply feedback this solo version cannot.

## 12 September update: blue palette and verb families

The user's revised direction replaces paper/copper/pastels with white, black, and blue. Inspected the rendered [Apple iPhone page](https://www.apple.com/iphone/) and [Distinction App page](https://distinction.atsueigo.com/app): neutral surfaces, dark text, and blue links/buttons informed the update. Verve keeps original artwork and uses its own darker blue action token (#005CCC) for text contrast. The icon, artwork, navigation tint, progress marks, and scene cards follow the new palette.

The curriculum now contains 80 expressions and 160 original conversation situations, organized into 28 base-verb families. The original 24 IDs remain unchanged so saved notes and reviews continue to resolve. Fifty-six additions broaden look, get, take, put, come, go, bring, turn, give, set, run, and hold. Each retains two different contexts, a Japanese gloss, a grammatical frame, and a sense contrast.

“By verb” is a browsing and comparison tool; it does not imply all expressions with one verb share a predictable meaning. Daily retrieval still prioritizes due reviews and the chosen conversation focus. The collection uses the learner-friendly broad category of multiword verbs, including prepositional patterns such as look for and three-word patterns such as look forward to. They are not all separable particle verbs.

Dictionary checks review the taught sense, not just HTTP status. For example, Oxford's dedicated look-for page teaches an expectation sense, so the search lesson links to the **search** sense under [look](https://www.oxfordlearnersdictionaries.com/definition/english/look_1). Get along with uses the [American entry](https://www.oxfordlearnersdictionaries.com/definition/american_english/get-along-with); go ahead and run out use their verb entries rather than similarly named other parts of speech. The original examples are not copied from Distinction or a dictionary.

## Vocabulary reference update

The referenced app is [Vocabulary – Learn words daily by Monkey Taps](https://apps.apple.com/us/app/vocabulary-learn-words-daily/id1084540807), also linked from its [official site](https://vocabulary.monkeytaps.app/). Inspected the site's rendered page and its public iPhone screenshot: one large centered headword, a short meaning, generous space, and a small action row. Verve adopts that visual hierarchy with its own white/black/blue palette; it does not reuse the reference's illustrations, teaching copy, or assets.

The Today reading surface is discovery, not evidence of retrieval: paging, listening, and bookmarking never create practice events. Practice started from Today receives the IDs that were displayed there and prevents a Came naturally rating for those items. This is session-local support tracking, not a validated memory-decay model; it does not attempt to measure exposure outside this screen or across app launches. Existing prompt → comparison → transfer → self-reflection practice and spaced reviews remain in place.
