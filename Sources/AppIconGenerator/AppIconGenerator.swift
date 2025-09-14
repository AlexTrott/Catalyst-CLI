import Foundation
import CoreGraphics
import AppKit

/// Error types for app icon generation
public enum AppIconError: LocalizedError {
    case failedToFetchEmoji
    case invalidURL
    case invalidImageData

    public var errorDescription: String? {
        switch self {
        case .failedToFetchEmoji:
            return "Failed to fetch pig emoji from API"
        case .invalidURL:
            return "Invalid URL for emoji API"
        case .invalidImageData:
            return "Invalid image data received from API"
        }
    }
}

/// Generates modern single-size app icons with pig emojis for MicroApps
/// Uses the simplified iOS 14+ approach with a single 1024x1024 icon
public class AppIconGenerator {

    private let iconSize: CGFloat = 1024
    private let randomEmojis: [String] = [
        "1fa84",
        "1f600",
        "1f603",
        "1f604",
        "1f601",
        "1f606",
        "1f605",
        "1f923",
        "1f602",
        "1f642",
        "1f643",
        "1fae0",
        "1f609",
        "1f60a",
        "1f607",
        "1f970",
        "1f60d",
        "1f929",
        "1f618",
        "1f617",
        "263a-fe0f",
        "1f61a",
        "1f619",
        "1f437",
        "1f972",
        "1f60b",
        "1f61b",
        "1f61c",
        "1f92a",
        "1f61d",
        "1f911",
        "1f917",
        "1f92d",
        "1fae2",
        "1fae3",
        "1f92b",
        "1f914",
        "1fae1",
        "1f910",
        "1f928",
        "1f610",
        "1f611",
        "1f636",
        "1fae5",
        "1f636-200d-1f32b-fe0f",
        "1f60f",
        "1f612",
        "1f644",
        "1f62c",
        "1f62e-200d-1f4a8",
        "1f925",
        "1f60c",
        "1f614",
        "1f62a",
        "1f924",
        "1f634",
        "1f637",
        "1f912",
        "1f915",
        "1f922",
        "1f92e",
        "1f927",
        "1f975",
        "1f976",
        "1f974",
        "1f635",
        "1f92f",
        "1f920",
        "1f973",
        "1f978",
        "1f60e",
        "1f913",
        "1f9d0",
        "1f615",
        "1fae4",
        "1f61f",
        "1f641",
        "2639-fe0f",
        "1f62e",
        "1f62f",
        "1f632",
        "1f633",
        "1f97a",
        "1f979",
        "1f626",
        "1f627",
        "1f628",
        "1f630",
        "1f625",
        "1f622",
        "1f62d",
        "1f631",
        "1f616",
        "1f623",
        "1f61e",
        "1f613",
        "1f629",
        "1f62b",
        "1f971",
        "1f624",
        "1f621",
        "1f620",
        "1f92c",
        "1f608",
        "1f47f",
        "1f480",
        "1f4a9",
        "1f921",
        "1f47b",
        "1f47d",
        "1f916",
        "1f648",
        "1f48c",
        "1f498",
        "1f49d",
        "1f496",
        "1f497",
        "1f493",
        "1f49e",
        "1f495",
        "2763-fe0f",
        "1f494",
        "2764-fe0f-200d-1fa79",
        "1f48b",
        "1f4af",
        "1f4a5",
        "1f4ab",
        "1f573-fe0f",
        "1f4ac",
        "1f5ef-fe0f",
        "1f44d",
        "1f441-fe0f",
        "1fae6",
        "1f937",
        "1f463",
        "1f435",
        "1f436",
        "1f429",
        "1f43a",
        "1f98a",
        "1f99d",
        "1f431",
        "1f981",
        "1f42f",
        "1f40e",
        "1f984",
        "1f98c",
        "1f42e",
        "1f410",
        "1f999",
        "1f42d",
        "1f430",
        "1f994",
        "1f987",
        "1f43b",
        "1f428",
        "1f43c",
        "1f9a5",
        "1f414",
        "1f426",
        "1f427",
        "1f54a-fe0f",
        "1f989",
        "1fabf",
        "1f438",
        "1f422",
        "1f40d",
        "1f409",
        "1f433",
        "1f41f",
        "1f988",
        "1f419",
        "1f40c",
        "1f41d",
        "1f577-fe0f",
        "1f982",
        "1f9a0",
        "1f490",
        "1f338",
        "1f4ae",
        "1f339",
        "1f33c",
        "1f337",
        "1f332",
        "1f335",
        "1f344",
        "1f349",
        "1f34a",
        "1f34b",
        "1f34c",
        "1f34d",
        "1f352",
        "1f353",
        "1f951",
        "1f336-fe0f",
        "1f35e",
        "1f9c0",
        "1f32d",
        "1f365",
        "1f960",
        "1f382",
        "1f9c1",
        "1f36c",
        "2615",
        "1f9c3",
        "1f9ca",
        "1f37d-fe0f",
        "1f3fa",
        "1f30d",
        "1f30b",
        "1faa8",
        "1fab5",
        "1f304",
        "1f307",
        "1f69a",
        "26fd",
        "1f6a8",
        "1f6a6",
        "1f6d1",
        "1fa82",
        "1f6f8",
        "231a",
        "1f31c",
        "1f31e",
        "2b50",
        "1f31f",
        "1f30c",
        "2601-fe0f",
        "26c5",
        "1f327-fe0f",
        "1f32a-fe0f",
        "1f308",
        "2602-fe0f",
        "26c4",
        "2604-fe0f",
        "1f525",
        "1f30a",
        "1f383",
        "1f386",
        "1f388",
        "1f38a",
        "1f381",
        "1f39f-fe0f",
        "1f3c6",
        "1f947",
        "1f948",
        "1f949",
        "26bd",
        "1f3c0",
        "1f3c8",
        "1f3b3",
        "1f945",
        "1f3a3",
        "1f3bf",
        "1f3af",
        "1f52e",
        "1f3b0",
        "1f9e9",
        "1faa9",
        "2665-fe0f",
        "1f0cf",
        "1f5bc-fe0f",
        "1f455",
        "1f460",
        "1f451",
        "1f48e",
        "1f514",
        "1f3b6",
        "1f3a7",
        "1f4df",
        "1f4e0",
        "1f4bb",
        "1f4be",
        "1f39e-fe0f",
        "1f3ac",
        "1f4a1",
        "1f4da",
        "1f4f0",
        "1f58d-fe0f",
        "1f4c8",
        "1f4c9",
        "2702-fe0f",
        "1f5d1-fe0f",
        "1f47e",
        "1f9ea",
        "1faa4",
        "26a0-fe0f",
        "2622-fe0f",
        "2757"
    ]

    public init() {}

    /// Generate modern single-size app icons with light, dark, and tinted variants
    public func generateAppIcons(at path: URL, featureName: String) throws {
        // Select a random emoji to combine with the pig
        let randomEmoji = randomEmojis.randomElement() ?? "🔥"

        // Fetch the pig emoji combination from the API
        guard let pigEmojiImage = try fetchPigEmojiImage(withEmoji: randomEmoji) else {
            throw AppIconError.failedToFetchEmoji
        }

        // Generate the main (light mode) icon
        if let lightIconData = createIconFromImage(
            pigEmojiImage,
            size: CGSize(width: iconSize, height: iconSize),
            mode: .light
        ) {
            let lightIconPath = path.appendingPathComponent("AppIcon.png")
            try lightIconData.write(to: lightIconPath)
        }

        // Generate dark mode icon
        if let darkIconData = createIconFromImage(
            pigEmojiImage,
            size: CGSize(width: iconSize, height: iconSize),
            mode: .dark
        ) {
            let darkIconPath = path.appendingPathComponent("AppIcon-Dark.png")
            try darkIconData.write(to: darkIconPath)
        }

        // Generate tinted icon
        if let tintedIconData = createIconFromImage(
            pigEmojiImage,
            size: CGSize(width: iconSize, height: iconSize),
            mode: .tinted
        ) {
            let tintedIconPath = path.appendingPathComponent("AppIcon-Tinted.png")
            try tintedIconData.write(to: tintedIconPath)
        }

        // Create the modern single-size Contents.json
        try createSingleSizeContentsJSON(at: path)

        print("🐷 Generated app icon with pig + \(randomEmoji) combination")
    }

    /// Fetch pig emoji image from the API
    private func fetchPigEmojiImage(withEmoji emoji: String) throws -> NSImage? {
        // URL encode the emoji
        let urlString = "https://emojik.vercel.app/s/1f437_\(emoji)?size=768"

        guard let url = URL(string: urlString) else {
            throw AppIconError.invalidURL
        }

        // Fetch the image data
        let semaphore = DispatchSemaphore(value: 0)
        var imageData: Data?
        var fetchError: Error?

        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            imageData = data
            fetchError = error
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        if let error = fetchError {
            throw error
        }

        guard let data = imageData,
              let image = NSImage(data: data) else {
            throw AppIconError.invalidImageData
        }

        return image
    }

    /// Icon appearance modes
    private enum IconMode {
        case light
        case dark
        case tinted
    }

    /// Create an icon image from the fetched emoji image with the specified mode
    private func createIconFromImage(_ emojiImage: NSImage, size: CGSize, mode: IconMode) -> Data? {
        // Create a bitmap image rep with exact 1024x1024 dimensions
        let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )

        guard let bitmap = bitmapRep else {
            return nil
        }

        // Create graphics context for exact pixel control
        let context = NSGraphicsContext(bitmapImageRep: bitmap)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        // Set up the background based on mode
        switch mode {
        case .light:
            // White background for light mode
            NSColor.white.setFill()
            NSRect(origin: .zero, size: size).fill()
        case .dark:
            // Transparent background for dark mode - no fill needed
            break
        case .tinted:
            // Black background for tinted mode
            NSColor.black.setFill()
            NSRect(origin: .zero, size: size).fill()
        }

        // Calculate the size to draw the emoji (leave some padding)
        let drawSize = size.width * 0.8
        let offset = (size.width - drawSize) / 2

        let drawRect = NSRect(x: offset, y: offset, width: drawSize, height: drawSize)

        // Apply any necessary filters based on mode
        if mode == .tinted {
            // For tinted mode, we'll draw it with some transparency
            emojiImage.draw(in: drawRect, from: NSRect.zero, operation: .sourceOver, fraction: 0.7)
        } else {
            // For light and dark modes, draw normally
            emojiImage.draw(in: drawRect, from: NSRect.zero, operation: .sourceOver, fraction: 1.0)
        }

        NSGraphicsContext.restoreGraphicsState()

        // Convert bitmap to PNG data
        guard let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }

        return pngData
    }

    /// Create modern single-size Contents.json for iOS 14+ / Xcode 14+
    private func createSingleSizeContentsJSON(at path: URL) throws {
        let contents: [String: Any] = [
            "images": [
                // Light mode icon
                [
                    "filename": "AppIcon.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ],
                // Dark mode icon
                [
                    "appearances": [
                        ["appearance": "luminosity", "value": "dark"]
                    ],
                    "filename": "AppIcon-Dark.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ],
                // Tinted icon
                [
                    "appearances": [
                        ["appearance": "luminosity", "value": "tinted"]
                    ],
                    "filename": "AppIcon-Tinted.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ]
            ],
            "info": [
                "author": "catalyst-cli",
                "version": 1
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
        let contentsPath = path.appendingPathComponent("Contents.json")
        try jsonData.write(to: contentsPath)
    }

    /// Create legacy multi-size Contents.json for older Xcode versions
    /// Falls back to single light mode icon repeated for all sizes
    public func createLegacyContentsJSON(at path: URL) throws {
        let contents: [String: Any] = [
            "images": [
                // Just use the single 1024x1024 icon for all sizes
                [
                    "filename": "AppIcon.png",
                    "idiom": "universal",
                    "platform": "ios",
                    "size": "1024x1024"
                ]
            ],
            "info": [
                "author": "catalyst-cli",
                "version": 1
            ]
        ]

        let jsonData = try JSONSerialization.data(withJSONObject: contents, options: .prettyPrinted)
        let contentsPath = path.appendingPathComponent("Contents.json")
        try jsonData.write(to: contentsPath)
    }
}