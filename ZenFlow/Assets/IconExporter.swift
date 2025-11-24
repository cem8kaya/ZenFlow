//
//  IconExporter.swift
//  ZenFlow
//
//  Created by Claude AI on 24.11.2025.
//
//  Utility to export app icons in all required sizes.
//  Run this in a SwiftUI preview or from a debug menu to generate icons.
//

import SwiftUI
import UIKit

// MARK: - Icon Size Configuration

struct IconExportConfig {
    let name: String
    let size: CGFloat
    let scale: CGFloat

    var pixelSize: CGFloat {
        size * scale
    }

    var filename: String {
        if scale == 1.0 {
            return "icon-\(Int(size)).png"
        } else {
            return "icon-\(Int(size))@\(Int(scale))x.png"
        }
    }
}

// MARK: - Icon Sizes

@MainActor
struct IconSizes {
    static let all: [IconExportConfig] = [
        // iPhone
        IconExportConfig(name: "iPhone Notification", size: 20, scale: 2),
        IconExportConfig(name: "iPhone Notification", size: 20, scale: 3),
        IconExportConfig(name: "iPhone Settings", size: 29, scale: 2),
        IconExportConfig(name: "iPhone Settings", size: 29, scale: 3),
        IconExportConfig(name: "iPhone Spotlight", size: 40, scale: 2),
        IconExportConfig(name: "iPhone Spotlight", size: 40, scale: 3),
        IconExportConfig(name: "iPhone App", size: 60, scale: 2),
        IconExportConfig(name: "iPhone App", size: 60, scale: 3),

        // iPad
        IconExportConfig(name: "iPad Notification", size: 20, scale: 1),
        IconExportConfig(name: "iPad Notification", size: 20, scale: 2),
        IconExportConfig(name: "iPad Settings", size: 29, scale: 1),
        IconExportConfig(name: "iPad Settings", size: 29, scale: 2),
        IconExportConfig(name: "iPad Spotlight", size: 40, scale: 1),
        IconExportConfig(name: "iPad Spotlight", size: 40, scale: 2),
        IconExportConfig(name: "iPad App", size: 76, scale: 1),
        IconExportConfig(name: "iPad App", size: 76, scale: 2),
        IconExportConfig(name: "iPad Pro App", size: 83.5, scale: 2),

        // App Store
        IconExportConfig(name: "App Store", size: 1024, scale: 1),
    ]

    static let recommended: [IconExportConfig] = [
        IconExportConfig(name: "iPhone App", size: 60, scale: 3),     // 180x180
        IconExportConfig(name: "iPhone App", size: 60, scale: 2),     // 120x120
        IconExportConfig(name: "iPad App", size: 76, scale: 2),       // 152x152
        IconExportConfig(name: "App Store", size: 1024, scale: 1),    // 1024x1024
    ]
}

// MARK: - Icon Exporter

@MainActor
class IconExporter {

    // MARK: - Export Methods

    /// Export a single icon at specified size
    static func exportIcon(
        style: IconStyle,
        size: IconExportConfig,
        completion: @escaping (Result<UIImage, Error>) -> Void
    ) {
        let view = IconExportView(style: style, size: size.pixelSize)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1.0

        if let image = renderer.uiImage {
            completion(.success(image))
        } else {
            completion(.failure(ExportError.renderFailed))
        }
    }

    /// Export all recommended sizes
    static func exportAllSizes(
        style: IconStyle,
        sizes: [IconExportConfig] = IconSizes.recommended,
        progress: @escaping (String, Int, Int) -> Void,
        completion: @escaping ([String: UIImage]) -> Void
    ) {
        var exportedIcons: [String: UIImage] = [:]
        let total = sizes.count

        for (index, size) in sizes.enumerated() {
            exportIcon(style: style, size: size) { result in
                switch result {
                case .success(let image):
                    exportedIcons[size.filename] = image
                    progress(size.name, index + 1, total)
                case .failure(let error):
                    print("Failed to export \(size.name): \(error)")
                }

                if index == sizes.count - 1 {
                    completion(exportedIcons)
                }
            }
        }
    }

    /// Save image to photo library
    static func saveToPhotos(_ image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
    }

    /// Get Documents directory URL
    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    /// Save image to Documents directory
    static func saveToDocuments(_ image: UIImage, filename: String) throws {
        let url = documentsDirectory().appendingPathComponent(filename)
        if let data = image.pngData() {
            try data.write(to: url)
            print("✅ Saved: \(filename)")
        }
    }

    /// Export and save all icons to Documents
    static func exportAndSave(
        style: IconStyle,
        sizes: [IconExportConfig] = IconSizes.all,
        completion: @escaping (Int) -> Void
    ) {
        exportAllSizes(style: style, sizes: sizes) { filename, current, total in
            print("📦 Exporting \(current)/\(total): \(filename)")
        } completion: { icons in
            var savedCount = 0

            for (filename, image) in icons {
                do {
                    try saveToDocuments(image, filename: filename)
                    savedCount += 1
                } catch {
                    print("❌ Failed to save \(filename): \(error)")
                }
            }

            completion(savedCount)
            print("✨ Export complete! Saved \(savedCount) icons to Documents folder")
        }
    }
}

// MARK: - Export Error

enum ExportError: Error {
    case renderFailed
    case saveFailed

    var localizedDescription: String {
        switch self {
        case .renderFailed:
            return "Failed to render icon"
        case .saveFailed:
            return "Failed to save icon"
        }
    }
}

// MARK: - Export UI View

struct IconExportUIView: View {
    @State private var selectedStyle: IconStyle = .breathingCircles
    @State private var isExporting = false
    @State private var exportStatus = ""
    @State private var exportedCount = 0

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Style Selection
                VStack(spacing: 15) {
                    Text("Select Icon Style")
                        .font(.headline)

                    Picker("Style", selection: $selectedStyle) {
                        ForEach(IconStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding()

                // Icon Preview
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                        .frame(width: 256, height: 256)

                    Group {
                        switch selectedStyle {
                        case .lotus:
                            LotusIconView()
                        case .breathingCircles:
                            BreathingCirclesIconView()
                        case .zenStones:
                            ZenStonesIconView()
                        }
                    }
                    .frame(width: 220, height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 48))
                    .shadow(radius: 10)
                }

                // Export Buttons
                VStack(spacing: 15) {
                    Button(action: exportRecommended) {
                        Label("Export Recommended Sizes", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isExporting)

                    Button(action: exportAll) {
                        Label("Export All Sizes", systemImage: "square.and.arrow.down.on.square")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(isExporting)
                }
                .padding(.horizontal)

                // Status
                if isExporting {
                    ProgressView()
                        .padding()
                }

                if !exportStatus.isEmpty {
                    Text(exportStatus)
                        .font(.caption)
                        .foregroundColor(exportedCount > 0 ? .green : .secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Export Icons")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func exportRecommended() {
        isExporting = true
        exportStatus = "Exporting recommended sizes..."

        IconExporter.exportAndSave(
            style: selectedStyle,
            sizes: IconSizes.recommended
        ) { count in
            isExporting = false
            exportedCount = count
            exportStatus = "✅ Exported \(count) icons to Documents folder"
        }
    }

    private func exportAll() {
        isExporting = true
        exportStatus = "Exporting all sizes..."

        IconExporter.exportAndSave(
            style: selectedStyle,
            sizes: IconSizes.all
        ) { count in
            isExporting = false
            exportedCount = count
            exportStatus = "✅ Exported \(count) icons to Documents folder"
        }
    }
}

// MARK: - Previews

#Preview("Export UI") {
    IconExportUIView()
}

// MARK: - Usage Example

/*
 // In your app or debug menu:

 import SwiftUI

 struct DebugMenu: View {
     var body: some View {
         List {
             NavigationLink("Export App Icons") {
                 IconExportUIView()
             }
         }
     }
 }

 // Or programmatically:

 @MainActor
 func exportIcons() {
     IconExporter.exportAndSave(
         style: .breathingCircles,
         sizes: IconSizes.all
     ) { count in
         print("Exported \(count) icons")
     }
 }

 // Individual export:

 @MainActor
 func exportSingle() {
     let size = IconSize(name: "App Store", size: 1024, scale: 1)

     IconExporter.exportIcon(style: .breathingCircles, size: size) { result in
         switch result {
         case .success(let image):
             IconExporter.saveToPhotos(image)
         case .failure(let error):
             print("Export failed: \(error)")
         }
     }
 }
 */
