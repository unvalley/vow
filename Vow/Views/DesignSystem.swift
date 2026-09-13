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
    static let paper = adaptive(0xFAFAF9, 0x141414)
    static let ink = adaptive(0x202020, 0xF2F2F0)
    static let secondary = adaptive(0x686866, 0xA5A5A0)
    static let surface = adaptive(0xF0F0ED, 0x252525)
    static let charcoal = Color(hex: 0x202020)
    static let recording = adaptive(0xBB3038, 0xFF9399)
}

/// New York gives vocabulary its voice; SF keeps reading and controls quiet.
/// Semantic styles retain Dynamic Type, optical sizing, and system language fallback.
enum Typography {
    static func featured(size: CGFloat) -> Font { .system(size: size, weight: .regular, design: .serif) }
    static let phrase = Font.system(.largeTitle, design: .serif)
    static let phraseRow = Font.system(.title2, design: .serif)
    static let compactPhrase = Font.system(.title3, design: .serif)
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
    static let xxl: CGFloat = 48
    static let hero: CGFloat = 64
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
    var color: Color {
        switch self {
        case .black: Palette.ink
        case .blue: Palette.adaptive(0x3155D9, 0x91A8FF)
        case .green: Palette.adaptive(0x287447, 0x8AD4A3)
        case .yellow: Palette.adaptive(0x806000, 0xF3D65A)
        case .pink: Palette.adaptive(0xB32F70, 0xF59BC4)
        case .orange: Palette.adaptive(0xB34B20, 0xFFAA80)
        case .purple: Palette.adaptive(0x7545BB, 0xC7A3F0)
        }
    }
    /// Filled selection surfaces can be vivid without forcing white text on yellow.
    var fill: Color {
        switch self {
        case .yellow: Palette.adaptive(0xF3CF4A, 0xF3D65A)
        default: color
        }
    }
    var onFill: Color { self == .yellow ? Palette.charcoal : Palette.paper }
    var soft: Color { fill.opacity(0.12) }
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
    private var reduceMotion: Bool { MotionPreference.reduce(systemReduceMotion) }
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title).font(Typography.control).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol).font(.body.weight(.semibold)).accessibilityHidden(true)
                }
            }
                .padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.md)
                .foregroundStyle(Palette.paper).background(Palette.ink, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(PressStyle())
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text).font(Typography.metadata).foregroundStyle(Palette.secondary) }
}

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil
    var body: some View { HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) { Text(title).font(Typography.section); Spacer(); if let trailing { Text(trailing).font(.caption).foregroundStyle(Palette.secondary) } } }
}

/// An original drawing: one continuous thought finding its way into speech.
/// Geometry is static; no timer or perpetual animation runs behind reading content.
struct ThreadArtwork: View {
    var style = 0
    var body: some View {
        Canvas { context, size in
            let w = size.width, h = size.height
            for i in 0..<26 {
                let t = Double(i) / 25
                var path = Path()
                switch style % 4 {
                case 0:
                    path.move(to: CGPoint(x: -w * 0.12, y: h * (0.3 + t * 0.4)))
                    path.addCurve(to: CGPoint(x: w * 1.1, y: h * (0.32 + t * 0.14)), control1: CGPoint(x: w * 0.5, y: -h * (0.55 - t * 0.3)), control2: CGPoint(x: w * 0.38, y: h * (1.6 - t * 0.7)))
                case 1:
                    path.addEllipse(in: CGRect(x: w * (0.12 + t * 0.25), y: h * (0.12 + t * 0.13), width: w * 0.43, height: h * 0.66))
                case 2:
                    path.move(to: CGPoint(x: w * 0.05, y: h * (0.85 - t * 0.4)))
                    path.addCurve(to: CGPoint(x: w * 0.95, y: h * (0.15 + t * 0.4)), control1: CGPoint(x: w * 0.7, y: h * 0.9), control2: CGPoint(x: w * 0.22, y: h * 0.1))
                default:
                    path.addEllipse(in: CGRect(x: w * (0.1 + t * 0.18), y: h * (0.18 + t * 0.13), width: w * (0.8 - t * 0.36), height: h * (0.64 - t * 0.26)))
                }
                context.stroke(path, with: .linearGradient(Gradient(colors: [Palette.ink.opacity(0.7), Palette.ink.opacity(0.2)]), startPoint: .zero, endPoint: CGPoint(x: w, y: h)), lineWidth: 1.6)
            }
        }.clipped().accessibilityHidden(true)
    }
}

struct SceneTile: View {
    let scene: Scene
    let index: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: Spacing.sm) { Image(systemName: scene.symbol).font(.body); Spacer(); Image(systemName: "arrow.up.right").font(.caption) }
            Spacer(minLength: Spacing.xl)
            Text(scene.subtitle).font(Typography.phraseRow).fixedSize(horizontal: false, vertical: true)
        }.padding(Spacing.lg).frame(maxWidth: .infinity, minHeight: 168, alignment: .leading).foregroundStyle(Palette.ink)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
            .contentShape(RoundedRectangle(cornerRadius: 24))
    }
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
            .opacity(appeared || reduceMotion ? 1 : 0)
            .onAppear { withAnimation(reduceMotion ? nil : .easeOut(duration: 0.24)) { appeared = true } }
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

/// Saving stays local to the tapped control, with a short cross-fade and haptic.
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
            ZStack {
                Image(systemName: "bookmark").opacity(saved ? 0 : 1)
                Image(systemName: "bookmark.fill").opacity(saved ? 1 : 0)
            }.frame(width: 48, height: 48)
                .foregroundStyle(saved ? accent.color : Palette.ink)
                .background(saved ? accent.soft : Color.clear, in: Circle())
                .animation(reduceMotion ? nil : .easeOut(duration: 0.18), value: saved)
        }.buttonStyle(PressStyle())
            .sensoryFeedback(.selection, trigger: saved)
            .accessibilityLabel(saved ? (featured ? "Unsave featured phrase" : "Unsave phrase") : (featured ? "Save featured phrase" : "Save phrase"))
    }
}
