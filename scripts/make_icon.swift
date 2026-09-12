import AppKit
let dimension = 1024
let output = CommandLine.arguments[1]
let bitmap = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: dimension, pixelsHigh: dimension, bitsPerSample: 8, samplesPerPixel: 3, hasAlpha: false, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
NSColor(red: 0.063, green: 0.067, blue: 0.078, alpha: 1).setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: dimension, height: dimension)).fill()
for index in 0..<24 {
    let t = Double(index) / 23
    let path = NSBezierPath()
    path.move(to: NSPoint(x: 174 + t * 100, y: 690))
    path.curve(to: NSPoint(x: 748 + t * 100, y: 722), controlPoint1: NSPoint(x: 450 - t * 100, y: -40 + t * 180), controlPoint2: NSPoint(x: 582 + t * 80, y: 338 - t * 90))
    path.lineWidth = 5
    NSColor(red: 0.09 + t * 0.63, green: 0.46 + t * 0.41, blue: 0.95 + t * 0.05, alpha: 1).setStroke()
    path.stroke()
}
NSGraphicsContext.restoreGraphicsState()
let data = bitmap.representation(using: .png, properties: [:])!
try data.write(to: URL(fileURLWithPath: output))
