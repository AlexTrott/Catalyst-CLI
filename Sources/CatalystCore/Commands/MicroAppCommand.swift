import ArgumentParser
import Foundation
import Utilities
import MicroAppGenerator
import ConfigurationManager

public struct MicroAppCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "microapp",
        abstract: "Manage MicroApps (DEPRECATED: Use 'catalyst new microapp' to create)",
        usage: """
        catalyst microapp list
        catalyst microapp create <feature-name>  [DEPRECATED]
        """,
        discussion: """
        Manage existing MicroApps. For creating new MicroApps, use:
        - 'catalyst new feature <name>' for features with automatic companion MicroApp
        - 'catalyst new microapp <name>' for standalone MicroApps

        The create subcommand is deprecated and will be removed in a future version.
        """,
        subcommands: [
            CreateMicroAppCommand.self,
            ListMicroAppCommand.self
        ]
    )

    public init() {}
}

// MARK: - Subcommands

public struct CreateMicroAppCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new MicroApp from a Feature Module"
    )

    @Argument(help: "Name of the Feature Module to create a MicroApp for")
    public var featureName: String

    @Option(name: .shortAndLong, help: "Output directory for the MicroApp (overrides configured path)")
    public var output: String?

    @Flag(name: .long, help: "Preview what would be created without making changes")
    public var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() async throws {
        Console.printHeader("MicroApp Creation")

        Console.print("⚠️  DEPRECATED: Use 'catalyst new microapp <name>' instead", type: .warning)
        Console.print("   The 'microapp create' command will be removed in a future version.", type: .detail)
        Console.newLine()

        Console.print("💡 Try this instead:", type: .info)
        Console.print("   catalyst new microapp \(featureName)", type: .detail)
        Console.newLine()

        // Ask for confirmation to continue with deprecated command
        let shouldContinue = Console.confirm("Continue with deprecated command?", defaultAnswer: false)
        if !shouldContinue {
            Console.print("Operation cancelled. Use 'catalyst new microapp \(featureName)' for the new approach.", type: .info)
            return
        }

        // Continue with existing logic for backward compatibility
        try await runLegacyMicroAppCreation()
    }

    private func runLegacyMicroAppCreation() async throws {
        // Validate inputs
        try validateInputs()

        // Load configuration
        let configManager = ConfigurationManager()
        let config = try configManager.loadConfiguration()

        // Resolve output path from configuration or use explicit path
        let outputPath = output ?? config.paths.microApps ?? "./MicroApps"

        // Create MicroApp configuration
        let microAppConfig = MicroAppConfiguration(
            featureName: featureName,
            outputPath: outputPath,
            bundleIdentifier: config.bundleIdentifierPrefix.map { "\($0).\(featureName.lowercased())app" },
            author: config.author,
            organizationName: config.organizationName,
            swiftVersion: config.swiftVersion
        )

        if dryRun {
            try previewMicroAppCreation(microAppConfig)
            return
        }

        // Create the MicroApp
        try await createMicroApp(microAppConfig)

        let projectPath = (outputPath as NSString)
            .appendingPathComponent("\(featureName)App/\(featureName)App.xcodeproj")

        enableMicroAppTestsIfNeeded(
            config: config,
            moduleName: featureName,
            projectPath: projectPath
        )

        // Success message
        Console.printEmoji("✅", message: "MicroApp '\(featureName)App' created successfully!")
        Console.print("Location: \(outputPath)/\(featureName)App", type: .detail)

        // Provide next steps
        Console.newLine()
        Console.print("Next steps:", type: .info)
        Console.printList([
            "cd \(outputPath)/\(featureName)App",
            "open \(featureName)App.xcodeproj",
            "Build and run the MicroApp to test your feature"
        ])
    }

    private func validateInputs() throws {
        Console.printStep(1, total: 4, message: "Validating feature module...")

        // Check if feature name is valid
        try Validators.validateModuleName(featureName)

        // Find the feature module in configured paths
        guard let featureModulePath = try findFeatureModule(named: featureName) else {
            let searchPaths = try getSearchPaths()
            throw CatalystError.invalidModuleName("Feature module '\(featureName)' not found in search paths: \(searchPaths.joined(separator: ", "))")
        }

        // Validate it's a proper Swift package
        let packageSwiftPath = (featureModulePath as NSString).appendingPathComponent("Package.swift")
        guard FileManager.default.fileExists(atPath: packageSwiftPath) else {
            throw CatalystError.invalidProjectStructure("'\(featureName)' is not a valid Swift package (no Package.swift found)")
        }

        if verbose {
            Console.print("✓ Feature module found: \(featureName)", type: .detail)
            Console.print("✓ Valid Swift package structure", type: .detail)
        }
    }

    private func enableMicroAppTestsIfNeeded(config: CatalystConfiguration, moduleName: String, projectPath: String) {
        guard config.shouldAddTestTargetsToTestPlan == true,
              let planPath = config.microAppTestTargetPath,
              !planPath.isEmpty else {
            return
        }

        let testTargetName = "\(moduleName)AppUITests"
        do {
            try TestPlanManager().enableTestTarget(
                named: testTargetName,
                in: planPath,
                targetPath: projectPath,
                identifier: testTargetName,
                entryAttributes: ["parallelizable": true]
            )
            Console.print("✓ Enabled \(testTargetName) in test plan \(planPath)", type: .detail)
        } catch {
            Console.print("⚠️  Could not enable \(testTargetName) in test plan \(planPath): \(error.localizedDescription)", type: .warning)
        }
    }

    private func findFeatureModule(named name: String) throws -> String? {
        let searchPaths = try getSearchPaths()

        for searchPath in searchPaths {
            // Check direct path
            let directPath = (searchPath as NSString).appendingPathComponent(name)
            if FileManager.default.fileExists(atPath: directPath) {
                return directPath
            }

            // Search recursively in this path
            if let foundPath = try searchForModule(named: name, in: searchPath) {
                return foundPath
            }
        }

        return nil
    }

    private func getSearchPaths() throws -> [String] {
        let configManager = ConfigurationManager()
        let config = try configManager.loadConfiguration()

        var searchPaths: [String] = []

        // Add feature modules path from config
        if let featurePath = config.paths.featureModules {
            searchPaths.append(featurePath)
        }

        // Add current directory as fallback
        searchPaths.append(FileManager.default.currentDirectoryPath)

        return Array(Set(searchPaths)) // Remove duplicates
    }

    private func searchForModule(named name: String, in basePath: String) throws -> String? {
        let baseURL = URL(fileURLWithPath: basePath)
        return try searchDirectoryForModule(named: name, at: baseURL, depth: 0)
    }

    private func searchDirectoryForModule(named name: String, at url: URL, depth: Int) throws -> String? {
        // Prevent infinite recursion
        guard depth < 5 else { return nil }

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles])

        for item in contents {
            let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])

            if let isDirectory = resourceValues.isDirectory, isDirectory {
                // Check if this is the module we're looking for
                if item.lastPathComponent == name {
                    let packageSwiftPath = item.appendingPathComponent("Package.swift")
                    if fileManager.fileExists(atPath: packageSwiftPath.path) {
                        return item.path
                    }
                }

                // Continue searching recursively
                if let foundPath = try searchDirectoryForModule(named: name, at: item, depth: depth + 1) {
                    return foundPath
                }
            }
        }

        return nil
    }

    private func previewMicroAppCreation(_ configuration: MicroAppConfiguration) throws {
        Console.print("DRY RUN - No files will be created", type: .warning)
        Console.newLine()

        Console.print("Would create MicroApp: \(configuration.featureName)App")
        Console.print("Location: \(configuration.outputPath)/\(configuration.featureName)App")
        Console.print("Bundle ID: \(configuration.bundleIdentifier ?? "com.catalyst.\(configuration.featureName.lowercased())app")")

        Console.newLine()
        Console.print("Files to be created:", type: .info)
        Console.printList([
            "project.yml (XcodeGen configuration)",
            "\(configuration.featureName)App/AppDelegate.swift",
            "\(configuration.featureName)App/SceneDelegate.swift",
            "\(configuration.featureName)App/DependencyContainer.swift",
            "Info.plist",
            "Assets.xcassets/ (with app icons)",
            "LaunchScreen.storyboard"
        ])

        Console.newLine()
        Console.print("Dependencies:", type: .info)
        Console.printList([
            "Local package: ../\(configuration.featureName)"
        ])
    }

    private func createMicroApp(_ configuration: MicroAppConfiguration) async throws {
        Console.printStep(2, total: 4, message: "Creating MicroApp structure...")

        let microAppGenerator = MicroAppGenerator()
        try microAppGenerator.generateMicroApp(configuration)

        Console.printStep(3, total: 4, message: "Configuring dependencies...")
        // Dependencies are configured in the generateMicroApp method

        Console.printStep(4, total: 4, message: "Finalizing setup...")
        // XcodeGen project generation happens in generateMicroApp
    }
}

public struct ListMicroAppCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List existing MicroApps"
    )

    @Option(name: .shortAndLong, help: "Directory to search for MicroApps")
    public var directory: String = "./MicroApps"

    @Flag(name: .shortAndLong, help: "Show detailed information")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() throws {
        Console.printHeader("Existing MicroApps")

        guard FileManager.default.fileExists(atPath: directory) else {
            Console.print("MicroApps directory not found: \(directory)", type: .warning)
            Console.print("Create MicroApps with 'catalyst microapp create <feature-name>'", type: .detail)
            return
        }

        let microApps = try scanForMicroApps(in: directory)

        if microApps.isEmpty {
            Console.print("No MicroApps found in: \(directory)", type: .warning)
            Console.print("Create your first MicroApp with 'catalyst microapp create <feature-name>'", type: .detail)
            return
        }

        displayMicroApps(microApps)
    }

    private func scanForMicroApps(in directory: String) throws -> [MicroAppInfo] {
        let contents = try FileManager.default.contentsOfDirectory(atPath: directory)
        var microApps: [MicroAppInfo] = []

        for item in contents {
            let itemPath = (directory as NSString).appendingPathComponent(item)
            guard FileManager.default.isDirectory(at: itemPath) else { continue }

            // Check if it looks like a MicroApp (has project.yml)
            let projectYmlPath = (itemPath as NSString).appendingPathComponent("project.yml")
            guard FileManager.default.fileExists(atPath: projectYmlPath) else { continue }

            let microAppInfo = try extractMicroAppInfo(from: itemPath, name: item)
            microApps.append(microAppInfo)
        }

        return microApps.sorted { $0.name < $1.name }
    }

    private func extractMicroAppInfo(from path: String, name: String) throws -> MicroAppInfo {
        let projectYmlPath = (path as NSString).appendingPathComponent("project.yml")

        // Try to parse project.yml for info
        var featureName: String?
        var bundleId: String?

        if let content = try? String(contentsOfFile: projectYmlPath, encoding: .utf8) {
            // Simple parsing - look for package dependencies
            let lines = content.components(separatedBy: .newlines)
            for line in lines {
                if line.contains("packages:") {
                    continue
                } else if line.trimmingCharacters(in: .whitespaces).contains(":") &&
                          !line.contains("path:") {
                    let parts = line.trimmingCharacters(in: .whitespaces).components(separatedBy: ":")
                    if parts.count >= 2 && !parts[0].isEmpty {
                        featureName = parts[0].trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
            }

            // Extract bundle ID
            if let range = content.range(of: "bundleIdPrefix: ") {
                let afterPrefix = content[range.upperBound...]
                if let endRange = afterPrefix.range(of: "\n") {
                    bundleId = String(afterPrefix[..<endRange.lowerBound])
                }
            }
        }

        // Check if .xcodeproj exists
        let hasXcodeProject = (try? FileManager.default.contentsOfDirectory(atPath: path))?.contains { $0.hasSuffix(".xcodeproj") } ?? false

        return MicroAppInfo(
            name: name,
            path: path,
            featureName: featureName ?? extractFeatureNameFromAppName(name),
            bundleId: bundleId,
            hasXcodeProject: hasXcodeProject
        )
    }

    private func extractFeatureNameFromAppName(_ appName: String) -> String {
        if appName.hasSuffix("App") {
            return String(appName.dropLast(3))
        }
        return appName
    }

    private func displayMicroApps(_ microApps: [MicroAppInfo]) {
        Console.print("Found \(microApps.count) MicroApp\(microApps.count == 1 ? "" : "s"):", type: .info)
        Console.newLine()

        for (index, microApp) in microApps.enumerated() {
            let number = String(format: "%2d", index + 1)
            let statusIcon = microApp.hasXcodeProject ? "📱" : "⚠️"

            Console.print("\(number). \(statusIcon) \(microApp.name)")
            Console.print("    Feature: \(microApp.featureName)", type: .detail)

            if verbose {
                Console.print("    Path: \(microApp.path)", type: .detail)
                if let bundleId = microApp.bundleId {
                    Console.print("    Bundle ID: \(bundleId)", type: .detail)
                }
                Console.print("    Status: \(microApp.hasXcodeProject ? "Ready (Xcode project generated)" : "Incomplete (run XcodeGen)")", type: .detail)
            }
        }

        Console.newLine()
        Console.print("Usage:", type: .info)
        Console.printList([
            "Open: cd \(directory)/<MicroApp> && open *.xcodeproj",
            "Regenerate project: catalyst microapp create <feature-name> --dry-run=false"
        ])
    }

    private struct MicroAppInfo {
        let name: String
        let path: String
        let featureName: String
        let bundleId: String?
        let hasXcodeProject: Bool
    }
}
