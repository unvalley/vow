import Foundation

/// Stable trial IDs; adding or sorting the catalog never changes the free selection.
enum AccessPolicy {
    static let productID = "me.unvalley.verve.complete.lifetime"
    static let freePhraseIDs: Set<String> = [
        "01-bring-up", "02-get-across", "03-follow-up", "04-push-back", "05-talk-through",
        "07-catch-up", "08-open-up", "09-reach-out", "10-drift-apart", "11-let-down",
        "13-put-off", "14-work-out", "15-fall-through", "16-turn-down", "17-come-up",
        "19-come-across", "20-figure-out", "21-back-up", "22-go-over", "23-think-through"
    ]
    static func allows(_ phrase: Phrase, purchased: Bool) -> Bool { purchased || freePhraseIDs.contains(phrase.id) }
    static func allowsStory(_ sceneID: String, purchased: Bool) -> Bool { purchased || sceneID == "work" }
}
