import SwiftUI

extension Color {
    init(hex: UInt32) { self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1) }
}

enum Palette {
    static let paper = Color(uiColor: .systemBackground)
    static let ink = Color.primary
    static let secondary = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.68, green: 0.68, blue: 0.70, alpha: 1) : UIColor(red: 0.37, green: 0.37, blue: 0.40, alpha: 1) })
    static let surface = Color(uiColor: .secondarySystemBackground)
    static let accent = Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? UIColor(red: 0.30, green: 0.65, blue: 1, alpha: 1) : UIColor(red: 0, green: 0.36, blue: 0.80, alpha: 1) })
    static let charcoal = Color(hex: 0x101114)
    static let action = Color(hex: 0x005CCC)
    static let artwork = [Color(hex: 0x1877F2), Color(hex: 0x4AA3FF), Color(hex: 0xB8DFFF)]
    static func scene(_ id: String) -> Color {
        switch id { case "work": Color(hex: 0xEAF2FF); case "connect": Color(hex: 0xF2F4F7); case "plans": Color(hex: 0xDCEBFF); default: Color(hex: 0xE8EDF5) }
    }
}

/// Static color washes leave the center quiet for reading.
struct ReadingBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        GeometryReader { proxy in
            let dark = colorScheme == .dark
            let edge = Color(hex: dark ? 0x172C43 : 0xDCEBFA)
            ZStack {
                Color(hex: dark ? 0x111820 : 0xF3F7FC)
                RadialGradient(colors: [edge, .clear], center: .bottomLeading, startRadius: 0, endRadius: max(proxy.size.width, proxy.size.height) * 0.8)
                RadialGradient(colors: [edge.opacity(0.8), .clear], center: .topTrailing, startRadius: 0, endRadius: max(proxy.size.width, proxy.size.height) * 0.6)
                RadialGradient(colors: [Color.white.opacity(dark ? 0 : 0.85), .clear], center: .center, startRadius: 0, endRadius: max(proxy.size.width, proxy.size.height) * 0.55)
            }
        }.ignoresSafeArea().allowsHitTesting(false).accessibilityHidden(true)
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
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    let title: String
    var symbol: String = "arrow.right"
    var action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title).font(.headline).fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if !dynamicTypeSize.isAccessibilitySize {
                    Image(systemName: symbol).font(.body.weight(.semibold)).accessibilityHidden(true)
                }
            }
                .padding(.horizontal, 22).padding(.vertical, 19)
                .foregroundStyle(.white).background(Palette.action, in: RoundedRectangle(cornerRadius: 22))
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
    var body: some View { HStack(alignment: .firstTextBaseline) { Text(title).font(.title3.weight(.semibold)); Spacer(); if let trailing { Text(trailing).font(.caption).foregroundStyle(Palette.secondary) } } }
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
                context.stroke(path, with: .linearGradient(Gradient(colors: Palette.artwork), startPoint: .zero, endPoint: CGPoint(x: w, y: h)), lineWidth: 1.6)
            }
        }.clipped().accessibilityHidden(true)
    }
}

struct SceneTile: View {
    let scene: Scene
    let index: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack { Image(systemName: scene.symbol).font(.body); Spacer(); Image(systemName: "arrow.up.right").font(.caption) }
            Spacer(minLength: 32)
            Text(scene.subtitle).font(.system(.title2, design: .serif)).fixedSize(horizontal: false, vertical: true)
        }.padding(22).frame(maxWidth: .infinity, minHeight: 168, alignment: .leading).foregroundStyle(Palette.charcoal)
            .background(Palette.scene(scene.id), in: RoundedRectangle(cornerRadius: 24))
            .contentShape(RoundedRectangle(cornerRadius: 24))
    }
}

struct PaperPage<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View { ScrollView { content.frame(maxWidth: 680).padding(.horizontal, 24).padding(.top, 16).padding(.bottom, 32).frame(maxWidth: .infinity) }.scrollDismissesKeyboard(.interactively).background { ReadingBackground() } }
}

struct CompletionMark: View {
    var body: some View {
        Image(systemName: "checkmark").font(.system(size: 30, weight: .medium))
            .foregroundStyle(Palette.accent).frame(width: 80, height: 80)
            .background(Palette.accent.opacity(0.08), in: Circle()).accessibilityHidden(true)
    }
}
