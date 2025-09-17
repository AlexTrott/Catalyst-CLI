import Foundation
import SwiftyTextTable
import Rainbow

public enum PackageCategory: String, CaseIterable {
    case shared = "Shared"
    case core = "Core"
    case feature = "Feature"
    case unknown = "Unknown"

    public var icon: String {
        switch self {
        case .shared: return "🎯"
        case .core: return "🏗️"
        case .feature: return "🎨"
        case .unknown: return "📦"
        }
    }

    public var displayName: String {
        return "\(icon) \(rawValue) Packages"
    }
}

extension Console {

    public struct CategoryTableData {
        public let category: PackageCategory
        public let packages: [PackageRowData]
        public let startIndex: Int // For continuous numbering across tables

        public init(category: PackageCategory, packages: [PackageRowData], startIndex: Int) {
            self.category = category
            self.packages = packages
            self.startIndex = startIndex
        }
    }

    public struct PackageRowData {
        public let index: Int
        public let packageName: String
        public let productName: String
        public let type: String
        public let categoryPath: String // Shortened path within category
        public let isExcluded: Bool
        public let isInterface: Bool

        public init(index: Int, packageName: String, productName: String, type: String, categoryPath: String, isExcluded: Bool, isInterface: Bool) {
            self.index = index
            self.packageName = packageName
            self.productName = productName
            self.type = type
            self.categoryPath = categoryPath
            self.isExcluded = isExcluded
            self.isInterface = isInterface
        }
    }

    public static func printCategoryTables(
        _ categoryData: [CategoryTableData],
        title: String? = nil,
        exclusionInfo: ExclusionInfo? = nil
    ) {
        // Print main title if provided
        if let title = title {
            Console.newLine()
            Console.print(title.cyan.bold, type: .info)
            Console.newLine()
        }

        // Print exclusion info if packages were excluded
        if let exclusionInfo = exclusionInfo, exclusionInfo.count > 0 {
            printExclusionSummary(exclusionInfo)
            Console.newLine()
        }

        // Print each category table
        for (categoryIndex, data) in categoryData.enumerated() {
            if !data.packages.isEmpty {
                printCategoryTable(data)

                // Add spacing between tables except for the last one
                if categoryIndex < categoryData.count - 1 {
                    Console.newLine()
                }
            }
        }
    }

    private static func printCategoryTable(_ data: CategoryTableData) {
        let categoryTitle = "\(data.category.displayName) (\(data.packages.count))"
        Console.print(categoryTitle.bold, type: .info)
        Console.newLine()

        let columns = [
            TextTableColumn(header: "#"),
            TextTableColumn(header: "Package"),
            TextTableColumn(header: "Product"),
            TextTableColumn(header: "Type"),
            TextTableColumn(header: "Path")
        ]
        var table = TextTable(columns: columns)

        // Configure table styling
        table.cornerFence = "+"
        table.rowFence = "-"
        table.columnFence = "|"

        // Add data rows
        for package in data.packages {
            let indexStr = String(package.index)
            let typeStyled = stylePackageType(package.type, isInterface: package.isInterface)

            table.addRow(values: [
                indexStr,
                package.packageName.cyan,
                package.productName,
                typeStyled,
                package.categoryPath.lightBlack
            ])
        }

        // Print the table
        print(table.render())
    }

    private static func stylePackageType(_ type: String, isInterface: Bool) -> String {
        if isInterface {
            return type.cyan.bold
        } else {
            return type
        }
    }

    public struct ExclusionInfo {
        public let count: Int
        public let patterns: [String]
        public let hasWildcards: Bool

        public init(count: Int, patterns: [String], hasWildcards: Bool) {
            self.count = count
            self.patterns = patterns
            self.hasWildcards = hasWildcards
        }
    }

    private static func printExclusionSummary(_ info: ExclusionInfo) {
        var table = TextTable(columns: [
            TextTableColumn(header: "Exclusion Summary")
        ])

        table.cornerFence = "+"
        table.rowFence = "-"
        table.columnFence = "|"

        // Add exclusion details
        table.addRow(values: ["🚫 \(info.count) packages excluded by configuration".yellow])
        table.addRow(values: ["Exclusion patterns: \(info.patterns.joined(separator: ", "))".yellow])

        if info.hasWildcards {
            table.addRow(values: ["💡 Using wildcard matching (*) for flexible exclusions"])
        }

        print(table.render())
    }

    // Helper method to categorize packages by path
    public static func categorizePackage(path: String, basePaths: CategoryBasePaths? = nil) -> PackageCategory {
        let normalizedPath = path.replacingOccurrences(of: "\\", with: "/")

        // Use provided base paths or defaults
        let corePattern = basePaths?.core ?? "Modules/Core"
        let sharedPattern = basePaths?.shared ?? "Modules/Shared"
        let featurePattern = basePaths?.feature ?? "Modules/Features"

        if normalizedPath.contains(corePattern) {
            return .core
        } else if normalizedPath.contains(sharedPattern) {
            return .shared
        } else if normalizedPath.contains(featurePattern) {
            return .feature
        } else {
            return .unknown
        }
    }

    public struct CategoryBasePaths {
        public let core: String
        public let shared: String
        public let feature: String

        public init(core: String, shared: String, feature: String) {
            self.core = core
            self.shared = shared
            self.feature = feature
        }
    }

    // Helper to create shortened path within category
    public static func createCategoryPath(fullPath: String, category: PackageCategory, basePaths: CategoryBasePaths? = nil) -> String {
        let normalizedPath = fullPath.replacingOccurrences(of: "\\", with: "/")

        let basePattern: String
        switch category {
        case .core:
            basePattern = basePaths?.core ?? "Modules/Core"
        case .shared:
            basePattern = basePaths?.shared ?? "Modules/Shared"
        case .feature:
            basePattern = basePaths?.feature ?? "Modules/Features"
        case .unknown:
            return fullPath
        }

        // Remove the base pattern to show relative path within category
        if let range = normalizedPath.range(of: basePattern) {
            let remainingPath = String(normalizedPath[range.upperBound...])
            let trimmedPath = remainingPath.hasPrefix("/") ? String(remainingPath.dropFirst()) : remainingPath
            return trimmedPath.isEmpty ? "." : trimmedPath
        }

        return fullPath
    }

    // Legacy compatibility method for simple tables
    public static func printLegacyTable(
        columns: [String],
        rows: [[String]],
        title: String? = nil
    ) {
        var table = TextTable(columns: columns.map { TextTableColumn(header: $0) })

        table.cornerFence = "+"
        table.rowFence = "-"
        table.columnFence = "|"

        if let title = title {
            // Add title as first row
            let titleRow = [title.cyan.bold] + Array(repeating: "", count: columns.count - 1)
            table.addRow(values: titleRow)
            table.addRow(values: Array(repeating: "", count: columns.count))
        }

        for row in rows {
            table.addRow(values: row)
        }

        print(table.render())
    }
}
