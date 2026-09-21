import AppKit
import CoreText
import CryptoKit

// Usage: swift scripts/make_wordmark.swift "/path/to/Figtree[wght].ttf" Brand
// Obtain the variable font from https://github.com/google/fonts/tree/main/ofl/figtree.
// Font software is not redistributed; only the outlined letters are kept.
guard CommandLine.arguments.count == 3 else {
    fatalError("Usage: make_wordmark.swift FONT_FILE OUTPUT_DIRECTORY")
}
let fontURL = URL(fileURLWithPath: CommandLine.arguments[1])
let digest = SHA256.hash(data: try Data(contentsOf: fontURL)).map { String(format: "%02x", $0) }.joined()
guard digest == "26ad3db9b31ff7dde67a91ff515d022d2f495cd506590699cf264f0bfe6fb714" else {
    fatalError("Font differs from the Figtree variable font the wordmark was drawn from; review before regenerating")
}
var registrationError: Unmanaged<CFError>?
guard CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &registrationError) else {
    fatalError("Cannot register font: \(String(describing: registrationError?.takeRetainedValue()))")
}
let output = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor],
      let descriptor = descriptors.first else { fatalError("Cannot read font") }
// Approved direction: Figtree Medium, so 500 on the weight axis ('wght').
let weightAxis: UInt32 = 0x7767_6874
let medium = CTFontDescriptorCreateCopyWithVariation(descriptor, weightAxis as CFNumber, 500)
// 1000 points per em keeps the master in the same coordinate scale as the previous wordmark,
// which the social image and store artwork place with fixed scale factors.
let font = CTFontCreateWithFontDescriptor(medium, 1000, nil)
let line = CTLineCreateWithAttributedString(NSAttributedString(
    string: "izzy", attributes: [NSAttributedString.Key(kCTFontAttributeName as String): font]
))
let outline = CGMutablePath()
for run in CTLineGetGlyphRuns(line) as! [CTRun] {
    let count = CTRunGetGlyphCount(run)
    var glyphs = [CGGlyph](repeating: 0, count: count)
    var positions = [CGPoint](repeating: .zero, count: count)
    CTRunGetGlyphs(run, CFRange(location: 0, length: 0), &glyphs)
    CTRunGetPositions(run, CFRange(location: 0, length: 0), &positions)
    let runFont = (CTRunGetAttributes(run) as NSDictionary)[kCTFontAttributeName as String] as! CTFont
    for index in glyphs.indices {
        guard let path = CTFontCreatePathForGlyph(runFont, glyphs[index], nil) else { fatalError("Missing glyph outline") }
        outline.addPath(path, transform: CGAffineTransform(translationX: positions[index].x, y: positions[index].y))
    }
}
let bounds = outline.boundingBoxOfPath
let margin: CGFloat = 24
let width = (bounds.width + margin * 2).rounded(.up)
let height = (bounds.height + margin * 2).rounded(.up)
func number(_ value: CGFloat) -> String { String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), Double(value)) }
// SVG space directly: y runs down from the top margin, so consumers need no transform.
var svgPath = ""
outline.applyWithBlock { pointer in
    let element = pointer.pointee
    func point(_ i: Int) -> String {
        "\(number(element.points[i].x - bounds.minX + margin)) \(number(bounds.maxY - element.points[i].y + margin))"
    }
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
<svg xmlns="http://www.w3.org/2000/svg" width="\(Int(width))" height="\(Int(height))" viewBox="0 0 \(Int(width)) \(Int(height))" role="img" aria-labelledby="title"><title id="title">izzy</title><g fill="#202020"><path d="\(svgPath)"/></g></svg>

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
let scale = min(1200 * 0.6 / bounds.width, 600 * 0.6 / bounds.height)
preview.translateBy(x: (1200 - bounds.width * scale) / 2, y: (600 - bounds.height * scale) / 2)
preview.scaleBy(x: scale, y: scale)
draw(preview, at: .zero)
let bitmap = NSBitmapImageRep(cgImage: preview.makeImage()!)
try bitmap.representation(using: .png, properties: [:])!.write(to: output.appendingPathComponent("izzy-wordmark-preview.png"))
print("Created outlined izzy wordmark: \(Int(width)) × \(Int(height)), x-height \(number(CTFontGetXHeight(font)))")
