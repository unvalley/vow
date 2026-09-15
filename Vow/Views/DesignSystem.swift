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
    static func featured(size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }
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
    /// Readable text, thin marks, focus rings, and selected tab labels.
    /// Every accent shares one OKLCH lightness per appearance (L 0.50 light, 0.80 dark) and keeps its hue;
    /// chroma is the lesser of 0.17 / 0.12 and 95% of what sRGB allows for that hue. Text in the accent
    /// stays at least 4.5:1 on paper and on its soft fill over paper or surface (the selection pills). See docs/DESIGN-SYSTEM.md.
    var color: Color {
        switch self {
        case .black: Palette.ink
        case .blue: Palette.adaptive(0x3759C3, 0xA2BCFC)
        case .green: Palette.adaptive(0x10703E, 0x7CD49A) // L 0.48: green's low chroma ceiling needs a step darker on surface
        case .yellow: Palette.adaptive(0x7C5E0E, 0xE0B85C)
        case .pink: Palette.adaptive(0xA72A68, 0xFB9DC2)
        case .orange: Palette.adaptive(0xA53E0E, 0xFCA584)
        case .purple: Palette.adaptive(0x7245B5, 0xC7AEFC)
        }
    }
    /// Filled selection surfaces can be vivid without forcing white text on yellow.
    var fill: Color {
        switch self {
        case .yellow: Palette.adaptive(0xF3CF4A, 0xE0B85C)
        default: color
        }
    }
    var soft: Color { fill.opacity(0.12) }
}

extension Color {
    /// WCAG relative luminance of the color as it resolves in `scheme`.
    func luminance(in scheme: ColorScheme) -> Double {
        let resolved = UIColor(self).resolvedColor(with: UITraitCollection(userInterfaceStyle: scheme == .dark ? .dark : .light))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
        func channel(_ value: CGFloat) -> Double {
            let v = Double(value)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }
}

extension AppAccent {
    /// Ink or paper, whichever reads better on this accent fill laid over paper at `alpha`.
    /// The accent is the learner's choice, so the text color follows the fill instead of assuming one.
    func readableText(onFillAlpha alpha: Double, scheme: ColorScheme) -> Color {
        let blended = alpha * fill.luminance(in: scheme) + (1 - alpha) * Palette.paper.luminance(in: scheme)
        func contrast(_ color: Color) -> Double {
            let other = color.luminance(in: scheme)
            return (max(blended, other) + 0.05) / (min(blended, other) + 0.05)
        }
        return contrast(Palette.ink) >= contrast(Palette.paper) ? Palette.ink : Palette.paper
    }
}

private struct AppAccentKey: EnvironmentKey { static let defaultValue = AppAccent.blue }
extension EnvironmentValues {
    var appAccent: AppAccent {
        get { self[AppAccentKey.self] }
        set { self[AppAccentKey.self] = newValue }
    }
}

struct ReadingBackground: View {
    var body: some View {
        Palette.paper.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// System preference in production; a DEBUG-only override makes the same
/// animation branches reproducible in simulator UI tests.
enum MotionPreference {
    static func reduce(_ systemPreference: Bool) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--design-reduce-motion") { return true }
        #endif
        return systemPreference
    }
}

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.isEnabled) private var isEnabled
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    /// Off where the control shows its own disabled state (the rating grid keeps the chosen answer bright).
    var dimsWhenDisabled = true
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled || !dimsWhenDisabled ? 1 : DisabledStyle.opacity)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// Press feedback for full-width rows, where shrinking the whole row would look like it moved:
/// a surface wash behind the row instead. It reaches a little past the row so text stays aligned.
struct RowPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: Radius.small)
                    .fill(Palette.surface.opacity(configuration.isPressed ? 1 : 0))
                    .padding(.horizontal, -Spacing.xs)
            }
    }
}

struct HitRect: Shape {
    var dx: CGFloat
    var dy: CGFloat
    func path(in rect: CGRect) -> Path { Path(rect.insetBy(dx: -dx, dy: -dy)) }
}

/// Disabled controls read the same everywhere.
enum DisabledStyle { static let opacity = 0.45 }

extension View {
    /// Keeps the drawn size and lets touches land up to `inset` points outside it (Jakub's pseudo-element hit area).
    func hitArea(_ inset: CGFloat) -> some View { contentShape(HitRect(dx: inset, dy: inset)) }
    /// For controls side by side with no gap: grow the target up and down only, so neighbors never overlap.
    func hitArea(vertical inset: CGFloat) -> some View { contentShape(HitRect(dx: 0, dy: inset)) }
}

/// Emphasis levels. A solid ink fill means one thing: the action that moves the learner forward
/// (`PrimaryButton`) — at most one per screen. Everything else steps down:
/// - Selected: `selectionSurface(true)` — accent soft fill and accent text for the chosen option among peers.
/// - Secondary: `SecondaryButton` or `selectionSurface(false)` — surface fill, ink text, for supporting actions.
/// - Tertiary: a plain `Button` or `Link` in `Typography.control` — inline actions and links.
/// Decorative icons are outline symbols in `Palette.secondary`; a filled symbol only reports state.
/// Media transport (play, pause, skip) keeps the platform's filled glyphs.
struct PrimaryButton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        let showsSymbol = !dynamicTypeSize.isAccessibilitySize
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title).font(Typography.control).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if showsSymbol {
                    Image(systemName: symbol).font(.body.weight(.semibold)).accessibilityHidden(true)
                }
            }
                // The icon side sits 4 pt tighter: a glyph's own side bearing already reads as space.
                .padding(.leading, Spacing.lg).padding(.trailing, showsSymbol ? Spacing.lg - 4 : Spacing.lg)
                .padding(.vertical, Spacing.md)
                .foregroundStyle(Palette.paper).background(Palette.ink, in: RoundedRectangle(cornerRadius: Radius.large))
        }.buttonStyle(PressStyle())
    }
}

/// Supporting action: surface fill, ink text. Never the loudest thing on the screen.
struct SecondaryButton: View {
    let title: String
    var symbol: String? = nil
    /// Set on the button itself: inside a List row an identifier on the wrapper view does not reach the button.
    var identifier: String? = nil
    var action: () -> Void
    var body: some View {
        if let identifier { button.accessibilityIdentifier(identifier) } else { button }
    }
    private var button: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                if let symbol { Image(systemName: symbol).accessibilityHidden(true) }
                Text(title).fixedSize(horizontal: false, vertical: true)
            }
            .font(Typography.control).frame(maxWidth: .infinity, minHeight: 44)
            .padding(.horizontal, Spacing.lg)
            .foregroundStyle(Palette.ink).background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.large))
        }.buttonStyle(PressStyle())
    }
}

/// The chosen option among peers: accent soft fill with accent text; surface (or a clear slot
/// inside a surface track) at rest. Shared by mode switches, option tiles and button-built pickers.
struct SelectionSurface: ViewModifier {
    @Environment(\.appAccent) private var accent
    let isSelected: Bool
    var cornerRadius: CGFloat
    var restFill: Color
    func body(content: Content) -> some View {
        content
            .foregroundStyle(isSelected ? accent.color : Palette.ink)
            .background(isSelected ? accent.soft : restFill, in: RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func selectionSurface(_ isSelected: Bool, cornerRadius: CGFloat = Radius.small, restFill: Color = Palette.surface) -> some View {
        modifier(SelectionSurface(isSelected: isSelected, cornerRadius: cornerRadius, restFill: restFill))
    }
}

/// Meaning of a phrase: the short English gloss first (look into → investigate), then the explanation.
/// Japanese explanations have no gloss and render as one line. `font` styles the lead; the
/// explanation steps down to the secondary color when a lead is present.
struct PhraseMeaning: View {
    let phrase: Phrase
    let language: MeaningLanguage
    var font: Font = Typography.meaning
    var detailFont: Font? = nil
    /// Lists show the gloss alone; the explanation waits for the detail screens.
    var leadOnly = false
    /// Color of the gloss, and of the explanation when there is no gloss. The explanation under a gloss is always secondary.
    var color: Color = Palette.ink
    var identifier: String? = nil
    var body: some View {
        let lead = phrase.lead(in: language)
        let explanation = phrase.explanation(in: language)
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            if let lead {
                Text(lead).font(font).foregroundStyle(color)
                if !leadOnly {
                    Text(explanation).font(detailFont ?? font).foregroundStyle(Palette.secondary)
                }
            } else {
                Text(explanation).font(font).foregroundStyle(color)
            }
        }.fixedSize(horizontal: false, vertical: true)
            .modifier(CombinedMeaningAccessibility(identifier: identifier,
                                                   label: lead.map { leadOnly ? $0 : "\($0). \(explanation)" } ?? explanation))
    }
}

/// Combines the meaning into one accessibility element only where a screen names it (identifier
/// given). Applying the combined element to every row of the Phrases list made the scroll view
/// open part-way down on iOS 26 (measured; see docs/VERIFICATION.md), so list rows stay plain.
private struct CombinedMeaningAccessibility: ViewModifier {
    let identifier: String?
    let label: String
    func body(content: Content) -> some View {
        if let identifier {
            content.accessibilityElement(children: .combine).accessibilityIdentifier(identifier).accessibilityLabel(label)
        } else {
            content
        }
    }
}

/// Label for an inline Menu that filters or sorts a list: small icon, short title, secondary color.
/// The font goes on the Text only: `.font` on the whole menu label makes a surrounding scroll view
/// open part-way down its list on iOS 26 (measured; see docs/VERIFICATION.md).
struct MenuControlLabel: View {
    let title: LocalizedStringKey
    let systemImage: String
    var font: Font = .subheadline
    var minHeight: CGFloat = 44
    var color: Color = Palette.secondary
    var body: some View {
        HStack(spacing: Spacing.xxs + 2) {
            Image(systemName: systemImage).imageScale(.small)
            Text(title).font(font).lineLimit(1)
        }.foregroundStyle(color).frame(minHeight: minHeight)
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text).font(Typography.metadata).foregroundStyle(Palette.secondary) }
}

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil
    var body: some View { HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) { Text(title).font(Typography.section).accessibilityAddTraits(.isHeader); Spacer(); if let trailing { Text(trailing).font(.caption.monospacedDigit()).foregroundStyle(Palette.secondary) } } }
}

struct PaperPage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { ScrollView { content.frame(maxWidth: 680).padding(.horizontal, Spacing.lg).padding(.top, Spacing.md).padding(.bottom, Spacing.xl).frame(maxWidth: .infinity) }.scrollDismissesKeyboard(.interactively).background { ReadingBackground() } }
}

struct CompletionMark: View {
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @State private var appeared = false
    var body: some View {
        Image(systemName: "checkmark").font(.system(size: 30, weight: .medium))
            .foregroundStyle(accent.color).frame(width: 80, height: 80)
            .background(accent.soft, in: Circle()).accessibilityHidden(true)
            .scaleEffect(appeared || reduceMotion ? 1 : 0.96)
            .blur(radius: appeared || reduceMotion ? 0 : 4)
            .opacity(appeared ? 1 : 0)
            .onAppear { withAnimation(reduceMotion ? Motion.reducedFade : Motion.entrance) { appeared = true } }
    }
}

/// A quiet progress track shared by the daily entry and its review session.
/// Only changes to the value animate; opening the screen never replays progress.
struct LearningProgressTrack: View {
    let completed: Int
    let total: Int
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }

    var body: some View {
        GeometryReader { geometry in
            Capsule().fill(Palette.secondary.opacity(0.16))
                .overlay(alignment: .leading) {
                    Capsule().fill(accent.color)
                        .frame(width: geometry.size.width * min(1, max(0, Double(completed) / Double(max(1, total)))))
                }
        }.frame(height: 4)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.24), value: completed)
            .accessibilityHidden(true)
    }
}

/// Saving stays local to the tapped control: the symbol swaps in place (scale, blur and fade) with a haptic.
struct SavePhraseButton: View {
    let phraseID: String
    var featured = false
    @Environment(LearningStore.self) private var store
    @Environment(\.appAccent) private var accent
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    private var saved: Bool { store.data.saved.contains(phraseID) }

    var body: some View {
        Button { store.toggleSaved(phraseID) } label: {
            Image(systemName: saved ? "bookmark.fill" : "bookmark")
                .contentTransition(reduceMotion ? .opacity : .symbolEffect(.replace))
                .frame(width: 48, height: 48)
                .foregroundStyle(saved ? accent.color : Palette.ink)
                .background(saved ? accent.soft : Color.clear, in: Circle())
                .animation(reduceMotion ? Motion.reducedFade : Motion.snappy, value: saved)
        }.buttonStyle(PressStyle())
            .sensoryFeedback(.selection, trigger: saved)
            .accessibilityLabel(saved ? (featured ? "Unsave featured phrase" : "Unsave phrase") : (featured ? "Save featured phrase" : "Save phrase"))
    }
}

/// A rare entrance: the block rises 8 pt out of a light blur, `index` steps after the first.
/// Only for screens seen once in a while (completion, onboarding, purchase); never for paging or rating.
struct StaggeredEntrance: ViewModifier {
    let index: Int
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    @State private var shown = false
    func body(content: Content) -> some View {
        content
            .opacity(shown ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 8)
            .blur(radius: shown || reduceMotion ? 0 : 6)
            .onAppear {
                guard !shown else { return }
                withAnimation(reduceMotion ? Motion.reducedFade : Motion.entrance.delay(Double(index) * 0.08)) { shown = true }
            }
    }
}

extension View {
    func staggeredEntrance(_ index: Int) -> some View { modifier(StaggeredEntrance(index: index)) }

    /// iOS 18 and later zoom a phrase from where it was tapped into its details; earlier systems push as before.
    @ViewBuilder func zoomSource(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) { matchedTransitionSource(id: id, in: namespace) } else { self }
    }
    @ViewBuilder func zoomDestination(id: String, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) { navigationTransition(.zoom(sourceID: id, in: namespace)) } else { self }
    }
}
