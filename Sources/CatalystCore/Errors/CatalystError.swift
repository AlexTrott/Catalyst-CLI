import Foundation

public enum CatalystError: LocalizedError {
    case invalidModuleName(String)
    case moduleAlreadyExists(String)
    case workspaceNotFound
    case workspaceModificationFailed(String)
    case templateNotFound(String)
    case templateRenderingFailed(String, Error)
    case fileOperationFailed(String, Error)
    case dependencyNotFound(String, installInstructions: String)
    case configurationError(String)
    case commandExecutionFailed(String, Int32)
    case invalidProjectStructure(String)
    case unsupportedPlatform
    case networkError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidModuleName(let name):
            return "Invalid module name: '\(name)'"
        case .moduleAlreadyExists(let name):
            return "Module '\(name)' already exists"
        case .workspaceNotFound:
            return "No Xcode workspace found in current directory"
        case .workspaceModificationFailed(let reason):
            return "Failed to modify workspace: \(reason)"
        case .templateNotFound(let name):
            return "Template '\(name)' not found"
        case .templateRenderingFailed(let template, let error):
            return "Failed to render template '\(template)': \(error.localizedDescription)"
        case .fileOperationFailed(let operation, let error):
            return "File operation '\(operation)' failed: \(error.localizedDescription)"
        case .dependencyNotFound(let dependency, _):
            return "Required dependency '\(dependency)' not found"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .commandExecutionFailed(let command, let exitCode):
            return "Command '\(command)' failed with exit code \(exitCode)"
        case .invalidProjectStructure(let reason):
            return "Invalid project structure: \(reason)"
        case .unsupportedPlatform:
            return "This platform is not supported"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidModuleName(_):
            return "Module names must start with a letter and contain only alphanumeric characters and underscores."
        case .moduleAlreadyExists(let name):
            return "Choose a different name or use --force to overwrite the existing module '\(name)'."
        case .workspaceNotFound:
            return """
            Make sure you're in a directory containing an Xcode workspace (.xcworkspace file).
            You can create one with: catalyst init
            """
        case .workspaceModificationFailed(_):
            return "Check that the workspace file is not open in Xcode and that you have write permissions."
        case .templateNotFound(let name):
            return "Available templates: core, feature. Use 'catalyst template list' to see all available templates."
        case .templateRenderingFailed(_, _):
            return "Check the template syntax and ensure all required variables are provided."
        case .fileOperationFailed(_, _):
            return "Check file permissions and available disk space."
        case .dependencyNotFound(_, let instructions):
            return instructions
        case .configurationError(_):
            return "Check your .catalyst.yml configuration file for syntax errors."
        case .commandExecutionFailed(_, _):
            return "Check that all required tools are installed and accessible."
        case .invalidProjectStructure(_):
            return "Ensure you're running this command from a valid Swift project directory."
        case .unsupportedPlatform:
            return "This tool currently supports macOS only."
        case .networkError(_):
            return "Check your internet connection and try again."
        }
    }

    public var failureReason: String? {
        switch self {
        case .invalidModuleName(_):
            return "The provided module name doesn't meet naming requirements."
        case .moduleAlreadyExists(_):
            return "A module with this name already exists."
        case .workspaceNotFound:
            return "No Xcode workspace was found in the current directory."
        case .workspaceModificationFailed(_):
            return "The workspace could not be modified."
        case .templateNotFound(_):
            return "The specified template could not be located."
        case .templateRenderingFailed(_, _):
            return "The template could not be processed."
        case .fileOperationFailed(_, _):
            return "A file system operation failed."
        case .dependencyNotFound(_, _):
            return "A required external dependency is missing."
        case .configurationError(_):
            return "The configuration is invalid or corrupt."
        case .commandExecutionFailed(_, _):
            return "An external command failed to execute successfully."
        case .invalidProjectStructure(_):
            return "The project structure is not valid for this operation."
        case .unsupportedPlatform:
            return "The current platform is not supported."
        case .networkError(_):
            return "A network operation failed."
        }
    }
}