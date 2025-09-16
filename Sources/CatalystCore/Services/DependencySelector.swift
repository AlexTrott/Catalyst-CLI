import Foundation
import PackageGenerator
import Utilities

final class DependencySelector {
    private let discovery = LocalPackageDiscovery()

    func selectDependencies(for configuration: ModuleConfiguration) -> [LocalPackageDependency] {
        _ = configuration
        let discoveredPackages = discovery.discoverPackages()

        let options = buildOptions(from: discoveredPackages)
        guard !options.isEmpty else { return [] }

        Console.newLine()
        Console.print("Available dependencies:", type: .info)

        for (index, option) in options.enumerated() {
            let number = String(format: "%2d", index + 1)
            Console.print("\(number). \(option.packageName) / \(option.productName)")
            Console.print("    Path: \(option.displayPath)", type: .detail)
        }

        Console.newLine()
        Console.print("Select dependencies to add (comma-separated numbers, press Enter to skip): ", type: .info)

        guard let input = readLine(), !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            Console.print("No additional dependencies selected", type: .detail)
            return []
        }

        let indexes = parseIndexes(from: input)
        guard !indexes.isEmpty else {
            Console.print("No valid selections detected. Continuing without additional dependencies.", type: .warning)
            return []
        }

        let selectedOptions = indexes.compactMap { index -> DependencyOption? in
            guard index > 0, index <= options.count else { return nil }
            return options[index - 1]
        }

        if selectedOptions.isEmpty {
            Console.print("No valid selections detected. Continuing without additional dependencies.", type: .warning)
            return []
        }

        let grouped = groupSelections(selectedOptions)
        let summary = Array(Set(selectedOptions.map { "\($0.packageName)/\($0.productName)" })).sorted().joined(separator: ", ")
        Console.print("Added dependencies: \(summary)", type: .success)
        return grouped
    }

    private func buildOptions(from packages: [DiscoveredPackage]) -> [DependencyOption] {
        let basePath = FileManager.default.currentDirectoryPath
        return packages
            .flatMap { $0.nonTestProductOptions(relativeTo: basePath) }
            .sorted { lhs, rhs in
                if lhs.packageName == rhs.packageName {
                    return lhs.productName < rhs.productName
                }
                return lhs.packageName < rhs.packageName
            }
    }

    private func parseIndexes(from input: String) -> [Int] {
        let separators = CharacterSet(charactersIn: ", \\t\n ")
        return input
            .components(separatedBy: separators)
            .compactMap { component in
                let trimmed = component.trimmingCharacters(in: .whitespaces)
                return trimmed.isEmpty ? nil : Int(trimmed)
            }
    }

    private func groupSelections(_ options: [DependencyOption]) -> [LocalPackageDependency] {
        var grouped: [String: LocalPackageDependency] = [:]
        var orderedKeys: [String] = []

        for option in options {
            var entry = grouped[option.packagePath]

            if entry == nil {
                entry = LocalPackageDependency(
                    packageName: option.packageName,
                    packagePath: option.packagePath,
                    productNames: [],
                    availableProducts: option.availableProducts
                )
                orderedKeys.append(option.packagePath)
            }

            if !entry!.productNames.contains(option.productName) {
                entry!.productNames.append(option.productName)
            }

            grouped[option.packagePath] = entry
        }

        return orderedKeys.compactMap { grouped[$0] }
    }
}
