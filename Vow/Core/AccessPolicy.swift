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
    static func allows(_ phrase: Phrase, purchased: Bool) -> Bool { purchased || freePhraseIDs.contains(phrase.id) }
}
