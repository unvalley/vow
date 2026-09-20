import Foundation

/// Shares the catalog importer's word-form rules. Returned ranges preserve the original text.
enum PhraseHighlight {
    private static let words = try! NSRegularExpression(pattern: #"\p{L}+(?:['’]\p{L}+)?"#)
    private static let boundaries = CharacterSet(charactersIn: ".!?;:/,\n\r—")
    private static let reflexives: Set<String> = ["oneself", "myself", "yourself", "himself", "herself", "itself", "ourselves", "yourselves", "themselves"]

    static func ranges(in text: String, phrase: Phrase) -> [Range<String.Index>] {
        ranges(in: text, expressions: [phrase.phrase] + (phrase.aliases ?? []), allowsGaps: !phrase.isIdiom)
    }

    static func ranges(in text: String, expressions: [String], allowsGaps: Bool = true) -> [Range<String.Index>] {
        let tokens = words.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match -> (word: String, range: Range<String.Index>)? in
            guard let range = Range(match.range, in: text) else { return nil }
            return (String(text[range]).lowercased(), range)
        }
        var highlighted = Set<Int>()
        for expression in expressions {
            // Tokenize both sides identically, including hyphenated compounds and
            // trailing possessive apostrophes (e.g. "at your wits' end").
            let parts = words.matches(in: expression, range: NSRange(expression.startIndex..., in: expression)).compactMap { match -> String? in
                guard let range = Range(match.range, in: expression) else { return nil }
                return String(expression[range]).lowercased()
            }
            guard let verb = parts.first, parts.count > 1 else { continue }
            let variants = forms(of: verb)
            for start in tokens.indices where variants.contains(tokens[start].word) {
                var matched = [start]
                var cursor = start + 1
                for particle in parts.dropFirst() {
                    var found: Int?
                    while cursor < min(start + 10, tokens.count) {
                        let between = text[tokens[start].range.upperBound..<tokens[cursor].range.lowerBound]
                        if between.rangeOfCharacter(from: boundaries) != nil { break }
                        let word = tokens[cursor].word
                        if word == particle || (particle == "oneself" && reflexives.contains(word)) {
                            found = cursor
                            cursor += 1
                            break
                        }
                        // Do not pair an earlier verb with a later occurrence's particle.
                        if !allowsGaps || variants.contains(word) { break }
                        cursor += 1
                    }
                    guard let found else { break }
                    matched.append(found)
                }
                if matched.count == parts.count { highlighted.formUnion(matched) }
            }
        }
        // Adjacent words share one highlight; an intervening object stays unhighlighted.
        var result: [Range<String.Index>] = []
        for index in highlighted.sorted() {
            let range = tokens[index].range
            if let previous = result.last,
               text[previous.upperBound..<range.lowerBound].allSatisfy({ $0.isWhitespace || "-'’".contains($0) }) {
                result[result.count - 1] = previous.lowerBound..<range.upperBound
            } else { result.append(range) }
        }
        return result
    }

    private static func forms(of verb: String) -> Set<String> {
        var variants: Set<String> = [verb, verb + "s", verb + "ed", verb + "ing"]
        if verb.hasSuffix("e") { variants.formUnion([verb + "d", String(verb.dropLast()) + "ing"]) }
        if verb.hasSuffix("ie") { variants.insert(String(verb.dropLast(2)) + "ying") }
        let letters = Array(verb)
        if letters.count > 1, letters.last == "y", !"aeiou".contains(letters[letters.count - 2]) {
            variants.formUnion([String(verb.dropLast()) + "ies", String(verb.dropLast()) + "ied"])
        }
        if ["s", "sh", "ch", "x", "z", "o"].contains(where: { verb.hasSuffix($0) }) { variants.insert(verb + "es") }
        if letters.count > 2, let last = letters.last,
           !"aeiouwxy".contains(last), "aeiou".contains(letters[letters.count - 2]), !"aeiou".contains(letters[letters.count - 3]) {
            variants.formUnion([verb + String(last) + "ed", verb + String(last) + "ing"])
        }
        variants.formUnion(irregular[verb] ?? [])
        return variants
    }

    private static let irregular: [String: [String]] = [
        "be": ["am", "is", "are", "was", "were", "been", "being"],
        "bend": ["bent"],
        "creep": ["crept"],
        "win": ["won"],
        "drive": ["drove", "driven"],
        "kneel": ["knelt"],
        "lean": ["leant"],
        "lie": ["lay", "lain", "lying"],
        "ride": ["rode", "ridden", "riding"],
        "bear": ["bore", "borne", "born"],
        "blow": ["blew", "blown"],
        "break": ["broke", "broken"],
        "bring": ["brought"],
        "build": ["built"],
        "burn": ["burnt"],
        "burst": ["burst"],
        "buy": ["bought"],
        "catch": ["caught"],
        "come": ["came"],
        "cut": ["cut", "cutting"],
        "deal": ["dealt"],
        "do": ["did", "done", "doing", "does"],
        "draw": ["drew", "drawn"],
        "eat": ["ate", "eaten"],
        "fall": ["fell", "fallen"],
        "feel": ["felt"],
        "find": ["found"],
        "fly": ["flew", "flown"],
        "get": ["got", "gotten", "getting"],
        "give": ["gave", "given"],
        "go": ["went", "gone", "goes"],
        "grow": ["grew", "grown"],
        "hang": ["hung"],
        "have": ["had", "has", "having"],
        "hear": ["heard"],
        "hit": ["hit", "hitting"],
        "hold": ["held"],
        "keep": ["kept"],
        "lay": ["laid"],
        "leave": ["left"],
        "let": ["let", "letting"],
        "make": ["made", "making"],
        "pay": ["paid"],
        "put": ["put", "putting"],
        "run": ["ran", "running"],
        "see": ["saw", "seen"],
        "sell": ["sold"],
        "send": ["sent"],
        "set": ["set", "setting"],
        "shut": ["shut", "shutting"],
        "sit": ["sat", "sitting"],
        "sleep": ["slept"],
        "speak": ["spoke", "spoken"],
        "stand": ["stood"],
        "steal": ["stole", "stolen"],
        "stick": ["stuck"],
        "take": ["took", "taken", "taking"],
        "tear": ["tore", "torn"],
        "tell": ["told"],
        "think": ["thought"],
        "throw": ["threw", "thrown"],
        "wake": ["woke", "woken"],
        "wear": ["wore", "worn"],
        "write": ["wrote", "written", "writing"],
        "read": ["read"],
        "shake": ["shook", "shaken"],
        "show": ["showed", "shown"],
        "sink": ["sank", "sunk"],
        "spin": ["spun", "spinning"],
        "spit": ["spat", "spit", "spitting"],
        "split": ["split", "splitting"],
        "spring": ["sprang", "sprung"],
        "strike": ["struck", "stricken"],
        "swear": ["swore", "sworn"],
        "wind": ["wound"],
        "bite": ["bit", "bitten"],
        "dig": ["dug"],
        "sweep": ["swept"],
        "stink": ["stank", "stunk"],
        "swim": ["swam", "swum"],
        "ring": ["rang", "rung"],
        "sing": ["sang", "sung"],
        "hide": ["hid", "hidden"],
        "freeze": ["froze", "frozen"],
        "choose": ["chose", "chosen"],
        "forget": ["forgot", "forgotten", "forgetting"],
        "lose": ["lost", "losing"],
        "meet": ["met"],
        "feed": ["fed"],
        "lead": ["led"],
        "spend": ["spent"],
        "rise": ["rose", "risen", "rising"],
        "fight": ["fought"],
        "dive": ["dove", "dived", "diving"],
        "fling": ["flung"],
        "light": ["lit"],
    ]
}
