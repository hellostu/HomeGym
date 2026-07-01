#!/usr/bin/env swift
//
// Generates the HomeGym app icon: a blue→indigo rounded-square with a white
// "dumbbell.fill" SF Symbol (matching the menu-bar glyph). Renders every size the
// macOS AppIcon set needs, straight into the .appiconset directory.
//
// Usage: swift scripts/make_icon.swift <output-appiconset-dir>
import AppKit

let outDir = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "HomeGym/Assets.xcassets/AppIcon.appiconset"

func tint(_ image: NSImage, _ color: NSColor) -> NSImage {
    let out = NSImage(size: image.size)
    out.lockFocus()
    color.set()
    let rect = NSRect(origin: .zero, size: image.size)
    image.draw(in: rect)
    rect.fill(using: .sourceAtop)
    out.unlockFocus()
    return out
}

func renderIcon(size: Int) -> Data {
    let px = CGFloat(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx

    // Rounded-square icon body, inset to the macOS icon grid (~82% of canvas).
    let pad = px * 0.098
    let bodyRect = NSRect(x: pad, y: pad, width: px - 2 * pad, height: px - 2 * pad)
    let radius = bodyRect.width * 0.225

    let clip = NSBezierPath(roundedRect: bodyRect, xRadius: radius, yRadius: radius)
    clip.addClip()

    let top = NSColor(srgbRed: 0.32, green: 0.55, blue: 0.98, alpha: 1)
    let bottom = NSColor(srgbRed: 0.15, green: 0.24, blue: 0.68, alpha: 1)
    NSGradient(starting: top, ending: bottom)!.draw(in: bodyRect, angle: -90)

    // White dumbbell glyph, centred at ~52% of the canvas width.
    let cfg = NSImage.SymbolConfiguration(pointSize: px * 0.5, weight: .semibold)
    if let base = NSImage(systemSymbolName: "dumbbell.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(cfg) {
        let white = tint(base, .white)
        let target = px * 0.52
        let scale = target / max(white.size.width, white.size.height)
        let w = white.size.width * scale
        let h = white.size.height * scale
        white.draw(in: NSRect(x: (px - w) / 2, y: (px - h) / 2, width: w, height: h))
    }

    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let fm = FileManager.default
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

for size in [16, 32, 64, 128, 256, 512, 1024] {
    let data = renderIcon(size: size)
    let path = "\(outDir)/icon_\(size).png"
    try! data.write(to: URL(fileURLWithPath: path))
    print("wrote \(path)")
}
