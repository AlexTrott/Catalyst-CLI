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
/// - **Feature modules**: UI components, view controllers, and coordinators
/// - **MicroApps**: Complete iOS applications for isolated testing
///
/// ## Examples
///
/// Create a core module for business logic:
/// ```bash
/// catalyst new core NetworkingCore
/// ```
///
/// Create a feature module with custom options:
/// ```bash
/// catalyst new feature ShoppingCart --author "John Doe" --path "./Features"
/// ```
///
/// Create a MicroApp for isolated testing:
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
        Creates a new Swift package module or MicroApp from a template. Supports Core modules for business logic,
        Feature modules for UI components, and MicroApps for isolated testing environments.
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

        // Create the module
        if configuration.type == .microapp {
            try await createMicroApp(configuration)
        } else {
            try await createModule(configuration)
        }

        // Success message
        Console.printEmoji("✅", message: "Module '\(moduleName)' created successfully!")
        Console.print("Location: \(configuration.path)/\(moduleName)", type: .detail)

        if let workspace = FileManager.default.findWorkspace() {
            Console.print("Added to workspace: \(workspace)", type: .detail)
        }
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

        return ModuleConfiguration(
            name: moduleName,
            type: type,
            path: targetPath,
            author: author,
            organizationName: organization
        )
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
        try packageGenerator.generatePackage(configuration)

        Console.printStep(3, total: 4, message: "Adding to workspace...")

        if let workspacePath = FileManager.default.findWorkspace() {
            let workspaceManager = WorkspaceManager()
            let packagePath = (configuration.path as NSString).appendingPathComponent(configuration.name)

            do {
                try workspaceManager.addPackageToWorkspace(
                    packagePath: packagePath,
                    workspacePath: workspacePath
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

        Console.printStep(4, total: 4, message: "Finalizing setup...")
    }

    private func createMicroApp(_ configuration: ModuleConfiguration) async throws {
        Console.printStep(2, total: 4, message: "Creating MicroApp...")

        // Convert ModuleConfiguration to MicroAppConfiguration
        let microAppConfig = MicroAppConfiguration(
            featureName: configuration.name,
            outputPath: configuration.path,
            bundleIdentifier: nil, // This will be generated based on app name
            author: configuration.author,
            organizationName: configuration.organizationName
        )

        let templateEngine = TemplateEngine()
        let microAppGenerator = MicroAppGenerator(templateEngine: templateEngine)
        try microAppGenerator.generateMicroApp(microAppConfig)

        Console.printStep(3, total: 4, message: "Configuring project...")
        Console.printStep(4, total: 4, message: "Finalizing setup...")
    }
}