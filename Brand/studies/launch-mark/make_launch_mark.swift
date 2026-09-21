import AppKit
import SceneKit

// Builds the launch cover's solid mark and the still that matches it.
//
// The icon artwork is a raster with no model behind it. Seen face-on, though, it is a fat tube swept along a
// bent spine: two lobes joined by a neck. Fitting that silhouette to Izzy.icon/Assets/mark.png leaves 1% of
// the mark's area unexplained, and the spine and widths below are that fit. The solid is the set of balls
// along the spine, taken as a distance field, softened a little so that surfaces which all but coincide run
// into one another while the deep folds stay folds, and then meshed.
//
// Writes LaunchMark.scn (mark, lights, camera) and renders its resting pose into the LaunchMark image set, so
// the static launch screen and the scene that takes over from it are the same picture.
//
// Usage, from the repository root (the unoptimised interpreter takes minutes over the field):
//   swiftc -O Brand/studies/launch-mark/LaunchMarkScene.swift Brand/studies/launch-mark/make_launch_mark.swift -o .build/make_launch_mark
//   .build/make_launch_mark .build/LaunchMark.scn .build/launch-mark-stills .build/launch-mark-turn
// The third argument is optional and receives previews of the turn, one PNG every 45 degrees.
// README.md beside this file says where the outputs go if the study is adopted.

/// Spine points in units of the artwork's width, origin top-left, y down.
private let spine: [SIMD2<Float>] = [
    [0.2372, 0.5344], [0.2944, 0.4520], [0.4913, 0.3190], [0.5562, 0.3325], [0.5344, 0.4625],
    [0.5007, 0.4993], [0.4708, 0.6633], [0.5445, 0.6766], [0.7108, 0.5843], [0.7630, 0.5191],
]
/// Half-width across the spine, over its length 0...1: the lobes, and the neck that pinches in halfway.
private func halfWidth(at u: Float) -> Float { 0.1159 + 0.0021 * u - neck(at: u) }
/// Half-depth, which the face-on artwork cannot give. Its front runs through the neck at nearly full height,
/// the folds cut into it as grooves, so the neck keeps most of the depth it loses in width.
private func halfDepth(at u: Float) -> Float { 0.1159 + 0.0021 * u - 0.25 * neck(at: u) }
private func neck(at u: Float) -> Float { 0.0589 * exp(-pow((u - 0.5106) / 0.1148, 2)) }

private let cell: Float = 0.008
/// Softening of the field: enough to melt hairline creases, not enough to fill the folds.
private let softening: Float = 0.009
/// How dark the depths of a fold go.
private let foldShade: Float = 0.85

private struct Ball { var centre: SIMD2<Float>, halfWidth: Float, halfDepth: Float }

/// Centripetal Catmull-Rom through the spine, in scene space: centred, y up, one unit per artwork width.
private func balls(perSpan: Int) -> [Ball] {
    let points = spine.map { SIMD2<Float>($0.x - 0.5, 0.5 - $0.y) }
    func knot(_ t: Float, _ a: SIMD2<Float>, _ b: SIMD2<Float>) -> Float { t + max(simd_length(b - a), 1e-6).squareRoot() }
    var line: [SIMD2<Float>] = []
    for i in 0..<(points.count - 1) {
        let p1 = points[i], p2 = points[i + 1]
        let p0 = i == 0 ? p1 * 2 - p2 : points[i - 1]
        let p3 = i + 2 < points.count ? points[i + 2] : p2 * 2 - p1
        let t0: Float = 0, t1 = knot(t0, p0, p1), t2 = knot(t1, p1, p2), t3 = knot(t2, p2, p3)
        for step in 0..<perSpan {
            let t = t1 + (t2 - t1) * Float(step) / Float(perSpan)
            let a1 = p0 * ((t1 - t) / (t1 - t0)) + p1 * ((t - t0) / (t1 - t0))
            let a2 = p1 * ((t2 - t) / (t2 - t1)) + p2 * ((t - t1) / (t2 - t1))
            let a3 = p2 * ((t3 - t) / (t3 - t2)) + p3 * ((t - t2) / (t3 - t2))
            let b1 = a1 * ((t2 - t) / (t2 - t0)) + a2 * ((t - t0) / (t2 - t0))
            let b2 = a2 * ((t3 - t) / (t3 - t1)) + a3 * ((t - t1) / (t3 - t1))
            line.append(b1 * ((t2 - t) / (t2 - t1)) + b2 * ((t - t1) / (t2 - t1)))
        }
    }
    line.append(points[points.count - 1])
    var lengths: [Float] = [0]
    for i in 1..<line.count { lengths.append(lengths[i - 1] + simd_length(line[i] - line[i - 1])) }
    return line.indices.map { Ball(centre: line[$0], halfWidth: halfWidth(at: lengths[$0] / lengths[line.count - 1]),
                                   halfDepth: halfDepth(at: lengths[$0] / lengths[line.count - 1])) }
}

/// A box of samples of the distance field, negative inside the solid.
private struct Field {
    let origin: SIMD3<Float>, nx: Int, ny: Int, nz: Int
    var values: [Float]
    func index(_ x: Int, _ y: Int, _ z: Int) -> Int { (z * ny + y) * nx + x }
    func point(_ x: Int, _ y: Int, _ z: Int) -> SIMD3<Float> { origin + SIMD3(Float(x), Float(y), Float(z)) * cell }

    init(balls: [Ball]) {
        let margin: Float = 0.06
        let low = SIMD3<Float>(balls.map { $0.centre.x - $0.halfWidth }.min()! - margin, balls.map { $0.centre.y - $0.halfWidth }.min()! - margin,
                               -balls.map(\.halfDepth).max()! - margin)
        let high = SIMD3<Float>(balls.map { $0.centre.x + $0.halfWidth }.max()! + margin, balls.map { $0.centre.y + $0.halfWidth }.max()! + margin, -low.z)
        origin = low
        nx = Int(((high.x - low.x) / cell).rounded(.up)) + 1
        ny = Int(((high.y - low.y) / cell).rounded(.up)) + 1
        nz = Int(((high.z - low.z) / cell).rounded(.up)) + 1
        values = [Float](repeating: 0, count: nx * ny * nz)
        let (nx, ny, nz, origin) = (nx, ny, nz, origin)
        values.withUnsafeMutableBufferPointer { buffer in
            let out = buffer.baseAddress!
            DispatchQueue.concurrentPerform(iterations: nz) { z in
                for y in 0..<ny {
                    for x in 0..<nx {
                        let p = origin + SIMD3(Float(x), Float(y), Float(z)) * cell
                        var nearest = Float.infinity
                        for ball in balls {
                            // A ball deeper than it is wide: distance measured with depth squeezed to match.
                            let dz = p.z * ball.halfWidth / ball.halfDepth
                            let dx = p.x - ball.centre.x, dy = p.y - ball.centre.y
                            nearest = min(nearest, (dx * dx + dy * dy + dz * dz).squareRoot() - ball.halfWidth)
                        }
                        out[(z * ny + y) * nx + x] = nearest
                    }
                }
            }
        }
    }

    /// Separable Gaussian blur of the field.
    mutating func soften(by distance: Float) {
        let sigma = distance / cell
        let reach = Int((sigma * 3).rounded(.up))
        var kernel = (-reach...reach).map { exp(-Float($0 * $0) / (2 * sigma * sigma)) }
        let sum = kernel.reduce(0, +)
        kernel = kernel.map { $0 / sum }
        for axis in 0..<3 {
            var next = values
            let count = [nx, ny, nz][axis], stride = [1, nx, nx * ny][axis]
            for z in 0..<nz { for y in 0..<ny { for x in 0..<nx {
                let here = [x, y, z][axis], base = index(x, y, z)
                var total: Float = 0
                for tap in -reach...reach {
                    let clamped = min(max(here + tap, 0), count - 1)
                    total += values[base + (clamped - here) * stride] * kernel[tap + reach]
                }
                next[base] = total
            } } }
            values = next
        }
    }

    /// Trilinear sample of the field's gradient, which points out of the solid.
    func gradient(at p: SIMD3<Float>) -> SIMD3<Float> {
        func sample(_ q: SIMD3<Float>) -> Float {
            let g = (q - origin) / cell
            let x = min(max(Int(g.x), 0), nx - 2), y = min(max(Int(g.y), 0), ny - 2), z = min(max(Int(g.z), 0), nz - 2)
            let f = SIMD3(g.x - Float(x), g.y - Float(y), g.z - Float(z))
            func v(_ i: Int, _ j: Int, _ k: Int) -> Float { values[index(x + i, y + j, z + k)] }
            let x00 = v(0, 0, 0) + (v(1, 0, 0) - v(0, 0, 0)) * f.x, x10 = v(0, 1, 0) + (v(1, 1, 0) - v(0, 1, 0)) * f.x
            let x01 = v(0, 0, 1) + (v(1, 0, 1) - v(0, 0, 1)) * f.x, x11 = v(0, 1, 1) + (v(1, 1, 1) - v(0, 1, 1)) * f.x
            let y0 = x00 + (x10 - x00) * f.y, y1 = x01 + (x11 - x01) * f.y
            return y0 + (y1 - y0) * f.z
        }
        let e = cell
        return simd_normalize(SIMD3(sample(p + [e, 0, 0]) - sample(p - [e, 0, 0]), sample(p + [0, e, 0]) - sample(p - [0, e, 0]),
                                    sample(p + [0, 0, e]) - sample(p - [0, 0, e])))
    }
}

/// Surface nets: one vertex in every cell the surface crosses, one quad across every grid edge it cuts.
private func mesh(of field: Field) -> (positions: [SIMD3<Float>], indices: [UInt32]) {
    var positions: [SIMD3<Float>] = [], indices: [UInt32] = []
    var vertexOfCell = [Int32](repeating: -1, count: field.nx * field.ny * field.nz)
    let corners: [(Int, Int, Int)] = [(0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0), (0, 0, 1), (1, 0, 1), (0, 1, 1), (1, 1, 1)]
    let edges: [(Int, Int)] = [(0, 1), (2, 3), (4, 5), (6, 7), (0, 2), (1, 3), (4, 6), (5, 7), (0, 4), (1, 5), (2, 6), (3, 7)]
    for z in 0..<(field.nz - 1) { for y in 0..<(field.ny - 1) { for x in 0..<(field.nx - 1) {
        let values = corners.map { field.values[field.index(x + $0.0, y + $0.1, z + $0.2)] }
        guard values.contains(where: { $0 < 0 }), values.contains(where: { $0 >= 0 }) else { continue }
        var sum = SIMD3<Float>.zero, crossings: Float = 0
        for (a, b) in edges where (values[a] < 0) != (values[b] < 0) {
            let t = values[a] / (values[a] - values[b])
            let pa = field.point(x + corners[a].0, y + corners[a].1, z + corners[a].2), pb = field.point(x + corners[b].0, y + corners[b].1, z + corners[b].2)
            sum += pa + (pb - pa) * t
            crossings += 1
        }
        vertexOfCell[field.index(x, y, z)] = Int32(positions.count)
        positions.append(sum / crossings)
    } } }
    // The four cells around a grid edge, for an edge along x, y or z.
    let around: [[(Int, Int, Int)]] = [[(0, 0, 0), (0, -1, 0), (0, -1, -1), (0, 0, -1)], [(0, 0, 0), (0, 0, -1), (-1, 0, -1), (-1, 0, 0)], [(0, 0, 0), (-1, 0, 0), (-1, -1, 0), (0, -1, 0)]]
    let along: [(Int, Int, Int)] = [(1, 0, 0), (0, 1, 0), (0, 0, 1)]
    for z in 1..<(field.nz - 1) { for y in 1..<(field.ny - 1) { for x in 1..<(field.nx - 1) {
        let here = field.values[field.index(x, y, z)]
        for axis in 0..<3 {
            let there = field.values[field.index(x + along[axis].0, y + along[axis].1, z + along[axis].2)]
            guard (here < 0) != (there < 0) else { continue }
            var quad = around[axis].map { UInt32(vertexOfCell[field.index(x + $0.0, y + $0.1, z + $0.2)]) }
            // Wound so the face looks out of the solid, which lies on the negative side.
            if here >= 0 { quad.reverse() }
            indices += [quad[0], quad[1], quad[2], quad[0], quad[2], quad[3]]
        }
    } } }
    return (positions, indices)
}

/// The folds are what give the form away, and they are white on white until something shades them. SceneKit's
/// screen-space occlusion stair-steps along them, so the shade is baked in: how much of each vertex's sky the
/// balls along the spine cover. A vertex's own stretch of tube lies behind its tangent plane and drops out.
private func shades(positions: [SIMD3<Float>], normals: [SIMD3<Float>], indices: [UInt32], balls: [Ball]) -> [Float] {
    let occluders = stride(from: 0, to: balls.count, by: 3).map { balls[$0] }
    var length: Float = 0
    for i in 1..<balls.count { length += simd_length(balls[i].centre - balls[i - 1].centre) }
    let spacing = length / Float(occluders.count - 1)
    var shades: [Float] = zip(positions, normals).map { position, normal in
        var covered: Float = 0
        for ball in occluders {
            let toCentre = SIMD3<Float>(ball.centre.x, ball.centre.y, 0) - position
            let facing = simd_dot(normal, toCentre)
            guard facing > 0 else { continue }
            let distance2 = simd_length_squared(toCentre), radius = ball.halfWidth
            // Overlapping balls stand for one stretch of tube, so each counts for its share of the spine.
            covered += facing / distance2.squareRoot() * (radius * radius / distance2) * (spacing / (2 * radius))
        }
        // Only the depths of a fold go dark; the artwork's open surfaces stay clean right up to it.
        let depth = min(max((covered - 0.1) / 0.45, 0), 1)
        return 1 - foldShade * depth * depth * (3 - 2 * depth)
    }
    // Inside a fold neighbouring vertices see very different skies, which speckles; average each with its neighbours.
    var neighbours = [Set<UInt32>](repeating: [], count: positions.count)
    for triangle in stride(from: 0, to: indices.count, by: 3) {
        let corners = [indices[triangle], indices[triangle + 1], indices[triangle + 2]]
        for a in corners { for b in corners where a != b { neighbours[Int(a)].insert(b) } }
    }
    for _ in 0..<3 {
        shades = shades.indices.map { i in
            neighbours[i].isEmpty ? shades[i] : (shades[i] + neighbours[i].reduce(0) { $0 + shades[Int($1)] } / Float(neighbours[i].count)) / 2
        }
    }
    return shades
}

private func light(_ type: SCNLight.LightType, red: CGFloat, green: CGFloat, blue: CGFloat, intensity: CGFloat, in scene: SCNScene) -> SCNNode {
    let light = SCNLight()
    light.type = type
    light.color = NSColor(srgbRed: red, green: green, blue: blue, alpha: 1)
    light.intensity = intensity
    let node = SCNNode()
    node.light = light
    scene.rootNode.addChildNode(node)
    return node
}

@main
enum MakeLaunchMark {
    static func main() throws {
        guard CommandLine.arguments.count >= 3 else { fatalError("Usage: make_launch_mark SCENE_FILE IMAGESET_DIRECTORY [PREVIEW_DIRECTORY]") }
        let chain = balls(perSpan: 32)
        var field = Field(balls: chain)
        field.soften(by: softening)
        let (positions, indices) = mesh(of: field)
        let normals = positions.map { field.gradient(at: $0) }
        // SceneKit reads 8-bit colours as 0...255 rather than 0...1, so the shades stay floats.
        let colours = shades(positions: positions, normals: normals, indices: indices, balls: chain).flatMap { [$0, $0, $0] }
        precondition(positions.count <= Int(UInt16.max), "Too many vertices for 16-bit indices; raise `cell`")

        let geometry = SCNGeometry(sources: [
            SCNGeometrySource(vertices: positions.map { SCNVector3(CGFloat($0.x), CGFloat($0.y), CGFloat($0.z)) }),
            SCNGeometrySource(normals: normals.map { SCNVector3(CGFloat($0.x), CGFloat($0.y), CGFloat($0.z)) }),
            SCNGeometrySource(data: colours.withUnsafeBufferPointer { Data(buffer: $0) }, semantic: .color, vectorCount: positions.count,
                              usesFloatComponents: true, componentsPerVector: 3, bytesPerComponent: 4, dataOffset: 0, dataStride: 12),
        ], elements: [SCNGeometryElement(indices: indices.map(UInt16.init), primitiveType: .triangles)])
        let material = SCNMaterial()
        material.lightingModel = .lambert
        material.diffuse.contents = NSColor.white
        geometry.materials = [material]

        let scene = SCNScene()
        scene.background.contents = NSColor.clear
        let mark = SCNNode(geometry: geometry)
        mark.name = LaunchMarkScene.markName
        scene.rootNode.addChildNode(mark)
        // Lit as the artwork is: a soft key from above and in front, over a cool ambient that is its shadow tone.
        _ = light(.ambient, red: 0.66, green: 0.68, blue: 0.72, intensity: 1000, in: scene)
        light(.directional, red: 0.97, green: 0.985, blue: 1, intensity: 560, in: scene).eulerAngles = SCNVector3(-0.85, 0.2, 0)
        let camera = SCNCamera()
        let distance: CGFloat = 4
        // The artwork is 160 points wide and one unit wide here, so `side` points span side/160 units.
        camera.fieldOfView = 2 * atan(LaunchMarkScene.side / 160 / 2 / distance) * 180 / .pi
        camera.zNear = 1
        camera.zFar = 10
        let eye = SCNNode()
        eye.camera = camera
        eye.position = SCNVector3(0, 0, distance)
        scene.rootNode.addChildNode(eye)

        let sceneFile = URL(fileURLWithPath: CommandLine.arguments[1])
        guard scene.write(to: sceneFile, options: nil, delegate: nil, progressHandler: nil) else { fatalError("Cannot write \(sceneFile.path)") }
        print("\(positions.count) vertices, \(indices.count / 3) triangles, \(try sceneFile.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0) bytes")

        let renderer = SCNRenderer(device: MTLCreateSystemDefaultDevice(), options: nil)
        renderer.scene = scene
        func render(scale: Int, to url: URL) throws {
            let pixels = LaunchMarkScene.side * CGFloat(scale)
            let image = renderer.snapshot(atTime: 0, with: CGSize(width: pixels, height: pixels), antialiasingMode: .multisampling4X)
            guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil),
                  let png = NSBitmapImageRep(cgImage: cgImage).representation(using: .png, properties: [:])
            else { fatalError("Cannot encode the render") }
            try png.write(to: url)
        }
        let imageSet = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
        try FileManager.default.createDirectory(at: imageSet, withIntermediateDirectories: true)
        for scale in [2, 3] { try render(scale: scale, to: imageSet.appending(path: "launch-mark@\(scale)x.png")) }
        if CommandLine.arguments.count > 3 {
            let previews = URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
            try FileManager.default.createDirectory(at: previews, withIntermediateDirectories: true)
            let axis = LaunchMarkScene.axis
            for degrees in stride(from: 0, to: 360, by: 45) {
                mark.rotation = SCNVector4(CGFloat(axis.x), CGFloat(axis.y), CGFloat(axis.z), CGFloat(degrees) * .pi / 180)
                try render(scale: 3, to: previews.appending(path: "turn-\(degrees).png"))
            }
        }
    }
}
