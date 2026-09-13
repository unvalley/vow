import Foundation

/// Stable free IDs; adding or sorting the catalog never changes the free selection.
enum AccessPolicy {
    static let productID = "me.unvalley.verve.complete.lifetime"
    static let freePhraseIDs: Set<String> = [
        "01-bring-up", "02-get-across", "03-follow-up", "04-push-back", "05-talk-through",
        "06-wrap-up", "07-catch-up", "08-open-up", "09-reach-out", "10-drift-apart",
        "11-let-down", "12-bring-out", "13-put-off", "14-work-out", "15-fall-through",
        "16-turn-down", "17-come-up", "18-rule-out", "19-come-across", "20-figure-out",
        "21-back-up", "22-go-over", "23-think-through", "24-point-out", "25-look-for",
        "26-look-into", "27-look-after", "28-look-up", "29-look-forward-to", "30-look-out-for",
        "31-look-up-to", "32-look-back-on", "33-look-through", "34-look-down-on", "35-get-back-to",
        "36-get-around-to", "37-get-along-with", "38-get-over", "39-get-through", "40-get-away-with",
        "41-get-by", "42-take-on", "43-take-over", "44-take-in", "45-take-up",
        "46-take-back", "47-take-off", "48-put-up-with", "49-put-forward", "50-put-together"
    ]
    static let freeIdiomIDs: Set<String> = [
        "idiom-break-the-ice",
        "idiom-a-piece-of-cake",
        "idiom-under-the-weather",
        "idiom-on-the-same-page",
        "idiom-once-in-a-blue-moon",
        "idiom-the-ball-is-in-your-court",
        "idiom-spill-the-beans",
        "idiom-hit-the-nail-on-the-head",
        "idiom-cost-an-arm-and-a-leg",
        "idiom-call-it-a-day",
        "idiom-get-cold-feet",
        "idiom-in-the-long-run",
        "idiom-out-of-the-blue",
        "idiom-a-blessing-in-disguise",
        "idiom-the-last-straw",
        "idiom-on-the-fence",
        "idiom-miss-the-boat",
        "idiom-go-the-extra-mile",
        "idiom-cut-corners",
        "idiom-in-hot-water",
        "idiom-a-dime-a-dozen",
        "idiom-a-drop-in-the-ocean",
        "idiom-a-far-cry-from",
        "idiom-a-fish-out-of-water",
        "idiom-a-hard-nut-to-crack",
        "idiom-a-long-shot",
        "idiom-a-mixed-bag",
        "idiom-a-pain-in-the-neck",
        "idiom-a-penny-for-your-thoughts",
        "idiom-a-red-herring",
        "idiom-a-safe-bet",
        "idiom-a-second-wind",
        "idiom-a-stone's-throw",
        "idiom-a-tall-order",
        "idiom-a-tough-act-to-follow",
        "idiom-add-fuel-to-the-fire",
        "idiom-add-insult-to-injury",
        "idiom-against-the-clock",
        "idiom-all-ears",
        "idiom-in-the-same-boat",
        "idiom-an-uphill-battle",
        "idiom-around-the-clock",
        "idiom-at-a-crossroads",
        "idiom-at-a-loose-end",
        "idiom-at-arm's-length",
        "idiom-at-first-glance",
        "idiom-at-the-drop-of-a-hat",
        "idiom-back-to-square-one",
        "idiom-back-to-the-drawing-board",
        "idiom-bark-up-the-wrong-tree"
    ]
    static let freeIDs = freePhraseIDs.union(freeIdiomIDs)
    static func allows(_ phrase: Phrase, purchased: Bool) -> Bool { purchased || freeIDs.contains(phrase.id) }
}
