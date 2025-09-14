import ArgumentParser
import Foundation
import Utilities
import ConfigurationManager

public struct ConfigCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "config",
        abstract: "Manage Catalyst configuration settings",
        usage: """
        catalyst config get <key>
        catalyst config set <key> <value>
        catalyst config list
        catalyst config reset
        """,
        discussion: """
        Configure default settings for Catalyst CLI. Settings are stored in .catalyst.yml
        in the current directory or user's home directory.
        """,
        subcommands: [
            GetCommand.self,
            SetCommand.self,
            ListConfigCommand.self,
            ResetCommand.self,
            InitCommand.self
        ]
    )

    public init() {}
}

// MARK: - Subcommands

public struct GetCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "get",
        abstract: "Get a configuration value"
    )

    @Argument(help: "Configuration key to retrieve")
    public var key: String

    public init() {}

    public mutating func run() throws {
        let configManager = ConfigurationManager()

        do {
            let config = try configManager.loadConfiguration()

            if let value = config.getValue(for: key) {
                Console.print("\(key): \(value)")
            } else {
                Console.print("Configuration key '\(key)' not found", type: .warning)
                Console.print("Use 'catalyst config list' to see available keys", type: .detail)
                throw ExitCode.failure
            }
        } catch {
            throw CatalystError.configurationError("Failed to read configuration: \(error.localizedDescription)")
        }
    }
}

public struct SetCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "set",
        abstract: "Set a configuration value"
    )

    @Argument(help: "Configuration key to set")
    public var key: String

    @Argument(help: "Value to set")
    public var value: String

    @Flag(name: .long, help: "Set globally (in user home directory)")
    public var global: Bool = false

    public init() {}

    public mutating func run() throws {
        let configManager = ConfigurationManager()

        do {
            var config = (try? configManager.loadConfiguration()) ?? CatalystConfiguration.default

            config.setValue(value, for: key)

            let configPath = global ? configManager.globalConfigPath : configManager.localConfigPath
            try configManager.saveConfiguration(config, to: configPath)

            Console.printEmoji("✅", message: "Configuration updated")
            Console.print("\(key): \(value)", type: .detail)

            if global {
                Console.print("Saved to global configuration", type: .detail)
            } else {
                Console.print("Saved to local configuration (.catalyst.yml)", type: .detail)
            }

        } catch {
            throw CatalystError.configurationError("Failed to save configuration: \(error.localizedDescription)")
        }
    }
}

public struct ListConfigCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List all configuration values"
    )

    @Flag(name: .long, help: "Show global configuration only")
    public var global: Bool = false

    @Flag(name: .long, help: "Show local configuration only")
    public var local: Bool = false

    public init() {}

    public mutating func run() throws {
        let configManager = ConfigurationManager()

        Console.printHeader("Catalyst Configuration")

        // Determine which configurations to show
        let showGlobal = !local
        let showLocal = !global

        if showGlobal {
            displayConfiguration(
                title: "Global Configuration",
                path: configManager.globalConfigPath,
                configManager: configManager
            )
        }

        if showLocal && showGlobal {
            Console.newLine()
        }

        if showLocal {
            displayConfiguration(
                title: "Local Configuration",
                path: configManager.localConfigPath,
                configManager: configManager
            )
        }

        if !showGlobal && !showLocal {
            Console.print("No configuration to display", type: .warning)
        }
    }

    private func displayConfiguration(title: String, path: String, configManager: ConfigurationManager) {
        Console.print(title, type: .info)
        Console.print("Path: \(path)", type: .detail)

        do {
            let config = try configManager.loadConfiguration(from: path)
            displayConfigurationValues(config)
        } catch {
            Console.print("Not found or invalid", type: .warning)
        }
    }

    private func displayConfigurationValues(_ config: CatalystConfiguration) {
        Console.newLine()

        let allSettings = config.allSettings
        if allSettings.isEmpty {
            Console.print("No settings configured", type: .detail)
            return
        }

        for (key, value) in allSettings.sorted(by: { $0.key < $1.key }) {
            Console.print("\(key): \(value)")
        }
    }
}

public struct ResetCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "reset",
        abstract: "Reset configuration to defaults"
    )

    @Flag(name: .long, help: "Reset global configuration")
    public var global: Bool = false

    @Flag(name: .long, help: "Reset local configuration")
    public var local: Bool = false

    @Flag(name: .shortAndLong, help: "Force reset without confirmation")
    public var force: Bool = false

    public init() {}

    public mutating func run() throws {
        let configManager = ConfigurationManager()

        if !global && !local {
            // Reset both if neither specified
            try resetConfiguration(at: configManager.globalConfigPath, name: "global", force: force)
            try resetConfiguration(at: configManager.localConfigPath, name: "local", force: force)
        } else {
            if global {
                try resetConfiguration(at: configManager.globalConfigPath, name: "global", force: force)
            }
            if local {
                try resetConfiguration(at: configManager.localConfigPath, name: "local", force: force)
            }
        }

        Console.printEmoji("✅", message: "Configuration reset complete")
    }

    private func resetConfiguration(at path: String, name: String, force: Bool) throws {
        if FileManager.default.fileExists(atPath: path) {
            if !force {
                Console.print("This will reset \(name) configuration at: \(path)", type: .warning)
                Console.print("Are you sure? (y/N)", type: .info)

                let response = readLine() ?? ""
                if !["y", "yes", "Y", "YES"].contains(response) {
                    Console.print("Reset cancelled")
                    return
                }
            }

            try FileManager.default.removeItem(atPath: path)
            Console.print("Reset \(name) configuration", type: .detail)
        } else {
            Console.print("\(name.capitalized) configuration not found (already at defaults)", type: .detail)
        }
    }
}

public struct InitCommand: ParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "init",
        abstract: "Initialize configuration file with defaults"
    )

    @Flag(name: .long, help: "Initialize global configuration")
    public var global: Bool = false

    @Flag(name: .shortAndLong, help: "Overwrite existing configuration")
    public var force: Bool = false

    public init() {}

    public mutating func run() throws {
        let configManager = ConfigurationManager()
        let configPath = global ? configManager.globalConfigPath : configManager.localConfigPath
        let configName = global ? "global" : "local"

        if FileManager.default.fileExists(atPath: configPath) && !force {
            Console.print("\(configName.capitalized) configuration already exists at: \(configPath)", type: .warning)
            Console.print("Use --force to overwrite", type: .detail)
            throw ExitCode.failure
        }

        let defaultConfig = CatalystConfiguration.default
        try configManager.saveConfiguration(defaultConfig, to: configPath)

        Console.printEmoji("✅", message: "\(configName.capitalized) configuration initialized")
        Console.print("Location: \(configPath)", type: .detail)
        Console.print("Use 'catalyst config set <key> <value>' to customize", type: .detail)
    }
}