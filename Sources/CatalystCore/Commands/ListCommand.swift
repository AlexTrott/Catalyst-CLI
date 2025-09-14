import ArgumentParser
import Foundation
import Utilities
import WorkspaceManager
import Files

public struct ListCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List modules and packages in the current workspace",
        usage: """
        catalyst list [options]
        catalyst list --verbose
        catalyst list --type packages
        """,
        discussion: """
        Shows all Swift packages and modules in the current Xcode workspace.
        Displays package names, types, and paths for easy reference.
        """
    )

    @Option(name: .shortAndLong, help: "Filter by type (packages, modules, all)")
    public var type: String = "all"

    @Flag(name: .shortAndLong, help: "Show detailed information")
    public var verbose: Bool = false

    @Flag(name: .long, help: "Show full paths instead of relative paths")
    public var fullPaths: Bool = false

    @Flag(name: .shortAndLong, help: "Search recursively through nested folders")
    public var recursive: Bool = false

    @Option(name: .long, help: "Base path to search for modules (defaults to current directory)")
    public var searchPath: String?

    public init() {}

    public mutating func run() async throws {
        if recursive {
            try await runRecursiveSearch()
        } else {
            try await runWorkspaceSearch()
        }
    }

    private func runWorkspaceSearch() async throws {
        Console.printHeader("Workspace Contents")

        guard let workspacePath = FileManager.default.findWorkspace() else {
            throw CatalystError.workspaceNotFound
        }

        Console.print("Workspace: \(workspacePath)", type: .info)
        Console.newLine()

        let workspaceManager = WorkspaceManager()

        do {
            let packages = try workspaceManager.listPackagesInWorkspace(workspacePath: workspacePath)

            if packages.isEmpty {
                Console.print("No packages found in workspace", type: .warning)
                Console.print("Use 'catalyst new' to create your first module", type: .detail)
                return
            }

            await displayPackages(packages, workspacePath: workspacePath)

        } catch {
            throw CatalystError.workspaceModificationFailed("Failed to read workspace: \(error.localizedDescription)")
        }
    }

    private func runRecursiveSearch() async throws {
        Console.printHeader("Recursive Module Search")

        let basePath = searchPath ?? FileManager.default.currentDirectoryPath
        Console.print("Searching in: \(basePath)", type: .info)
        Console.newLine()

        let packages = try findPackagesRecursively(in: basePath)

        if packages.isEmpty {
            Console.print("No Swift packages found", type: .warning)
            Console.print("Use 'catalyst new' to create your first module", type: .detail)
            return
        }

        await displayPackages(packages, workspacePath: basePath)
    }

    private func findPackagesRecursively(in basePath: String) throws -> [WorkspacePackage] {
        var packages: [WorkspacePackage] = []
        let baseURL = URL(fileURLWithPath: basePath)

        try searchDirectory(at: baseURL, packages: &packages, depth: 0)

        return packages.sorted { $0.path < $1.path }
    }

    private func searchDirectory(at url: URL, packages: inout [WorkspacePackage], depth: Int) throws {
        // Prevent infinite recursion and overly deep searches
        guard depth < 10 else { return }

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

        for item in contents {
            let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])

            if let isDirectory = resourceValues.isDirectory, isDirectory {
                // Check if this directory contains Package.swift
                let packageSwiftPath = item.appendingPathComponent("Package.swift")
                if fileManager.fileExists(atPath: packageSwiftPath.path) {
                    let relativePath = item.path.replacingOccurrences(of: url.path + "/", with: "")
                    let package = WorkspacePackage(
                        name: item.lastPathComponent,
                        path: relativePath,
                        fullPath: item.path,
                        type: .swiftPackage
                    )
                    packages.append(package)
                }

                // Continue searching recursively in subdirectories
                try searchDirectory(at: item, packages: &packages, depth: depth + 1)
            }
        }
    }

    private func displayPackages(_ packages: [WorkspacePackage], workspacePath: String) async {
        let filteredPackages = filterPackages(packages)

        Console.print("Found \(filteredPackages.count) package\(filteredPackages.count == 1 ? "" : "s"):", type: .info)
        Console.newLine()

        if verbose {
            await displayDetailedView(filteredPackages, workspacePath: workspacePath)
        } else {
            displaySimpleView(filteredPackages)
        }

        Console.newLine()
        displaySummary(filteredPackages)
    }

    private func filterPackages(_ packages: [WorkspacePackage]) -> [WorkspacePackage] {
        switch type.lowercased() {
        case "packages", "package":
            return packages.filter { $0.type == .swiftPackage }
        case "projects", "project":
            return packages.filter { $0.type == .xcodeProject }
        case "folders", "folder":
            return packages.filter { $0.type == .folder }
        case "all", "":
            return packages
        default:
            Console.print("Unknown filter type '\(type)'. Showing all packages.", type: .warning)
            return packages
        }
    }

    private func displaySimpleView(_ packages: [WorkspacePackage]) {
        for (index, package) in packages.enumerated() {
            let number = String(format: "%2d", index + 1)
            let typeIcon = iconFor(packageType: package.type)
            let path = fullPaths ? package.fullPath : package.path

            Console.print("\(number). \(typeIcon) \(package.name)")
            Console.print("    Path: \(path)", type: .detail)
        }
    }

    private func displayDetailedView(_ packages: [WorkspacePackage], workspacePath: String) async {
        for (index, package) in packages.enumerated() {
            Console.print("─" * 50)
            Console.print("\(index + 1). \(package.name)", type: .info)

            let typeIcon = iconFor(packageType: package.type)
            Console.print("   Type: \(typeIcon) \(packageTypeDescription(package.type))")

            let path = fullPaths ? package.fullPath : package.path
            Console.print("   Path: \(path)")

            // Additional details for Swift packages
            if package.type == .swiftPackage {
                await displaySwiftPackageDetails(package)
            }

            Console.newLine()
        }
    }

    private func displaySwiftPackageDetails(_ package: WorkspacePackage) async {
        let packageSwiftPath = (package.fullPath as NSString).appendingPathComponent("Package.swift")

        if FileManager.default.fileExists(atPath: packageSwiftPath) {
            // Try to read Package.swift for more details
            do {
                let content = try String(contentsOfFile: packageSwiftPath)

                // Extract product names (simplified parsing)
                let productNames = extractProducts(from: content)
                if !productNames.isEmpty {
                    Console.print("   Products: \(productNames.joined(separator: ", "))")
                }

                // Extract target names (simplified parsing)
                let targetNames = extractTargets(from: content)
                if !targetNames.isEmpty {
                    Console.print("   Targets: \(targetNames.joined(separator: ", "))")
                }

            } catch {
                Console.print("   (Unable to read Package.swift details)")
            }
        }

        // Check for README
        let readmePaths = ["README.md", "README.txt", "README"]
        for readmeName in readmePaths {
            let readmePath = (package.fullPath as NSString).appendingPathComponent(readmeName)
            if FileManager.default.fileExists(atPath: readmePath) {
                Console.print("   Documentation: \(readmeName)")
                break
            }
        }
    }

    private func displaySummary(_ packages: [WorkspacePackage]) {
        let swiftPackages = packages.filter { $0.type == .swiftPackage }.count
        let xcodeProjects = packages.filter { $0.type == .xcodeProject }.count
        let folders = packages.filter { $0.type == .folder }.count

        Console.print("Summary:", type: .info)
        if swiftPackages > 0 {
            Console.print("  📦 \(swiftPackages) Swift package\(swiftPackages == 1 ? "" : "s")")
        }
        if xcodeProjects > 0 {
            Console.print("  🏗  \(xcodeProjects) Xcode project\(xcodeProjects == 1 ? "" : "s")")
        }
        if folders > 0 {
            Console.print("  📁 \(folders) folder\(folders == 1 ? "" : "s")")
        }
    }

    private func iconFor(packageType: WorkspacePackage.PackageType) -> String {
        switch packageType {
        case .swiftPackage:
            return "📦"
        case .xcodeProject:
            return "🏗"
        case .folder:
            return "📁"
        }
    }

    private func packageTypeDescription(_ type: WorkspacePackage.PackageType) -> String {
        switch type {
        case .swiftPackage:
            return "Swift Package"
        case .xcodeProject:
            return "Xcode Project"
        case .folder:
            return "Folder"
        }
    }

    // Simple regex-based extraction (could be improved with proper parsing)
    private func extractProducts(from content: String) -> [String] {
        let pattern = #"\.library\(\s*name:\s*"([^"]+)""#
        return extractMatches(from: content, pattern: pattern)
    }

    private func extractTargets(from content: String) -> [String] {
        let pattern = #"\.target\(\s*name:\s*"([^"]+)""#
        return extractMatches(from: content, pattern: pattern)
    }

    private func extractMatches(from content: String, pattern: String) -> [String] {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            return matches.compactMap { match in
                guard match.numberOfRanges > 1 else { return nil }
                let range = match.range(at: 1)
                guard let swiftRange = Range(range, in: content) else { return nil }
                return String(content[swiftRange])
            }
        } catch {
            return []
        }
    }
}

// String extension for repeating characters
private extension String {
    static func *(lhs: String, rhs: Int) -> String {
        return String(repeating: lhs, count: rhs)
    }
}