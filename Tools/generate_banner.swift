#!/usr/bin/env swift
//
// generate_banner.swift — render the social-preview banner (1280×640) from code.
//
// Usage:
//   swift Tools/generate_banner.swift [output.png]
//
// Produces an on-brand dark banner with the name, tagline, and a tiny
// "AX tree → action" motif. Pure CoreGraphics/CoreText — no third-party deps.

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

func rgb(_ r: Double, _ g: Double, _ b: Double, _ a: Double = 1) -> CGColor {
    CGColor(colorSpace: colorSpace, components: [r, g, b, a]) ?? CGColor(gray: 0, alpha: 1)
}

let background = rgb(0.05, 0.07, 0.09)
let accent = rgb(1.0, 0.45, 0.0)  // MacAgentKit orange
let nodeColor = rgb(0.20, 0.55, 0.95)
let textPrimary = rgb(0.96, 0.97, 0.98)
let textSecondary = rgb(0.62, 0.67, 0.73)

// Background.
context.setFillColor(background)
context.fill(CGRect(x: 0, y: 0, width: width, height: height))

// Subtle accent bar along the bottom.
context.setFillColor(accent)
context.fill(CGRect(x: 0, y: 0, width: width, height: 8))

// MARK: Text

func drawText(_ string: String, fontSize: CGFloat, weight: CGFloat, color: CGColor, x: CGFloat, y: CGFloat) {
    let font = CTFontCreateUIFontForLanguage(.system, fontSize, nil) ?? CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
    let traits: [CFString: Any] = [kCTFontWeightTrait: weight]
    let attributesDict: [CFString: Any] = [kCTFontTraitsAttribute: traits]
    let descriptor = CTFontDescriptorCreateWithAttributes(attributesDict as CFDictionary)
    let weightedFont = CTFontCreateCopyWithAttributes(font, fontSize, nil, descriptor)

    let attributes: [CFString: Any] = [
        kCTFontAttributeName: weightedFont,
        kCTForegroundColorAttributeName: color,
    ]
    guard let attributed = CFAttributedStringCreate(nil, string as CFString, attributes as CFDictionary) else {
        return
    }
    let line = CTLineCreateWithAttributedString(attributed)
    context.textPosition = CGPoint(x: x, y: y)
    CTLineDraw(line, context)
}

// Title + tagline (CoreGraphics origin is bottom-left).
drawText("MacAgentKit", fontSize: 96, weight: 0.6, color: textPrimary, x: 80, y: 380)
drawText(
    "The missing low-level toolkit for macOS automation & agents",
    fontSize: 34, weight: 0.0, color: textSecondary, x: 84, y: 320)
drawText("Swift • macOS 13+ • zero dependencies", fontSize: 26, weight: 0.0, color: accent, x: 84, y: 270)

// MARK: Motif — AX tree → action

func fillCircle(center: CGPoint, radius: CGFloat, color: CGColor) {
    context.setFillColor(color)
    context.fillEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
}

func line(from a: CGPoint, to b: CGPoint, color: CGColor, lineWidth: CGFloat = 3) {
    context.setStrokeColor(color)
    context.setLineWidth(lineWidth)
    context.move(to: a)
    context.addLine(to: b)
    context.strokePath()
}

let treeRootX: CGFloat = 880
let treeRootY: CGFloat = 460
let root = CGPoint(x: treeRootX, y: treeRootY)
let childA = CGPoint(x: treeRootX - 70, y: treeRootY - 90)
let childB = CGPoint(x: treeRootX + 70, y: treeRootY - 90)
let leaf = CGPoint(x: treeRootX + 70, y: treeRootY - 180)

line(from: root, to: childA, color: textSecondary)
line(from: root, to: childB, color: textSecondary)
line(from: childB, to: leaf, color: textSecondary)
fillCircle(center: root, radius: 16, color: nodeColor)
fillCircle(center: childA, radius: 14, color: nodeColor)
fillCircle(center: childB, radius: 14, color: nodeColor)
fillCircle(center: leaf, radius: 14, color: accent)  // the matched element

// Arrow → action.
let arrowStart = CGPoint(x: leaf.x + 28, y: leaf.y)
let arrowEnd = CGPoint(x: arrowStart.x + 90, y: leaf.y)
line(from: arrowStart, to: arrowEnd, color: accent, lineWidth: 4)
context.setFillColor(accent)
context.move(to: CGPoint(x: arrowEnd.x + 14, y: arrowEnd.y))
context.addLine(to: CGPoint(x: arrowEnd.x - 6, y: arrowEnd.y + 10))
context.addLine(to: CGPoint(x: arrowEnd.x - 6, y: arrowEnd.y - 10))
context.closePath()
context.fillPath()

// "action" pill.
let pill = CGRect(x: arrowEnd.x + 28, y: leaf.y - 26, width: 150, height: 52)
let pillPath = CGPath(roundedRect: pill, cornerWidth: 26, cornerHeight: 26, transform: nil)
context.addPath(pillPath)
context.setFillColor(accent)
context.fillPath()
drawText("press()", fontSize: 24, weight: 0.4, color: background, x: pill.minX + 28, y: pill.minY + 16)

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
