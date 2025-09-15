import Foundation
import Yams
import PathKit

public class ConfigurationManager {

    public let globalConfigPath: String
    public let localConfigPath: String

    public init() {
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path
        self.globalConfigPath = (homeDirectory as NSString).appendingPathComponent(".catalyst.yml")
        self.localConfigPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(".catalyst.yml")
    }

    /// Load configuration from default locations (local overrides global)
    public func loadConfiguration() throws -> CatalystConfiguration {
        var config = CatalystConfiguration.default

        // Load global configuration first
        if FileManager.default.fileExists(atPath: globalConfigPath) {
            let globalConfig = try loadConfiguration(from: globalConfigPath)
            config = config.merged(with: globalConfig)
        }

        // Load local configuration (overrides global)
        if FileManager.default.fileExists(atPath: localConfigPath) {
            let localConfig = try loadConfiguration(from: localConfigPath)
            config = config.merged(with: localConfig)
        }

        return config
    }

    /// Load configuration from specific path
    public func loadConfiguration(from path: String) throws -> CatalystConfiguration {
        let yamlContent = try String(contentsOfFile: path, encoding: .utf8)
        let decoder = YAMLDecoder()
        return try decoder.decode(CatalystConfiguration.self, from: yamlContent)
    }

    /// Save configuration to specific path
    public func saveConfiguration(_ configuration: CatalystConfiguration, to path: String) throws {
        let encoder = YAMLEncoder()
        let yamlContent = try encoder.encode(configuration)

        // Create directory if needed
        let directory = (path as NSString).deletingLastPathComponent
        if !FileManager.default.fileExists(atPath: directory) {
            try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        }

        try yamlContent.write(toFile: path, atomically: true, encoding: .utf8)
    }

    /// Validate configuration file
    public func validateConfiguration(at path: String) -> ValidationResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return .invalid(reason: "Configuration file does not exist")
        }

        do {
            _ = try loadConfiguration(from: path)
            return .valid
        } catch let error as DecodingError {
            return .invalid(reason: "Invalid YAML structure: \(error.localizedDescription)")
        } catch {
            return .invalid(reason: "Failed to read configuration: \(error.localizedDescription)")
        }
    }
}

// MARK: - Configuration Model

public struct ModulePaths: Codable {
    public var coreModules: String?
    public var featureModules: String?
    public var sharedModules: String?
    public var microApps: String?

    public init(
        coreModules: String? = nil,
        featureModules: String? = nil,
        sharedModules: String? = nil,
        microApps: String? = nil
    ) {
        self.coreModules = coreModules
        self.featureModules = featureModules
        self.sharedModules = sharedModules
        self.microApps = microApps
    }

    public static var `default`: ModulePaths {
        return ModulePaths(
            coreModules: ".",
            featureModules: ".",
            sharedModules: "./Modules/Shared",
            microApps: "./MicroApps"
        )
    }
}

public struct CatalystConfiguration: Codable {

    // MARK: - Default Settings
    public var author: String?
    public var organizationName: String?
    public var bundleIdentifierPrefix: String?

    // MARK: - Template Settings
    public var templatesPath: [String]?
    public var defaultTemplateVariables: [String: String]?

    // MARK: - Module Settings
    public var swiftVersion: String?
    public var defaultPlatforms: [String]?

    // MARK: - Output Settings
    public var verbose: Bool?
    public var colorOutput: Bool?

    // MARK: - Path Settings
    public var defaultModulesPath: String?
    public var paths: ModulePaths

    // MARK: - Package Management
    public var brewPackages: [String]?

    public init(
        author: String? = nil,
        organizationName: String? = nil,
        bundleIdentifierPrefix: String? = nil,
        templatesPath: [String]? = nil,
        defaultTemplateVariables: [String: String]? = nil,
        swiftVersion: String? = nil,
        defaultPlatforms: [String]? = nil,
        verbose: Bool? = nil,
        colorOutput: Bool? = nil,
        defaultModulesPath: String? = nil,
        paths: ModulePaths = .default,
        brewPackages: [String]? = nil
    ) {
        self.author = author
        self.organizationName = organizationName
        self.bundleIdentifierPrefix = bundleIdentifierPrefix
        self.templatesPath = templatesPath
        self.defaultTemplateVariables = defaultTemplateVariables
        self.swiftVersion = swiftVersion
        self.defaultPlatforms = defaultPlatforms
        self.verbose = verbose
        self.colorOutput = colorOutput
        self.defaultModulesPath = defaultModulesPath
        self.paths = paths
        self.brewPackages = brewPackages
    }

    /// Default configuration
    public static var `default`: CatalystConfiguration {
        return CatalystConfiguration(
            swiftVersion: "6.0",
            defaultPlatforms: [".iOS(.v15)"],
            verbose: false,
            colorOutput: true,
            defaultModulesPath: ".",
            brewPackages: ["swiftlint", "swiftformat", "xcodes"]
        )
    }

    /// Merge this configuration with another (other takes precedence)
    public func merged(with other: CatalystConfiguration) -> CatalystConfiguration {
        return CatalystConfiguration(
            author: other.author ?? self.author,
            organizationName: other.organizationName ?? self.organizationName,
            bundleIdentifierPrefix: other.bundleIdentifierPrefix ?? self.bundleIdentifierPrefix,
            templatesPath: other.templatesPath ?? self.templatesPath,
            defaultTemplateVariables: mergedTemplateVariables(other.defaultTemplateVariables),
            swiftVersion: other.swiftVersion ?? self.swiftVersion,
            defaultPlatforms: other.defaultPlatforms ?? self.defaultPlatforms,
            verbose: other.verbose ?? self.verbose,
            colorOutput: other.colorOutput ?? self.colorOutput,
            defaultModulesPath: other.defaultModulesPath ?? self.defaultModulesPath,
            paths: mergedPaths(other.paths),
            brewPackages: other.brewPackages ?? self.brewPackages
        )
    }

    private func mergedTemplateVariables(_ otherVariables: [String: String]?) -> [String: String]? {
        guard let otherVariables = otherVariables else { return self.defaultTemplateVariables }
        guard let selfVariables = self.defaultTemplateVariables else { return otherVariables }

        var merged = selfVariables
        for (key, value) in otherVariables {
            merged[key] = value
        }
        return merged
    }

    private func mergedPaths(_ otherPaths: ModulePaths) -> ModulePaths {
        return ModulePaths(
            coreModules: otherPaths.coreModules ?? self.paths.coreModules,
            featureModules: otherPaths.featureModules ?? self.paths.featureModules,
            sharedModules: otherPaths.sharedModules ?? self.paths.sharedModules,
            microApps: otherPaths.microApps ?? self.paths.microApps
        )
    }

    /// Get value for a configuration key using dot notation
    public func getValue(for key: String) -> String? {
        let mirror = Mirror(reflecting: self)

        for child in mirror.children {
            if let label = child.label, label == key {
                if let value = child.value as? String {
                    return value
                } else if let value = child.value as? Bool {
                    return String(value)
                } else if let value = child.value as? [String] {
                    return value.joined(separator: ", ")
                } else if let value = child.value as? [String: String] {
                    return value.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
                }
            }
        }

        // Handle nested keys (e.g., "defaultTemplateVariables.key")
        if key.contains(".") {
            let components = key.split(separator: ".", maxSplits: 1)
            if components.count == 2 {
                let firstKey = String(components[0])
                let secondKey = String(components[1])

                if firstKey == "defaultTemplateVariables",
                   let variables = defaultTemplateVariables {
                    return variables[secondKey]
                }
            }
        }

        return nil
    }

    /// Set value for a configuration key
    public mutating func setValue(_ value: String, for key: String) {
        switch key {
        case "author":
            author = value
        case "organizationName":
            organizationName = value
        case "bundleIdentifierPrefix":
            bundleIdentifierPrefix = value
        case "swiftVersion":
            swiftVersion = value
        case "verbose":
            verbose = Bool(value) ?? false
        case "colorOutput":
            colorOutput = Bool(value) ?? true
        case "defaultModulesPath":
            defaultModulesPath = value
        default:
            // Handle nested keys
            if key.contains(".") {
                let components = key.split(separator: ".", maxSplits: 1)
                if components.count == 2 {
                    let firstKey = String(components[0])
                    let secondKey = String(components[1])

                    if firstKey == "defaultTemplateVariables" {
                        if defaultTemplateVariables == nil {
                            defaultTemplateVariables = [:]
                        }
                        defaultTemplateVariables?[secondKey] = value
                    }
                }
            }
        }
    }

    /// Get all configuration settings as key-value pairs
    public var allSettings: [String: String] {
        var settings: [String: String] = [:]

        if let author = author {
            settings["author"] = author
        }
        if let organizationName = organizationName {
            settings["organizationName"] = organizationName
        }
        if let bundleIdentifierPrefix = bundleIdentifierPrefix {
            settings["bundleIdentifierPrefix"] = bundleIdentifierPrefix
        }
        if let swiftVersion = swiftVersion {
            settings["swiftVersion"] = swiftVersion
        }
        if let verbose = verbose {
            settings["verbose"] = String(verbose)
        }
        if let colorOutput = colorOutput {
            settings["colorOutput"] = String(colorOutput)
        }
        if let defaultModulesPath = defaultModulesPath {
            settings["defaultModulesPath"] = defaultModulesPath
        }
        if let templatesPath = templatesPath {
            settings["templatesPath"] = templatesPath.joined(separator: ", ")
        }
        if let defaultPlatforms = defaultPlatforms {
            settings["defaultPlatforms"] = defaultPlatforms.joined(separator: ", ")
        }
        if let templateVariables = defaultTemplateVariables {
            for (key, value) in templateVariables {
                settings["defaultTemplateVariables.\(key)"] = value
            }
        }

        return settings
    }
}

// MARK: - Supporting Types

public enum ValidationResult {
    case valid
    case invalid(reason: String)

    public var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
}