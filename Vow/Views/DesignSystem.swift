import SwiftUI

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

enum Palette {
    static let paper = Color(uiColor: .systemBackground)
    static let ink = Color.primary
    static let secondary = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.68, green: 0.68, blue: 0.70, alpha: 1) : UIColor(red: 0.37, green: 0.37, blue: 0.40, alpha: 1) })
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let charcoal = Color(hex: 0x101114)
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

extension AppAccent {
    private var lightHex: UInt32 {
        switch self {
        case .black: 0x171717
        case .blue: 0x005CCC
        case .green: 0x23733C
        case .yellow: 0x806000
        case .pink: 0xB52B68
        case .orange: 0xA84510
        case .purple: 0x713BCC
        }
    }
    private var darkHex: UInt32 {
        switch self {
        case .black: 0xF5F5F5
        case .blue: 0x78B8FF
        case .green: 0x76D991
        case .yellow: 0xF3D65A
        case .pink: 0xFF91C1
        case .orange: 0xFFAA72
        case .purple: 0xC6A1FF
        }
    }
    var color: Color {
        let light = lightHex, dark = darkHex
        return Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, alpha: 1)
        })
    }
    /// Dark fills retain white-label contrast, including yellow and orange.
    var fill: Color { Color(hex: lightHex) }
}

private struct AppAccentKey: EnvironmentKey { static let defaultValue = AppAccent.black }
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

struct PressStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    @Environment(\.appAccent) private var accent
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: Spacing.sm) {
                Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol).font(.body.weight(.semibold)).accessibilityHidden(true)
                }
            }
                .padding(.horizontal, Spacing.lg).padding(.vertical, Spacing.md)
                .foregroundStyle(.white).background(accent.fill, in: RoundedRectangle(cornerRadius: 22))
        }.buttonStyle(PressStyle())
    }
}

struct Eyebrow: View {
    let text: String
    var body: some View { Text(text.uppercased()).font(.caption2.weight(.semibold)).tracking(2).foregroundStyle(Palette.secondary) }
}

struct SectionTitle: View {
    let title: String
    var trailing: String? = nil
    var body: some View { HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) { Text(title).font(.title3.weight(.semibold)); Spacer(); if let trailing { Text(trailing).font(.caption).foregroundStyle(Palette.secondary) } } }
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
            Text(scene.subtitle).font(.system(.title2, design: .serif)).fixedSize(horizontal: false, vertical: true)
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
    var body: some View {
        Image(systemName: "checkmark").font(.system(size: 30, weight: .medium))
            .foregroundStyle(accent.color).frame(width: 80, height: 80)
            .background(accent.color.opacity(0.08), in: Circle()).accessibilityHidden(true)
    }
}
