import Foundation

/// Original learning sketches, not rules for deriving every idiomatic meaning.
struct ParticleConcept: Identifiable, Hashable, Sendable {
    let id: String
    let japanese: String
    let english: String
    let japaneseExtension: String
    let englishExtension: String
    let comparison: String

    func title(in language: MeaningLanguage) -> String { language == .japanese ? japanese : english }
    func extensionText(in language: MeaningLanguage) -> String { language == .japanese ? japaneseExtension : englishExtension }

    static let all: [ParticleConcept] = [
        .init(id: "up", japanese: "上へ・高いところまで", english: "Higher; up to a limit", japaneseExtension: "量や強さが上がるイメージは、強化や、ある限度までやり切る意味につながります。", englishExtension: "Moving higher can suggest more strength or reaching a limit and finishing.", comparison: "down"),
        .init(id: "down", japanese: "下へ・低いところまで", english: "Lower; less", japaneseExtension: "高さが下がることから、量・速さ・強さが減る意味へ広がります。", englishExtension: "A lower position can suggest less speed, strength, or activity.", comparison: "up"),
        .init(id: "in", japanese: "境界の内側にある", english: "Inside a boundary", japaneseExtension: "集団や活動も「内側のある場所」と捉えられます。中に入る動きを表す用法もあります。", englishExtension: "A group or activity can be pictured as a space with an inside. In can also describe movement inward.", comparison: "into"),
        .init(id: "into", japanese: "外から内側へ", english: "Move from outside to inside", japaneseExtension: "境界を越えて入ることから、ある状態になる、ある対象に深く関わるイメージへ広がります。", englishExtension: "Entering a space can suggest entering a new state or getting deeply involved.", comparison: "in"),
        .init(id: "out", japanese: "内側から外へ", english: "Move from inside to outside", japaneseExtension: "中に隠れていたものが外に出ることから、見える・分かるイメージにもつながります。", englishExtension: "Something hidden inside becomes available or visible when it comes out.", comparison: "off"),
        .init(id: "on", japanese: "表面に接している", english: "In contact with a surface", japaneseExtension: "接触・つながりを保つイメージがあります。活動が続く用法も、別の広がりとして覚えます。", englishExtension: "Contact suggests connection. Continuing an activity is another useful sense to learn.", comparison: "off"),
        .init(id: "off", japanese: "接していたところから離れる", english: "Separate from contact", japaneseExtension: "接触が切れることから、接続を切る・活動を止める意味にも広がります。", englishExtension: "Breaking contact can suggest disconnection or stopping an activity.", comparison: "out"),
        .init(id: "onto", japanese: "表面に向かって接する", english: "Move onto a surface", japaneseExtension: "移動の先で接触する関係です。単なる内側への移動とは、到達点が違います。", englishExtension: "The movement ends in contact with a surface rather than inside a space.", comparison: "into"),
        .init(id: "to", japanese: "到達点へ", english: "To an endpoint", japaneseExtension: "目的地だけでなく、相手や結果が到達点になることもあります。", englishExtension: "The endpoint can be a place, a person, or a result.", comparison: "for"),
        .init(id: "from", japanese: "出発点から", english: "From a starting point", japaneseExtension: "動きの出発点から、情報の出所・原因・由来へ広がります。", englishExtension: "A starting point can become the source of information or the origin of something.", comparison: "to"),
        .init(id: "for", japanese: "目的・相手に向けて", english: "Directed toward a purpose", japaneseExtension: "何を目指すか、誰のためかに焦点があります。到着したことまでは表しません。", englishExtension: "Focus on the aim or intended person. This does not itself show arrival.", comparison: "to"),
        .init(id: "at", japanese: "ひとつの点に焦点を合わせる", english: "Focus on a point", japaneseExtension: "場所・時刻・注意や行為の対象を、ひとつの点として捉えます。", englishExtension: "A place, time, or target of attention can be treated as a point.", comparison: "in"),
        .init(id: "by", japanese: "そばに・そばを通って", english: "Beside; passing close", japaneseExtension: "近さや通過を表します。手段・行為者などの意味は、それぞれの文で確かめます。", englishExtension: "Picture closeness or passing nearby. Uses for a method or an agent need their own context.", comparison: "through"),
        .init(id: "with", japanese: "一緒に・関係を持って", english: "Together; in connection", japaneseExtension: "人や物とのつながりを表します。協力だけでなく、対立する相手にも使われます。", englishExtension: "It links people or things, including companions and sometimes opponents.", comparison: "without"),
        .init(id: "without", japanese: "それを伴わずに", english: "Without something present", japaneseExtension: "あるものが一緒にない状態です。必要なものが欠けても行動する文にも使います。", englishExtension: "Something is absent, including a resource you manage without.", comparison: "with"),
        .init(id: "over", japanese: "上を越えて向こうへ", english: "Above and across", japaneseExtension: "上を越す空間関係が出発点です。全体を見渡す・見直す用法もあります。", englishExtension: "Start with an above-and-across path. Other uses include reviewing a whole thing.", comparison: "under"),
        .init(id: "under", japanese: "基準となるものの下に", english: "Below a reference", japaneseExtension: "覆いや基準の下にあることから、影響・支配のもとにある意味にも広がります。", englishExtension: "Being below something can suggest being under its influence or control.", comparison: "over"),
        .init(id: "across", japanese: "一方の側から反対側へ", english: "From one side to the other", japaneseExtension: "隔たりを越えて反対側に届くことから、考えが相手に伝わるイメージにもつながります。", englishExtension: "Crossing a gap can suggest getting an idea to another person.", comparison: "through"),
        .init(id: "through", japanese: "中を通って反対側まで", english: "Through the inside and beyond", japaneseExtension: "途中の空間を通り抜けます。過程や困難を経て、終わりまで進むイメージにもなります。", englishExtension: "The path passes through an interior, like going through a process or difficulty.", comparison: "across"),
        .init(id: "around", japanese: "周囲を回って", english: "Around a center", japaneseExtension: "中心の周囲を動く関係です。回避したり、あちこちに広がったりする用法があります。", englishExtension: "Moving around a center can suggest going around a problem or moving among places.", comparison: "through"),
        .init(id: "about", japanese: "周辺に・その話題について", english: "Around; concerning a topic", japaneseExtension: "あたりに広がる空間関係と、話題に関係する用法があります。", englishExtension: "It can describe a surrounding area or a connection to a topic.", comparison: "around"),
        .init(id: "back", japanese: "元の位置・方向へ戻る", english: "Return toward the starting point", japaneseExtension: "場所だけでなく、返答・返却・以前の状態への戻りにも使われます。", englishExtension: "Returning can concern a place, an answer, an object, or an earlier state.", comparison: "forward"),
        .init(id: "away", japanese: "基準から遠ざかる", english: "Increase distance from a reference", japaneseExtension: "距離を広げる動きから、取り除く・手元からなくなるイメージにもつながります。", englishExtension: "Increasing distance can suggest removal or something no longer being here.", comparison: "back"),
        .init(id: "along", japanese: "道筋に沿って進む", english: "Follow a path", japaneseExtension: "同じ道筋を進むことから、一緒に行く・物事が進む用法にも広がります。", englishExtension: "Following a path can suggest accompanying someone or making progress.", comparison: "across"),
        .init(id: "after", japanese: "後ろから追って", english: "Follow behind", japaneseExtension: "空間で後を追う関係から、時間的な順序にも広がります。", englishExtension: "Following behind in space also gives a way to think about order in time.", comparison: "ahead"),
        .init(id: "ahead", japanese: "進む方向の先に", english: "Further along the direction of travel", japaneseExtension: "進行方向の先にあることから、将来を見据える・先へ進む意味へ広がります。", englishExtension: "Being further along can suggest the future or making progress.", comparison: "behind"),
        .init(id: "behind", japanese: "進む方向の後ろに", english: "Behind a reference", japaneseExtension: "後ろにある位置関係から、進み具合が遅れるイメージにもつながります。", englishExtension: "A position behind can suggest slower progress.", comparison: "ahead"),
        .init(id: "forward", japanese: "前方へ進める", english: "Move toward the front", japaneseExtension: "前へ出すことから、案を提示するなどの用法にも広がります。", englishExtension: "Moving something forward can suggest presenting an idea for others to consider.", comparison: "back"),
        .init(id: "apart", japanese: "互いに離れて", english: "Separate from each other", japaneseExtension: "ひとつだったものの距離が広がることから、分解や関係の隔たりにもつながります。", englishExtension: "Parts move away from each other, as in taking something apart or becoming less close.", comparison: "together"),
        .init(id: "together", japanese: "互いに近づいてひとつに", english: "Bring separate parts together", japaneseExtension: "別々のものが集まることから、組み立てや協力のイメージにもつながります。", englishExtension: "Separate parts meet, suggesting assembly or cooperation.", comparison: "apart"),
        .init(id: "aside", japanese: "中心の道筋から脇へ", english: "To the side of the main path", japaneseExtension: "脇に置くことから、取り置く・一時的に扱わない意味へ広がります。", englishExtension: "Putting something to the side can suggest reserving it or not dealing with it for now.", comparison: "away"),
        .init(id: "against", japanese: "向かい合って接する", english: "In opposing contact", japaneseExtension: "接触や反対向きの力から、反対する・抵抗する意味にも広がります。", englishExtension: "Contact with opposing force can suggest resistance or disagreement.", comparison: "with"),
        .init(id: "of", japanese: "全体と一部の関係", english: "A part linked to a whole", japaneseExtension: "所属や関連を表す用法のひとつを描いています。out of などはまとまりでも確かめます。", englishExtension: "This sketches one part–whole relation. Also learn combinations such as out of as a whole.", comparison: "from"),
        .init(id: "like", japanese: "共通する形・性質", english: "Similarity in shape or quality", japaneseExtension: "似ている関係です。feel like の「〜したい」は、表現全体として覚えます。", englishExtension: "This is a similarity relation. Learn the desire sense of feel like as a whole expression.", comparison: "with"),
        .init(id: "aback", japanese: "後ろへ押し戻される", english: "Taken backward", japaneseExtension: "現代英語では主に taken aback の形で、驚いてひるむことを表します。", englishExtension: "Today, mainly learn taken aback as a whole: surprised and unsure how to react.", comparison: "back")
    ]

    static func find(_ word: String) -> ParticleConcept? {
        let normalized = ["upon": "on", "round": "around"][word.lowercased()] ?? word.lowercased()
        return all.first { $0.id == normalized }
    }
    static func concepts(in phrase: String) -> [ParticleConcept] {
        var seen = Set<String>()
        return phrase.lowercased().split(separator: " ").dropFirst().compactMap {
            guard let concept = find(String($0)), seen.insert(concept.id).inserted else { return nil }
            return concept
        }
    }
}

extension Phrase {
    var particleConcepts: [ParticleConcept] { ParticleConcept.concepts(in: phrase) }
}
