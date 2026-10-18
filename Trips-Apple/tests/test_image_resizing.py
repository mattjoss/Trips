"""Tests for image resizing logic and MediaItem serialization.

Run: python3 Trips-Apple/tests/test_image_resizing.py
Requires the Swift compiler from Xcode.
"""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[1]
platform_support_source = (root / "Trips/PlatformSupport.swift").read_text()
trip_source = (root / "Trips/Trip.swift").read_text()

harness = r'''
import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

''' + platform_support_source + r'''

@main struct ImageChecks {
    static func createTestImageData(width: Int, height: Int, orientation: UInt32 = 1) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(CGColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let cgImage = context.makeImage()!

        let data = NSMutableData()
        let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)!
        let props: [CFString: Any] = [kCGImagePropertyOrientation: orientation]
        CGImageDestinationAddImage(dest, cgImage, props as CFDictionary)
        CGImageDestinationFinalize(dest)
        return data as Data
    }

    static func getImageDimensions(_ data: Data) -> (width: Int, height: Int) {
        let source = CGImageSourceCreateWithData(data as CFData, nil)!
        let props = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as! [CFString: Any]
        let w = props[kCGImagePropertyPixelWidth] as! Int
        let h = props[kCGImagePropertyPixelHeight] as! Int
        return (w, h)
    }

    static func main() throws {
        // 1. Test resizing down to max dimension 2048
        let largeData = createTestImageData(width: 4000, height: 3000)
        guard let data2048 = resizeImageData(largeData, maxDimension: 2048) else {
            fatalError("Failed to resize to 2048")
        }
        let dims2048 = getImageDimensions(data2048)
        print("largeData 2048 dims: \(dims2048)")
        assert(dims2048.width == 2048 && dims2048.height == 1536)

        // 2. Test resizing down to max dimension 640
        guard let data640 = resizeImageData(largeData, maxDimension: 640) else {
            fatalError("Failed to resize to 640")
        }
        let dims640 = getImageDimensions(data640)
        print("largeData 640 dims: \(dims640)")
        assert(dims640.width == 640 && dims640.height == 480)

        // 3. Test that small images are not upscaled
        let smallData = createTestImageData(width: 500, height: 350)
        guard let smallResized2048 = resizeImageData(smallData, maxDimension: 2048) else {
            fatalError("Failed to resize small image with max 2048")
        }
        let dimsSmall2048 = getImageDimensions(smallResized2048)
        print("smallData 2048 dims: \(dimsSmall2048)")
        assert(dimsSmall2048.width == 500 && dimsSmall2048.height == 350)

        guard let smallResized640 = resizeImageData(smallData, maxDimension: 640) else {
            fatalError("Failed to resize small image with max 640")
        }
        let dimsSmall640 = getImageDimensions(smallResized640)
        print("smallData 640 dims: \(dimsSmall640)")
        assert(dimsSmall640.width == 500 && dimsSmall640.height == 350)

        // 4. Test EXIF orientation handling (Orientation 6 = 90 deg clockwise)
        let portraitViaExif = createTestImageData(width: 3000, height: 2000, orientation: 6)
        guard let exif2048 = resizeImageData(portraitViaExif, maxDimension: 2048) else {
            fatalError("Failed to resize EXIF image to 2048")
        }
        let dimsExif2048 = getImageDimensions(exif2048)
        print("portraitViaExif 2048 dims: \(dimsExif2048)")
        assert(dimsExif2048.width == 1365 && dimsExif2048.height == 2048)

        guard let exif640 = resizeImageData(portraitViaExif, maxDimension: 640) else {
            fatalError("Failed to resize EXIF image to 640")
        }
        let dimsExif640 = getImageDimensions(exif640)
        print("portraitViaExif 640 dims: \(dimsExif640)")
        assert(dimsExif640.width == 427 && dimsExif640.height == 640)

        // 5. Test MediaItem JSON encoding and decoding
        let itemWithThumb = MediaItem(
            url: "https://storage.googleapis.com/test/large.jpg",
            caption: "Test photo",
            type: "image",
            thumbnailUrl: "https://storage.googleapis.com/test/large_640.jpg"
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let encodedData = try encoder.encode(itemWithThumb)
        let jsonString = String(data: encodedData, encoding: .utf8)!
        print("Encoded jsonString: \(jsonString)")
        assert(jsonString.contains("thumbnail_url"))

        // Decode from JSON with thumbnail_url
        let decoded = try JSONDecoder().decode(MediaItem.self, from: encodedData)
        assert(decoded.thumbnailUrl == "https://storage.googleapis.com/test/large_640.jpg")
        assert(decoded.url == "https://storage.googleapis.com/test/large.jpg")
        assert(decoded.caption == "Test photo")
        assert(decoded.type == "image")

        // Decode from legacy JSON without thumbnail_url
        let legacyJSON = """
        {"url": "https://storage.googleapis.com/test/old.jpg", "caption": "Old", "type": "image"}
        """.data(using: .utf8)!
        let legacyDecoded = try JSONDecoder().decode(MediaItem.self, from: legacyJSON)
        assert(legacyDecoded.thumbnailUrl == nil)
        assert(legacyDecoded.url == "https://storage.googleapis.com/test/old.jpg")

        print("PASS: image resizing (2048, 640, no upscaling, EXIF orientation) and MediaItem serialization")
    }
}
'''

with tempfile.TemporaryDirectory(prefix="trips-image-checks-") as temporary:
    directory = Path(temporary)
    swift_source = directory / "ImageChecks.swift"
    executable = directory / "ImageChecks"
    swift_source.write_text(harness)
    subprocess.run([
        "swiftc", "-module-cache-path", str(directory / "ModuleCache"),
        "-parse-as-library", str(root / "Trips/Trip.swift"), str(swift_source),
        "-o", str(executable)
    ], check=True)
    subprocess.run([str(executable)], check=True)
