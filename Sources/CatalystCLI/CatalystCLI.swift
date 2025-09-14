import ArgumentParser
import Foundation
import CatalystCore
import Utilities

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
/// - ``InstallCommand``: Install development tools and git hooks
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
          catalyst install git-message                # Install JIRA ticket git hook
          catalyst list --verbose
          catalyst doctor
          catalyst config set author "John Doe"
        """,
        version: "1.0.0",
        subcommands: [
            NewCommand.self,
            InstallCommand.self,
            ResetSpmCommand.self,
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
        Console.printBanner()

        // Show some helpful tips
        Console.printBoxed("""
        🚀 Quick Start:
        • catalyst new feature MyFeature  # Creates feature + MicroApp
        • catalyst new core MyCore        # Creates core module
        • catalyst install git-message    # Auto-prefix commits with JIRA tickets
        • catalyst install packages       # Install development tools (brew)
        • catalyst reset-spm              # Clean Package.resolved conflicts
        • catalyst doctor                 # Check your environment
        • catalyst --help                 # See all commands
        """, style: .rounded)

        Console.newLine()
        Console.printGradientText("Ready to accelerate your iOS development! ⚡")
        Console.newLine()

        print(Catalyst.helpMessage())
    }
}