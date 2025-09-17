import Foundation
import PathKit
import Utilities

struct LocalPackageProduct: Codable {
    let name: String
    let targets: [String]
}

struct LocalPackageTarget: Codable {
    let name: String
    let type: String?
}

struct DiscoveredPackage {
    let name: String
    let path: String
    let products: [LocalPackageProduct]
    let targets: [LocalPackageTarget]

    func nonTestProductOptions(relativeTo basePath: String) -> [DependencyOption] {
        let targetTypes = Dictionary(uniqueKeysWithValues: targets.map { ($0.name, $0.type ?? "") })
        let availableProducts = Array(Set(products.filter { product in
            product.targets.contains { targetName in
                targetTypes[targetName]?.lowercased() != "test"
            }
        }.map { $0.name })).sorted()

        return products.compactMap { product in
            let hasRegularTarget = product.targets.contains { targetName in
                targetTypes[targetName]?.lowercased() != "test"
            }

            guard hasRegularTarget else { return nil }

            let relativePath = relativePath(from: Path(basePath).absolute(), to: Path(path).absolute())

            return DependencyOption(
                packageName: name,
                packagePath: path,
                productName: product.name,
                displayPath: relativePath.isEmpty ? "." : relativePath,
                availableProducts: availableProducts
            )
        }
    }
}

struct DependencyOption {
    let packageName: String
    let packagePath: String
    let productName: String
    let displayPath: String
    let availableProducts: [String]
}

protocol LocalPackageDiscovering {
    func discoverPackages() -> [DiscoveredPackage]
}

final class LocalPackageDiscovery: LocalPackageDiscovering {
    private let fileManager = FileManager.default
    private let excludedDirectories: Set<String> = [
        ".git",
        ".build",
        "DerivedData",
        ".swiftpm",
        "build",
        "Pods",
        "node_modules",
        ".vscode",
        ".idea"
    ]
    private let packageCache = PackageCache()
    private let maxConcurrentDescribes = 6
    private let queue = DispatchQueue(label: "com.catalyst.packagediscovery", attributes: .concurrent)

    func discoverPackages() -> [DiscoveredPackage] {
        guard Shell.exists("swift") else {
            Console.print("Swift toolchain not found. Skipping dependency discovery.", type: .warning)
            return []
        }

        let rootPath = FileManager.default.currentDirectoryPath
        let rootPackagePath = Path(rootPath)

        let packageDirectories = findPackageDirectories(at: Path(rootPath))
            .filter { $0 != rootPackagePath }

        if #available(macOS 10.15, *) {
            // Use async/parallel processing for better performance
            return discoverPackagesAsync(from: packageDirectories)
        } else {
            // Fallback to sequential processing for older macOS
            return discoverPackagesSequential(from: packageDirectories)
        }
    }

    @available(macOS 10.15, *)
    private func discoverPackagesAsync(from directories: [Path]) -> [DiscoveredPackage] {
        let group = DispatchGroup()
        var results: [DiscoveredPackage] = []
        var resultsLock = NSLock()
        let semaphore = DispatchSemaphore(value: maxConcurrentDescribes)

        for directory in directories {
            group.enter()
            queue.async { [weak self] in
                guard let self = self else {
                    group.leave()
                    return
                }

                semaphore.wait()
                defer {
                    semaphore.signal()
                    group.leave()
                }

                // Check cache first
                if let cached = self.packageCache.getCachedPackage(at: directory) {
                    resultsLock.lock()
                    results.append(cached)
                    resultsLock.unlock()
                    return
                }

                // If not in cache, describe the package synchronously
                if let package = self.describePackage(at: directory) {
                    resultsLock.lock()
                    results.append(package)
                    resultsLock.unlock()
                }
            }
        }

        group.wait()
        return results
    }

    private func discoverPackagesSequential(from directories: [Path]) -> [DiscoveredPackage] {
        return directories.compactMap { directory in
            // Check cache first
            if let cached = packageCache.getCachedPackage(at: directory) {
                return cached
            }

            // If not in cache, describe the package
            return describePackage(at: directory)
        }
    }

    private func findPackageDirectories(at path: Path) -> [Path] {
        var results: [Path] = []

        guard let contents = try? fileManager.contentsOfDirectory(atPath: path.string) else {
            return []
        }

        if (path + "Package.swift").exists {
            results.append(path)
        }

        for item in contents {
            if excludedDirectories.contains(item) {
                continue
            }

            let itemPath = path + item
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: itemPath.string, isDirectory: &isDirectory), isDirectory.boolValue {
                results.append(contentsOf: findPackageDirectories(at: itemPath))
            }
        }

        return results
    }


    private func describePackage(at path: Path) -> DiscoveredPackage? {
        do {
            let output = try Shell.run("swift package describe --type json", at: path.string, timeout: 30, silent: true)
            let data = Data(output.utf8)
            let decoder = JSONDecoder()
            let manifest = try decoder.decode(DescribeManifest.self, from: data)

            let products = manifest.products.map { LocalPackageProduct(name: $0.name, targets: $0.targets) }
            let targets = manifest.targets.map { LocalPackageTarget(name: $0.name, type: $0.type) }

            let package = DiscoveredPackage(
                name: manifest.name,
                path: path.string,
                products: products,
                targets: targets
            )

            // Cache the result
            packageCache.cachePackage(package, at: path)

            return package
        } catch {
            Console.print("⚠️  Could not inspect package at \(path.string): \(error.localizedDescription)", type: .warning)
            return nil
        }
    }
}

private struct DescribeManifest: Decodable {
    struct Product: Decodable {
        let name: String
        let targets: [String]
    }

    struct Target: Decodable {
        let name: String
        let type: String?
    }

    let name: String
    let products: [Product]
    let targets: [Target]
}