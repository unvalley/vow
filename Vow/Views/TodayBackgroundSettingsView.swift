import SwiftUI

struct TodayBackgroundSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    private var selected: TodayBackground { store.data.backgroundChoice }

    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Shown softly behind your daily phrases.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 280 : 148), spacing: Spacing.md)], spacing: Spacing.lg) {
                    ForEach(TodayBackground.allCases, id: \.self) { choice in
                        BackgroundChoiceTile(choice: choice, isSelected: choice == selected) {
                            store.configure(background: choice)
                        }
                    }
                }.accessibilityIdentifier("backgroundGrid")
                Divider()
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(LocalizedStringKey(selected.title)).font(Typography.section).accessibilityAddTraits(.isHeader)
                    // A fixed preview canvas preserves the whole composition without changing layout.
                    Rectangle().fill(Palette.surface).aspectRatio(4.0 / 3.0, contentMode: .fit)
                        .overlay {
                            Image(selected.imageName).resizable().scaledToFit()
                        }.clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                        .overlay { RoundedRectangle(cornerRadius: Radius.medium).strokeBorder(Palette.outline, lineWidth: 1) }
                        .accessibilityLabel(Text(LocalizedStringKey(selected.title)))
                    Text(LocalizedStringKey(selected.credit)).font(.subheadline).foregroundStyle(Palette.secondary)
                    Link("View source", destination: selected.sourceURL).font(.subheadline).frame(minHeight: 44)
                }
            }
        }.navigationTitle("Today background").navigationBarTitleDisplayMode(.inline)
    }
}

private struct BackgroundChoiceTile: View {
    let choice: TodayBackground
    let isSelected: Bool
    let select: () -> Void
    @Environment(\.appAccent) private var accent

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // The canvas, not the source image, determines every tile's dimensions.
                Color.clear.aspectRatio(4.0 / 3.0, contentMode: .fit)
                    .overlay {
                        GeometryReader { geometry in
                            Image(choice.imageName).resizable().scaledToFill()
                                .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        }
                    }.clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.medium).strokeBorder(Palette.outline, lineWidth: 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 21, weight: .semibold))
                            .foregroundStyle(isSelected ? accent.color : Palette.secondary)
                            .padding(6).background(Palette.paper, in: Circle()).padding(Spacing.xs)
                    }
                Text(LocalizedStringKey(choice.title)).font(.subheadline.weight(.medium))
                    .lineLimit(2, reservesSpace: true).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Palette.ink)
            }.contentShape(Rectangle())
        }.buttonStyle(PressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringKey(choice.title)))
            .accessibilityIdentifier("background-\(choice.rawValue)")
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

extension TodayBackground {
    var credit: String {
        switch self {
        case .mountains: "Photo by m wrona · Unsplash"
        case .ocean: "Photo by Hannah Reding · Unsplash"
        case .waterLilies: "Claude Monet, Water Lilies, 1906\nArt Institute of Chicago"
        case .forest: "Photo by Todd Aarnes · Unsplash"
        case .lake: "Photo by Andrew Svk · Unsplash"
        case .dunes: "Photo by Simon Schwyter · Unsplash"
        case .hills: "Photo by Ricardo Gomez Angel · Unsplash"
        case .clouds: "Photo by Billy Huynh · Unsplash"
        }
    }

    var sourceURL: URL {
        switch self {
        case .mountains: URL(string: "https://unsplash.com/photos/JG7KBXn-_Mc")!
        case .ocean: URL(string: "https://unsplash.com/photos/yVl4V7dUS2Y")!
        case .waterLilies: URL(string: "https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Water_Lilies_-_1906,_Ryerson.jpg")!
        case .forest: URL(string: "https://unsplash.com/photos/wmFTP3vbYKU")!
        case .lake: URL(string: "https://unsplash.com/photos/9lLcLf490nM")!
        case .dunes: URL(string: "https://unsplash.com/photos/mK5OE9bgg1Q")!
        case .hills: URL(string: "https://unsplash.com/photos/tNYTM5_Fpes")!
        case .clouds: URL(string: "https://unsplash.com/photos/v9bnfMCyKbg")!
        }
    }
}
