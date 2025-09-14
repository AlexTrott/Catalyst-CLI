import Foundation

public enum ValidationError: LocalizedError {
    case invalidModuleName(String, reason: String)
    case invalidPath(String)
    case fileAlreadyExists(String)
    case directoryNotFound(String)
    case unsupportedModuleType(String)

    public var errorDescription: String? {
        switch self {
        case .invalidModuleName(let name, let reason):
            return "Invalid module name '\(name)': \(reason)"
        case .invalidPath(let path):
            return "Invalid path: \(path)"
        case .fileAlreadyExists(let path):
            return "File already exists at path: \(path)"
        case .directoryNotFound(let path):
            return "Directory not found: \(path)"
        case .unsupportedModuleType(let type):
            return "Unsupported module type: \(type)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .invalidModuleName(_, _):
            return "Module names must start with a letter and contain only alphanumeric characters and underscores."
        case .invalidPath(_):
            return "Please provide a valid file system path."
        case .fileAlreadyExists(_):
            return "Use --force to overwrite existing files, or choose a different name."
        case .directoryNotFound(_):
            return "Make sure the directory exists or create it first."
        case .unsupportedModuleType(_):
            return "Supported module types are: core, feature."
        }
    }
}

public struct Validators {

    public static func validateModuleName(_ name: String) throws {
        guard !name.isEmpty else {
            throw ValidationError.invalidModuleName(name, reason: "Module name cannot be empty")
        }

        guard name.count <= 50 else {
            throw ValidationError.invalidModuleName(name, reason: "Module name must be 50 characters or less")
        }

        let firstCharacter = name.first!
        guard firstCharacter.isLetter else {
            throw ValidationError.invalidModuleName(name, reason: "Module name must start with a letter")
        }

        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        guard name.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
            throw ValidationError.invalidModuleName(name, reason: "Module name can only contain letters, numbers, and underscores")
        }

        let reservedNames = [
            "swift", "foundation", "uikit", "swiftui", "combine", "core", "main", "test", "tests",
            "package", "sources", "resources", "build", "derived", "xcuserdata"
        ]

        if reservedNames.contains(name.lowercased()) {
            throw ValidationError.invalidModuleName(name, reason: "Module name conflicts with reserved keyword")
        }
    }

    public static func validatePath(_ path: String) throws {
        guard !path.isEmpty else {
            throw ValidationError.invalidPath(path)
        }

        let expandedPath = NSString(string: path).expandingTildeInPath
        let url = URL(fileURLWithPath: expandedPath)

        guard url.isFileURL else {
            throw ValidationError.invalidPath(path)
        }
    }

    public static func validateDirectoryExists(_ path: String) throws {
        let expandedPath = NSString(string: path).expandingTildeInPath

        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: expandedPath, isDirectory: &isDirectory)

        if !exists {
            throw ValidationError.directoryNotFound(path)
        }

        if !isDirectory.boolValue {
            throw ValidationError.invalidPath(path)
        }
    }

    public static func validateFileDoesNotExist(_ path: String, allowOverwrite: Bool = false) throws {
        if !allowOverwrite && FileManager.default.fileExists(atPath: path) {
            throw ValidationError.fileAlreadyExists(path)
        }
    }

    public static func validateModuleType(_ type: String) throws {
        let supportedTypes = ["core", "feature"]
        guard supportedTypes.contains(type.lowercased()) else {
            throw ValidationError.unsupportedModuleType(type)
        }
    }

    public static func validateSwiftProjectStructure(at path: String) throws {
        let packageSwiftPath = (path as NSString).appendingPathComponent("Package.swift")
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")

        if !FileManager.default.fileExists(atPath: packageSwiftPath) &&
           !FileManager.default.fileExists(atPath: sourcesPath) &&
           FileManager.default.findWorkspace(in: path) == nil &&
           FileManager.default.findProject(in: path) == nil {

            Console.print("Warning: This doesn't appear to be a Swift project directory", type: .warning)
            Console.print("Expected to find one of: Package.swift, Sources/, *.xcworkspace, or *.xcodeproj", type: .detail)
        }
    }
}