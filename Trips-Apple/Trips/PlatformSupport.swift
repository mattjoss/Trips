import SwiftUI
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
