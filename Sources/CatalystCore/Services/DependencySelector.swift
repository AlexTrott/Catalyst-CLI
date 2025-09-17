import Foundation
import PackageGenerator
import Utilities
import ConfigurationManager

final class DependencySelector {
    private let discovery: LocalPackageDiscovering
    private let configuration: CatalystConfiguration

    init(configuration: CatalystConfiguration, discovery: LocalPackageDiscovering = LocalPackageDiscovery()) {
        self.configuration = configuration
        self.discovery = discovery
    }

    func selectDependencies(for configuration: ModuleConfiguration) -> [LocalPackageDependency] {
        _ = configuration
        let discoveredPackages = discovery.discoverPackages()

        let baseOptions = buildOptions(from: discoveredPackages)
        let orderedOptions = orderOptions(filterExcludedPackages(in: baseOptions))

        guard !orderedOptions.isEmpty else { return [] }

        Console.newLine()
        Console.print("Available dependencies:", type: .info)

        let interfaceCount = orderedOptions.prefix { isInterface($0) }.count
        let hasNonInterfaceOptions = interfaceCount < orderedOptions.count

        for (index, option) in orderedOptions.enumerated() {
            if index == interfaceCount, hasNonInterfaceOptions {
                if index > 0 {
                    Console.newLine()
                }
                Console.print("⚠️  Selecting non-Interface packages can introduce performance impact.", type: .warning)
                Console.newLine()
            }

            let number = String(format: "%2d", index + 1)
            Console.print("\(number). \(option.packageName) / \(option.productName)")
            Console.print("    Path: \(option.displayPath)", type: .detail)
        }

        Console.newLine()
        let input = Console.prompt(
            "Select dependencies to add (comma-separated numbers, press Enter to skip)",
            allowEmpty: true,
            style: .selection
        ) ?? ""

        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Console.print("No additional dependencies selected", type: .detail)
            return []
        }

        let indexes = parseIndexes(from: input)
        guard !indexes.isEmpty else {
            Console.print("No valid selections detected. Continuing without additional dependencies.", type: .warning)
            return []
        }

        let selectedOptions = indexes.compactMap { index -> DependencyOption? in
            guard index > 0, index <= orderedOptions.count else { return nil }
            return orderedOptions[index - 1]
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

    func makeOrderedOptions(from packages: [DiscoveredPackage]) -> [DependencyOption] {
        let baseOptions = buildOptions(from: packages)
        return orderOptions(filterExcludedPackages(in: baseOptions))
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

    private func filterExcludedPackages(in options: [DependencyOption]) -> [DependencyOption] {
        guard let excluded = configuration.dependencyExclusions, !excluded.isEmpty else {
            return options
        }

        return options.filter { option in
            !excluded.contains(option.packageName)
        }
    }

    private func orderOptions(_ options: [DependencyOption]) -> [DependencyOption] {
        let interfaceOptions = options.filter { isInterface($0) }
        let remainingOptions = options.filter { !isInterface($0) }
        return interfaceOptions + remainingOptions
    }

    private func parseIndexes(from input: String) -> [Int] {
        let separators = CharacterSet(charactersIn: ", \t\n ")
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

    private func isInterface(_ option: DependencyOption) -> Bool {
        option.productName.hasSuffix("Interface")
    }
}
