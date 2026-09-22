import SwiftUI

struct TodayBackgroundSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var purchase = false
    private var selected: TodayBackground { store.data.background(fullAccess: purchases.hasFullAccess) }

    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Shown softly behind your daily phrases.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                group("Scenes", TodayBackground.allCases.filter { $0.imageName != nil })
                group("Colors", TodayBackground.allCases.filter { $0.imageName == nil })
                if !purchases.hasFullAccess {
                    ProAppearanceNote(text: "Mountains and Ocean are free. Every background opens with Izzy Pro.") { purchase = true }
                }
                if let credit = selected.credit, let sourceURL = selected.sourceURL {
                    Divider()
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(LocalizedStringKey(selected.title)).font(Typography.section).accessibilityAddTraits(.isHeader)
                        Text(LocalizedStringKey(credit)).font(.subheadline).foregroundStyle(Palette.secondary)
                        Link("View source", destination: sourceURL).font(.subheadline).frame(minHeight: 44)
                    }
                }
            }
        }.navigationTitle("Home background").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $purchase) { PurchaseView(from: "background") }
            .closesForReviewRequest($purchase)
    }

    private func group(_ title: LocalizedStringKey, _ choices: [TodayBackground]) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(title).font(Typography.section).accessibilityAddTraits(.isHeader)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 280 : 148), spacing: Spacing.md)], spacing: Spacing.lg) {
                ForEach(choices, id: \.self) { choice in
                    let locked = !choice.isFree && !purchases.hasFullAccess
                    // Portrait, like the screen the background fills.
                    AppearanceChoiceTile(title: choice.title, identifier: "background-\(choice.rawValue)",
                                         isSelected: choice == selected, isLocked: locked, aspect: 3.0 / 4.0) {
                        if locked { purchase = true } else { store.configure(background: choice) }
                    } canvas: {
                        if let color = choice.color {
                            color
                        } else if let imageName = choice.imageName {
                            GeometryReader { geometry in
                                Image(imageName).resizable().scaledToFill()
                                    .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                            }
                        }
                    }
                }
            }
        }
    }
}

/// Phrase typeface, chosen the way the background is: a grid of samples, then the choice at full size.
struct PhraseTypefaceSettingsView: View {
    @Environment(LearningStore.self) private var store
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var purchase = false
    private var selected: PhraseTypeface { store.data.typeface(fullAccess: purchases.hasFullAccess) }

    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text("Used for phrases on Home, in Phrases and in reviews.")
                    .font(.subheadline).foregroundStyle(Palette.secondary)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: typeSize.isAccessibilitySize ? 280 : 148), spacing: Spacing.md)], spacing: Spacing.lg) {
                    ForEach(PhraseTypeface.allCases, id: \.self) { choice in
                        let locked = !choice.isFree && !purchases.hasFullAccess
                        AppearanceChoiceTile(title: choice.title, identifier: "typeface-\(choice.rawValue)",
                                             isSelected: choice == selected, isLocked: locked) {
                            if locked { purchase = true } else { store.configure(typeface: choice) }
                        } canvas: {
                            Palette.surface.overlay {
                                // The same phrase in every tile, so the faces compare letter for letter.
                                Text(verbatim: "bring up").font(choice.font(size: 30)).foregroundStyle(Palette.ink)
                                    .lineLimit(1).minimumScaleFactor(0.5).padding(.horizontal, Spacing.sm)
                            }
                        }
                    }
                }.accessibilityIdentifier("typefaceGrid")
                if !purchases.hasFullAccess {
                    ProAppearanceNote(text: "New York and SF Pro are free. Every font opens with Izzy Pro.") { purchase = true }
                }
                Divider()
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text(verbatim: selected.title).font(Typography.section).accessibilityAddTraits(.isHeader)
                    VStack(spacing: Spacing.lg) {
                        Text(verbatim: "bring up").font(selected.font(size: 48)).tracking(48 * selected.displayTracking)
                            .lineLimit(1).minimumScaleFactor(0.6)
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            ForEach(["a blessing in disguise", "get across"], id: \.self) { sample in
                                Text(verbatim: sample).font(selected.font(.title2))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }.foregroundStyle(Palette.ink).padding(Spacing.lg).frame(maxWidth: .infinity)
                        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.medium))
                        .accessibilityElement(children: .combine)
                        .accessibilityIdentifier("typefacePreview")
                }
            }
        }.navigationTitle("Phrase font").navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $purchase) { PurchaseView(from: "font") }
            .closesForReviewRequest($purchase)
    }
}

/// A tertiary line that says what's free and opens the purchase screen.
private struct ProAppearanceNote: View {
    let text: LocalizedStringKey
    let open: () -> Void
    var body: some View {
        Button(action: open) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Image(systemName: "lock").accessibilityHidden(true)
                Text(text).multilineTextAlignment(.leading).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).accessibilityHidden(true)
            }.font(.subheadline).foregroundStyle(Palette.secondary).frame(minHeight: 44).contentShape(Rectangle())
        }.buttonStyle(PressStyle()).accessibilityIdentifier("appearanceUnlockPro")
    }
}

private struct AppearanceChoiceTile<Canvas: View>: View {
    let title: String
    let identifier: String
    let isSelected: Bool
    let isLocked: Bool
    var aspect: CGFloat = 4.0 / 3.0
    let select: () -> Void
    @ViewBuilder var canvas: Canvas
    @Environment(\.appAccent) private var accent

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: Spacing.xs) {
                // The canvas, not its content, determines every tile's dimensions.
                Color.clear.aspectRatio(aspect, contentMode: .fit)
                    .overlay { canvas }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.medium))
                    .overlay {
                        RoundedRectangle(cornerRadius: Radius.medium).strokeBorder(Palette.outline, lineWidth: 1)
                    }
                    .overlay(alignment: .topTrailing) {
                        Image(systemName: isLocked ? "lock.fill" : isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: isLocked ? 15 : 21, weight: .semibold))
                            .frame(width: 21, height: 21)
                            .foregroundStyle(isSelected ? accent.color : Palette.secondary)
                            .padding(6).background(Palette.paper, in: Circle()).padding(Spacing.xs)
                    }
                Text(LocalizedStringKey(title)).font(.subheadline.weight(.medium))
                    .lineLimit(2, reservesSpace: true).multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading).foregroundStyle(Palette.ink)
            }.contentShape(Rectangle())
        }.buttonStyle(PressStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(LocalizedStringKey(title)))
            .accessibilityValue(isLocked ? Text("Izzy Pro") : Text(verbatim: ""))
            .accessibilityIdentifier(identifier)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

extension TodayBackground {
    /// A solid tone per appearance for the colors; nil for the scenes, which are images.
    /// Every tone keeps secondary text at 4.5:1 or more in both appearances.
    var color: Color? {
        switch self {
        case .mono: Palette.adaptive(0xFFFFFF, 0x000000)
        case .gray: Palette.adaptive(0xEBEBEB, 0x333333)
        case .ecru: Palette.adaptive(0xF3EEE3, 0x1C1A16)
        case .slate: Palette.adaptive(0xE4E8ED, 0x1A1E23)
        default: nil
        }
    }

    var credit: String? {
        switch self {
        case .mono, .gray, .ecru, .slate: nil
        case .mountains: "Photo by m wrona · Unsplash"
        case .ocean: "Photo by Hannah Reding · Unsplash"
        case .waterLilies: "Claude Monet, Water Lilies, 1906\nArt Institute of Chicago"
        case .forest: "Photo by Todd Aarnes · Unsplash"
        case .lake: "Photo by Andrew Svk · Unsplash"
        case .dunes: "Photo by Simon Schwyter · Unsplash"
        case .hills: "Photo by Ricardo Gomez Angel · Unsplash"
        case .clouds: "Photo by Billy Huynh · Unsplash"
        case .london: "Photo by Ming Han Low · Unsplash"
        case .unitedStates: "Photo by Julius Drost · Unsplash"
        case .australia: "Photo by Kay · Unsplash"
        case .canada: "Photo by Alice Triquet · Unsplash"
        }
    }

    var sourceURL: URL? {
        switch self {
        case .mono, .gray, .ecru, .slate: nil
        case .mountains: URL(string: "https://unsplash.com/photos/JG7KBXn-_Mc")!
        case .ocean: URL(string: "https://unsplash.com/photos/yVl4V7dUS2Y")!
        case .waterLilies: URL(string: "https://commons.wikimedia.org/wiki/File:Claude_Monet_-_Water_Lilies_-_1906,_Ryerson.jpg")!
        case .forest: URL(string: "https://unsplash.com/photos/wmFTP3vbYKU")!
        case .lake: URL(string: "https://unsplash.com/photos/9lLcLf490nM")!
        case .dunes: URL(string: "https://unsplash.com/photos/mK5OE9bgg1Q")!
        case .hills: URL(string: "https://unsplash.com/photos/tNYTM5_Fpes")!
        case .clouds: URL(string: "https://unsplash.com/photos/v9bnfMCyKbg")!
        case .london: URL(string: "https://unsplash.com/photos/iSYP6IWD-5k")!
        case .unitedStates: URL(string: "https://unsplash.com/photos/sf8b4ucpdkg")!
        case .australia: URL(string: "https://unsplash.com/photos/Gpgcc_Z2p_g")!
        case .canada: URL(string: "https://unsplash.com/photos/HeEJU3nrg_0")!
        }
    }
}
