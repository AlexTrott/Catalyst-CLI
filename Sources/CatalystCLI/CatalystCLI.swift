import ArgumentParser
import Foundation
import CatalystCore

/// Catalyst CLI - A Swift CLI tool for iOS module generation and management.
///
/// Catalyst accelerates iOS development by automating the creation of modular Swift packages
/// and isolated testing environments (MicroApps). Feature modules now automatically include
/// companion MicroApps for immediate testing capabilities.
///
/// ## Usage
///
/// ```bash
/// catalyst new core NetworkingCore
/// catalyst new feature AuthenticationFeature  # Creates both module and MicroApp
/// catalyst new microapp TestApp
/// catalyst list --verbose
/// catalyst doctor
/// ```
///
/// ## Available Commands
///
/// - ``NewCommand``: Create new Swift modules (features include automatic MicroApps)
/// - ``ListCommand``: List modules and packages in workspace
/// - ``ConfigCommand``: Manage configuration settings
/// - ``TemplateCommand``: Manage templates for module generation
/// - ``MicroAppCommand``: Create and manage MicroApps (deprecated - use `new feature` instead)
/// - ``DoctorCommand``: Diagnose and validate environment
@main
struct Catalyst: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "catalyst",
        abstract: "A Swift CLI tool for iOS module generation and management",
        discussion: """
        Catalyst accelerates iOS development by automating the creation of modular Swift packages
        and isolated testing environments (MicroApps). Feature modules now automatically include
        companion MicroApps for immediate testing capabilities.

        Examples:
          catalyst new core NetworkingCore
          catalyst new feature AuthenticationFeature  # Creates both module and MicroApp
          catalyst list --verbose
          catalyst doctor
          catalyst config set author "John Doe"
        """,
        version: "1.0.0",
        subcommands: [
            NewCommand.self,
            MicroAppCommand.self,
            ListCommand.self,
            ConfigCommand.self,
            TemplateCommand.self,
            DoctorCommand.self
        ],
        helpNames: [.short, .long, .customLong("help")]
    )

    init() {}

    mutating func run() async throws {
        print(Catalyst.helpMessage())
    }
}