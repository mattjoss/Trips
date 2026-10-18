import SwiftUI
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
#if os(macOS)
import AppKit

typealias TripPlatformImage = NSImage

extension NSImage {
    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let data = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else { return nil }
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }

    func pngData() -> Data? {
        guard let data = tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}

func tripImage(from image: CGImage) -> TripPlatformImage {
    NSImage(cgImage: image, size: .zero)
}

// Desktop thumbnails stay compact as the window grows.
let tripMediaTileSize: CGFloat = 160
#else
import UIKit

typealias TripPlatformImage = UIImage

func tripImage(from image: CGImage) -> TripPlatformImage {
    UIImage(cgImage: image)
}

var tripMediaTileSize: CGFloat { (UIScreen.main.bounds.width - 68) / 3.5 }
#endif

extension Image {
    init(tripImage: TripPlatformImage) {
        #if os(macOS)
        self.init(nsImage: tripImage)
        #else
        self.init(uiImage: tripImage)
        #endif
    }
}

enum TripsNavigationTitleStyle { case inline, large }

extension View {
    @ViewBuilder
    func tripsNavigationTitleStyle(_ style: TripsNavigationTitleStyle) -> some View {
        #if os(macOS)
        self
        #else
        self.navigationBarTitleDisplayMode(style == .inline ? .inline : .large)
        #endif
    }

    @ViewBuilder
    func tripsDarkToolbar() -> some View {
        #if os(macOS)
        self
        #else
        self.toolbarColorScheme(.dark, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    func tripsToolbarHidden(_ hidden: Bool) -> some View {
        #if os(macOS)
        self.toolbar(hidden ? .hidden : .visible, for: .windowToolbar)
        #else
        self.toolbar(hidden ? .hidden : .visible, for: .navigationBar)
        #endif
    }

    @ViewBuilder
    func tripsYearKeyboard() -> some View {
        #if os(macOS)
        self
        #else
        self.keyboardType(.numberPad)
        #endif
    }
}

// MARK: - Image Resizing

/// Resize an image encoded in `Data` so its maximum dimension is at most `maxDimension`.
/// Respects EXIF orientation, preserves aspect ratio, and does not upscale smaller images.
func resizeImageData(_ data: Data, maxDimension: CGFloat, compressionQuality: CGFloat = 0.85) -> Data? {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return nil }

    let propertiesOptions = [kCGImageSourceShouldCache: false] as CFDictionary
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, propertiesOptions) as? [CFString: Any] else {
        return nil
    }

    let width = (properties[kCGImagePropertyPixelWidth] as? CGFloat) ?? 0
    let height = (properties[kCGImagePropertyPixelHeight] as? CGFloat) ?? 0
    let originalMax = max(width, height)

    let targetMax = originalMax > 0 && originalMax < maxDimension ? originalMax : maxDimension

    let downsampleOptions: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceShouldCacheImmediately: true,
        kCGImageSourceCreateThumbnailWithTransform: true,
        kCGImageSourceThumbnailMaxPixelSize: targetMax
    ]

    guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions as CFDictionary) else {
        return nil
    }

    let mutableData = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(mutableData, UTType.jpeg.identifier as CFString, 1, nil) else {
        return nil
    }

    let destinationOptions: [CFString: Any] = [
        kCGImageDestinationLossyCompressionQuality: compressionQuality
    ]
    CGImageDestinationAddImage(destination, downsampledImage, destinationOptions as CFDictionary)
    guard CGImageDestinationFinalize(destination) else { return nil }

    return mutableData as Data
}
