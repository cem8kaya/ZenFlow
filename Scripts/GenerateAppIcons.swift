#!/usr/bin/env swift

//
//  GenerateAppIcons.swift
//  ZenFlow
//
//  Command-line tool to generate all iOS app icons
//  Run: swift Scripts/GenerateAppIcons.swift
//

import Foundation
import SwiftUI
import AppKit

// MARK: - Icon Colors (from IconGenerator.swift)

struct IconColors {
    static let calmBlue = NSColor(red: 0.35, green: 0.45, blue: 0.85, alpha: 1.0)
    static let serenePurple = NSColor(red: 0.50, green: 0.35, blue: 0.85, alpha: 1.0)
    static let softPurple = NSColor(red: 0.45, green: 0.35, blue: 0.65, alpha: 1.0)
    static let deepIndigo = NSColor(red: 0.18, green: 0.15, blue: 0.35, alpha: 1.0)
    static let lighterIndigo = NSColor(red: 0.25, green: 0.22, blue: 0.42, alpha: 1.0)
}

// MARK: - Icon Rendering

func drawBreathingCirclesIcon(in context: CGContext, size: CGFloat) {
    context.saveGState()

    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let center = CGPoint(x: size / 2, y: size / 2)

    // Background gradient
    let backgroundColors = [
        IconColors.lighterIndigo.cgColor,
        IconColors.deepIndigo.cgColor
    ]
    let backgroundGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: backgroundColors as CFArray,
        locations: [0.0, 1.0]
    )!

    context.drawLinearGradient(
        backgroundGradient,
        start: CGPoint(x: 0, y: 0),
        end: CGPoint(x: size, y: size),
        options: []
    )

    // Outer glow
    let glowColors = [
        IconColors.serenePurple.withAlphaComponent(0.3).cgColor,
        NSColor.clear.cgColor
    ]
    let glowGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: glowColors as CFArray,
        locations: [0.0, 1.0]
    )!

    context.drawRadialGradient(
        glowGradient,
        startCenter: center,
        startRadius: size * 0.1,
        endCenter: center,
        endRadius: size * 0.3,
        options: .drawsAfterEndLocation
    )

    // Scale factors for circles
    let scale = size / 1024.0

    // Draw concentric circles
    drawStrokedCircle(context: context, center: center, radius: 400 * scale, lineWidth: 3 * scale, color: IconColors.softPurple.withAlphaComponent(0.4))
    drawStrokedCircle(context: context, center: center, radius: 330 * scale, lineWidth: 4 * scale, color: IconColors.softPurple.withAlphaComponent(0.5))
    drawStrokedCircle(context: context, center: center, radius: 260 * scale, lineWidth: 5 * scale, color: IconColors.calmBlue.withAlphaComponent(0.6))
    drawStrokedCircle(context: context, center: center, radius: 190 * scale, lineWidth: 6 * scale, color: IconColors.calmBlue.withAlphaComponent(0.7))
    drawStrokedCircle(context: context, center: center, radius: 120 * scale, lineWidth: 7 * scale, color: IconColors.calmBlue.withAlphaComponent(0.8))

    // Center filled circle with gradient
    let centerRadius = 40 * scale
    let centerRect = CGRect(
        x: center.x - centerRadius,
        y: center.y - centerRadius,
        width: centerRadius * 2,
        height: centerRadius * 2
    )

    let centerColors = [
        NSColor.white.withAlphaComponent(0.9).cgColor,
        IconColors.calmBlue.withAlphaComponent(0.8).cgColor,
        IconColors.serenePurple.withAlphaComponent(0.7).cgColor
    ]
    let centerGradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: centerColors as CFArray,
        locations: [0.0, 0.5, 1.0]
    )!

    context.saveGState()
    context.addEllipse(in: centerRect)
    context.clip()
    context.drawRadialGradient(
        centerGradient,
        startCenter: center,
        startRadius: 0,
        endCenter: center,
        endRadius: centerRadius,
        options: []
    )
    context.restoreGState()

    // Center circle stroke
    context.setStrokeColor(IconColors.calmBlue.cgColor)
    context.setLineWidth(2 * scale)
    context.strokeEllipse(in: centerRect)

    context.restoreGState()
}

func drawStrokedCircle(context: CGContext, center: CGPoint, radius: CGFloat, lineWidth: CGFloat, color: NSColor) {
    context.saveGState()
    context.setStrokeColor(color.cgColor)
    context.setLineWidth(lineWidth)
    let rect = CGRect(
        x: center.x - radius,
        y: center.y - radius,
        width: radius * 2,
        height: radius * 2
    )
    context.strokeEllipse(in: rect)
    context.restoreGState()
}

// MARK: - Icon Generation

struct IconSize {
    let filename: String
    let pixelSize: Int

    static let allSizes: [IconSize] = [
        // iPhone
        IconSize(filename: "icon-20@2x.png", pixelSize: 40),
        IconSize(filename: "icon-20@3x.png", pixelSize: 60),
        IconSize(filename: "icon-29@2x.png", pixelSize: 58),
        IconSize(filename: "icon-29@3x.png", pixelSize: 87),
        IconSize(filename: "icon-40@2x.png", pixelSize: 80),
        IconSize(filename: "icon-40@3x.png", pixelSize: 120),
        IconSize(filename: "icon-60@2x.png", pixelSize: 120),
        IconSize(filename: "icon-60@3x.png", pixelSize: 180),

        // iPad
        IconSize(filename: "icon-20.png", pixelSize: 20),
        IconSize(filename: "icon-20@2x-ipad.png", pixelSize: 40),
        IconSize(filename: "icon-29.png", pixelSize: 29),
        IconSize(filename: "icon-29@2x-ipad.png", pixelSize: 58),
        IconSize(filename: "icon-40.png", pixelSize: 40),
        IconSize(filename: "icon-40@2x-ipad.png", pixelSize: 80),
        IconSize(filename: "icon-76.png", pixelSize: 76),
        IconSize(filename: "icon-76@2x.png", pixelSize: 152),
        IconSize(filename: "icon-83.5@2x.png", pixelSize: 167),

        // App Store
        IconSize(filename: "icon-1024.png", pixelSize: 1024),
    ]
}

func generateIcon(size: IconSize, outputPath: String) -> Bool {
    let pixelSize = CGFloat(size.pixelSize)

    // Create bitmap context
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
            data: nil,
            width: size.pixelSize,
            height: size.pixelSize,
            bitsPerComponent: 8,
            bytesPerRow: size.pixelSize * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        print("❌ Failed to create context for \(size.filename)")
        return false
    }

    // Draw icon
    drawBreathingCirclesIcon(in: context, size: pixelSize)

    // Create image
    guard let cgImage = context.makeImage() else {
        print("❌ Failed to create image for \(size.filename)")
        return false
    }

    // Save as PNG
    let outputURL = URL(fileURLWithPath: outputPath).appendingPathComponent(size.filename)
    guard let destination = CGImageDestinationCreateWithURL(outputURL as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        print("❌ Failed to create destination for \(size.filename)")
        return false
    }

    CGImageDestinationAddImage(destination, cgImage, nil)
    guard CGImageDestinationFinalize(destination) else {
        print("❌ Failed to write \(size.filename)")
        return false
    }

    return true
}

// MARK: - Contents.json

let contentsJSON = """
{
  "images" : [
    {
      "filename" : "icon-20@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-20@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-29@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-60@2x.png",
      "idiom" : "iphone",
      "scale" : "2x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-60@3x.png",
      "idiom" : "iphone",
      "scale" : "3x",
      "size" : "60x60"
    },
    {
      "filename" : "icon-20.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-20@2x-ipad.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "20x20"
    },
    {
      "filename" : "icon-29.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-29@2x-ipad.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "29x29"
    },
    {
      "filename" : "icon-40.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-40@2x-ipad.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "40x40"
    },
    {
      "filename" : "icon-76.png",
      "idiom" : "ipad",
      "scale" : "1x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-76@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "76x76"
    },
    {
      "filename" : "icon-83.5@2x.png",
      "idiom" : "ipad",
      "scale" : "2x",
      "size" : "83.5x83.5"
    },
    {
      "filename" : "icon-1024.png",
      "idiom" : "ios-marketing",
      "scale" : "1x",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
"""

// MARK: - Main

func main() {
    print("🎨 ZenFlow App Icon Generator")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("📱 Design: Breathing Circles")
    print("")

    // Determine output path
    let fileManager = FileManager.default
    let currentPath = fileManager.currentDirectoryPath
    let outputPath = "\(currentPath)/ZenFlow/Assets.xcassets/AppIcon.appiconset"

    print("📍 Output: \(outputPath)")
    print("")

    // Create directory if needed
    try? fileManager.createDirectory(atPath: outputPath, withIntermediateDirectories: true, attributes: nil)

    // Generate all icons
    var successCount = 0
    var failCount = 0

    for iconSize in IconSize.allSizes {
        if generateIcon(size: iconSize, outputPath: outputPath) {
            let padded = iconSize.filename.padding(toLength: 25, withPad: " ", startingAt: 0)
            print("✅ \(padded) (\(iconSize.pixelSize)x\(iconSize.pixelSize)px)")
            successCount += 1
        } else {
            failCount += 1
        }
    }

    // Write Contents.json
    let contentsPath = "\(outputPath)/Contents.json"
    do {
        try contentsJSON.write(toFile: contentsPath, atomically: true, encoding: .utf8)
        print("✅ Contents.json")
    } catch {
        print("❌ Failed to write Contents.json: \(error)")
        failCount += 1
    }

    print("")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("✨ Generation complete!")
    print("📊 Success: \(successCount)/\(IconSize.allSizes.count) icons")
    if failCount > 0 {
        print("⚠️  Failed: \(failCount)")
    }
    print("")
    print("🎯 Ready for Xcode build and App Store submission")
}

main()
