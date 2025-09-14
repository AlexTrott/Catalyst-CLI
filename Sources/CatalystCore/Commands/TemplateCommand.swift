import ArgumentParser
import Foundation
import Utilities
import TemplateEngine
import PathKit
import Stencil

public struct TemplateCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "template",
        abstract: "Manage Catalyst templates",
        usage: """
        catalyst template list
        catalyst template show <name>
        catalyst template validate <name>
        """,
        discussion: """
        View, add, and manage templates used by Catalyst for module generation.
        Templates are written using Stencil syntax and can be customized for your needs.
        """,
        subcommands: [
            ListTemplatesCommand.self,
            ShowTemplateCommand.self,
            ValidateTemplateCommand.self
        ]
    )

    public init() {}
}

// MARK: - Subcommands

public struct ListTemplatesCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List available templates"
    )

    @Flag(name: .shortAndLong, help: "Show detailed information about each template")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() throws {
        Console.printHeader("Available Templates")

        let templateEngine = TemplateEngine()
        let templateLoader = TemplateLoader()

        let templates = templateLoader.listTemplatesWithDetails()

        if templates.isEmpty {
            Console.print("No templates found", type: .warning)
            Console.print("Templates should be placed in:", type: .info)
            Console.printList([
                "Templates/ (in current directory)",
                "~/.catalyst/templates/ (user templates)",
                "Built-in templates (CoreModule, FeatureModule)"
            ])
            return
        }

        if verbose {
            displayDetailedTemplates(templates)
        } else {
            displaySimpleTemplates(templates)
        }

        Console.newLine()
        displayTemplateSummary(templates)
    }

    private func displaySimpleTemplates(_ templates: [(name: String, path: String, type: String)]) {
        Console.print("Found \(templates.count) template\(templates.count == 1 ? "" : "s"):", type: .info)
        Console.newLine()

        for (index, template) in templates.enumerated() {
            let number = String(format: "%2d", index + 1)
            let typeIcon = template.type == "directory" ? "📁" : "📄"

            Console.print("\(number). \(typeIcon) \(template.name)")
            Console.print("    Type: \(template.type)", type: .detail)
        }
    }

    private func displayDetailedTemplates(_ templates: [(name: String, path: String, type: String)]) {
        for (index, template) in templates.enumerated() {
            Console.print(String(repeating: "─", count: 50))
            Console.print("\(index + 1). \(template.name)", type: .info)

            let typeIcon = template.type == "directory" ? "📁" : "📄"
            Console.print("   Type: \(typeIcon) \(template.type.capitalized)")
            Console.print("   Path: \(template.path)")

            if template.type == "directory" {
                displayDirectoryTemplateDetails(at: template.path)
            } else {
                displayFileTemplateDetails(at: template.path)
            }

            Console.newLine()
        }
    }

    private func displayDirectoryTemplateDetails(at path: String) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: path)
            let stencilFiles = contents.filter { $0.hasSuffix(".stencil") }

            if !stencilFiles.isEmpty {
                Console.print("   Template files: \(stencilFiles.count)")
                for file in stencilFiles.prefix(3) {
                    Console.print("     • \(file)")
                }
                if stencilFiles.count > 3 {
                    Console.print("     • ... and \(stencilFiles.count - 3) more")
                }
            }

            let subdirectories = contents.filter { item in
                let itemPath = (path as NSString).appendingPathComponent(item)
                return FileManager.default.isDirectory(at: itemPath)
            }

            if !subdirectories.isEmpty {
                Console.print("   Subdirectories: \(subdirectories.joined(separator: ", "))")
            }
        } catch {
            Console.print("   (Unable to read directory contents)")
        }
    }

    private func displayFileTemplateDetails(at path: String) {
        do {
            let content = try String(contentsOfFile: path)
            let lines = content.components(separatedBy: .newlines)
            Console.print("   Size: \(content.count) characters, \(lines.count) lines")

            // Try to find template variables
            let variables = extractTemplateVariables(from: content)
            if !variables.isEmpty {
                Console.print("   Variables: \(variables.joined(separator: ", "))")
            }
        } catch {
            Console.print("   (Unable to read file)")
        }
    }

    private func displayTemplateSummary(_ templates: [(name: String, path: String, type: String)]) {
        let directoryTemplates = templates.filter { $0.type == "directory" }.count
        let fileTemplates = templates.filter { $0.type == "file" }.count

        Console.print("Summary:", type: .info)
        if directoryTemplates > 0 {
            Console.print("  📁 \(directoryTemplates) directory template\(directoryTemplates == 1 ? "" : "s")")
        }
        if fileTemplates > 0 {
            Console.print("  📄 \(fileTemplates) file template\(fileTemplates == 1 ? "" : "s")")
        }
    }

    private func extractTemplateVariables(from content: String) -> [String] {
        let pattern = #"\{\{([^}]+)\}\}"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            let variables = matches.compactMap { match -> String? in
                guard match.numberOfRanges > 1 else { return nil }
                let range = match.range(at: 1)
                guard let swiftRange = Range(range, in: content) else { return nil }
                let variable = String(content[swiftRange])
                return variable.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return Array(Set(variables)).sorted() // Remove duplicates and sort
        } catch {
            return []
        }
    }
}

public struct ShowTemplateCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "show",
        abstract: "Show template content and details"
    )

    @Argument(help: "Template name to show")
    public var templateName: String

    @Flag(name: .long, help: "Show raw template content")
    public var raw: Bool = false

    public init() {}

    public mutating func run() throws {
        Console.printHeader("Template: \(templateName)")

        let templateLoader = TemplateLoader()

        do {
            let templatePath = try templateLoader.getTemplate(named: templateName)

            Console.print("Path: \(templatePath.string)", type: .info)
            Console.print("Type: \(templatePath.isDirectory ? "Directory" : "File")", type: .info)
            Console.newLine()

            if templatePath.isDirectory {
                try showDirectoryTemplate(at: templatePath)
            } else {
                try showFileTemplate(at: templatePath)
            }

        } catch TemplateEngineError.templateNotFound(let name, let available) {
            Console.print("Template '\(name)' not found", type: .error)
            Console.print("Available templates: \(available.joined(separator: ", "))", type: .detail)
            throw ExitCode.failure
        } catch {
            Console.print("Error loading template: \(error.localizedDescription)", type: .error)
            throw ExitCode.failure
        }
    }

    private func showDirectoryTemplate(at path: PathKit.Path) throws {
        Console.print("Template Structure:", type: .info)
        try showDirectoryContents(path, prefix: "")

        Console.newLine()

        // Show main template files
        let packageSwiftTemplate = path + "Package.swift.stencil"
        if packageSwiftTemplate.exists {
            Console.print("Package.swift Template:", type: .info)
            try showTemplateFile(packageSwiftTemplate, maxLines: raw ? nil : 20)
            Console.newLine()
        }

        // Find and show main source template
        let sourcesDir = path + "Sources"
        if sourcesDir.exists {
            let mainTemplate = findMainSourceTemplate(in: sourcesDir)
            if let mainTemplate = mainTemplate {
                Console.print("Main Source Template:", type: .info)
                Console.print("File: \(mainTemplate.string)", type: .detail)
                try showTemplateFile(mainTemplate, maxLines: raw ? nil : 15)
            }
        }
    }

    private func showFileTemplate(at path: PathKit.Path) throws {
        let content = try path.read(.utf8)
        let lines = content.components(separatedBy: .newlines)

        Console.print("Content (\(content.count) characters, \(lines.count) lines):", type: .info)
        Console.newLine()

        if raw {
            Console.print(content)
        } else {
            // Show first 30 lines with line numbers
            let displayLines = Array(lines.prefix(30))
            for (index, line) in displayLines.enumerated() {
                let lineNumber = String(format: "%3d", index + 1)
                Console.print("\(lineNumber): \(line)")
            }

            if lines.count > 30 {
                Console.print("... (\(lines.count - 30) more lines)")
                Console.print("Use --raw to see full content", type: .detail)
            }
        }

        Console.newLine()

        // Show template variables
        let variables = extractTemplateVariables(from: content)
        if !variables.isEmpty {
            Console.print("Template Variables:", type: .info)
            Console.printList(variables)
        }
    }

    private func showDirectoryContents(_ directory: PathKit.Path, prefix: String) throws {
        let contents = try directory.children().sorted { $0.string < $1.string }

        for item in contents {
            let name = item.lastComponent
            let isLast = item == contents.last

            if item.isDirectory {
                Console.print("\(prefix)📁 \(name)/")
                let newPrefix = prefix + (isLast ? "    " : "│   ")
                try showDirectoryContents(item, prefix: newPrefix)
            } else {
                let icon = name.hasSuffix(".stencil") ? "📝" : "📄"
                Console.print("\(prefix)\(icon) \(name)")
            }
        }
    }

    private func showTemplateFile(_ file: PathKit.Path, maxLines: Int?) throws {
        let content = try file.read(.utf8)
        let lines = content.components(separatedBy: .newlines)

        let linesToShow = maxLines.map { Array(lines.prefix($0)) } ?? lines

        for (index, line) in linesToShow.enumerated() {
            let lineNumber = String(format: "%3d", index + 1)
            Console.print("\(lineNumber): \(line)")
        }

        if let maxLines = maxLines, lines.count > maxLines {
            Console.print("... (\(lines.count - maxLines) more lines)")
        }
    }

    private func findMainSourceTemplate(in sourcesDir: PathKit.Path) -> PathKit.Path? {
        do {
            let subdirs = try sourcesDir.children().filter { $0.isDirectory }

            for subdir in subdirs {
                let templateFiles = try subdir.children().filter { $0.extension == "stencil" }

                // Look for main template file (matches directory name)
                let dirName = subdir.lastComponent
                let mainTemplate = templateFiles.first { file in
                    file.lastComponentWithoutExtension.contains(dirName) ||
                    file.lastComponentWithoutExtension == "{{ModuleName}}"
                }

                if let mainTemplate = mainTemplate {
                    return mainTemplate
                }

                // Fallback to first template file
                if let firstTemplate = templateFiles.first {
                    return firstTemplate
                }
            }
        } catch {
            return nil
        }

        return nil
    }

    private func extractTemplateVariables(from content: String) -> [String] {
        let pattern = #"\{\{([^}|]+)(\|[^}]+)?\}\}"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            let variables = matches.compactMap { match -> String? in
                guard match.numberOfRanges > 1 else { return nil }
                let range = match.range(at: 1)
                guard let swiftRange = Range(range, in: content) else { return nil }
                let variable = String(content[swiftRange])
                return variable.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return Array(Set(variables)).sorted()
        } catch {
            return []
        }
    }
}

public struct ValidateTemplateCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "validate",
        abstract: "Validate template syntax and structure"
    )

    @Argument(help: "Template name to validate")
    public var templateName: String

    @Flag(name: .shortAndLong, help: "Show detailed validation results")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() throws {
        Console.printHeader("Validating Template: \(templateName)")

        let templateLoader = TemplateLoader()

        do {
            let templatePath = try templateLoader.getTemplate(named: templateName)
            try templateLoader.validateTemplate(at: templatePath)

            Console.printEmoji("✅", message: "Template validation successful")

            if verbose {
                Console.newLine()
                try showValidationDetails(templatePath)
            }

        } catch TemplateEngineError.templateNotFound(let name, let available) {
            Console.print("Template '\(name)' not found", type: .error)
            Console.print("Available templates: \(available.joined(separator: ", "))", type: .detail)
            throw ExitCode.failure

        } catch TemplateEngineError.invalidTemplate(let name, let reason) {
            Console.print("Template validation failed for '\(name)':", type: .error)
            Console.print(reason, type: .detail)
            throw ExitCode.failure

        } catch {
            Console.print("Validation error: \(error.localizedDescription)", type: .error)
            throw ExitCode.failure
        }
    }

    private func showValidationDetails(_ templatePath: PathKit.Path) throws {
        Console.print("Validation Details:", type: .info)

        if templatePath.isDirectory {
            try validateDirectoryTemplate(templatePath)
        } else {
            try validateFileTemplate(templatePath)
        }
    }

    private func validateDirectoryTemplate(_ path: PathKit.Path) throws {
        Console.print("✓ Template directory structure is valid")

        // Check for required files
        let packageSwift = path + "Package.swift.stencil"
        if packageSwift.exists {
            Console.print("✓ Package.swift template found")
            try validateStencilSyntax(packageSwift)
        } else {
            Console.print("⚠ Package.swift template not found", type: .warning)
        }

        // Check Sources directory
        let sourcesDir = path + "Sources"
        if sourcesDir.exists {
            Console.print("✓ Sources directory found")
            let stencilFiles = try findStencilFiles(in: sourcesDir)
            Console.print("✓ \(stencilFiles.count) template file\(stencilFiles.count == 1 ? "" : "s") found")

            for file in stencilFiles {
                do {
                    try validateStencilSyntax(file)
                } catch {
                    Console.print("⚠ Issues in \(file.lastComponent): \(error.localizedDescription)", type: .warning)
                }
            }
        }

        // Check Tests directory
        let testsDir = path + "Tests"
        if testsDir.exists {
            Console.print("✓ Tests directory found")
        }
    }

    private func validateFileTemplate(_ path: PathKit.Path) throws {
        try validateStencilSyntax(path)
        Console.print("✓ Template syntax is valid")

        let content = try path.read(.utf8)
        let variables = extractTemplateVariables(from: content)

        if !variables.isEmpty {
            Console.print("✓ Template variables detected: \(variables.joined(separator: ", "))")
        }
    }

    private func validateStencilSyntax(_ file: PathKit.Path) throws {
        let content = try file.read(.utf8)

        // Try to parse with Stencil
        let template = try Template(templateString: content)

        // Try a test render with common variables
        let testContext: [String: Any] = [
            "ModuleName": "TestModule",
            "Author": "Test Author",
            "Date": "2024-01-01",
            "Year": "2024",
            "OrganizationName": "Test Org",
            "SwiftVersion": "5.9"
        ]

        _ = try template.render(testContext)
    }

    private func findStencilFiles(in directory: PathKit.Path) throws -> [PathKit.Path] {
        var stencilFiles: [PathKit.Path] = []

        let contents = try directory.children()
        for item in contents {
            if item.isDirectory {
                stencilFiles.append(contentsOf: try findStencilFiles(in: item))
            } else if item.extension == "stencil" {
                stencilFiles.append(item)
            }
        }

        return stencilFiles
    }

    private func extractTemplateVariables(from content: String) -> [String] {
        let pattern = #"\{\{([^}|]+)(\|[^}]+)?\}\}"#
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)

            let variables = matches.compactMap { match -> String? in
                guard match.numberOfRanges > 1 else { return nil }
                let range = match.range(at: 1)
                guard let swiftRange = Range(range, in: content) else { return nil }
                let variable = String(content[swiftRange])
                return variable.trimmingCharacters(in: .whitespacesAndNewlines)
            }

            return Array(Set(variables)).sorted()
        } catch {
            return []
        }
    }
}