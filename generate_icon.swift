import Cocoa

// Generates a macOS-style app icon for "Klicker"
// Rounded rect with gradient background + cursor + sound waves

func generateIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    guard let ctx = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }

    let cornerRadius = s * 0.22

    // -- Background: rounded rect with gradient --
    let bgPath = CGPath(roundedRect: CGRect(x: 0, y: 0, width: s, height: s),
                        cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    let colors = [
        CGColor(red: 0.10, green: 0.10, blue: 0.18, alpha: 1.0),
        CGColor(red: 0.18, green: 0.15, blue: 0.30, alpha: 1.0),
        CGColor(red: 0.12, green: 0.12, blue: 0.22, alpha: 1.0)
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                              colors: colors as CFArray,
                              locations: [0.0, 0.5, 1.0])!
    ctx.drawLinearGradient(gradient,
                           start: CGPoint(x: 0, y: s),
                           end: CGPoint(x: s, y: 0),
                           options: [])

    // -- Subtle inner glow --
    ctx.resetClip()
    ctx.addPath(bgPath)
    ctx.clip()

    // -- Cursor arrow (center-left) --
    let cursorScale = s / 512.0
    let cx = s * 0.32
    let cy = s * 0.52

    ctx.saveGState()
    ctx.translateBy(x: cx, y: cy)
    ctx.scaleBy(x: cursorScale, y: cursorScale)

    // Arrow shape
    let arrow = CGMutablePath()
    arrow.move(to: CGPoint(x: 0, y: 120))
    arrow.addLine(to: CGPoint(x: 0, y: -120))
    arrow.addLine(to: CGPoint(x: 85, y: -40))
    arrow.addLine(to: CGPoint(x: 130, y: -100))
    arrow.addLine(to: CGPoint(x: 160, y: -80))
    arrow.addLine(to: CGPoint(x: 110, y: -15))
    arrow.addLine(to: CGPoint(x: 180, y: -15))
    arrow.closeSubpath()

    // Shadow for cursor
    ctx.setShadow(offset: CGSize(width: 3 * cursorScale, height: -3 * cursorScale),
                  blur: 12 * cursorScale,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))

    ctx.setFillColor(CGColor.white)
    ctx.addPath(arrow)
    ctx.fillPath()

    // Cursor border
    ctx.setShadow(offset: .zero, blur: 0)
    ctx.setStrokeColor(CGColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 0.3))
    ctx.setLineWidth(2.0)
    ctx.addPath(arrow)
    ctx.strokePath()

    ctx.restoreGState()

    // -- Sound waves (right side) --
    let waveX = s * 0.58
    let waveY = s * 0.50
    let waveColor = CGColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1.0)

    for i in 0..<3 {
        let radius = s * (0.10 + Double(i) * 0.08)
        let alpha = 1.0 - Double(i) * 0.28
        let lineWidth = s * (0.025 - Double(i) * 0.004)

        ctx.saveGState()
        ctx.setStrokeColor(waveColor.copy(alpha: alpha)!)
        ctx.setLineWidth(lineWidth)
        ctx.setLineCap(.round)

        let startAngle = -CGFloat.pi / 3.2
        let endAngle = CGFloat.pi / 3.2

        ctx.addArc(center: CGPoint(x: waveX, y: waveY),
                   radius: radius,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: false)
        ctx.strokePath()
        ctx.restoreGState()
    }

    // -- Small "click" dot --
    let dotRadius = s * 0.025
    let dotX = s * 0.52
    let dotY = s * 0.50
    ctx.saveGState()
    ctx.setShadow(offset: .zero, blur: s * 0.04,
                  color: CGColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 0.8))
    ctx.setFillColor(CGColor(red: 0.45, green: 0.75, blue: 1.0, alpha: 1.0))
    ctx.fillEllipse(in: CGRect(x: dotX - dotRadius, y: dotY - dotRadius,
                               width: dotRadius * 2, height: dotRadius * 2))
    ctx.restoreGState()

    image.unlockFocus()
    return image
}

func saveAsPNG(_ image: NSImage, path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("Erro ao gerar PNG")
        return
    }
    try! png.write(to: URL(fileURLWithPath: path))
}

// Generate all required sizes for .icns
let outputDir = "icon.iconset"
try! FileManager.default.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

let sizes: [(String, Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

for (name, size) in sizes {
    let img = generateIcon(size: size)
    saveAsPNG(img, path: "\(outputDir)/\(name).png")
    print("  ✓ \(name).png (\(size)x\(size))")
}

print("\n✅ Iconset gerado! Convertendo para .icns...")
