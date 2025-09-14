import Foundation
import Stencil
import PathKit

public class TemplateEngine {
    private let environment: Environment
    private let templateLoader: TemplateLoader

    public init(templateSearchPaths: [String] = []) {
        self.templateLoader = TemplateLoader(searchPaths: templateSearchPaths)
        self.environment = Environment(
            loader: templateLoader.stencilLoader,
            extensions: [StencilHelpers.catalystExtension]
        )
    }

    public func renderTemplate(
        named templateName: String,
        with context: [String: Any]
    ) throws -> String {
        do {
            let template = try environment.loadTemplate(name: templateName)
            return try template.render(context)
        } catch _ as TemplateDoesNotExist {
            throw TemplateEngineError.templateNotFound(templateName, availableTemplates: templateLoader.availableTemplates)
        } catch {
            throw TemplateEngineError.renderingFailed(templateName, error)
        }
    }

    public func renderTemplateToFile(
        named templateName: String,
        with context: [String: Any],
        to outputPath: String
    ) throws {
        let renderedContent = try renderTemplate(named: templateName, with: context)

        // Create directory if it doesn't exist
        let outputURL = URL(fileURLWithPath: outputPath)
        let directory = outputURL.deletingLastPathComponent()

        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true,
            attributes: nil
        )

        // Write the file
        try renderedContent.write(
            to: outputURL,
            atomically: true,
            encoding: .utf8
        )
    }

    public func processTemplateDirectory(
        named templateDirectoryName: String,
        with context: [String: Any],
        to outputDirectory: String
    ) throws {
        let templateDirectory = try templateLoader.getTemplateDirectory(named: templateDirectoryName)
        let outputPath = Path(outputDirectory)

        try processDirectory(
            templateDirectory: templateDirectory,
            context: context,
            outputDirectory: outputPath,
            basePath: templateDirectory
        )
    }

    private func processDirectory(
        templateDirectory: Path,
        context: [String: Any],
        outputDirectory: Path,
        basePath: Path
    ) throws {
        for child in try templateDirectory.children() {
            let relativePath = child.string.replacingOccurrences(of: basePath.string + "/", with: "")

            // Process path template variables (e.g., {{ModuleName}})
            let processedRelativePath = try processPathTemplate(relativePath, with: context)
            let outputPath = outputDirectory + processedRelativePath

            if child.isDirectory {
                try outputPath.mkpath()
                try processDirectory(
                    templateDirectory: child,
                    context: context,
                    outputDirectory: outputPath,
                    basePath: basePath
                )
            } else {
                if child.extension == "stencil" {
                    // Render template file
                    // For files in template directories, we need to construct the proper template name
                    // that Stencil can find in its search paths
                    let components = child.string.components(separatedBy: "/Templates/")
                    let templateName = components.count > 1 ? components[1] : child.lastComponent
                    let renderedContent = try renderTemplate(named: templateName, with: context)

                    // Remove .stencil extension from output
                    let outputFileName = outputPath.lastComponent.replacingOccurrences(of: ".stencil", with: "")
                    let finalOutputPath = outputPath.parent() + outputFileName

                    // Ensure parent directory exists
                    try finalOutputPath.parent().mkpath()

                    try renderedContent.write(
                        to: finalOutputPath.url,
                        atomically: true,
                        encoding: String.Encoding.utf8
                    )
                } else {
                    // Copy file as-is
                    try child.copy(outputPath)
                }
            }
        }
    }

    private func processPathTemplate(_ path: String, with context: [String: Any]) throws -> String {
        // Simple template variable replacement in paths
        var processedPath = path
        for (key, value) in context {
            if let stringValue = value as? String {
                processedPath = processedPath.replacingOccurrences(of: "{{\(key)}}", with: stringValue)
            }
        }
        return processedPath
    }
}

public enum TemplateEngineError: LocalizedError {
    case templateNotFound(String, availableTemplates: [String])
    case renderingFailed(String, Error)
    case directoryNotFound(String)
    case invalidTemplate(String, reason: String)

    public var errorDescription: String? {
        switch self {
        case .templateNotFound(let name, let available):
            return "Template '\(name)' not found. Available templates: \(available.joined(separator: ", "))"
        case .renderingFailed(let template, let error):
            return "Failed to render template '\(template)': \(error.localizedDescription)"
        case .directoryNotFound(let path):
            return "Template directory not found: \(path)"
        case .invalidTemplate(let name, let reason):
            return "Invalid template '\(name)': \(reason)"
        }
    }
}