#!/usr/bin/env swift
//
// generate_banner.swift — render the social-preview banner (1280×640) from code.
//
// Usage:
//   swift Tools/generate_banner.swift [output.png]
//
// Produces a professional, on-brand dark banner: a gradient backdrop with a
// faint dot grid, a logo mark, the name + tagline + metadata chips, and an
// "editor window" code card with syntax-highlighted Swift. Pure
// CoreGraphics/CoreText — no third-party dependencies.

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let width = 1280
let height = 640
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "docs/banner.png"

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard
    let context = CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    )
else {
    fputs("Failed to create CGContext\n", stderr)
    exit(1)
}

// CoreGraphics origin is bottom-left; design top-down and convert.
func top(_ y: CGFloat) -> CGFloat { CGFloat(height) - y }

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a]) ?? CGColor(gray: 0, alpha: 1)
}

// GitHub-dark-inspired palette — familiar and professional to developers.
let bgTop = rgb(0.043, 0.055, 0.078)  // #0B0E14
let bgBottom = rgb(0.071, 0.090, 0.125)  // #121720
let textPrimary = rgb(0.902, 0.929, 0.953)  // #E6EDF3
let textSecondary = rgb(0.545, 0.580, 0.620)  // #8B949E
let accent = rgb(0.941, 0.533, 0.243)  // #F0883E  orange
let codeKeyword = rgb(0.941, 0.533, 0.243)  // orange
let codeType = rgb(0.475, 0.757, 1.0)  // #79C0FF blue
let codeString = rgb(0.494, 0.831, 0.541)  // #7EE787 green
let codeFunc = rgb(0.824, 0.659, 1.0)  // #D2A8FF purple
let codeComment = rgb(0.431, 0.475, 0.522)  // #6E7681
let codePlain = rgb(0.792, 0.835, 0.878)
let cardFill = rgb(0.086, 0.106, 0.145)  // #161B25
let cardBorder = rgb(0.137, 0.165, 0.220)  // #232A38
let cardHeader = rgb(0.067, 0.082, 0.114)

// MARK: Background

if let gradient = CGGradient(
    colorsSpace: colorSpace, colors: [bgTop, bgBottom] as CFArray, locations: [0, 1])
{
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: CGFloat(height)),
        end: CGPoint(x: CGFloat(width), y: 0),
        options: [])
} else {
    context.setFillColor(bgTop)
    context.fill(CGRect(x: 0, y: 0, width: width, height: height))
}

// Faint dot grid for subtle texture.
context.setFillColor(rgb(1, 1, 1, 0.025))
let gridStep: CGFloat = 34
var gx: CGFloat = gridStep
while gx < CGFloat(width) {
    var gy: CGFloat = gridStep
    while gy < CGFloat(height) {
        context.fillEllipse(in: CGRect(x: gx - 1, y: gy - 1, width: 2, height: 2))
        gy += gridStep
    }
    gx += gridStep
}

// Soft accent glow behind the logo/title.
if let glow = CGGradient(
    colorsSpace: colorSpace,
    colors: [rgb(0.941, 0.533, 0.243, 0.16), rgb(0.941, 0.533, 0.243, 0)] as CFArray,
    locations: [0, 1])
{
    context.drawRadialGradient(
        glow,
        startCenter: CGPoint(x: 150, y: top(242)), startRadius: 0,
        endCenter: CGPoint(x: 150, y: top(242)), endRadius: 360,
        options: [])
}

// MARK: Text helpers

let systemFontName = "Helvetica Neue"
let monoFontName = "Menlo"

func font(_ name: String, _ size: CGFloat, bold: Bool = false) -> CTFont {
    let resolved = bold ? "\(name) Bold" : name
    return CTFontCreateWithName(resolved as CFString, size, nil)
}

@discardableResult
func draw(_ string: String, font ctFont: CTFont, color: CGColor, x: CGFloat, y: CGFloat) -> CGFloat {
    let attributes: [CFString: Any] = [
        kCTFontAttributeName: ctFont,
        kCTForegroundColorAttributeName: color,
    ]
    guard let attributed = CFAttributedStringCreate(nil, string as CFString, attributes as CFDictionary) else {
        return 0
    }
    let line = CTLineCreateWithAttributedString(attributed)
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

func measure(_ string: String, font ctFont: CTFont) -> CGFloat {
    let attributes: [CFString: Any] = [kCTFontAttributeName: ctFont]
    guard let attributed = CFAttributedStringCreate(nil, string as CFString, attributes as CFDictionary) else {
        return 0
    }
    let line = CTLineCreateWithAttributedString(attributed)
    return CGFloat(CTLineGetTypographicBounds(line, nil, nil, nil))
}

func roundedRect(_ rect: CGRect, radius: CGFloat, fill: CGColor? = nil, stroke: CGColor? = nil, lineWidth: CGFloat = 1) {
    let path = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
    if let fill {
        context.addPath(path)
        context.setFillColor(fill)
        context.fillPath()
    }
    if let stroke {
        context.addPath(path)
        context.setStrokeColor(stroke)
        context.setLineWidth(lineWidth)
        context.strokePath()
    }
}

// MARK: Logo mark — rounded badge with a minimal AX-node motif

let logoRect = CGRect(x: 96, y: top(280), width: 76, height: 76)
roundedRect(logoRect, radius: 20, fill: cardFill, stroke: cardBorder, lineWidth: 1.5)
do {
    let cx = logoRect.midX
    let cy = logoRect.midY
    let rootP = CGPoint(x: cx, y: cy + 18)
    let leftP = CGPoint(x: cx - 18, y: cy - 6)
    let rightP = CGPoint(x: cx + 18, y: cy - 6)
    let leafP = CGPoint(x: cx + 18, y: cy - 26)
    context.setStrokeColor(textSecondary)
    context.setLineWidth(2)
    for (a, b) in [(rootP, leftP), (rootP, rightP), (rightP, leafP)] {
        context.move(to: a)
        context.addLine(to: b)
        context.strokePath()
    }
    func dot(_ p: CGPoint, _ r: CGFloat, _ c: CGColor) {
        context.setFillColor(c)
        context.fillEllipse(in: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
    }
    dot(rootP, 5.5, codeType)
    dot(leftP, 4.5, codeType)
    dot(rightP, 4.5, codeType)
    dot(leafP, 5.5, accent)
}

// MARK: Title + tagline

let titleX = logoRect.maxX + 24
draw("MacAgentKit", font: font(systemFontName, 64, bold: true), color: textPrimary, x: titleX, y: top(264))

draw(
    "The missing low-level toolkit for",
    font: font(systemFontName, 30), color: textSecondary, x: 100, y: top(352))
draw(
    "macOS automation & AI agents.",
    font: font(systemFontName, 30), color: textSecondary, x: 100, y: top(392))

// MARK: Metadata chips

func chip(_ text: String, x: CGFloat, y: CGFloat, accentText: Bool = false) -> CGFloat {
    let chipFont = font(monoFontName, 19)
    let padding: CGFloat = 18
    let textWidth = measure(text, font: chipFont)
    let chipHeight: CGFloat = 38
    let rect = CGRect(x: x, y: y - chipHeight, width: textWidth + padding * 2, height: chipHeight)
    roundedRect(rect, radius: 10, fill: cardFill, stroke: cardBorder, lineWidth: 1)
    draw(text, font: chipFont, color: accentText ? accent : textSecondary, x: x + padding, y: y - chipHeight + 11)
    return rect.width + 12
}

do {
    var x: CGFloat = 100
    let chipBaseline = top(444)
    x += chip("Swift", x: x, y: chipBaseline, accentText: true)
    x += chip("macOS 13+", x: x, y: chipBaseline)
    x += chip("Zero dependencies", x: x, y: chipBaseline)
    x += chip("MIT", x: x, y: chipBaseline)
}

// MARK: Code card — an "editor window" with syntax-highlighted Swift

let card = CGRect(x: 712, y: top(502), width: 476, height: 320)
// Drop shadow.
context.saveGState()
context.setShadow(offset: CGSize(width: 0, height: -18), blur: 40, color: rgb(0, 0, 0, 0.45))
roundedRect(card, radius: 16, fill: cardFill)
context.restoreGState()
roundedRect(card, radius: 16, stroke: cardBorder, lineWidth: 1.5)

// Header bar with traffic-light dots + filename.
let headerHeight: CGFloat = 44
let headerRect = CGRect(x: card.minX, y: card.maxY - headerHeight, width: card.width, height: headerHeight)
context.saveGState()
context.addPath(CGPath(roundedRect: card, cornerWidth: 16, cornerHeight: 16, transform: nil))
context.clip()
context.setFillColor(cardHeader)
context.fill(headerRect)
context.restoreGState()
// Header divider.
context.setStrokeColor(cardBorder)
context.setLineWidth(1)
context.move(to: CGPoint(x: card.minX, y: headerRect.minY))
context.addLine(to: CGPoint(x: card.maxX, y: headerRect.minY))
context.strokePath()

do {
    let dotY = headerRect.midY
    let colors = [rgb(0.92, 0.34, 0.32), rgb(0.95, 0.74, 0.18), rgb(0.18, 0.78, 0.27)]
    for (index, color) in colors.enumerated() {
        let dx = card.minX + 24 + CGFloat(index) * 22
        context.setFillColor(color)
        context.fillEllipse(in: CGRect(x: dx - 6, y: dotY - 6, width: 12, height: 12))
    }
    let nameFont = font(monoFontName, 17)
    let name = "Automate.swift"
    draw(name, font: nameFont, color: textSecondary, x: card.midX - measure(name, font: nameFont) / 2, y: dotY - 7)
}

// Syntax-highlighted code. Each line is a list of (text, color) tokens.
let codeFont = font(monoFontName, 19)
let codeLines: [[(String, CGColor)]] = [
    [("import", codeKeyword), (" MacAgentKit", codeType)],
    [],
    [("// Drive another app by its stable id", codeComment)],
    [("let", codeKeyword), (" app = ", codePlain), ("AXElement", codeType), (".application(", codePlain)],
    [("    bundleID: ", codePlain), ("\"com.apple.Safari\"", codeString), (")", codePlain)],
    [],
    [("let", codeKeyword), (" reload = app?.", codePlain), ("firstByIdentifier", codeFunc)],
    [("    (", codePlain), ("\"ReloadButton\"", codeString), (")", codePlain)],
    [("try", codeKeyword), (" reload?.", codePlain), ("press", codeFunc), ("()", codePlain)],
]

let codeStartX = card.minX + 28
var lineTop = card.maxY - headerHeight - 38
let lineHeight: CGFloat = 28
for tokens in codeLines {
    var x = codeStartX
    for (text, color) in tokens {
        x += draw(text, font: codeFont, color: color, x: x, y: lineTop)
    }
    lineTop -= lineHeight
}

// MARK: Write PNG

guard let image = context.makeImage() else {
    fputs("Failed to render image\n", stderr)
    exit(1)
}

let url = URL(fileURLWithPath: outputPath)
try? FileManager.default.createDirectory(
    at: url.deletingLastPathComponent(), withIntermediateDirectories: true)

guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
    fputs("Failed to create image destination at \(outputPath)\n", stderr)
    exit(1)
}
CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("Failed to write PNG\n", stderr)
    exit(1)
}

print("Wrote banner to \(outputPath) (\(width)×\(height))")
