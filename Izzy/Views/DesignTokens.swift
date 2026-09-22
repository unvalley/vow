// Colors, type, spacing, radii and motion: the tokens every surface shares. Separate from the
// rest of the design system because the widget extension compiles this file too, while the
// rest of DesignSystem.swift needs the app's phrases and store.
import SwiftUI

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

enum Palette {
    static func adaptive(_ light: UInt32, _ dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, alpha: 1)
        })
    }
    // Neutrals carry no hue (OKLCH chroma 0), so text and surfaces read the same next to any accent.
    static let paper = adaptive(0xFAFAFA, 0x141414)
    static let ink = adaptive(0x202020, 0xF2F2F2)
    static let secondary = adaptive(0x686868, 0xA5A5A5)
    static let surface = adaptive(0xF0F0F0, 0x252525)
    /// Image edges: pure black or white at 10%, never a tinted gray.
    static let outline = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(white: 1, alpha: 0.1) : UIColor(white: 0, alpha: 0.1) })
}

/// New York gives vocabulary its voice; SF keeps reading and controls quiet.
/// Semantic styles retain Dynamic Type, optical sizing, and system language fallback.
enum Typography {
    static let phrase = Font.system(.largeTitle, design: .serif)
    static let phraseRow = Font.system(.title2, design: .serif)
    static let family = Font.system(.title, design: .serif)
    static let meaning = Font.system(.body).leading(.loose)
    static let example = Font.system(.body).leading(.loose)
    static let section = Font.system(.subheadline, weight: .medium)
    static let control = Font.system(.subheadline, weight: .medium)
    static let context = Font.system(.caption, weight: .medium)
    static let metadata = Font.system(.caption)
    static let counter = Font.system(.largeTitle, weight: .regular).monospacedDigit()
}

/// All layout gaps and insets follow a four-point scale. Sizes and drawing coordinates are separate.
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
}

/// Four radii. Nested shapes stay concentric: outer radius = inner radius + the padding between them.
enum Radius {
    /// Cells, small tiles and the calendar's today mark.
    static let small: CGFloat = 12
    /// Inputs, rating cells, option tiles, links and inline cards.
    static let medium: CGFloat = 18
    /// Cards, sheets' content blocks and buttons.
    static let large: CGFloat = 24
}

/// Springs without bounce, short enough to stay out of the way. Exits are quieter than entrances.
enum Motion {
    /// State changes the learner caused: selection pills, icon swaps, card moves.
    static let snappy = Animation.spring(duration: 0.3, bounce: 0)
    /// Rare entrances: completion, onboarding and purchase content.
    static let entrance = Animation.spring(duration: 0.5, bounce: 0)
    /// With Reduce Motion, only a short fade remains.
    static let reducedFade = Animation.easeOut(duration: 0.15)
}

extension AppTheme {
    var colorScheme: ColorScheme? {
        switch self {
        case .light: .light
        case .dark: .dark
        case .system: nil
        }
    }
}

extension AppAccent {
    /// Text in the accent: selected labels, highlighted phrases, focus text. On light, each hue is the lightest
    /// OKLCH shade (chroma at 95% of what sRGB allows) that stays at least 4.5:1 on paper, surface and its own
    /// soft fill over either; dark keeps L 0.80. See docs/DESIGN-SYSTEM.md.
    var color: Color {
        switch self {
        // Black is the default, and it is the ink token: graphite on the light theme, near-white on the dark one.
        case .black: Palette.ink
        case .blue: Palette.adaptive(0x2C4EF8, 0xA2BCFC)
        case .green: Palette.adaptive(0x117340, 0x7CD49A)
        case .yellow: Palette.adaptive(0x7C5E0E, 0xE0B85C)
        case .pink: Palette.adaptive(0xBB1670, 0xFB9DC2)
        case .orange: Palette.adaptive(0xAC410F, 0xFCA584)
        case .purple: Palette.adaptive(0x8B1CF3, 0xC7AEFC)
        }
    }
    /// The accent itself, for areas: swatches, calendar cells and, at 12%, the soft backgrounds. On light it is
    /// brighter than the text shade, the lightest that keeps 3:1 on paper; yellow stays a true yellow.
    var fill: Color {
        switch self {
        case .black: Palette.ink
        case .blue: Palette.adaptive(0x5C84F9, 0xA2BCFC)
        case .green: Palette.adaptive(0x1B9F5B, 0x7CD49A)
        case .yellow: Palette.adaptive(0xF3CF4A, 0xE0B85C)
        case .pink: Palette.adaptive(0xFB389C, 0xFB9DC2)
        case .orange: Palette.adaptive(0xEC5C19, 0xFCA584)
        case .purple: Palette.adaptive(0xA56DFA, 0xC7AEFC)
        }
    }
    /// Icons, strokes, switches and dots: the fill wherever it keeps 3:1 on paper, and a deeper yellow where it cannot.
    var mark: Color {
        switch self {
        case .yellow: Palette.adaptive(0xAE8418, 0xE0B85C)
        default: fill
        }
    }
    var soft: Color { fill.opacity(0.12) }
}

extension PhraseTypeface {
    /// PostScript name for the faces that aren't a system design.
    private var fontName: String? {
        switch self {
        case .newYork, .sfPro, .rounded: nil
        case .georgia: "Georgia"
        case .palatino: "Palatino-Roman"
        case .baskerville: "Baskerville"
        case .charter: "Charter-Roman"
        case .didot: "Didot"
        case .avenir: "AvenirNext-Regular"
        case .typewriter: "AmericanTypewriter"
        }
    }
    private var design: Font.Design {
        switch self {
        case .sfPro: .default
        case .rounded: .rounded
        default: .serif
        }
    }
    /// Follows Dynamic Type from the style's default size.
    func font(_ style: Font.TextStyle) -> Font {
        guard let fontName else { return .system(style, design: design) }
        let size: CGFloat = switch style {
        case .largeTitle: 34
        case .title: 28
        case .title2: 22
        case .title3: 20
        default: 17
        }
        return .custom(fontName, size: size, relativeTo: style)
    }
    /// An already scaled size, as Home's featured phrase uses.
    func font(size: CGFloat) -> Font {
        guard let fontName else { return .system(size: size, weight: .regular, design: design) }
        return .custom(fontName, fixedSize: size)
    }
    /// Display tracking tuned per face: the wide faces open up less.
    var displayTracking: CGFloat {
        switch self {
        case .typewriter, .avenir, .didot: -0.008
        default: -0.018
        }
    }
}
