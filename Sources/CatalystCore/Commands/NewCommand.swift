import ArgumentParser
import Foundation
import Utilities
import TemplateEngine
import PackageGenerator
import struct PackageGenerator.ModuleConfiguration
import enum PackageGenerator.ModuleType
import WorkspaceManager
import ConfigurationManager
import MicroAppGenerator

/// Create new Swift modules from templates.
///
/// The `NewCommand` supports creating three types of modules:
/// - **Core modules**: Business logic, services, and models
/// - **Feature modules**: UI components with companion MicroApp for testing
/// - **MicroApps**: Complete iOS applications for isolated testing
///
/// ## Feature Module Creation
///
/// When creating a feature module, Catalyst now automatically generates both:
/// - A reusable Swift Package for the feature
/// - A companion MicroApp for isolated testing
///
/// The structure will be:
/// ```
/// FeatureName/
///   ├── FeatureName/        # The Feature Module package
///   └── FeatureNameApp/     # The companion MicroApp
/// ```
///
/// ## Examples
///
/// Create a core module for business logic:
/// ```bash
/// catalyst new core NetworkingCore
/// ```
///
/// Create a feature module with companion MicroApp:
/// ```bash
/// catalyst new feature ShoppingCart --author "John Doe" --path "./Features"
/// ```
///
/// Create a standalone MicroApp:
/// ```bash
/// catalyst new microapp TestApp
/// ```
///
/// Preview creation without making changes:
/// ```bash
/// catalyst new core DataLayer --dry-run
/// ```
public struct NewCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new Swift module",
        usage: """
        catalyst new <type> <name> [options]
        catalyst new core NetworkingCore
        catalyst new feature AuthenticationFeature --author "John Doe"
        catalyst new microapp TestApp
        """,
        discussion: """
        Creates a new Swift package module or MicroApp from a template.

        Core modules: Create business logic and service layers
        Feature modules: Create UI components with automatic companion MicroApp for testing
        MicroApps: Create standalone iOS applications for isolated testing

        Note: Feature modules now automatically include a companion MicroApp in the same folder structure.
        """
    )

    @Argument(help: "The type of module to create (core, feature, microapp)")
    public var moduleType: String

    @Argument(help: "The name of the module")
    public var moduleName: String

    @Option(name: .shortAndLong, help: "The path where the module should be created (overrides default paths)")
    public var path: String?

    @Option(name: .shortAndLong, help: "The author name for the module")
    public var author: String?

    @Option(name: .shortAndLong, help: "The organization name")
    public var organization: String?

    @Option(name: .shortAndLong, help: "Custom template to use instead of built-in templates")
    public var template: String?

    @Flag(name: .shortAndLong, help: "Force overwrite if module already exists")
    public var force: Bool = false

    @Flag(name: .long, help: "Preview what would be created without making changes")
    public var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() async throws {
        // Show the awesome banner
        Console.printBanner()

        Console.printHeader("Creating New Module")

        // Resolve target path first
        let targetPath = try resolveTargetPath()

        // Validate inputs
        try validateInputs(targetPath: targetPath)

        // Create module configuration
        let configuration = try createModuleConfiguration(targetPath: targetPath)

        if dryRun {
            try previewModuleCreation(configuration)
            return
        }

        // Create the module with fancy progress
        if configuration.type == .microapp {
            try await createMicroApp(configuration)
        } else {
            try await createModule(configuration)
        }

        // Success celebration
        Console.newLine()
        Console.printRainbow("🎉 SUCCESS! 🎉")
        Console.printBoxed("Module '\(moduleName)' created successfully!", style: .rounded)

        // Show appropriate location based on module type
        if configuration.type == .feature {
            Console.newLine()
            Console.print("📁 Created at: \(configuration.path)/\(moduleName)/", type: .info)
            Console.print("  🎯 Feature Module: \(moduleName)/\(moduleName)", type: .detail)
            Console.print("  📱 MicroApp: \(moduleName)/\(moduleName)App", type: .detail)
        } else {
            Console.print("📁 Location: \(configuration.path)/\(moduleName)", type: .info)
        }

        if let workspace = FileManager.default.findWorkspace() {
            Console.print("🔗 Added to workspace: \(workspace)", type: .success)
        }

        Console.newLine()
        Console.printGradientText("Happy coding! ⚡")
    }

    private func resolveTargetPath() throws -> String {
        if let explicitPath = path {
            return explicitPath
        }

        // Load configuration to get default paths
        let configManager = ConfigurationManager()
        let config = try configManager.loadConfiguration()

        guard let moduleType = ModuleType.from(string: moduleType) else {
            return "."
        }

        switch moduleType {
        case .core:
            return config.paths.coreModules ?? "."
        case .feature:
            return config.paths.featureModules ?? "."
        case .microapp:
            return config.paths.microApps ?? "./MicroApps"
        }
    }

    private func validateInputs(targetPath: String) throws {
        Console.printStep(1, total: 4, message: "Validating inputs...")

        // Validate module type
        guard let _ = ModuleType.from(string: moduleType) else {
            throw CatalystError.invalidModuleName("Unsupported module type: \(moduleType)")
        }

        // Validate module name
        try Validators.validateModuleName(moduleName)

        // Create target directory if it doesn't exist
        try FileManager.default.createDirectoryIfNeeded(at: targetPath)

        // Validate path exists now
        try Validators.validateDirectoryExists(targetPath)

        // Check if module already exists
        let modulePath = (targetPath as NSString).appendingPathComponent(moduleName)
        if !force && FileManager.default.fileExists(atPath: modulePath) {
            throw CatalystError.moduleAlreadyExists(moduleName)
        }

        if verbose {
            if let type = ModuleType.from(string: moduleType) {
                Console.print("✓ Module type: \(type.displayName)", type: .detail)
            }
            Console.print("✓ Module name: \(moduleName)", type: .detail)
            Console.print("✓ Target path: \(targetPath)", type: .detail)
        }
    }

    private func createModuleConfiguration(targetPath: String) throws -> ModuleConfiguration {
        guard let type = ModuleType.from(string: moduleType) else {
            throw CatalystError.invalidModuleName("Invalid module type")
        }

        // Load configuration from .catalyst.yml
        let configManager = ConfigurationManager()
        let config = try configManager.loadConfiguration()

        // Parse platforms from configuration
        let platforms = parsePlatforms(from: config.defaultPlatforms) ?? [.iOS(.v16)]

        // Use configuration values or fallbacks
        let resolvedAuthor = author ?? config.author
        let resolvedOrganization = organization ?? config.organizationName
        let swiftVersion = config.swiftVersion ?? "5.9"

        return ModuleConfiguration(
            name: moduleName,
            type: type,
            path: targetPath,
            author: resolvedAuthor,
            organizationName: resolvedOrganization,
            bundleIdentifier: config.bundleIdentifierPrefix.map { "\($0).\(moduleName.lowercased())" },
            swiftVersion: swiftVersion,
            platforms: platforms,
            dependencies: [],
            customTemplateVariables: config.defaultTemplateVariables ?? [:]
        )
    }

    private func parsePlatforms(from platformStrings: [String]?) -> [Platform]? {
        guard let platformStrings = platformStrings, !platformStrings.isEmpty else {
            return nil
        }

        return platformStrings.compactMap { platformString in
            // Parse strings like ".iOS(.v15)", ".macOS(.v12)"
            if platformString.contains("iOS") {
                if platformString.contains("v15") {
                    return .iOS(.v15)
                } else if platformString.contains("v16") {
                    return .iOS(.v16)
                } else if platformString.contains("v17") {
                    return .iOS(.v17)
                } else if platformString.contains("v14") {
                    return .iOS(.v14)
                } else if platformString.contains("v13") {
                    return .iOS(.v13)
                } else if platformString.contains("v12") {
                    return .iOS(.v12)
                } else {
                    return .iOS(.v16) // Default iOS version
                }
            } else if platformString.contains("macOS") {
                if platformString.contains("v12") {
                    return .macOS(.v12)
                } else if platformString.contains("v13") {
                    return .macOS(.v13)
                } else if platformString.contains("v14") {
                    return .macOS(.v14)
                } else if platformString.contains("v15") {
                    return .macOS(.v15)
                } else if platformString.contains("v16") {
                    return .macOS(.v16)
                } else if platformString.contains("v17") {
                    return .macOS(.v17)
                } else {
                    return .macOS(.v13) // Default macOS version
                }
            }
            return nil
        }
    }

    private func previewModuleCreation(_ configuration: ModuleConfiguration) throws {
        Console.print("DRY RUN - No files will be created", type: .warning)
        Console.newLine()

        Console.print("Would create \(configuration.type.displayName): \(configuration.name)")
        Console.print("Location: \(configuration.path)/\(configuration.name)")

        Console.newLine()
        Console.print("Directory structure:", type: .info)
        let structure = configuration.type.directoryStructure.map { path in
            path.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
        }
        Console.printList(structure)

        Console.newLine()
        Console.print("Source files:", type: .info)
        let sourceFiles = configuration.type.sourceFiles.map { file in
            file.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
        }
        Console.printList(sourceFiles)

        Console.newLine()
        Console.print("Test files:", type: .info)
        let testFiles = configuration.type.testFiles.map { file in
            file.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
        }
        Console.printList(testFiles)
    }

    private func createModule(_ configuration: ModuleConfiguration) async throws {
        Console.printStep(2, total: 4, message: "Generating package structure...")

        let templateEngine = TemplateEngine()
        let packageGenerator = PackageGenerator(templateEngine: templateEngine)

        // For feature modules, create both the module and MicroApp
        if configuration.type == .feature {
            try await createFeatureWithMicroApp(configuration, templateEngine: templateEngine, packageGenerator: packageGenerator)
        } else {
            // For other module types, use the existing flow
            try packageGenerator.generatePackage(configuration)

            Console.printStep(3, total: 4, message: "Adding to workspace...")

            if let workspacePath = FileManager.default.findWorkspace() {
                let workspaceManager = WorkspaceManager()
                let packagePath = (configuration.path as NSString).appendingPathComponent(configuration.name)

                // Determine appropriate group based on module type
                let groupPath = getWorkspaceGroupPath(for: configuration.type)

                do {
                    try workspaceManager.addPackageToWorkspace(
                        packagePath: packagePath,
                        workspacePath: workspacePath,
                        groupPath: groupPath
                    )
                    Console.print("✓ Added package to workspace", type: .detail)
                } catch {
                    Console.print("⚠️  Could not add to workspace: \(error.localizedDescription)", type: .warning)
                    Console.print("You can manually add the package to your workspace later", type: .detail)
                }
            } else {
                Console.print("⚠️  No workspace found - package created but not added to workspace", type: .warning)
                Console.print("Create an Xcode workspace to automatically include new packages", type: .detail)
            }
        }

        Console.printStep(4, total: 4, message: "Finalizing setup...")
    }

    private func createFeatureWithMicroApp(_ configuration: ModuleConfiguration, templateEngine: TemplateEngine, packageGenerator: PackageGenerator) async throws {
        // Create wrapper folder
        let wrapperPath = (configuration.path as NSString).appendingPathComponent(configuration.name)
        try FileManager.default.createDirectory(atPath: wrapperPath, withIntermediateDirectories: true, attributes: nil)

        // Create Feature Module in wrapper/FeatureName
        let featureConfiguration = ModuleConfiguration(
            name: configuration.name,
            type: configuration.type,
            path: wrapperPath,
            author: configuration.author,
            organizationName: configuration.organizationName,
            bundleIdentifier: configuration.bundleIdentifier,
            swiftVersion: configuration.swiftVersion,
            platforms: configuration.platforms,
            dependencies: configuration.dependencies,
            customTemplateVariables: configuration.customTemplateVariables
        )
        try packageGenerator.generatePackage(featureConfiguration)

        Console.printStep(3, total: 4, message: "Creating companion MicroApp...")

        // Create MicroApp in wrapper/FeatureNameApp
        let microAppConfig = MicroAppConfiguration(
            featureName: configuration.name,
            outputPath: wrapperPath,
            bundleIdentifier: configuration.bundleIdentifier,
            author: configuration.author,
            organizationName: configuration.organizationName,
            isLocalPackage: true,  // New parameter to indicate local package reference
            addToWorkspace: false  // We handle workspace integration manually in NewCommand
        )

        let microAppGenerator = MicroAppGenerator(templateEngine: templateEngine)
        try microAppGenerator.generateMicroApp(microAppConfig)

        // Add Feature Module and MicroApp to workspace using feature-specific integration
        if let workspacePath = FileManager.default.findWorkspace() {
            let workspaceManager = WorkspaceManager()
            let packagePath = (wrapperPath as NSString).appendingPathComponent(configuration.name)
            let microAppProjectPath = (wrapperPath as NSString).appendingPathComponent("\(configuration.name)App")
            let microAppXcodeProjPath = (microAppProjectPath as NSString).appendingPathComponent("\(configuration.name)App.xcodeproj")

            do {
                // Use feature-specific workspace integration to create proper nested structure
                try workspaceManager.addFeatureToWorkspace(
                    featureName: configuration.name,
                    featurePackagePath: packagePath,
                    microAppProjectPath: microAppXcodeProjPath,
                    workspacePath: workspacePath
                )
                Console.print("✓ Added feature package to workspace", type: .detail)
                Console.print("✓ Added MicroApp project to workspace", type: .detail)
                Console.print("✓ Created companion MicroApp at \(wrapperPath)/\(configuration.name)App", type: .detail)
            } catch {
                Console.print("⚠️  Could not add to workspace: \(error.localizedDescription)", type: .warning)
                Console.print("You can manually add the package to your workspace later", type: .detail)
            }
        } else {
            Console.print("⚠️  No workspace found - package created but not added to workspace", type: .warning)
            Console.print("Create an Xcode workspace to automatically include new packages", type: .detail)
        }
    }

    private func createMicroApp(_ configuration: ModuleConfiguration) async throws {
        Console.printStep(2, total: 4, message: "Creating MicroApp...")

        // Convert ModuleConfiguration to MicroAppConfiguration
        let microAppConfig = MicroAppConfiguration(
            featureName: configuration.name,
            outputPath: configuration.path,
            bundleIdentifier: nil, // This will be generated based on app name
            author: configuration.author,
            organizationName: configuration.organizationName,
            addToWorkspace: true  // Standalone MicroApps should be added to workspace
        )

        let templateEngine = TemplateEngine()
        let microAppGenerator = MicroAppGenerator(templateEngine: templateEngine)
        try microAppGenerator.generateMicroApp(microAppConfig)

        Console.printStep(3, total: 4, message: "Configuring project...")
        Console.printStep(4, total: 4, message: "Finalizing setup...")
    }

    private func getWorkspaceGroupPath(for moduleType: ModuleType) -> String? {
        switch moduleType {
        case .core:
            return "Modules/Core"
        case .feature:
            return "Modules/Features"
        case .microapp:
            return "MicroApps"
        }
    }
}