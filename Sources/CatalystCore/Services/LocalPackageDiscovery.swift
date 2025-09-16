import Foundation
import PathKit
import Utilities

struct LocalPackageProduct {
    let name: String
    let targets: [String]
}

struct LocalPackageTarget {
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

final class LocalPackageDiscovery {
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

    func discoverPackages() -> [DiscoveredPackage] {
        guard Shell.exists("swift") else {
            Console.print("Swift toolchain not found. Skipping dependency discovery.", type: .warning)
            return []
        }

        let rootPath = FileManager.default.currentDirectoryPath
        let rootPackagePath = Path(rootPath)

        let packageDirectories = findPackageDirectories(at: Path(rootPath))
            .filter { $0 != rootPackagePath }

        return packageDirectories.compactMap { describePackage(at: $0) }
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

            return DiscoveredPackage(
                name: manifest.name,
                path: path.string,
                products: products,
                targets: targets
            )
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
