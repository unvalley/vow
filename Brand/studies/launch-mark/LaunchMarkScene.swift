import SceneKit

/// The icon's mark as a solid, so a launch cover can turn it in depth instead of spinning a picture.
/// `make_launch_mark.swift` builds `LaunchMark.scn` and renders its resting pose into the `LaunchMark`
/// image, so the launch screen's still and the scene that takes over from it are the same picture.
enum LaunchMarkScene {
    /// Side of the square the scene's camera is framed for, in points. The mark spans about 120 of them;
    /// the margin keeps the solid inside the frame at every angle of its turn.
    static let side: CGFloat = 240
    static let markName = "mark"
    /// The turn's axis, square to the mark's own slant: the near side sweeps up and to the right,
    /// the way the form already leans.
    static let axis = simd_normalize(SIMD3<Float>(-0.45, 1, 0))

    static func load() -> SCNScene? { SCNScene(named: "LaunchMark.scn") }
}
