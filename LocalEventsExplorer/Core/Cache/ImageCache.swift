import ImageIO
import UIKit

actor ImageCache {
    static let shared = ImageCache()

    private let memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    init() {
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        cacheDirectory = caches.appendingPathComponent("ImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        memoryCache.countLimit = 100
    }

    func image(for url: URL, maxPixel: CGFloat = 600) async -> UIImage? {
        let key = cacheKey(for: url)

        if let cached = memoryCache.object(forKey: key as NSString) {
            return cached
        }

        let diskPath = diskURL(for: key)
        if fileManager.fileExists(atPath: diskPath.path),
           let image = downsample(at: diskPath, maxPixel: maxPixel) {
            memoryCache.setObject(image, forKey: key as NSString)
            return image
        }

        guard let (data, _) = try? await URLSession.shared.data(from: url) else {
            return nil
        }

        try? data.write(to: diskPath)

        guard let image = downsample(at: diskPath, maxPixel: maxPixel) else {
            return nil
        }

        memoryCache.setObject(image, forKey: key as NSString)
        return image
    }

    private func cacheKey(for url: URL) -> String {
        let hash = url.absoluteString.utf8.reduce(into: UInt64(5381)) { result, byte in
            result = 127 &* (result & 0x00ff_ffff_ffff_ffff) &+ UInt64(byte)
        }
        return String(hash)
    }

    private func diskURL(for key: String) -> URL {
        cacheDirectory.appendingPathComponent(key)
    }

    private nonisolated func downsample(at url: URL, maxPixel: CGFloat) -> UIImage? {
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard let source = CGImageSourceCreateWithURL(url as CFURL, options as CFDictionary) else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel
        ]

        guard let cgImage = CGImageSourceCreateThumbnailAtIndex(
            source, 0, downsampleOptions as CFDictionary
        ) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
