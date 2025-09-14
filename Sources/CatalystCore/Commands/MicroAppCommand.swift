import ArgumentParser
import Foundation
import Utilities
import MicroAppGenerator
import ConfigurationManager

public struct MicroAppCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "microapp",
        abstract: "Create MicroApps for isolated feature testing",
        usage: """
        catalyst microapp create <feature-name>
        catalyst microapp list
        """,
        discussion: """
        MicroApps are minimal iOS applications that contain a single feature module
        for isolated development and testing. They use XcodeGen for project generation
        and include all necessary boilerplate to run immediately after creation.
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

    @Option(name: .shortAndLong, help: "Output directory for the MicroApp")
    public var output: String = "./MicroApps"

    @Flag(name: .long, help: "Preview what would be created without making changes")
    public var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() async throws {
        Console.printHeader("Creating MicroApp")

        // Validate inputs
        try validateInputs()

        // Load configuration
        let configManager = ConfigurationManager()
        let config = try configManager.loadConfiguration()

        // Create MicroApp configuration
        let microAppConfig = MicroAppConfiguration(
            featureName: featureName,
            outputPath: output,
            bundleIdentifier: config.bundleIdentifierPrefix.map { "\($0).\(featureName.lowercased())app" },
            author: config.author,
            organizationName: config.organizationName
        )

        if dryRun {
            try previewMicroAppCreation(microAppConfig)
            return
        }

        // Create the MicroApp
        try await createMicroApp(microAppConfig)

        // Success message
        Console.printEmoji("✅", message: "MicroApp '\(featureName)App' created successfully!")
        Console.print("Location: \(output)/\(featureName)App", type: .detail)

        // Provide next steps
        Console.newLine()
        Console.print("Next steps:", type: .info)
        Console.printList([
            "cd \(output)/\(featureName)App",
            "open \(featureName)App.xcodeproj",
            "Build and run the MicroApp to test your feature"
        ])
    }

    private func validateInputs() throws {
        Console.printStep(1, total: 4, message: "Validating feature module...")

        // Check if feature name is valid
        try Validators.validateModuleName(featureName)

        // Check if the feature module exists
        let featureModulePath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(featureName)
        guard FileManager.default.fileExists(atPath: featureModulePath) else {
            throw CatalystError.invalidModuleName("Feature module '\(featureName)' not found in current directory")
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

        if let content = try? String(contentsOfFile: projectYmlPath) {
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
            "Rebuild project: cd \(directory)/<MicroApp> && xcodegen generate"
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