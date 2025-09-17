import ArgumentParser
import Foundation
import Utilities
import WorkspaceManager
import ConfigurationManager

public struct DoctorCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Diagnose and validate Catalyst environment",
        usage: "catalyst doctor [options]",
        discussion: """
        Performs comprehensive checks on your development environment to ensure
        Catalyst can function properly. Validates dependencies, configuration,
        and project structure.
        """
    )

    @Flag(name: .shortAndLong, help: "Show detailed diagnostic information")
    public var verbose: Bool = false

    @Flag(name: .long, help: "Fix issues automatically where possible")
    public var fix: Bool = false

    public init() {}

    public mutating func run() async throws {
        Console.printMiniBanner()
        Console.printHeader("Environment Diagnostics")

        var allChecks: [DiagnosticCheck] = []

        // System checks
        allChecks.append(contentsOf: await performSystemChecks())

        // Dependencies checks
        allChecks.append(contentsOf: await performDependencyChecks())

        // Configuration checks
        allChecks.append(contentsOf: await performConfigurationChecks())

        // Project structure checks
        allChecks.append(contentsOf: await performProjectChecks())

        // Display results
        await displayResults(allChecks)

        // Attempt fixes if requested
        if fix {
            Console.newLine()
            await attemptFixes(allChecks.filter { !$0.passed })
        }

        // Summary
        Console.newLine()
        displaySummary(allChecks)

        // Exit with error code if any critical checks failed
        let criticalFailures = allChecks.filter { !$0.passed && $0.severity == .error }
        if !criticalFailures.isEmpty {
            throw ExitCode.failure
        }
    }

    // MARK: - System Checks

    private func performSystemChecks() async -> [DiagnosticCheck] {
        var checks: [DiagnosticCheck] = []

        Console.printStep(1, total: 4, message: "Checking system environment...")

        // Check macOS version
        checks.append(await checkMacOSVersion())

        // Check Xcode installation
        checks.append(await checkXcodeInstallation())

        // Check Swift version
        checks.append(await checkSwiftVersion())

        return checks
    }

    private func checkMacOSVersion() async -> DiagnosticCheck {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"

        if version.majorVersion >= 12 {
            return DiagnosticCheck(
                name: "macOS Version",
                passed: true,
                message: "macOS \(versionString)",
                severity: .error
            )
        } else {
            return DiagnosticCheck(
                name: "macOS Version",
                passed: false,
                message: "macOS \(versionString) - requires macOS 12.0+",
                severity: .error,
                suggestion: "Please upgrade to macOS 12.0 or later"
            )
        }
    }

    private func checkXcodeInstallation() async -> DiagnosticCheck {
        if Shell.exists("xcodebuild") {
            do {
                let version = try Shell.run("xcodebuild -version", silent: true)
                let versionLine = version.components(separatedBy: .newlines).first ?? "Unknown"

                return DiagnosticCheck(
                    name: "Xcode Installation",
                    passed: true,
                    message: versionLine.trimmingCharacters(in: .whitespacesAndNewlines),
                    severity: .error
                )
            } catch {
                return DiagnosticCheck(
                    name: "Xcode Installation",
                    passed: false,
                    message: "Xcode found but command line tools not working",
                    severity: .error,
                    suggestion: "Run 'xcode-select --install' to install command line tools"
                )
            }
        } else {
            return DiagnosticCheck(
                name: "Xcode Installation",
                passed: false,
                message: "Xcode not found",
                severity: .error,
                suggestion: "Install Xcode from the Mac App Store"
            )
        }
    }

    private func checkSwiftVersion() async -> DiagnosticCheck {
        if Shell.exists("swift") {
            do {
                let version = try Shell.run("swift --version", silent: true)
                let versionLine = version.components(separatedBy: .newlines).first ?? "Unknown"

                // Check for minimum Swift version (5.7+)
                if versionLine.contains("5.9") || versionLine.contains("5.8") || versionLine.contains("5.7") || versionLine.contains("6.") {
                    return DiagnosticCheck(
                        name: "Swift Version",
                        passed: true,
                        message: versionLine.trimmingCharacters(in: .whitespacesAndNewlines),
                        severity: .error
                    )
                } else {
                    return DiagnosticCheck(
                        name: "Swift Version",
                        passed: false,
                        message: "\(versionLine) - requires Swift 5.7+",
                        severity: .warning,
                        suggestion: "Update to a newer version of Xcode for Swift 5.7+"
                    )
                }
            } catch {
                return DiagnosticCheck(
                    name: "Swift Version",
                    passed: false,
                    message: "Swift found but version check failed",
                    severity: .warning
                )
            }
        } else {
            return DiagnosticCheck(
                name: "Swift Version",
                passed: false,
                message: "Swift not found in PATH",
                severity: .error,
                suggestion: "Install Xcode and command line tools"
            )
        }
    }

    // MARK: - Dependency Checks

    private func performDependencyChecks() async -> [DiagnosticCheck] {
        var checks: [DiagnosticCheck] = []

        Console.printStep(2, total: 4, message: "Checking optional dependencies...")

        // Check for XcodeGen (optional but recommended for MicroApps)
        checks.append(await checkXcodeGen())

        // Check for Git
        checks.append(await checkGit())

        return checks
    }

    private func checkXcodeGen() async -> DiagnosticCheck {
        if Shell.exists("xcodegen") {
            do {
                let version = try Shell.run("xcodegen --version", silent: true)
                return DiagnosticCheck(
                    name: "XcodeGen",
                    passed: true,
                    message: "Version \(version.trimmingCharacters(in: .whitespacesAndNewlines))",
                    severity: .info
                )
            } catch {
                return DiagnosticCheck(
                    name: "XcodeGen",
                    passed: false,
                    message: "Found but version check failed",
                    severity: .info
                )
            }
        } else {
            return DiagnosticCheck(
                name: "XcodeGen",
                passed: false,
                message: "Not installed (optional)",
                severity: .info,
                suggestion: "Install with 'brew install xcodegen' for MicroApp support"
            )
        }
    }

    private func checkGit() async -> DiagnosticCheck {
        if Shell.exists("git") {
            do {
                let version = try Shell.run("git --version", silent: true)
                return DiagnosticCheck(
                    name: "Git",
                    passed: true,
                    message: version.trimmingCharacters(in: .whitespacesAndNewlines),
                    severity: .info
                )
            } catch {
                return DiagnosticCheck(
                    name: "Git",
                    passed: false,
                    message: "Found but not working properly",
                    severity: .info
                )
            }
        } else {
            return DiagnosticCheck(
                name: "Git",
                passed: false,
                message: "Not installed",
                severity: .info,
                suggestion: "Install Git for version control: 'brew install git'"
            )
        }
    }

    // MARK: - Configuration Checks

    private func performConfigurationChecks() async -> [DiagnosticCheck] {
        var checks: [DiagnosticCheck] = []

        Console.printStep(3, total: 4, message: "Checking configuration...")

        let configManager = ConfigurationManager()

        // Check global configuration
        checks.append(await checkConfiguration(
            name: "Global Configuration",
            path: configManager.globalConfigPath,
            configManager: configManager
        ))

        // Check local configuration
        checks.append(await checkConfiguration(
            name: "Local Configuration",
            path: configManager.localConfigPath,
            configManager: configManager
        ))

        // Check template directories
        checks.append(await checkTemplateDirectories(configManager: configManager))

        return checks
    }

    private func checkConfiguration(name: String, path: String, configManager: ConfigurationManager) async -> DiagnosticCheck {
        if FileManager.default.fileExists(atPath: path) {
            let validation = configManager.validateConfiguration(at: path)
            if validation.isValid {
                return DiagnosticCheck(
                    name: name,
                    passed: true,
                    message: "Valid configuration found",
                    severity: .info
                )
            } else {
                return DiagnosticCheck(
                    name: name,
                    passed: false,
                    message: "Configuration file exists but is invalid",
                    severity: .warning,
                    suggestion: "Run 'catalyst config init' to recreate configuration"
                )
            }
        } else {
            return DiagnosticCheck(
                name: name,
                passed: true,
                message: "Using default settings",
                severity: .info
            )
        }
    }

    private func checkTemplateDirectories(configManager: ConfigurationManager) async -> DiagnosticCheck {
        do {
            let config = try configManager.loadConfiguration()
            let templatePaths = config.templatesPath ?? []

            var existingPaths = 0
            for path in templatePaths {
                if FileManager.default.fileExists(atPath: path) {
                    existingPaths += 1
                }
            }

            if templatePaths.isEmpty {
                return DiagnosticCheck(
                    name: "Custom Templates",
                    passed: true,
                    message: "Using built-in templates",
                    severity: .info
                )
            } else if existingPaths == templatePaths.count {
                return DiagnosticCheck(
                    name: "Custom Templates",
                    passed: true,
                    message: "\(existingPaths) custom template path\(existingPaths == 1 ? "" : "s") found",
                    severity: .info
                )
            } else {
                return DiagnosticCheck(
                    name: "Custom Templates",
                    passed: false,
                    message: "\(templatePaths.count - existingPaths) template path\(templatePaths.count - existingPaths == 1 ? "" : "s") not found",
                    severity: .warning,
                    suggestion: "Check template paths in configuration"
                )
            }
        } catch {
            return DiagnosticCheck(
                name: "Custom Templates",
                passed: false,
                message: "Could not read template configuration",
                severity: .warning
            )
        }
    }

    // MARK: - Project Checks

    private func performProjectChecks() async -> [DiagnosticCheck] {
        var checks: [DiagnosticCheck] = []

        Console.printStep(4, total: 4, message: "Checking project structure...")

        // Check for workspace
        checks.append(await checkWorkspace())

        // Check for package.swift
        checks.append(await checkPackageSwift())

        // Check for .gitignore
        checks.append(await checkGitignore())

        return checks
    }

    private func checkWorkspace() async -> DiagnosticCheck {
        if let workspacePath = FileManager.default.findWorkspace() {
            let workspaceManager = WorkspaceManager()
            let validation = try? workspaceManager.validateWorkspace(at: workspacePath)

            if let validation = validation, validation.isValid {
                if case .valid(let packageCount) = validation {
                    return DiagnosticCheck(
                        name: "Xcode Workspace",
                        passed: true,
                        message: "Found with \(packageCount) package\(packageCount == 1 ? "" : "s")",
                        severity: .info
                    )
                } else {
                    return DiagnosticCheck(
                        name: "Xcode Workspace",
                        passed: true,
                        message: "Found and valid",
                        severity: .info
                    )
                }
            } else {
                return DiagnosticCheck(
                    name: "Xcode Workspace",
                    passed: false,
                    message: "Found but appears to be corrupted",
                    severity: .warning,
                    suggestion: "Try opening the workspace in Xcode to repair it"
                )
            }
        } else {
            return DiagnosticCheck(
                name: "Xcode Workspace",
                passed: true,
                message: "No workspace found (not required)",
                severity: .info
            )
        }
    }

    private func checkPackageSwift() async -> DiagnosticCheck {
        let packageSwiftPath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent("Package.swift")

        if FileManager.default.fileExists(atPath: packageSwiftPath) {
            // Try to validate the Package.swift by running swift package describe
            do {
                _ = try Shell.run("swift package describe", silent: true)
                return DiagnosticCheck(
                    name: "Package.swift",
                    passed: true,
                    message: "Valid Swift package found",
                    severity: .info
                )
            } catch {
                return DiagnosticCheck(
                    name: "Package.swift",
                    passed: false,
                    message: "Package.swift exists but appears to be invalid",
                    severity: .warning,
                    suggestion: "Check Package.swift syntax with 'swift package describe'"
                )
            }
        } else {
            return DiagnosticCheck(
                name: "Package.swift",
                passed: true,
                message: "Not a Swift package (not required)",
                severity: .info
            )
        }
    }

    private func checkGitignore() async -> DiagnosticCheck {
        let gitignorePath = (FileManager.default.currentDirectoryPath as NSString).appendingPathComponent(".gitignore")

        if FileManager.default.fileExists(atPath: gitignorePath) {
            do {
                let content = try String(contentsOfFile: gitignorePath, encoding: .utf8)
                let hasSwiftEntries = content.contains(".build") || content.contains("*.xcworkspace")

                return DiagnosticCheck(
                    name: ".gitignore",
                    passed: true,
                    message: hasSwiftEntries ? "Includes Swift/Xcode entries" : "Found",
                    severity: .info,
                    suggestion: hasSwiftEntries ? nil : "Consider adding Swift/Xcode specific ignore patterns"
                )
            } catch {
                return DiagnosticCheck(
                    name: ".gitignore",
                    passed: true,
                    message: "Found but could not read",
                    severity: .info
                )
            }
        } else {
            return DiagnosticCheck(
                name: ".gitignore",
                passed: true,
                message: "Not found (not required)",
                severity: .info
            )
        }
    }

    // MARK: - Display Results

    private func displayResults(_ checks: [DiagnosticCheck]) async {
        Console.newLine()
        Console.print("Diagnostic Results:", type: .info)
        Console.newLine()

        let groupedChecks = Dictionary(grouping: checks, by: { $0.severity })

        // Display errors first
        if let errorChecks = groupedChecks[.error] {
            displayCheckGroup(errorChecks, title: "Critical Requirements", color: .error)
        }

        // Then warnings
        if let warningChecks = groupedChecks[.warning] {
            displayCheckGroup(warningChecks, title: "Warnings", color: .warning)
        }

        // Finally info
        if let infoChecks = groupedChecks[.info] {
            displayCheckGroup(infoChecks, title: "Information", color: .info)
        }
    }

    private func displayCheckGroup(_ checks: [DiagnosticCheck], title: String, color: Console.MessageType) {
        if !checks.isEmpty {
            Console.print(title, type: color)

            for check in checks {
                let icon = check.passed ? "✅" : (check.severity == .error ? "❌" : "⚠️")
                Console.print("  \(icon) \(check.name): \(check.message)")

                if verbose && check.suggestion != nil {
                    Console.print("     → \(check.suggestion!)", type: .detail)
                }
            }
            Console.newLine()
        }
    }

    private func attemptFixes(_ failedChecks: [DiagnosticCheck]) async {
        Console.print("Attempting automatic fixes...", type: .info)

        for check in failedChecks {
            if let fix = suggestFix(for: check) {
                Console.print("Fixing: \(check.name)...", type: .detail)
                do {
                    try await fix()
                    Console.print("✅ Fixed: \(check.name)")
                } catch {
                    Console.print("❌ Could not fix \(check.name): \(error.localizedDescription)", type: .warning)
                }
            }
        }
    }

    private func suggestFix(for check: DiagnosticCheck) -> (() async throws -> Void)? {
        switch check.name {
        case "Local Configuration", "Global Configuration":
            if check.message.contains("invalid") {
                return {
                    let configManager = ConfigurationManager()
                    let path = check.name.contains("Global") ? configManager.globalConfigPath : configManager.localConfigPath
                    try configManager.saveConfiguration(.default, to: path)
                }
            }
        default:
            return nil
        }
        return nil
    }

    private func displaySummary(_ checks: [DiagnosticCheck]) {
        let passed = checks.filter { $0.passed }.count
        let failed = checks.filter { !$0.passed }.count
        let total = checks.count

        let errors = checks.filter { !$0.passed && $0.severity == .error }.count
        let warnings = checks.filter { !$0.passed && $0.severity == .warning }.count

        Console.print("Summary:", type: .info)
        Console.print("  ✅ \(passed)/\(total) checks passed")

        if failed > 0 {
            Console.print("  ❌ \(failed) issue\(failed == 1 ? "" : "s") found")
            if errors > 0 {
                Console.print("     • \(errors) critical error\(errors == 1 ? "" : "s")", type: .error)
            }
            if warnings > 0 {
                Console.print("     • \(warnings) warning\(warnings == 1 ? "" : "s")", type: .warning)
            }
        }

        Console.newLine()
        if errors == 0 && warnings == 0 {
            Console.printRainbow("🎉 ALL SYSTEMS GO! 🎉")
            Console.printBoxed("Catalyst is ready to use!", style: .rounded)
        } else if errors == 0 {
            Console.printBoxed("⚠️ Catalyst should work, but consider addressing the warnings above.", style: .rounded)
        } else {
            Console.print("Please address the critical errors above before using Catalyst.", type: .error)
        }
    }
}

// MARK: - Supporting Types

private struct DiagnosticCheck {
    let name: String
    let passed: Bool
    let message: String
    let severity: Severity
    let suggestion: String?

    init(name: String, passed: Bool, message: String, severity: Severity, suggestion: String? = nil) {
        self.name = name
        self.passed = passed
        self.message = message
        self.severity = severity
        self.suggestion = suggestion
    }

    enum Severity {
        case error    // Critical - prevents functionality
        case warning  // Important - may cause issues
        case info     // Informational only
    }
}