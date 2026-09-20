import SwiftUI

struct PhraseExampleText: View {
    @Environment(\.appAccent) private var accent
    let text: String
    let phrase: Phrase
    var font: Font = Typography.example

    var body: some View { Text(highlighted).font(font) }

    private var highlighted: AttributedString {
        var result = AttributedString()
        var cursor = text.startIndex
        for range in PhraseHighlight.ranges(in: text, phrase: phrase) {
            result.append(AttributedString(String(text[cursor..<range.lowerBound])))
            var target = AttributedString(String(text[range]))
            target.foregroundColor = accent.color
            target.backgroundColor = accent.soft
            target.font = font.weight(.semibold)
            result.append(target)
            cursor = range.upperBound
        }
        result.append(AttributedString(String(text[cursor...])))
        return result
    }
}
