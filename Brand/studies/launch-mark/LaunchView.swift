import SceneKit
import SwiftUI

/// Picks up where the static launch screen leaves off: the same mark on the same black, now a solid,
/// given one turn in depth while Home lays itself out underneath.
struct LaunchView: View {
    /// Called once the turn has settled, or at once when there is no turn to show.
    let onFinished: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var scene: SCNScene?
    @State private var turning = false
    var body: some View {
        ZStack {
            Color("LaunchBackground")
            // Unscaled, so it sits exactly over the launch screen's copy of the mark. It is the scene's own
            // resting pose, and holds the screen until the solid above it starts to move.
            Image("LaunchMark").opacity(turning ? 0 : 1)
            if let scene {
                LaunchMarkView(scene: scene, onTurn: { turning = true }, onSettled: onFinished)
                    .frame(width: LaunchMarkScene.side, height: LaunchMarkScene.side)
            }
        }
        // The launch screen centres the mark on the whole screen, not on the safe area.
        .ignoresSafeArea()
        .accessibilityHidden(true)
        .task {
            // With Reduce Motion the mark stays still, so there is nothing to wait for.
            guard !reduceMotion, let loaded = LaunchMarkScene.load() else { return onFinished() }
            scene = loaded
            // Home must not wait on a renderer that never draws.
            guard (try? await Task.sleep(for: .seconds(3))) != nil else { return }
            onFinished()
        }
    }
}

private struct LaunchMarkView: UIViewRepresentable {
    let scene: SCNScene
    let onTurn: @MainActor () -> Void
    let onSettled: @MainActor () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(scene: scene, onTurn: onTurn, onSettled: onSettled) }
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = .clear
        view.antialiasingMode = .multisampling4X
        view.isUserInteractionEnabled = false
        view.rendersContinuously = true
        view.scene = scene
        view.delegate = context.coordinator
        return view
    }
    func updateUIView(_ view: SCNView, context: Context) {}

    @MainActor final class Coordinator: NSObject, SCNSceneRendererDelegate {
        /// The system cross-fades its launch snapshot away over the first frames.
        /// Turning under that fade shows the mark twice, so the turn waits it out.
        private static let handOff = 0.25
        private let scene: SCNScene
        private let onTurn: @MainActor () -> Void, onSettled: @MainActor () -> Void
        private let appeared = Date.now
        private var drawn = false

        init(scene: SCNScene, onTurn: @escaping @MainActor () -> Void, onSettled: @escaping @MainActor () -> Void) {
            self.scene = scene
            self.onTurn = onTurn
            self.onSettled = onSettled
        }

        nonisolated func renderer(_ renderer: any SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
            Task { @MainActor in self.firstFrameDrawn() }
        }

        /// The still underneath may only go once the solid is really on screen in its place.
        private func firstFrameDrawn() {
            guard !drawn else { return }
            drawn = true
            Task {
                try? await Task.sleep(for: .seconds(max(0, Self.handOff - Date.now.timeIntervalSince(appeared))))
                onTurn()
                scene.rootNode.childNode(withName: LaunchMarkScene.markName, recursively: false)?.runAction(Self.turn) {
                    Task { @MainActor in self.onSettled() }
                }
            }
        }

        /// One full turn on a spring: from rest, round, and a small overshoot so the inflated form lands with some weight.
        private static var turn: SCNAction {
            let period = 1.0, damping = 0.8, axis = LaunchMarkScene.axis
            let frequency = 2 * Double.pi / period, ringing = frequency * (1 - damping * damping).squareRoot()
            return .customAction(duration: period) { node, elapsed in
                let t = Double(elapsed)
                let remaining = exp(-damping * frequency * t) * (cos(ringing * t) + damping * frequency / ringing * sin(ringing * t))
                // A spring's tail is a second of nothing to see. The last third eases what is left of it away,
                // so the turn ends at rest, exactly round, while it still reads as one movement.
                let tail = min(max((t / period - 0.67) / 0.33, 0), 1)
                let turned = 1 - remaining * (1 - tail * tail * (3 - 2 * tail))
                node.rotation = SCNVector4(axis.x, axis.y, axis.z, Float(turned * 2 * .pi))
            }
        }
    }
}
