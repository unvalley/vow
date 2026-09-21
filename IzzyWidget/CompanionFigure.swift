import SwiftUI
import WidgetKit

/// How the figure stands. The icon gets its character from how its letters tilt and bounce rather
/// than from any drawn face, so a pose is the whole vocabulary here: nothing is added that would
/// have to mean something.
struct CompanionPose: Equatable {
    /// Degrees the stem leans from upright, swinging from its foot. Positive leans forward.
    var lean: Double
    /// Extra distance between stem and dot, as a fraction of the figure's size: the dot leaving the ground.
    var lift: Double
    /// How far the dot drifts off the stem's axis, as a fraction of the figure's size.
    var drift: Double
    /// Stem length against its resting length. Under one it reads as a squash, over one as a stretch.
    var squash: Double

    static func pose(for mood: CompanionMood) -> CompanionPose {
        switch mood {
        case .fresh: CompanionPose(lean: 0, lift: 0, drift: 0, squash: 1)
        case .resting: CompanionPose(lean: -7, lift: 0, drift: 0.01, squash: 1)
        case .working: CompanionPose(lean: 9, lift: 0.03, drift: 0.02, squash: 0.96)
        case .celebrating: CompanionPose(lean: 14, lift: 0.12, drift: 0.06, squash: 0.84)
        case .urging: CompanionPose(lean: -16, lift: 0.015, drift: -0.035, squash: 1.02)
        case .lapsed: CompanionPose(lean: -27, lift: -0.02, drift: -0.02, squash: 0.95)
        }
    }

    typealias Animatable = AnimatablePair<AnimatablePair<Double, Double>, AnimatablePair<Double, Double>>
    var animatable: Animatable {
        get { .init(.init(lean, lift), .init(drift, squash)) }
        set { lean = newValue.first.first; lift = newValue.first.second; drift = newValue.second.first; squash = newValue.second.second }
    }
}

/// A bold lowercase `i`: one stem and one dot, the letter the name starts from.
struct CompanionShape: Shape {
    var pose: CompanionPose

    /// Poses interpolate so a change between timeline entries reads as the figure moving, not swapping.
    var animatableData: CompanionPose.Animatable {
        get { pose.animatable }
        set { pose.animatable = newValue }
    }

    func path(in rect: CGRect) -> Path {
        // Proportions of the letter: a stem clearly taller than it is wide, under a dot a little
        // wider than the stem. The figure keeps clear of its box so the widest poses stay inside.
        let side = min(rect.width, rect.height) * 0.80
        let stemWidth = side * 0.27
        let stemHeight = side * 0.62 * pose.squash
        let dotRadius = side * 0.15
        let lean = pose.lean * .pi / 180
        // Built around the foot, which everything else swings from.
        var path = Path()
        let stem = Path(roundedRect: CGRect(x: -stemWidth / 2, y: -stemHeight, width: stemWidth, height: stemHeight),
                        cornerSize: CGSize(width: stemWidth * 0.45, height: stemWidth * 0.45), style: .continuous)
        path.addPath(stem, transform: CGAffineTransform(rotationAngle: lean))
        // The dot keeps the stem's axis and then drifts; that drift is what reads as a leap or a stumble.
        let reach = stemHeight + side * 0.055 + dotRadius + side * pose.lift
        let center = CGPoint(x: sin(lean) * reach + side * pose.drift, y: -cos(lean) * reach)
        path.addEllipse(in: CGRect(x: center.x - dotRadius, y: center.y - dotRadius,
                                   width: dotRadius * 2, height: dotRadius * 2))
        // Sideways, the pose is centered on what it actually occupies, so leaning never pushes the
        // figure off its box. Vertically the foot keeps one height for every pose, so a lifted dot
        // rises instead of sliding the stem down to meet it, and a toppled one really does sit lower.
        let bounds = path.boundingRect
        return path.applying(CGAffineTransform(translationX: rect.midX - bounds.midX,
                                               y: rect.midY + side * 0.4875))
    }
}

struct CompanionFigure: View {
    let mood: CompanionMood
    let accent: AppAccent

    /// A lapsed streak drains the accent out of the figure; every other pose keeps the learner's color.
    private var tint: Color { mood == .lapsed ? Palette.secondary : accent.fill }

    var body: some View {
        CompanionShape(pose: .pose(for: mood))
            .fill(tint)
            .animation(Motion.snappy, value: mood)
            // Tinted home screens desaturate a widget to one color; the figure is what should keep
            // it, so the text around it steps back the way it does in the app.
            .widgetAccentable()
            .accessibilityHidden(true)
    }
}
