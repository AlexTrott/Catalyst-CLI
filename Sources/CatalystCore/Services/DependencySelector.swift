import Foundation
import PackageGenerator
import Utilities
import ConfigurationManager

final class DependencySelector {
    private let discovery: LocalPackageDiscovering
    private let configuration: CatalystConfiguration

    // For tracking exclusions in UI
    private var lastExcludedCount = 0
    private var lastExcludedPatterns: [String] = []

    init(configuration: CatalystConfiguration, discovery: LocalPackageDiscovering = LocalPackageDiscovery()) {
        self.configuration = configuration
        self.discovery = discovery
    }

    func selectDependencies(for configuration: ModuleConfiguration) -> [LocalPackageDependency] {
        _ = configuration

        // Show discovery progress
        Console.print("Discovering available packages...", type: .progress)
        let discoveredPackages = discovery.discoverPackages()
        Console.clearLine() // Clear the progress message

        let baseOptions = buildOptions(from: discoveredPackages)
        let orderedOptions = orderOptions(filterExcludedPackages(in: baseOptions))

        guard !orderedOptions.isEmpty else {
            Console.print("No packages found in the current workspace.", type: .detail)
            return []
        }

        // Display packages in a beautiful table
        displayPackageTable(options: orderedOptions)

        // Get user selection
        Console.newLine()
        let input = Console.prompt(
            "Select dependencies to add (comma-separated numbers, or 'all' for all Interface packages, press Enter to skip)",
            allowEmpty: true,
            style: .selection
        ) ?? ""

        if input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Console.print("No additional dependencies selected", type: .detail)
            return []
        }

        // Handle special 'all' keyword for interface packages
        if input.lowercased().trimmingCharacters(in: .whitespaces) == "all" {
            let interfaceOptions = orderedOptions.filter { isInterface($0) }
            if !interfaceOptions.isEmpty {
                let grouped = groupSelections(interfaceOptions)
                displaySelectedSummary(options: interfaceOptions)
                return grouped
            } else {
                Console.print("No Interface packages found.", type: .warning)
                return []
            }
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

        // Show what was selected
        displaySelectedSummary(options: selectedOptions)

        let grouped = groupSelections(selectedOptions)
        return grouped
    }

    private func displayPackageTable(options: [DependencyOption]) {
        let columns = [
            Console.TableColumn(header: "Package", alignment: .left, color: .cyan),
            Console.TableColumn(header: "Product", alignment: .left, color: .lightCyan),
            Console.TableColumn(header: "Type", alignment: .center),
            Console.TableColumn(header: "Path", alignment: .left, color: .lightBlack)
        ]

        var rows: [Console.TableRow] = []
        var currentIsInterface = true

        for option in options {
            let isInterfacePackage = isInterface(option)

            // Determine the type and icon
            let typeInfo = getPackageTypeInfo(option)

            // Check if we're transitioning from Interface to non-Interface
            if currentIsInterface && !isInterfacePackage {
                currentIsInterface = false
                // We'll add visual separation through row styling
            }

            // Truncate path if too long
            let displayPath = truncatePath(option.displayPath, maxLength: 30)

            let cells = [
                option.packageName,
                option.productName,
                typeInfo.display,
                displayPath
            ]

            let rowStyle: Console.RowStyle = isInterfacePackage ? .highlight : .normal
            rows.append(Console.TableRow(cells: cells, style: rowStyle))
        }

        // Create title with exclusion info
        let title = createTableTitle()

        Console.printTable(
            columns: columns,
            rows: rows,
            title: title,
            showIndex: true
        )

        // Show exclusion info if packages were excluded
        if lastExcludedCount > 0 {
            Console.newLine()
            displayExclusionInfo()
        }

        // Print legend if we have mixed types
        let hasInterfaces = options.contains { isInterface($0) }
        let hasNonInterfaces = options.contains { !isInterface($0) }

        if hasInterfaces && hasNonInterfaces {
            Console.newLine()
            Console.print("Legend:", type: .info)
            Console.print("  🎯 Interface - Lightweight, protocol-based dependencies (recommended)", type: .detail)
            Console.print("  📚 Library - Full implementation packages", type: .detail)
            Console.newLine()
            Console.print("⚠️  Note: Selecting non-Interface packages can introduce performance impact.", type: .warning)
        }
    }

    private func createTableTitle() -> String {
        let baseTitle = "📦 Available Dependencies"
        if lastExcludedCount > 0 {
            return "\(baseTitle) (\(lastExcludedCount) excluded)"
        } else {
            return baseTitle
        }
    }

    private func displayExclusionInfo() {
        let columns = [
            Console.TableColumn(header: "Exclusion Summary", alignment: .left, color: .yellow)
        ]

        var rows: [Console.TableRow] = []

        // Show excluded count
        rows.append(Console.TableRow(
            cells: ["🚫 \(lastExcludedCount) packages excluded by configuration"],
            style: .warning
        ))

        // Show exclusion patterns
        let patternsText = "Exclusion patterns: " + lastExcludedPatterns.joined(separator: ", ")
        rows.append(Console.TableRow(
            cells: [patternsText],
            style: .warning
        ))

        // Show pattern matching info
        if lastExcludedPatterns.contains(where: { $0.contains("*") }) {
            rows.append(Console.TableRow(
                cells: ["💡 Using wildcard matching (*) for flexible exclusions"],
                style: .normal
            ))
        }

        Console.printTable(
            columns: columns,
            rows: rows,
            showIndex: false
        )
    }

    private func displaySelectedSummary(options: [DependencyOption]) {
        Console.newLine()

        let columns = [
            Console.TableColumn(header: "Selected Dependencies", alignment: .left, color: .green)
        ]

        let rows = options.map { option in
            let typeInfo = getPackageTypeInfo(option)
            let summary = "\(typeInfo.icon) \(option.packageName)/\(option.productName)"
            return Console.TableRow(cells: [summary], style: .success)
        }

        Console.printTable(
            columns: columns,
            rows: rows,
            title: "✅ Selection Summary",
            showIndex: false
        )

        Console.print("Dependencies will be added to your module.", type: .success)
    }

    private func getPackageTypeInfo(_ option: DependencyOption) -> (icon: String, display: String) {
        if isInterface(option) {
            return ("🎯", "🎯 Interface")
        } else if option.productName.hasSuffix("Tests") {
            return ("🧪", "🧪 Test")
        } else if option.productName.hasSuffix("App") || option.productName.hasSuffix("Application") {
            return ("📱", "📱 App")
        } else {
            return ("📚", "📚 Library")
        }
    }

    private func truncatePath(_ path: String, maxLength: Int) -> String {
        guard path.count > maxLength else { return path }

        let components = path.split(separator: "/")
        if components.count > 2 {
            let first = components.first ?? ""
            let last = components.last ?? ""
            let middle = "..."
            let truncated = "\(first)/\(middle)/\(last)"

            if truncated.count <= maxLength {
                return truncated
            }
        }

        // If still too long, just truncate with ellipsis
        return String(path.prefix(maxLength - 3)) + "..."
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

        var excludedCount = 0
        let filteredOptions = options.filter { option in
            let isExcluded = isPackageExcluded(option.packageName, excludedPatterns: excluded)
            if isExcluded {
                excludedCount += 1
                if configuration.verbose == true {
                    Console.print("Excluded package: \(option.packageName) (matched exclusion patterns)", type: .detail)
                }
            }
            return !isExcluded
        }

        // Store excluded count for UI display
        self.lastExcludedCount = excludedCount
        self.lastExcludedPatterns = excluded

        return filteredOptions
    }

    private func isPackageExcluded(_ packageName: String, excludedPatterns: [String]) -> Bool {
        for pattern in excludedPatterns {
            if matchesExclusionPattern(packageName, pattern: pattern) {
                return true
            }
        }
        return false
    }

    private func matchesExclusionPattern(_ packageName: String, pattern: String) -> Bool {
        // Exact match (backwards compatibility)
        if packageName == pattern {
            return true
        }

        // Wildcard support
        if pattern.contains("*") {
            return matchesWildcard(packageName, pattern: pattern)
        }

        // Contains matching (case insensitive for user-friendly experience)
        return packageName.localizedCaseInsensitiveContains(pattern)
    }

    private func matchesWildcard(_ text: String, pattern: String) -> Bool {
        // Convert wildcard pattern to regex
        let escapedPattern = NSRegularExpression.escapedPattern(for: pattern)
        let regexPattern = escapedPattern.replacingOccurrences(of: "\\*", with: ".*")

        do {
            let regex = try NSRegularExpression(pattern: "^" + regexPattern + "$", options: .caseInsensitive)
            let range = NSRange(location: 0, length: text.utf16.count)
            return regex.firstMatch(in: text, options: [], range: range) != nil
        } catch {
            // If regex fails, fall back to simple contains matching
            return text.localizedCaseInsensitiveContains(pattern.replacingOccurrences(of: "*", with: ""))
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

// Extension to clear console line for progress updates
extension Console {
    static func clearLine() {
        Swift.print("\r\u{001B}[K", terminator: "")
    }
}