import Foundation
import Stencil
import PathKit

public class TemplateLoader {
    public let basePath: Path
    public let stencilLoader: FileSystemLoader
    private let customSearchPaths: [String]

    public init(searchPaths: [String] = []) {
        self.customSearchPaths = searchPaths

        // Default template paths
        var allSearchPaths = searchPaths

        // Add built-in templates path
        if let bundlePath = Bundle.main.resourcePath {
            let templatesPath = Path(bundlePath) + "Templates"
            allSearchPaths.append(templatesPath.string)
        }

        // Add current directory templates
        let currentDirTemplates = Path.current + "Templates"
        if currentDirTemplates.exists {
            allSearchPaths.append(currentDirTemplates.string)
        }

        // Add user's home directory templates
        let homeTemplates = Path.home + ".catalyst" + "templates"
        if homeTemplates.exists {
            allSearchPaths.append(homeTemplates.string)
        }

        // Use first available path as base
        self.basePath = Path(allSearchPaths.first ?? Path.current.string)
        self.stencilLoader = FileSystemLoader(paths: allSearchPaths.map { Path($0) })
    }

    public var availableTemplates: [String] {
        var templates: [String] = []

        for searchPath in stencilLoader.paths {
            guard searchPath.exists else { continue }

            do {
                let contents = try searchPath.children()
                for item in contents {
                    if item.isDirectory {
                        templates.append(item.lastComponent)
                    } else if item.extension == "stencil" {
                        let name = item.lastComponentWithoutExtension
                        if !templates.contains(name) {
                            templates.append(name)
                        }
                    }
                }
            } catch {
                continue
            }
        }

        return templates.sorted()
    }

    public func getTemplateDirectory(named name: String) throws -> Path {
        for searchPath in stencilLoader.paths {
            let templatePath = searchPath + name
            if templatePath.exists && templatePath.isDirectory {
                return templatePath
            }
        }
        throw TemplateEngineError.directoryNotFound(name)
    }

    public func getTemplate(named name: String) throws -> Path {
        for searchPath in stencilLoader.paths {
            // Try as directory first
            let directoryPath = searchPath + name
            if directoryPath.exists && directoryPath.isDirectory {
                return directoryPath
            }

            // Try as .stencil file
            let filePath = searchPath + "\(name).stencil"
            if filePath.exists {
                return filePath
            }
        }
        throw TemplateEngineError.templateNotFound(name, availableTemplates: availableTemplates)
    }

    public func validateTemplate(at path: Path) throws {
        guard path.exists else {
            throw TemplateEngineError.directoryNotFound(path.string)
        }

        if path.isDirectory {
            try validateTemplateDirectory(at: path)
        } else {
            try validateTemplateFile(at: path)
        }
    }

    private func validateTemplateDirectory(at path: Path) throws {
        // Check for required template structure
        let expectedFiles = ["Package.swift.stencil"]

        for expectedFile in expectedFiles {
            let filePath = path + expectedFile
            guard filePath.exists else {
                throw TemplateEngineError.invalidTemplate(
                    path.lastComponent,
                    reason: "Missing required file: \(expectedFile)"
                )
            }
        }
    }

    private func validateTemplateFile(at path: Path) throws {
        guard path.extension == "stencil" else {
            throw TemplateEngineError.invalidTemplate(
                path.lastComponent,
                reason: "Template files must have .stencil extension"
            )
        }

        // Basic syntax validation
        do {
            let content = try path.read(.utf8)
            let template = Template(templateString: content)
            _ = try template.render([:]) // Test render with empty context
        } catch {
            throw TemplateEngineError.invalidTemplate(
                path.lastComponent,
                reason: "Invalid template syntax: \(error.localizedDescription)"
            )
        }
    }

    public func listTemplatesWithDetails() -> [(name: String, path: String, type: String)] {
        var templates: [(name: String, path: String, type: String)] = []

        for searchPath in stencilLoader.paths {
            guard searchPath.exists else { continue }

            do {
                let contents = try searchPath.children()
                for item in contents {
                    if item.isDirectory {
                        templates.append((
                            name: item.lastComponent,
                            path: item.string,
                            type: "directory"
                        ))
                    } else if item.extension == "stencil" {
                        templates.append((
                            name: item.lastComponentWithoutExtension,
                            path: item.string,
                            type: "file"
                        ))
                    }
                }
            } catch {
                continue
            }
        }

        return templates.sorted { $0.name < $1.name }
    }
}