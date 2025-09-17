import Foundation
import PathKit

struct CachedPackage: Codable {
    let name: String
    let path: String
    let products: [LocalPackageProduct]
    let targets: [LocalPackageTarget]
    let lastModified: Date
    let packageFileHash: String
}

final class PackageCache {
    private let cacheDirectory: Path
    private let cacheFile: Path
    private var cache: [String: CachedPackage] = [:]
    private let fileManager = FileManager.default

    init() {
        let homeDirectory = Path(NSHomeDirectory())
        self.cacheDirectory = homeDirectory + ".catalyst"
        self.cacheFile = cacheDirectory + "package-cache.json"
        loadCache()
    }

    private func loadCache() {
        guard cacheFile.exists else { return }

        do {
            let data = try Data(contentsOf: cacheFile.url)
            let decoder = JSONDecoder()
            cache = try decoder.decode([String: CachedPackage].self, from: data)
            cleanStaleEntries()
        } catch {
            // If cache is corrupted, start fresh
            cache = [:]
        }
    }

    private func saveCache() {
        do {
            if !cacheDirectory.exists {
                try fileManager.createDirectory(at: cacheDirectory.url, withIntermediateDirectories: true)
            }

            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(cache)
            try data.write(to: cacheFile.url)
        } catch {
            // Cache save failed, continue without caching
            print("Warning: Failed to save package cache: \(error)")
        }
    }

    private func cleanStaleEntries() {
        var updatedCache: [String: CachedPackage] = [:]

        for (key, cachedPackage) in cache {
            let packagePath = Path(cachedPackage.path)
            if packagePath.exists {
                updatedCache[key] = cachedPackage
            }
        }

        cache = updatedCache
    }

    private func computePackageFileHash(at path: Path) -> String? {
        let packageFile = path + "Package.swift"
        guard packageFile.exists,
              let attributes = try? fileManager.attributesOfItem(atPath: packageFile.string),
              let modificationDate = attributes[.modificationDate] as? Date,
              let fileSize = attributes[.size] as? NSNumber else {
            return nil
        }

        // Simple hash based on modification date and file size
        return "\(modificationDate.timeIntervalSince1970)-\(fileSize)"
    }

    func getCachedPackage(at path: Path) -> DiscoveredPackage? {
        guard let hash = computePackageFileHash(at: path),
              let cached = cache[path.string],
              cached.packageFileHash == hash else {
            return nil
        }

        return DiscoveredPackage(
            name: cached.name,
            path: cached.path,
            products: cached.products,
            targets: cached.targets
        )
    }

    func cachePackage(_ package: DiscoveredPackage, at path: Path) {
        guard let hash = computePackageFileHash(at: path) else { return }

        let cachedPackage = CachedPackage(
            name: package.name,
            path: package.path,
            products: package.products,
            targets: package.targets,
            lastModified: Date(),
            packageFileHash: hash
        )

        cache[path.string] = cachedPackage
        saveCache()
    }

    func clearCache() {
        cache = [:]
        if cacheFile.exists {
            try? fileManager.removeItem(at: cacheFile.url)
        }
    }
}