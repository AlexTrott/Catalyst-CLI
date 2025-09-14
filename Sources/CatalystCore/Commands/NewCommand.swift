import ArgumentParser
import Foundation
import Utilities
import TemplateEngine
import PackageGenerator
import struct PackageGenerator.ModuleConfiguration
import enum PackageGenerator.ModuleType
import WorkspaceManager

public struct NewCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "new",
        abstract: "Create a new Swift module",
        usage: """
        catalyst new <type> <name> [options]
        catalyst new core NetworkingCore
        catalyst new feature AuthenticationFeature --author "John Doe"
        """,
        discussion: """
        Creates a new Swift package module from a template. Supports Core modules for business logic
        and Feature modules for UI components. Automatically adds the module to your Xcode workspace.
        """
    )

    @Argument(help: "The type of module to create (core, feature)")
    public var moduleType: String

    @Argument(help: "The name of the module")
    public var moduleName: String

    @Option(name: .shortAndLong, help: "The path where the module should be created")
    public var path: String = "."

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

        // Validate inputs
        try validateInputs()

        // Create module configuration
        let configuration = try createModuleConfiguration()

        if dryRun {
            try previewModuleCreation(configuration)
            return
        }

        // Create the module
        try await createModule(configuration)

        // Success message
        Console.printEmoji("✅", message: "Module '\(moduleName)' created successfully!")
        Console.print("Location: \(configuration.path)/\(moduleName)", type: .detail)

        if let workspace = FileManager.default.findWorkspace() {
            Console.print("Added to workspace: \(workspace)", type: .detail)
        }
    }

    private func validateInputs() throws {
        Console.printStep(1, total: 4, message: "Validating inputs...")

        // Validate module type
        guard let _ = ModuleType.from(string: moduleType) else {
            throw CatalystError.invalidModuleName("Unsupported module type: \(moduleType)")
        }

        // Validate module name
        try Validators.validateModuleName(moduleName)

        // Validate path
        try Validators.validateDirectoryExists(path)

        // Check if module already exists
        let modulePath = (path as NSString).appendingPathComponent(moduleName)
        if !force && FileManager.default.fileExists(atPath: modulePath) {
            throw CatalystError.moduleAlreadyExists(moduleName)
        }

        if verbose {
            if let type = ModuleType.from(string: moduleType) {
                Console.print("✓ Module type: \(type.displayName)", type: .detail)
            }
            Console.print("✓ Module name: \(moduleName)", type: .detail)
            Console.print("✓ Target path: \(path)", type: .detail)
        }
    }

    private func createModuleConfiguration() throws -> ModuleConfiguration {
        guard let type = ModuleType.from(string: moduleType) else {
            throw CatalystError.invalidModuleName("Invalid module type")
        }

        return ModuleConfiguration(
            name: moduleName,
            type: type,
            path: path,
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
}