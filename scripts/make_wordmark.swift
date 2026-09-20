import AppKit
import CoreText
import CryptoKit

// Usage: swift scripts/make_wordmark.swift /path/to/Archivo-Italic.ttf Brand
// Obtain the font directly from Fontshare. Font software is not redistributed.
guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: make_wordmark.swift FONT_FILE OUTPUT_DIRECTORY")
}
let fontURL = URL(fileURLWithPath: CommandLine.arguments[1])
let digest = SHA256.hash(data: try Data(contentsOf: fontURL)).map { String(format: "%02x", $0) }.joined()
guard digest == "edd7f2cd765aecca123a2354ef91b783d2f8ec69075966c53a06ebbda0d01cdf" else {
    fatalError("Font differs from the selected Fontshare Archivo Regular Italic file; review before regenerating")
}
var registrationError: Unmanaged<CFError>?
guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError) else {
    fatalError("Cannot register font: \(String(describing: registrationError?.takeRetainedValue()))")
}
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor],
      let descriptor = descriptors.first else { fatalError("Cannot read font") }
let font = CTFontCreateWithFontDescriptor(descriptor, 200, nil)
// Fontshare's API file uses "false" for its internal family/PostScript name.
// Verify its bytes above, and build from its descriptor rather than a system name.
let line = CTLineCreateWithAttributedString(NSAttributedString(
    string: "izzy", attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
))
let originalOutline = CGMutablePath()
for run in CTLineGetGlyphRuns(line) as! [CTRun] {
    let count = CTRunGetGlyphCount(run)
    var glyphs = [CGGlyph](repeating: 0, count: count)
    var positions = [CGPoint](repeating: .zero, count: count)
    CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
    for index in glyphs.indices {
        guard let path = CTFontCreatePathForGlyph(font, glyphs[index], nil) else { fatalError("Missing glyph outline") }
        originalOutline.addPath(path, transform: CGAffineTransform(translationX: positions[index].x, y: positions[index].y))
    }
}
// Approved direction: narrower letters, with the original height retained.
// Apply once to the shaped word so SVG, PDF, and PNG share identical geometry.
let horizontalScale: CGFloat = 0.85
var condensation = CGAffineTransform(scaleX: horizontalScale, y: 1)
guard let outline = originalOutline.copy(using: &condensation) else { fatalError("Cannot transform wordmark") }
let bounds = outline.boundingBoxOfPath
let margin: CGFloat = 32
let width = bounds.width + margin * 2
let height = bounds.height + margin * 2
func number(_ value: CGFloat) -> String { String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), Double(value)) }
var svgPath = ""
outline.applyWithBlock { pointer in
    let element = pointer.pointee
    func point(_ i: Int) -> String { "\(number(element.points[i].x)) \(number(element.points[i].y))" }
    switch element.type {
    case .moveToPoint: svgPath += "M\(point(0))"
    case .addLineToPoint: svgPath += "L\(point(0))"
    case .addQuadCurveToPoint: svgPath += "Q\(point(0)) \(point(1))"
    case .addCurveToPoint: svgPath += "C\(point(0)) \(point(1)) \(point(2))"
    case .closeSubpath: svgPath += "Z"
    @unknown default: fatalError("Unknown path element")
    }
}
let svg = """
<svg xmlns="http://www.w3.org/2000/svg" width="\(number(width))" height="\(number(height))" viewBox="0 0 \(number(width)) \(number(height))" role="img" aria-labelledby="title">
  <title id="title">Izzy</title>
  <path fill="#202020" transform="translate(\(number(margin - bounds.minX)) \(number(margin + bounds.maxY))) scale(1 -1)" d="\(svgPath)"/>
</svg>
"""
try svg.write(to: output.appendingPathComponent("izzy-wordmark.svg"), atomically: true, encoding: .utf8)
func draw(_ context: CGContext, at point: CGPoint) {
    context.saveGState()
    context.translateBy(x: point.x - bounds.minX, y: point.y - bounds.minY)
    context.setFillColor(CGColor(red: 32.0 / 255, green: 32.0 / 255, blue: 32.0 / 255, alpha: 1))
    context.addPath(outline)
    context.fillPath()
    context.restoreGState()
}
var page = CGRect(x: 0, y: 0, width: width, height: height)
guard let pdf = CGContext(output.appendingPathComponent("izzy-wordmark.pdf") as CFURL, mediaBox: &page, nil) else { fatalError("Cannot create PDF") }
pdf.beginPDFPage(nil)
draw(pdf, at: CGPoint(x: margin, y: margin))
pdf.endPDFPage()
pdf.closePDF()

// An opaque preview for viewing the graphite mark on a white surface.
guard let preview = CGContext(data: nil, width: 1200, height: 600, bitsPerComponent: 8, bytesPerRow: 0,
    space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { fatalError("Cannot create preview") }
preview.setFillColor(CGColor(red: 250.0 / 255, green: 250.0 / 255, blue: 249.0 / 255, alpha: 1))
preview.fill(CGRect(x: 0, y: 0, width: 1200, height: 600))
let scale: CGFloat = 2.6
preview.translateBy(x: (1200 - bounds.width * scale) / 2, y: (600 - bounds.height * scale) / 2)
preview.scaleBy(x: scale, y: scale)
draw(preview, at: .zero)
let bitmap = NSBitmapImageRep(cgImage: preview.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("izzy-wordmark-preview.png"))
print("Created outlined Izzy wordmark: \(number(bounds.width)) × \(number(bounds.height)) points")
