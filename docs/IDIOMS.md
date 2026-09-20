# Idiom collection

The current catalog contains **1,370 expressions: 870 phrasal-verb lessons and
500 idiom lessons**. The latest batch adds 50 of each kind, with 200 new prompts
and model replies. Every addition has two contexts, Japanese and easy-English
meanings, a usage pattern, a usage note, a dictionary reference and an editorial
CEFR estimate. The 500 idioms provide 1,000 distinct prompts and 1,000 distinct
model replies. The full catalog has 2,273 examples, including earlier supplemental
usage.

The previous 1,200-entry catalog was uploaded in TestFlight build 6 on September 13,
2026, and the 1,300-entry catalog in build 21 on September 16, 2026. The 1,370-entry catalog has not been uploaded or deployed. See
[release evidence](../AppStore/TESTFLIGHT.md).

## Learning and browsing

**Phrases → Idioms** lists all 500 entries with search, difficulty filtering and
sorting. All and Saved include both kinds; Phrasal verbs excludes idioms. The additions use the existing
Today, scene, speaking and meaning-review flows, including daily new-expression
limits and the combined meaning/examples reveal.

The fixed 50 free IDs are unchanged. Additions use the existing Pro catalog
policy; Speaking itself remains a free feature. Idioms are learned as whole
expressions and have no verb-family or particle-image links. The 870 phrasal
verbs form 399 verb families.

| Scene | Idiom lessons |
| --- | ---: |
| Connection | 134 |
| Everyday life | 81 |
| Work | 118 |
| Perspective | 88 |
| Plans | 79 |

## Editorial approach and references

The [latest reference audit](catalog-1300-references.json) records the 100 new
lessons, taught senses and dictionary URLs. Every new source URL returned HTTP 200
on September 14, 2026, and its definition text was inspected for the taught sense.
Cambridge, Oxford, Merriam-Webster, Collins and Dictionary.com cover the taught senses. Definitions
and examples from dictionaries were not imported as teaching content.

Prompts, model replies, Japanese meanings and usage notes were authored for Izzy.
Notes distinguish register and meanings: for example, **a dark horse** teaches
hidden ability, **in the clear** teaches freedom from suspicion, **the bottom
line** teaches the main point, and **in the loop** teaches being kept informed
as the counterpart of the earlier **out of the loop**. Some fixed phrases and figurative noun phrases
are grouped with idioms for learning. Variants are aliases, not extra lessons.

Idiom levels are 5 A2, 51 B1, 338 B2 and 106 C1. These are Izzy's editorial
estimates for the supplied contexts, not copied dictionary classifications or
validated exam levels. They may differ from a reference dictionary's CEFR label.

## Regeneration and compatibility

Authored sources are `scripts/data/idioms.json` and `editorial-phrases.json`.
`phrase-difficulty.json` explicitly assigns levels. `catalog-order.json` records
every stable ID in learning order, independently of the source file it belongs to.
The generator requires exact, nonduplicate ID coverage and rejects phrase/alias
collisions. All previous 1,200 records retain every field, ID and position; the
new 100 records follow them. Thus adding phrasal verbs does not move older idioms.

The highlighter recognizes **crept** and **won**. Possessive and regional
variants used in idiom examples are explicit aliases, such as **pull my leg**,
**bear in mind** and **the other way round**. It remains a display aid,
not an assessment of learner language.

See [the expansion and verification record](CATALOG-1300.md). The earlier
[1,200-entry audit](catalog-1200-references.json), [400-idiom audit](idioms-400-references.json)
and [300-idiom audit](idioms-300-references.json) remain as historical records.
The reference index below covers the first 400 idioms; the two later audits list
the 100 idioms and 100 phrasal verbs added since.

## Reference index

| Expression | Editorial level | Reference |
| --- | --- | --- |
| break the ice | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/break-the-ice) |
| a piece of cake | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/piece-of-cake) |
| under the weather | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/under-the-weather) |
| on the same page | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/page) |
| once in a blue moon | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/once-in-a-blue-moon) |
| the ball is in your court | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/ball-is-in-court) |
| spill the beans | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/spill-the-beans) |
| hit the nail on the head | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hit-the-nail-on-the-head) |
| cost an arm and a leg | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/cost-an-arm-and-a-leg) |
| call it a day | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/call-it-a-day) |
| get cold feet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-cold-feet) |
| in the long run | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-long-run) |
| out of the blue | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/out-of-the-blue) |
| a blessing in disguise | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/blessing-in-disguise) |
| the last straw | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/last-straw) |
| on the fence | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-the-fence) |
| miss the boat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/miss-the-boat) |
| go the extra mile | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/go-the-extra-mile) |
| cut corners | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/cut-corners) |
| in hot water | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-hot-water) |
| a dime a dozen | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/dime-a-dozen) |
| a drop in the ocean | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/drop-in-the-ocean) |
| a far cry from | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-a-far-cry-from) |
| a fish out of water | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/fish-out-of-water) |
| a hard nut to crack | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hard-tough-nut-to-crack) |
| a long shot | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/long-shot) |
| a mixed bag | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/mixed-bag) |
| a pain in the neck | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/pain-in-the-neck) |
| a penny for your thoughts | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/penny-for-your-thoughts) |
| a red herring | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/red-herring) |
| a safe bet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/safe-bet) |
| a second wind | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/second-wind) |
| a stone's throw | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/stone-s-throw) |
| a tall order | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/tall-order) |
| a tough act to follow | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/tough-act-to-follow) |
| add fuel to the fire | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/add-fuel-to-the-fire) |
| add insult to injury | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/to-add-insult-to-injury) |
| against the clock | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/against-the-clock) |
| all ears | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-all-ears) |
| in the same boat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-same-boat) |
| an uphill battle | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/uphill) |
| around the clock | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/around-the-clock) |
| at a crossroads | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-at-a-crossroads) |
| at a loose end | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-at-a-loose-end) |
| at arm's length | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-at-arm-s-length) |
| at first glance | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/at-first-glance) |
| at the drop of a hat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/at-the-drop-of-a-hat) |
| back to square one | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/back-to-square-one) |
| back to the drawing board | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/back-to-the-drawing-board) |
| bark up the wrong tree | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-barking-up-the-wrong-tree) |
| all thumbs | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/all-thumbs) |
| beat around the bush | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/beat-around-the-bush) |
| behind closed doors | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/behind-closed-doors) |
| behind the scenes | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/behind-the-scenes) |
| bend over backwards | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bend-over-backwards) |
| between a rock and a hard place | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-caught-between-a-rock-and-a-hard-place) |
| bite off more than you can chew | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bite-off-more-than-can-chew) |
| bite the bullet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bite-the-bullet) |
| blow off steam | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/blow-off-steam) |
| born yesterday | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/not-be-born-yesterday) |
| break a leg | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/break-a-leg) |
| break even | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/break-even) |
| burn bridges | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/burn-boats-bridges) |
| burn the candle at both ends | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/burn-the-candle-at-both-ends) |
| by the book | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/by-the-book) |
| by the skin of your teeth | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/by-the-skin-of-teeth) |
| call the shots | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/call-the-shots) |
| catch wind of | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-wind-of) |
| change of heart | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/change-of-heart) |
| clear the air | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/clear-the-air) |
| close to home | C1 | [Dictionary.com](https://www.dictionary.com/browse/close-to-home) |
| come rain or shine | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/come-rain-or-shine) |
| cry over spilt milk | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/cry-over-spilled-milk) |
| cut to the chase | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/cut-to-the-chase) |
| down to earth | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/down-to-earth) |
| draw a blank | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/draw-a-blank) |
| draw the line | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/draw-the-line) |
| easier said than done | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/easier-said-than-done) |
| eat your words | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/eat-words) |
| face the music | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/face-the-music) |
| fair and square | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/fair-and-square) |
| fall on deaf ears | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/fall-on-deaf-ears) |
| few and far between | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/few-and-far-between) |
| a breath of fresh air | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/breath-of-fresh-air) |
| find your feet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/find-feet) |
| food for thought | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/food-for-thought) |
| from scratch | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/from-scratch) |
| get a taste of your own medicine | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/give-a-dose-taste-of-own-medicine) |
| get the ball rolling | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-start-the-ball-rolling) |
| get the hang of | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-the-hang-of) |
| get the wrong end of the stick | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-the-wrong-end-of-the-stick) |
| get your act together | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-act-together) |
| give it a shot | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/shot) |
| go back to basics | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/back-to-basics) |
| go down in flames | C1 | [Collins](https://www.collinsdictionary.com/us/dictionary/english/go-down-in-flames) |
| go with the flow | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/go-with-the-flow) |
| have a lot on your plate | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-on-plate) |
| have bigger fish to fry | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-bigger-other-fish-to-fry) |
| have second thoughts | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/second-thought) |
| head over heels | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/head-over-heels-in-love) |
| hit a brick wall | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/brick-wall) |
| hit the books | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hit-the-books) |
| hit the ground running | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hit-the-ground-running) |
| hit the road | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hit-the-road) |
| hit the sack | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hit-the-sack) |
| hold your horses | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hold-horses) |
| in a nutshell | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-a-nutshell) |
| in full swing | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-full-swing) |
| in the blink of an eye | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-blink-of-an-eye) |
| in the dark | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-dark) |
| in the driver's seat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-driving-seat) |
| in the nick of time | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-nick-of-time) |
| it takes two to tango | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/it-takes-two-to-tango) |
| jump on the bandwagon | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/jump-on-the-bandwagon) |
| jump the gun | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/jump-the-gun) |
| keep a low profile | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-a-low-profile) |
| keep an open mind | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/open-mind) |
| keep your chin up | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/chin-up) |
| keep your fingers crossed | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-fingers-crossed) |
| keep your head above water | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-head-above-water) |
| keep your options open | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-options-open) |
| keep your word | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/word) |
| kill two birds with one stone | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/kill-two-birds-with-one-stone) |
| learn the ropes | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/learn-know-the-ropes) |
| leave no stone unturned | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/leave-no-stone-unturned) |
| let sleeping dogs lie | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/let-sleeping-dogs-lie) |
| let the cat out of the bag | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/let-the-cat-out-of-the-bag) |
| light at the end of the tunnel | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/light-at-the-end-of-the-tunnel) |
| a needle in a haystack | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/needle-in-a-haystack) |
| look before you leap | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/look-before-you-leap) |
| lose your train of thought | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/train-of-thought-events) |
| make a mountain out of a molehill | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-a-mountain-out-of-a-molehill) |
| make ends meet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-ends-meet) |
| make waves | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-waves) |
| music to your ears | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/music-to-ears) |
| no strings attached | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/no-strings-attached) |
| not my cup of tea | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/not-be-cup-of-tea) |
| not rocket science | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/it-s-not-rocket-science) |
| off the beaten track | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/off-the-beaten-track) |
| off the top of your head | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/off-the-top-of-head) |
| on a roll | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-a-roll) |
| on cloud nine | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-on-cloud-nine) |
| on the ball | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-the-ball) |
| on the back burner | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-the-back-burner) |
| on the cards | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-on-the-cards) |
| on the right track | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-the-right-track) |
| on thin ice | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-skating-on-thin-ice) |
| out of the question | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/out-of-the-question) |
| out of the woods | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/out-of-the-woods) |
| over the moon | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-over-the-moon) |
| pass the buck | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/pass-the-buck) |
| play devil's advocate | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/devil-s-advocate) |
| play it by ear | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/play-it-by-ear) |
| play it safe | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/play-it-safe) |
| put all your eggs in one basket | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/put-all-eggs-in-one-basket) |
| put your foot down | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/put-foot-down) |
| put your foot in your mouth | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/put-foot-in-your-mouth) |
| read between the lines | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/read-between-the-lines) |
| ring a bell | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/ring-a-bell) |
| rock the boat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/rock-the-boat) |
| rule of thumb | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/rule-of-thumb) |
| run out of steam | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/run-out-of-steam) |
| save face | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/save-face) |
| scratch the surface | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/scratch-the-surface) |
| see eye to eye | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/see-eye-to-eye) |
| sit tight | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/sit-tight) |
| a gut feeling | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/gut-feeling-reaction) |
| small talk | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/small-talk) |
| so far so good | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/so-far-so-good) |
| speak of the devil | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/speak-talk-of-the-devil) |
| step on toes | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/step-tread-on-toes) |
| take a back seat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/take-a-back-seat) |
| take a rain check | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/take-a-rain-check-on) |
| take the plunge | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/take-the-plunge) |
| the best of both worlds | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/best-of-both-worlds) |
| the bigger picture | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/big-bigger-picture) |
| the elephant in the room | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/elephant-in-the-room) |
| the icing on the cake | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/icing-on-the-cake) |
| the tip of the iceberg | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/tip-of-the-iceberg) |
| through thick and thin | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/through-thick-and-thin) |
| throw in the towel | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/throw-in-the-towel) |
| touch and go | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/touch-and-go) |
| turn a blind eye | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/turn-a-blind-eye) |
| turn over a new leaf | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/turn-over-a-new-leaf) |
| under the radar | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/under-the-radar) |
| under your nose | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/under-nose) |
| up in the air | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/up-in-the-air) |
| up to speed | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/up-to-speed) |
| water under the bridge | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/water-under-the-bridge) |
| wear your heart on your sleeve | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/wear-heart-on-sleeve) |
| when push comes to shove | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/when-push-comes-to-shove) |
| word of mouth | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/word-of-mouth) |
| worth your while | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/worth-while) |
| you can say that again | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/you-can-say-that-again) |
| your guess is as good as mine | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/guess-is-as-good-as-mine) |
| a change of pace | B2 | [Dictionary.com](https://www.dictionary.com/browse/change-of-pace) |
| the nuts and bolts | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/nuts-and-bolts) |
| in a tight spot | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-in-a-tight-corner-spot) |
| out of your depth | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/out-of-depth) |
| off the hook | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-off-the-hook) |
| a ballpark figure | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/ballpark) |
| a bone to pick | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-a-bone-to-pick-with) |
| a close call | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/close-call) |
| a double-edged sword | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/double-edged-sword) |
| a grey area | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/grey-area) |
| a hidden gem | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hidden-gem) |
| a leap of faith | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/leap-of-faith) |
| a level playing field | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/level-playing-field) |
| a silver lining | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/silver-lining) |
| a slippery slope | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/slippery-slope) |
| a wild goose chase | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/wild-goose-chase) |
| a wake-up call | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/wake-up-call) |
| a weight off your shoulders | B2 | [Farlex](https://idioms.thefreedictionary.com/is%2Ba%2Bweight%2Boff%2Bshoulders) |
| a whole new ball game | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/whole-new-ballgame) |
| actions speak louder than words | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/actions-speak-louder-than-words) |
| all of a sudden | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/all-of-a-sudden) |
| an open book | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/open-book) |
| at a snail's pace | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/at-a-snail-s-pace) |
| at the eleventh hour | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/eleventh-hour) |
| at your wits' end | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/at-wits-end) |
| back on your feet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/back-on-feet) |
| beat the clock | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/beat-the-clock) |
| below the belt | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/below-the-belt) |
| bend the rules | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bend-the-rules) |
| bite your tongue | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bite-tongue) |
| break new ground | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/break-fresh-new-ground) |
| bring home the bacon | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bring-home-the-bacon) |
| burn the midnight oil | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/burn-the-midnight-oil) |
| bury the hatchet | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/bury-the-hatchet) |
| by a long shot | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/not-by-a-long-shot) |
| by and large | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/by-and-large) |
| caught red-handed | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/catch-red-handed) |
| cross that bridge when we come to it | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/i-ll-we-ll-cross-that-bridge-when-i-we-come-get-to-it) |
| cry wolf | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/cry-wolf) |
| cut me some slack | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/cut-some-slack) |
| day in day out | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/day-in-day-out) |
| don't hold your breath | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/don-t-hold-your-breath) |
| dodge a bullet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/dodge-a-bullet) |
| down the drain | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/down-the-drain) |
| down to the wire | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/down-to-the-wire) |
| easy does it | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/easy-does-it) |
| feel like a million dollars | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/look-feel-like-a-million-dollars) |
| for a song | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/for-a-song) |
| from the horse's mouth | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/straight-from-the-horse-s-mouth) |
| get a foot in the door | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-a-foot-in-the-door) |
| get a kick out of | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-a-kick-out-of) |
| get under your skin | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-under-skin) |
| give me a break | B2 | [Merriam-Webster](https://www.merriam-webster.com/dictionary/give%20me%20a%20break) |
| get your ducks in a row | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/get-have-your-ducks-in-a-row) |
| go against the grain | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/go-against-the-grain) |
| go belly up | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/go-belly-up) |
| with flying colors | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/with-flying-colours) |
| go out on a limb | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/out-on-a-limb) |
| go the distance | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/go-the-distance) |
| grasp at straws | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/clutch-grasp-at-straws) |
| have a heart of gold | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-a-heart-of-gold) |
| have an axe to grind | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-an-axe-to-grind) |
| have your hands full | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-hands-full) |
| have your work cut out | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/have-work-cut-out-for) |
| hear it through the grapevine | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hear-through-on-the-grapevine) |
| hold all the cards | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/hold-all-the-cards) |
| in a heartbeat | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-a-heartbeat) |
| in black and white | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-black-and-white) |
| in deep water | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-in-deep-water) |
| in the bag | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-bag) |
| in the limelight | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-limelight) |
| in the pipeline | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/in-the-pipeline) |
| in two minds | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/be-in-two-minds) |
| keep a straight face | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-a-straight-face) |
| keep your eyes peeled | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/keep-eyes-peeled-skinned) |
| kick the habit | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/kick-the-habit) |
| larger than life | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/larger-than-life) |
| in the lurch | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/leave-in-the-lurch) |
| make a beeline for | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-a-beeline-for) |
| make a splash | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-a-splash) |
| make light of | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-light-of) |
| make your day | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/make-day) |
| move the goalposts | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/move-the-goalposts) |
| no hard feelings | B1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/no-hard-feelings) |
| not lift a finger | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/not-lift-a-finger) |
| on a shoestring | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-a-shoestring) |
| on edge | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-edge) |
| on the mend | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-the-mend) |
| on the spur of the moment | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/on-the-spur-of-the-moment) |
| out of pocket | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/out-of-pocket) |
| over the top | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/over-the-top) |
| pay through the nose | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/pay-through-the-nose) |
| pull a few strings | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/pull-strings) |
| pull out all the stops | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/pull-out-all-the-stops) |
| put two and two together | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/put-two-and-two-together) |
| read the room | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/read-the-room) |
| see the light | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/see-the-light) |
| up for grabs | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/up-for-grabs) |
| steal the show | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/steal-the-show-scene) |
| take it with a grain of salt | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/take-with-a-pinch-of-salt) |
| the writing is on the wall | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/writing-is-on-the-wall) |
| think on your feet | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/think-on-feet) |
| throw caution to the wind | C1 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/throw-caution-to-the-wind-winds) |
| up to scratch | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/up-to-scratch) |
| work like a charm | B2 | [Cambridge](https://dictionary.cambridge.org/dictionary/english/work-like-a-charm) |
| a free hand | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/free-hand) |
| a labor of love | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/labour-of-love) |
| a matter of time | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/a-matter-of-time) |
| a new lease of life | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/a-new-lease-of-life) |
| a rough diamond | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/rough-diamond) |
| a shoulder to cry on | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/a-shoulder-to-cry-on) |
| a sight for sore eyes | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/a-sight-for-sore-eyes) |
| a storm in a teacup | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/a-storm-in-a-teacup) |
| a taste of things to come | C1 | [Reference](https://www.collinsdictionary.com/dictionary/english-french/to-be-a-taste-of-things-to-come) |
| a vicious circle | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/vicious-circle) |
| above board | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/above-board) |
| against all odds | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/against-all-odds) |
| all in a day's work | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/all-in-a-day-s-work) |
| all over the place | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/all-over-the-place) |
| as good as gold | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/as-good-as-gold) |
| as luck would have it | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/as-luck-would-have-it) |
| at face value | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/at-face-value) |
| at loggerheads | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/at-loggerheads) |
| at odds | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/at-odds) |
| at the end of your tether | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/at-the-end-of-tether) |
| bad blood | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/bad-blood) |
| be beside yourself | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/be-beside-yourself) |
| in your element | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-element) |
| on good terms | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/on-good-terms) |
| on the same wavelength | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/be-on-the-same-wavelength) |
| worlds apart | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/worlds-apart) |
| beyond your wildest dreams | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/beyond-wildest-dreams) |
| bite the hand that feeds you | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/bite-the-hand-that-feeds) |
| blow your own trumpet | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/blow-own-trumpet) |
| break the bank | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/break-the-bank) |
| bring to the table | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/bring-to-the-table) |
| by leaps and bounds | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/by-leaps-and-bounds) |
| can't make head nor tail of | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/can-t-make-head-nor-tail-of) |
| carry the can | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/carry-the-can) |
| change your tune | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/change-tune) |
| cheap and cheerful | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/cheap-and-cheerful) |
| come full circle | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/come-full-circle) |
| come to a head | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/come-to-a-head) |
| come to grips with | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/come-to-grips-with) |
| couldn't care less | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/couldn-t-care-less) |
| dead in the water | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/dead-in-the-water) |
| dog-eat-dog | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/dog-eat-dog) |
| down in the dumps | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/down-in-the-dumps) |
| drive a hard bargain | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/drive-a-hard-bargain) |
| a fly on the wall | C1 | [Reference](https://www.collinsdictionary.com/us/dictionary/english/a-fly-on-the-wall) |
| eye candy | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/eye-candy) |
| fly off the handle | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/fly-off-the-handle) |
| for the time being | B1 | [Reference](https://dictionary.cambridge.org/dictionary/english/for-the-time-being) |
| get a word in edgeways | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/get-a-word-in-edgeways) |
| get off on the wrong foot | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/get-off-on-the-wrong-foot) |
| give the benefit of the doubt | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/give-the-benefit-of-the-doubt) |
| go from strength to strength | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/go-from-strength-to-strength) |
| go hand in hand | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/go-hand-in-hand) |
| go pear-shaped | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/go-pear-shaped) |
| have a soft spot for | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/have-a-soft-spot-for) |
| have the final say | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/say) |
| in a rut | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/be-in-a-rut) |
| in a league of your own | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english-japanese/league) |
| in a pickle | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-a-pickle) |
| in a split second | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/split-second) |
| in no time | B1 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-no-time) |
| in the doghouse | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-the-doghouse) |
| in the red | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-the-red) |
| in the thick of | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-the-thick-of) |
| in your shoes | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/in-shoes) |
| at bay | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/keep-at-bay) |
| inside out | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/inside-out) |
| leave a lot to be desired | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/leave-a-lot-to-be-desired) |
| let your hair down | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/let-hair-down) |
| like a broken record | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/like-a-broken-record) |
| like chalk and cheese | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/like-chalk-and-cheese) |
| lose face | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/lose-face) |
| make a clean break | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/make-a-clean-break) |
| make a name for yourself | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/make-a-name-for-yourself) |
| make up your mind | B1 | [Reference](https://dictionary.cambridge.org/dictionary/english/make-up-mind) |
| more than meets the eye | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/more-than-meets-the-eye) |
| not the end of the world | B1 | [Reference](https://dictionary.cambridge.org/dictionary/english/not-the-end-of-the-world) |
| off the record | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/off-the-record) |
| on a knife-edge | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/on-a-knife-edge) |
| on the go | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/on-the-go) |
| on the house | B1 | [Reference](https://dictionary.cambridge.org/dictionary/english/on-the-house) |
| out of sorts | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/out-of-sorts) |
| over a barrel | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/have-over-a-barrel) |
| pull your weight | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/pull-weight) |
| put a brave face on | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/put-a-brave-face-on) |
| put your money where your mouth is | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/put-money-where-mouth-is) |
| rain on your parade | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/rain-on-parade) |
| right up your alley | B2 | [Reference](https://www.dictionary.com/browse/right-up-ones-alley) |
| through the roof | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/through-the-roof) |
| smell a rat | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/smell-a-rat) |
| spitting image | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/spitting-image) |
| stick to your guns | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/stick-to-guns) |
| sweep under the carpet | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/sweep-under-the-carpet) |
| take a leaf out of your book | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/take-a-leaf-out-of-book) |
| the early bird catches the worm | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/the-early-bird-catches-the-worm) |
| the ins and outs | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/the-ins-and-outs) |
| the lion's share | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/the-lion-s-share) |
| tie the knot | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/tie-the-knot) |
| under the same roof | B2 | [Reference](https://dictionary.cambridge.org/dictionary/english/under-the-same-roof) |
| wash your hands of | C1 | [Reference](https://dictionary.cambridge.org/dictionary/english/wash-hands-of) |

## Verification of the 400-idiom catalog

- All 1,000 previous records remain identical and in the same order. The 100
  additions have 200 original prompts and 200 original model replies.
- Regeneration is byte-identical. Catalog SHA-256:
  `2ae4b662fbb187ced9c6bf7c3b933ed041600eff7061d7c2a390f216cff338b7`.
- Seven Python collection tests and 59 Swift tests passed, covering every
  catalog example highlight (1,733 total), search, difficulty, both schedulers,
  and the unchanged fixed 50 free IDs. Swift log:
  `.build/Idioms-400/swift-tests.log`.
- English/Japanese landing build and all five page checks passed with 1,100
  as the current catalog count. No website publication was performed.
- iPhone simulator journey passed: 400-idiom list → search **on the house** →
  Japanese meaning and both highlighted examples → speaking and transfer
  practice → Saved after relaunch. The three exported screenshots were visually
  inspected. Result: `.build/Idioms-400/UI-Verified.xcresult`; screenshots:
  `.build/Idioms-400/screens/`.
- The initial UI run used the old 300-count expectation despite the updated test
  binary. Reinstalling the test runner and rerunning the same scenario completed
  successfully. No production behavior was changed for this test-runner issue.
- No TestFlight upload was performed for this expansion; build 5 contains the
  earlier 200-idiom catalog. Physical-device validation remains outstanding.

## Historical verification of the 300-idiom catalog

- All 900 previous records match the saved baseline field-for-field and in the
  same order. All 1,000 IDs and difficulty assignments are complete; the 300
  idioms have 600 distinct prompts and 600 distinct model replies.
- Regeneration is byte-identical. Catalog SHA-256:
  `ca0a650e19496135688824610c747ccbc0b37d1c8f73d73fc800d8b4f37d0650`.
- Seven Python collection tests and 59 Swift package tests passed. The Swift
  suite checks all 1,533 example highlights, including hyphenated expressions,
  trailing possessives and irregular forms such as “stole the show”. Final Swift
  results: `.build/idioms-300-unit-verified.log`.
- The English/Japanese landing build and five-page checks passed with 1,000 as
  the catalog count. The website has not been published with this update.
- The iPhone simulator journey passed:
  300-idiom list → search **read the room** → Japanese meaning and both highlighted
  examples → speaking and transfer practice → Saved after relaunch.
  Result: `.build/Idioms-300-UI.xcresult`. The three screenshots exported to
  `.build/Idioms-300-attachments/` were visually inspected. The subsequent
  irregular-form adjustment was validated by the final Swift suite.
- These additions have not been uploaded to TestFlight. Build 5 still contains
  the earlier 200-idiom catalog; physical-device validation remains outstanding.

## Historical verification of the 200-idiom catalog

- All 720 pre-expansion records match the saved baseline field-for-field and in
  the same order. All 900 IDs, names and difficulty assignments are complete.
- Regeneration is byte-identical. Catalog SHA-256:
  `9d9e3a587cf436639fde94b49fe37ee4b901c2a265552311ded9c0199b55d1a1`.
- Seven Python collection tests and 53 Swift package tests passed. Checks include
  all 1,333 example highlights, 400 distinct idiom prompts/replies, alias
  collisions, both review schedulers, free access, search and difficulty filters.
- The English/Japanese landing build and five-page checks passed with 900 as the
  current catalog count.
- The iPhone simulator journey passed with a newly added lesson:
  200-idiom list → search **read between the lines** → Japanese meaning and both
  highlighted examples → speaking and transfer practice → Saved after relaunch.
  Result: `.build/Idioms-200-UI.xcresult`. All three screenshots exported to
  `.build/Idioms-200-attachments/` were visually inspected.
- This earlier 200-idiom catalog was subsequently uploaded in TestFlight build 5.
  That upload does not contain the latest 100 additions. Physical-device and
  public App Store/website verification remain separate.
