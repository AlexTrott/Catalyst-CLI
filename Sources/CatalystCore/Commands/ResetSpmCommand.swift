import ArgumentParser
import Foundation
import PathKit
import Utilities

public struct ResetSpmCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "reset-spm",
        abstract: "Find and delete Package.resolved files to resolve SPM dependency conflicts",
        discussion: """
        Recursively searches for Package.resolved files in the current directory and subdirectories,
        then safely deletes them to resolve Swift Package Manager dependency conflicts.

        This command is useful when you encounter SPM resolution conflicts or need to force
        a fresh dependency resolution across your modular project structure.

        Examples:
          catalyst reset-spm                    # Find and delete with confirmation
          catalyst reset-spm --dry-run          # Preview what would be deleted
          catalyst reset-spm --force            # Delete without confirmation
          catalyst reset-spm --verbose          # Show detailed output
        """
    )

    @Flag(name: .shortAndLong, help: "Preview files that would be deleted without actually deleting them")
    var dryRun = false

    @Flag(name: .shortAndLong, help: "Delete files without confirmation prompt")
    var force = false

    @Flag(name: .shortAndLong, help: "Show detailed output during operation")
    var verbose = false

    @Option(name: .shortAndLong, help: "Directory to search in (defaults to current directory)")
    var path: String?

    @Flag(help: "Disable recursive search (search only in specified directory)")
    var noRecursive = false

    public init() {}

    public mutating func run() async throws {
        Console.printHeader("🧹 SPM Package Reset")

        let searchPath = Path(path ?? FileManager.default.currentDirectoryPath)

        if verbose {
            Console.print("Searching in: \(searchPath.absolute())", type: .detail)
            Console.print("Recursive: \(!noRecursive)", type: .detail)
        }

        Console.printStep(1, total: 3, message: "Scanning for Package.resolved files...")
        let resolvedFiles = try findPackageResolvedFiles(in: searchPath, recursive: !noRecursive)

        if resolvedFiles.isEmpty {
            Console.print("✨ No Package.resolved files found", type: .success)
            return
        }

        Console.print("Found \(resolvedFiles.count) Package.resolved file\(resolvedFiles.count == 1 ? "" : "s"):", type: .info)
        let fileList = resolvedFiles.map { file in
            let relativePath = getRelativePath(file: file, basePath: searchPath)
            return "📦 \(relativePath)"
        }
        Console.printList(fileList)

        if dryRun {
            Console.printBoxed("🔍 DRY RUN - No files were deleted", style: .rounded)
            return
        }

        if !force {
            Console.newLine()
            let confirmed = Console.confirm(
                "Delete these Package.resolved files?",
                defaultAnswer: false
            )

            if !confirmed {
                Console.print("Operation cancelled", type: .info)
                return
            }
        }

        Console.printStep(2, total: 3, message: "Deleting Package.resolved files...")
        var deletedCount = 0
        var failedCount = 0
        let progress = verbose ? nil : Console.progress(
            total: resolvedFiles.count,
            message: "Removing Package.resolved files"
        )

        for file in resolvedFiles {
            do {
                try file.delete()
                deletedCount += 1
                progress?.advance(message: getRelativePath(file: file, basePath: searchPath))

                if verbose {
                    let relativePath = getRelativePath(file: file, basePath: searchPath)
                    Console.print("✓ Deleted: \(relativePath)", type: .success)
                }
            } catch {
                failedCount += 1
                let relativePath = getRelativePath(file: file, basePath: searchPath)
                progress?.advance(message: relativePath)
                Console.print("✗ Failed to delete: \(relativePath) - \(error.localizedDescription)", type: .error)
            }
        }

        progress?.finish()

        Console.printStep(3, total: 3, message: "Cleanup completed")
        Console.newLine()
        if failedCount == 0 {
            Console.print("🎉 Successfully deleted \(deletedCount) Package.resolved file\(deletedCount == 1 ? "" : "s")", type: .success)
            Console.print("💡 Run `swift package resolve` in your project directories to regenerate dependencies", type: .info)
        } else {
            Console.print("⚠️  Deleted \(deletedCount) file\(deletedCount == 1 ? "" : "s"), failed to delete \(failedCount)", type: .warning)
        }
    }

    private func findPackageResolvedFiles(in directory: Path, recursive: Bool) throws -> [Path] {
        var resolvedFiles: [Path] = []
        let fileManager = FileManager.default

        // Check if Package.resolved exists in current directory
        let packageResolved = directory + "Package.resolved"
        if packageResolved.exists {
            resolvedFiles.append(packageResolved)
        }

        if recursive {
            // Get all subdirectories, excluding common build/cache directories
            let excludedDirectories: Set<String> = [
                ".git", ".build", "DerivedData", ".swiftpm", "build",
                "Pods", "node_modules", ".vscode", ".idea"
            ]

            let contents = try fileManager.contentsOfDirectory(atPath: directory.string)

            for item in contents {
                if excludedDirectories.contains(item) {
                    continue
                }

                let itemPath = directory + item
                var isDirectory: ObjCBool = false

                if fileManager.fileExists(atPath: itemPath.string, isDirectory: &isDirectory) && isDirectory.boolValue {
                    let subFiles = try findPackageResolvedFiles(in: itemPath, recursive: true)
                    resolvedFiles.append(contentsOf: subFiles)
                }
            }
        }

        return resolvedFiles
    }

    private func getRelativePath(file: Path, basePath: Path) -> String {
        let filePath = file.absolute().string
        let basePath = basePath.absolute().string

        if filePath.hasPrefix(basePath) {
            let relativePath = String(filePath.dropFirst(basePath.count))
            return relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        }

        return filePath
    }
}
