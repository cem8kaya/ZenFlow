//
//  AppIconExporter.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Production app icon exporter for ZenFlow.
//  Generates all iOS icon sizes from Breathing Circles design.
//  Exports to Assets.xcassets/AppIcon.appiconset/
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Icon Export Configuration

struct IconSize {
    let name: String
    let size: CGFloat
    let scale: Int

    var filename: String {
        scale == 1 ? "icon-\(Int(size)).png" : "icon-\(Int(size))@\(scale)x.png"
    }

    var pixelSize: CGFloat {
        size * CGFloat(scale)
    }
}

// MARK: - iOS Icon Sizes

struct iOSIconSizes {
    static let allSizes: [IconSize] = [
        // iPhone Notification - 20pt
        IconSize(name: "iPhone Notification 2x", size: 20, scale: 2),
        IconSize(name: "iPhone Notification 3x", size: 20, scale: 3),

        // iPhone Settings - 29pt
        IconSize(name: "iPhone Settings 2x", size: 29, scale: 2),
        IconSize(name: "iPhone Settings 3x", size: 29, scale: 3),

        // iPhone Spotlight - 40pt
        IconSize(name: "iPhone Spotlight 2x", size: 40, scale: 2),
        IconSize(name: "iPhone Spotlight 3x", size: 40, scale: 3),

        // iPhone App - 60pt
        IconSize(name: "iPhone App 2x", size: 60, scale: 2),
        IconSize(name: "iPhone App 3x", size: 60, scale: 3),

        // iPad Notification - 20pt
        IconSize(name: "iPad Notification 1x", size: 20, scale: 1),
        IconSize(name: "iPad Notification 2x", size: 20, scale: 2),

        // iPad Settings - 29pt
        IconSize(name: "iPad Settings 1x", size: 29, scale: 1),
        IconSize(name: "iPad Settings 2x", size: 29, scale: 2),

        // iPad Spotlight - 40pt
        IconSize(name: "iPad Spotlight 1x", size: 40, scale: 1),
        IconSize(name: "iPad Spotlight 2x", size: 40, scale: 2),

        // iPad App - 76pt
        IconSize(name: "iPad App 1x", size: 76, scale: 1),
        IconSize(name: "iPad App 2x", size: 76, scale: 2),

        // iPad Pro App - 83.5pt
        IconSize(name: "iPad Pro App 2x", size: 83.5, scale: 2),

        // App Store - 1024pt
        IconSize(name: "App Store", size: 1024, scale: 1),
    ]
}

// MARK: - Icon Exporter

@MainActor
class AppIconExporter {

    // Export all icon sizes
    static func exportAllIcons(to outputURL: URL) async throws {
        print("🎨 ZenFlow App Icon Exporter")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📱 Generating iOS app icons...")
        print("🎯 Design: Breathing Circles")
        print("📍 Output: \(outputURL.path)")
        print("")

        // Create output directory if needed
        try? FileManager.default.createDirectory(at: outputURL, withIntermediateDirectories: true)

        var successCount = 0
        var failCount = 0

        // Generate each icon size
        for iconSize in iOSIconSizes.allSizes {
            do {
                try await exportIcon(size: iconSize, to: outputURL)
                print("✅ \(iconSize.filename.padding(toLength: 25, withPad: " ", startingAt: 0)) (\(Int(iconSize.pixelSize))x\(Int(iconSize.pixelSize))px)")
                successCount += 1
            } catch {
                print("❌ Failed: \(iconSize.filename) - \(error.localizedDescription)")
                failCount += 1
            }
        }

        print("")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("✨ Export complete!")
        print("📊 Success: \(successCount)/\(iOSIconSizes.allSizes.count)")
        if failCount > 0 {
            print("⚠️  Failed: \(failCount)")
        }
        print("")
    }

    // Export single icon
    @MainActor
    private static func exportIcon(size iconSize: IconSize, to outputURL: URL) async throws {
        let renderer = ImageRenderer(content: BreathingCirclesIconView()
            .frame(width: iconSize.pixelSize, height: iconSize.pixelSize))

        // Set scale to 1 since we're already rendering at pixel size
        renderer.scale = 1.0

        // Render to PNG
        guard let image = renderer.cgImage else {
            throw IconExportError.renderFailed
        }

        // Save to file
        let fileURL = outputURL.appendingPathComponent(iconSize.filename)

        #if os(macOS)
        let nsImage = NSImage(cgImage: image, size: NSSize(width: iconSize.pixelSize, height: iconSize.pixelSize))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            throw IconExportError.conversionFailed
        }
        try pngData.write(to: fileURL)
        #else
        let uiImage = UIImage(cgImage: image)
        guard let pngData = uiImage.pngData() else {
            throw IconExportError.conversionFailed
        }
        try pngData.write(to: fileURL)
        #endif
    }

    // Generate Contents.json
    static func generateContentsJSON() -> String {
        """
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
    }
}

// MARK: - Errors

enum IconExportError: Error {
    case renderFailed
    case conversionFailed
}

// MARK: - Export View (for use in SwiftUI previews or apps)

struct AppIconExporterView: View {
    @State private var isExporting = false
    @State private var exportStatus = ""

    var body: some View {
        VStack(spacing: 30) {
            Text("ZenFlow App Icon Exporter")
                .font(.title)
                .fontWeight(.bold)

            // Preview
            BreathingCirclesIconView()
                .frame(width: 256, height: 256)
                .clipShape(RoundedRectangle(cornerRadius: 55))
                .shadow(radius: 10)

            VStack(spacing: 10) {
                Text("Breathing Circles Design")
                    .font(.headline)

                Text("Ready to export 18 icon sizes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: exportIcons) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                    Text(isExporting ? "Exporting..." : "Export All Icons")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isExporting)
            .padding(.horizontal)

            if !exportStatus.isEmpty {
                Text(exportStatus)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .padding()
    }

    private func exportIcons() {
        isExporting = true
        exportStatus = "Preparing export..."

        Task {
            do {
                // Get output directory (AppIcon.appiconset)
                guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                    exportStatus = "❌ Could not access documents directory"
                    isExporting = false
                    return
                }

                let outputURL = documentsURL.appendingPathComponent("AppIcon.appiconset")

                // Export all icons
                try await AppIconExporter.exportAllIcons(to: outputURL)

                // Write Contents.json
                let contentsURL = outputURL.appendingPathComponent("Contents.json")
                let contentsJSON = AppIconExporter.generateContentsJSON()
                try contentsJSON.write(to: contentsURL, atomically: true, encoding: .utf8)

                exportStatus = "✅ Successfully exported to:\n\(outputURL.path)"
                isExporting = false
            } catch {
                exportStatus = "❌ Export failed: \(error.localizedDescription)"
                isExporting = false
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AppIconExporterView()
}
