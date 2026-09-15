import SwiftUI

private struct ImageSketch {
    var lines: [[CGPoint]] = []
    var boxes: [CGRect] = []
    var circles: [CGRect] = []
    var routes: [[CGPoint]] = []
    var moving: Bool { routes.contains { $0.count > 1 } }

    static func make(_ id: String) -> ImageSketch {
        func points(_ values: [(Double, Double)]) -> [CGPoint] { values.map { CGPoint(x: $0.0, y: $0.1) } }
        let floor = points([(55, 145), (265, 145)])
        let container = CGRect(x: 125, y: 40, width: 130, height: 105)
        func route(_ values: [(Double, Double)]) -> [[CGPoint]] { [points(values)] }
        switch id {
        case "up": return .init(lines: [floor], routes: route([(160, 125), (160, 40)]))
        case "down": return .init(lines: [floor], routes: route([(160, 40), (160, 125)]))
        case "in": return .init(boxes: [container], routes: route([(190, 90)]))
        case "into": return .init(boxes: [container], routes: route([(55, 90), (190, 90)]))
        case "out": return .init(boxes: [CGRect(x: 50, y: 40, width: 130, height: 105)], routes: route([(110, 90), (265, 90)]))
        case "on": return .init(lines: [points([(65, 112), (255, 112)])], routes: route([(160, 103)]))
        case "off": return .init(lines: [points([(50, 130), (175, 130)])], routes: route([(105, 121), (245, 50)]))
        case "onto": return .init(lines: [points([(145, 130), (270, 130)])], routes: route([(55, 60), (130, 60), (205, 121)]))
        case "to": return .init(circles: [CGRect(x: 225, y: 65, width: 50, height: 50)], routes: route([(55, 90), (250, 90)]))
        case "from": return .init(circles: [CGRect(x: 45, y: 65, width: 50, height: 50)], routes: route([(70, 90), (255, 90)]))
        case "for": return .init(circles: [CGRect(x: 225, y: 65, width: 50, height: 50)], routes: route([(55, 90), (180, 90)]))
        case "at": return .init(lines: [points([(160, 40), (160, 140)]), points([(100, 90), (220, 90)])], circles: [CGRect(x: 132, y: 62, width: 56, height: 56)], routes: route([(160, 90)]))
        case "by": return .init(boxes: [CGRect(x: 135, y: 95, width: 60, height: 50)], routes: route([(55, 60), (265, 60)]))
        case "with": return .init(circles: [CGRect(x: 125, y: 81, width: 18, height: 18)], routes: route([(185, 90)]))
        case "without": return .init(lines: [points([(120, 70), (150, 110)]), points([(150, 70), (120, 110)])], circles: [CGRect(x: 112, y: 67, width: 46, height: 46)], routes: route([(205, 90)]))
        case "over": return .init(boxes: [CGRect(x: 125, y: 85, width: 70, height: 60)], routes: route([(55, 115), (105, 55), (160, 35), (215, 55), (265, 115)]))
        case "under": return .init(lines: [points([(70, 65), (250, 65)])], routes: route([(160, 115)]))
        case "across": return .init(lines: [points([(110, 35), (110, 145)]), points([(210, 35), (210, 145)])], routes: route([(55, 90), (265, 90)]))
        case "through": return .init(boxes: [CGRect(x: 110, y: 45, width: 100, height: 95)], routes: route([(55, 90), (265, 90)]))
        case "around": return .init(circles: [CGRect(x: 132, y: 62, width: 56, height: 56)], routes: route([(85, 120), (75, 70), (110, 35), (190, 30), (240, 70), (235, 125)]))
        case "about": return .init(circles: [CGRect(x: 135, y: 65, width: 50, height: 50)], routes: [points([(95, 60)]), points([(205, 45)]), points([(225, 125)]), points([(115, 140)])])
        case "back": return .init(lines: [floor], circles: [CGRect(x: 45, y: 65, width: 50, height: 50)], routes: route([(250, 90), (70, 90)]))
        case "away": return .init(circles: [CGRect(x: 45, y: 65, width: 50, height: 50)], routes: route([(115, 90), (265, 45)]))
        case "along": return .init(lines: [points([(40, 115), (130, 115), (210, 65), (280, 65)])], routes: route([(55, 100), (125, 100), (205, 50), (265, 50)]))
        case "after": return .init(lines: [floor], circles: [CGRect(x: 245, y: 81, width: 18, height: 18)], routes: route([(55, 90), (200, 90)]))
        case "ahead", "behind": return .init(lines: [points([(65, 135), (255, 135)]), points([(240, 126), (255, 135), (240, 144)])], circles: [CGRect(x: 151, y: 81, width: 18, height: 18)], routes: route([(id == "ahead" ? 245 : 75, 90)]))
        case "forward": return .init(lines: [floor], routes: route([(60, 90), (260, 90)]))
        case "apart": return .init(routes: [points([(150, 90), (65, 90)]), points([(170, 90), (255, 90)])])
        case "together": return .init(routes: [points([(65, 90), (150, 90)]), points([(255, 90), (170, 90)])])
        case "aside": return .init(lines: [points([(50, 115), (270, 115)])], routes: route([(155, 106), (210, 45)]))
        case "against": return .init(lines: [points([(235, 35), (235, 145)])], routes: route([(65, 90), (226, 90)]))
        case "of": return .init(boxes: [CGRect(x: 90, y: 40, width: 140, height: 105)], routes: route([(125, 90)]))
        case "like": return .init(circles: [CGRect(x: 95, y: 75, width: 30, height: 30)], routes: route([(210, 90)]))
        case "aback": return .init(lines: [points([(265, 40), (225, 70)]), points([(275, 90), (235, 90)]), points([(265, 140), (225, 110)])], routes: route([(190, 90), (70, 90)]))
        default: return .init()
        }
    }
}

/// All drawings share a 320 × 180 coordinate system and the same visual grammar.
struct ParticleDiagram: View {
    @Environment(\.appAccent) private var accent
    let concept: ParticleConcept
    var progress: Double = 1
    var body: some View {
        Canvas { context, size in
            let scale = min(size.width / 320, size.height / 180)
            context.translateBy(x: (size.width - 320 * scale) / 2, y: (size.height - 180 * scale) / 2)
            context.scaleBy(x: scale, y: scale)
            let sketch = ImageSketch.make(concept.id)
            for rect in sketch.boxes {
                let path = Path(roundedRect: rect, cornerRadius: 12)
                context.fill(path, with: .color(Palette.surface))
                context.stroke(path, with: .color(Palette.secondary), lineWidth: 2)
            }
            for rect in sketch.circles { context.stroke(Path(ellipseIn: rect), with: .color(Palette.secondary), lineWidth: 2) }
            for points in sketch.lines {
                context.stroke(path(points), with: .color(Palette.secondary), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            }
            for points in sketch.routes {
                guard let start = points.first, let end = points.last else { continue }
                if points.count > 1 {
                    context.stroke(path(points), with: .color(accent.color), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                    let previous = points[points.count - 2]
                    let angle = atan2(end.y - previous.y, end.x - previous.x)
                    let wings = [CGPoint(x: end.x - 18 * cos(angle - .pi / 6), y: end.y - 18 * sin(angle - .pi / 6)), end, CGPoint(x: end.x - 18 * cos(angle + .pi / 6), y: end.y - 18 * sin(angle + .pi / 6))]
                    context.stroke(path(wings), with: .color(accent.color), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    let origin = Path(ellipseIn: CGRect(x: start.x - 6, y: start.y - 6, width: 12, height: 12))
                    context.fill(origin, with: .color(Palette.paper))
                    context.stroke(origin, with: .color(accent.color), lineWidth: 2)
                }
                // The moving subject stops short of the arrowhead, which must remain readable.
                let length = zip(points, points.dropFirst()).reduce(0.0) { $0 + hypot($1.1.x - $1.0.x, $1.1.y - $1.0.y) }
                let markerProgress = length > 0 ? progress * max(0, 1 - 32 / length) : progress
                let point = position(on: points, progress: markerProgress)
                context.fill(Path(ellipseIn: CGRect(x: point.x - 9, y: point.y - 9, width: 18, height: 18)), with: .color(accent.color))
            }
        }.aspectRatio(320.0 / 180, contentMode: .fit).accessibilityHidden(true)
    }
    private func path(_ points: [CGPoint]) -> Path {
        Path { path in guard let first = points.first else { return }; path.move(to: first); for point in points.dropFirst() { path.addLine(to: point) } }
    }
    private func position(on points: [CGPoint], progress: Double) -> CGPoint {
        guard points.count > 1 else { return points.first ?? .zero }
        let lengths = zip(points, points.dropFirst()).map { hypot($1.x - $0.x, $1.y - $0.y) }
        var remaining = lengths.reduce(0, +) * min(1, max(0, progress))
        for (index, length) in lengths.enumerated() {
            if remaining <= length, length > 0 {
                let t = remaining / length
                return CGPoint(x: points[index].x + (points[index + 1].x - points[index].x) * t, y: points[index].y + (points[index + 1].y - points[index].y) * t)
            }
            remaining -= length
        }
        return points.last ?? .zero
    }
}

struct ParticleGalleryView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var query = ""
    private var concepts: [ParticleConcept] {
        ParticleConcept.all.filter { query.isEmpty || [$0.id, $0.japanese, $0.english].contains { $0.localizedCaseInsensitiveContains(query) } || ParticleConcept.find(query)?.id == $0.id }
    }
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(store.data.meaningLanguage == .japanese ? "前置詞・副詞のイメージ" : "Prepositions & particles").font(.subheadline).foregroundStyle(Palette.secondary)
                if concepts.isEmpty { ContentUnavailableView.search(text: query) }
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.md), count: typeSize.isAccessibilitySize ? 1 : 2), alignment: .leading, spacing: Spacing.md) {
                    ForEach(concepts) { concept in
                        NavigationLink { ParticleImageDetailView(concept: concept) } label: {
                            VStack(spacing: Spacing.sm) {
                                Text(concept.id).font(Typography.family).foregroundStyle(Palette.ink)
                                ParticleDiagram(concept: concept)
                                // Centered under the diagram; at most two balanced lines, scaled slightly before truncating.
                                Text(concept.title(in: store.data.meaningLanguage)).font(.subheadline).foregroundStyle(Palette.secondary)
                                    .multilineTextAlignment(.center).lineLimit(typeSize.isAccessibilitySize ? nil : 2).minimumScaleFactor(0.85)
                                    .fixedSize(horizontal: false, vertical: true).frame(maxWidth: .infinity)
                            }.padding(Spacing.md).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                                .background(Palette.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: Radius.large)).contentShape(Rectangle())
                        }.buttonStyle(PressStyle()).accessibilityIdentifier("particle-\(concept.id)")
                    }
                }
            }
        }.navigationTitle("Core images").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "in, into, out…")
    }
}

struct ParticleImageDetailView: View {
    @Environment(PurchaseStore.self) private var purchases
    @Environment(\.appAccent) private var accent
    @Environment(LearningStore.self) private var store
    let concept: ParticleConcept
    @State private var progress = 1.0
    private var japanese: Bool { store.data.meaningLanguage == .japanese }
    private var phrases: [Phrase] { store.data.sortOrder.ordered(store.phrases.filter { $0.particleConcepts.contains(concept) && purchases.allows($0) }, reviews: store.data.reviews) }
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                Text(concept.title(in: store.data.meaningLanguage)).font(.title2).accessibilityIdentifier("coreImageTitle")
                VStack(spacing: Spacing.sm) {
                    ParticleDiagram(concept: concept, progress: progress)
                    if ImageSketch.make(concept.id).moving {
                        Slider(value: $progress, in: 0...1).tint(accent.color)
                            .accessibilityLabel(japanese ? "図の動き" : "Diagram movement")
                            .accessibilityValue("\(Int(progress * 100))%")
                            .accessibilityIdentifier("diagramMovement")
                        HStack(spacing: Spacing.sm) { Text(japanese ? "始点" : "Start"); Spacer(); Text(japanese ? "終点" : "End") }.font(.caption).foregroundStyle(Palette.secondary)
                    }
                }.padding(Spacing.lg).background(Palette.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: Radius.large))
                Text(japanese ? "● 対象　○ 始点　線・枠：基準　矢印：動き" : "● Subject · ○ Start · Outline: reference · Arrow: movement")
                    .font(.caption).foregroundStyle(Palette.secondary)
                Text(concept.extensionText(in: store.data.meaningLanguage)).font(.body).lineSpacing(5)
                if let other = ParticleConcept.find(concept.comparison) {
                    NavigationLink { ParticleComparisonView(first: concept, second: other) } label: {
                        Label(japanese ? "\(other.id) と比較" : "Compare with \(other.id)", systemImage: "square.split.2x1").frame(minHeight: 44)
                    }.accessibilityIdentifier("compareParticle")
                }
                Text(japanese ? "図は覚えるための手がかりです。句動詞の意味は、表現全体と例文で確かめましょう。" : "The image is a memory cue. Check the whole phrase and its example for the intended meaning.")
                    .font(.caption).foregroundStyle(Palette.secondary)
                SectionTitle(title: japanese ? "この語を含む表現" : "Phrases with this word", trailing: "\(phrases.count)")
                LazyVStack(spacing: 0) {
                    ForEach(phrases) { phrase in
                        NavigationLink { PhraseDetailView(phrase: phrase) } label: { PhraseRow(phrase: phrase) }
                            .buttonStyle(RowPressStyle()).accessibilityIdentifier("imagePhrase-\(phrase.id)")
                        Divider()
                    }
                }
            }
        }.navigationTitle(concept.id).navigationBarTitleDisplayMode(.inline)
    }
}

private struct ParticleComparisonView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dynamicTypeSize) private var typeSize
    let first: ParticleConcept
    let second: ParticleConcept
    var body: some View {
        PaperPage {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                let layout = typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: Spacing.lg)) : AnyLayout(HStackLayout(alignment: .top, spacing: Spacing.md))
                layout {
                    ForEach([first, second]) { concept in
                        VStack(alignment: .leading, spacing: Spacing.md) {
                            Text(concept.id).font(Typography.phrase)
                            ParticleDiagram(concept: concept)
                            Text(concept.title(in: store.data.meaningLanguage)).font(.headline).fixedSize(horizontal: false, vertical: true)
                        }.padding(Spacing.md).frame(maxWidth: .infinity, alignment: .leading).background(Palette.paper.opacity(0.7), in: RoundedRectangle(cornerRadius: Radius.large))
                    }
                }
                ForEach([first, second]) { concept in
                    VStack(alignment: .leading, spacing: Spacing.xs) {
                        Text(concept.id).font(.headline)
                        Text(concept.extensionText(in: store.data.meaningLanguage)).font(.body).foregroundStyle(Palette.secondary)
                    }
                }
            }
        }.navigationTitle("\(first.id) / \(second.id)").navigationBarTitleDisplayMode(.inline)
    }
}
