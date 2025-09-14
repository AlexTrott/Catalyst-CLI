import ArgumentParser
import Foundation
import Utilities
import ConfigurationManager

/// Install various development tools and configurations.
///
/// The `InstallCommand` provides installation utilities for development workflow enhancements:
/// - **git-message**: Installs git hooks for automatic JIRA ticket prefixing
///
/// ## Examples
///
/// Install git message hook for JIRA ticket prefixing:
/// ```bash
/// catalyst install git-message
/// ```
///
/// Preview installation without making changes:
/// ```bash
/// catalyst install git-message --dry-run
/// ```
///
/// Force overwrite existing hooks:
/// ```bash
/// catalyst install git-message --force
/// ```
public struct InstallCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "install",
        abstract: "Install development tools and configurations",
        usage: """
        catalyst install git-message
        catalyst install git-message --force
        """,
        discussion: """
        Install various development workflow enhancements including git hooks,
        templates, and other development tools.

        Currently supported installations:
          git-message: Auto-prefix commits with JIRA tickets from branch names
          packages: Install and update Homebrew packages from configuration
        """,
        subcommands: [
            GitMessageCommand.self,
            PackagesCommand.self
        ]
    )

    public init() {}
}

// MARK: - Git Message Hook Command

public struct GitMessageCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "git-message",
        abstract: "Install git hook for automatic JIRA ticket prefixing"
    )

    @Flag(name: .shortAndLong, help: "Force overwrite existing hook")
    public var force: Bool = false

    @Flag(name: .long, help: "Preview what would be installed without making changes")
    public var dryRun: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose output")
    public var verbose: Bool = false

    public init() {}

    public mutating func run() async throws {
        Console.printMiniBanner()
        Console.printHeader("Installing Git Message Hook")

        let installer = GitMessageInstaller(
            force: force,
            dryRun: dryRun,
            verbose: verbose
        )

        do {
            try await installer.install()

            // Success celebration
            Console.newLine()
            Console.printRainbow("🎉 SUCCESS! 🎉")
            Console.printBoxed("Git message hook installed!", style: .rounded)

            Console.print("📁 Hook location: .git/hooks/prepare-commit-msg", type: .info)
            Console.print("🎯 Your commits will now be auto-prefixed with JIRA tickets!", type: .success)

            Console.newLine()
            Console.printGradientText("Happy coding! ⚡")

        } catch {
            Console.print("Failed to install git message hook: \(error.localizedDescription)", type: .error)
            throw ExitCode.failure
        }
    }
}

// MARK: - Git Message Installer

public class GitMessageInstaller {
    private let force: Bool
    private let dryRun: Bool
    private let verbose: Bool

    private let hookFileName = "prepare-commit-msg"
    private let backupSuffix = ".catalyst-backup"

    public init(force: Bool = false, dryRun: Bool = false, verbose: Bool = false) {
        self.force = force
        self.dryRun = dryRun
        self.verbose = verbose
    }

    public func install() async throws {
        Console.printStep(1, total: 4, message: "Validating git repository...")

        // Step 1: Validate git repository
        try validateGitRepository()

        Console.printStep(2, total: 4, message: "Generating hook script...")

        // Step 2: Generate hook script
        let hookScript = generateHookScript()

        Console.printStep(3, total: 4, message: "Installing hook...")

        // Step 3: Install hook
        try installHook(hookScript)

        Console.printStep(4, total: 4, message: "Finalizing setup...")

        // Step 4: Final verification
        try verifyInstallation()

        if verbose {
            Console.print("Installation completed successfully", type: .success)
        }
    }

    // MARK: - Validation

    private func validateGitRepository() throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let gitPath = "\(currentPath)/.git"

        guard FileManager.default.fileExists(atPath: gitPath) else {
            throw InstallError.notGitRepository
        }

        let hooksPath = "\(gitPath)/hooks"
        guard FileManager.default.fileExists(atPath: hooksPath) else {
            throw InstallError.gitHooksDirectoryMissing
        }

        if verbose {
            Console.print("✓ Git repository detected", type: .detail)
            Console.print("✓ Git hooks directory found", type: .detail)
        }
    }

    // MARK: - Hook Generation

    private func generateHookScript() -> String {
        return """
        #!/bin/bash
        #
        # Git prepare-commit-msg hook
        # Generated by Catalyst CLI
        #
        # Automatically prefix commit messages with JIRA tickets extracted from branch names
        # Supports patterns like: JIRA-123, ABC-999, etc.
        # Falls back to [NO-TICKET] if no ticket found in branch name
        #

        COMMIT_MSG_FILE=$1
        COMMIT_SOURCE=$2
        SHA1=$3

        # Skip if this is an amend, merge, squash, or cherry-pick
        if [ "$COMMIT_SOURCE" = "merge" ] || [ "$COMMIT_SOURCE" = "squash" ] || [ "$COMMIT_SOURCE" = "commit" ]; then
            exit 0
        fi

        # Skip if we're in a rebase
        if [ -d "$(git rev-parse --git-dir)/rebase-merge" ] || [ -d "$(git rev-parse --git-dir)/rebase-apply" ]; then
            exit 0
        fi

        # Get current branch name
        BRANCH=$(git branch --show-current 2>/dev/null)

        if [ -z "$BRANCH" ]; then
            # Fallback for detached HEAD or old git versions
            BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
        fi

        # Extract JIRA ticket using pattern: [A-Z]+-[0-9]+
        # Examples: JIRA-123, ABC-999, JIRA-1234
        TICKET=$(echo "$BRANCH" | grep -oE '[A-Z]+-[0-9]+' | head -1)

        # Use NO-TICKET if none found
        if [ -z "$TICKET" ]; then
            TICKET="NO-TICKET"
        fi

        # Read current commit message
        CURRENT_MSG=$(cat "$COMMIT_MSG_FILE")

        # Skip if message already has a ticket prefix or is empty
        if [ -z "$CURRENT_MSG" ] || echo "$CURRENT_MSG" | grep -qE '^\\[[A-Z]+-[0-9]+\\]|^\\[NO-TICKET\\]'; then
            exit 0
        fi

        # Skip if message starts with # (comment)
        if echo "$CURRENT_MSG" | grep -qE '^#'; then
            exit 0
        fi

        # Prepend ticket to commit message
        echo "[$TICKET] $CURRENT_MSG" > "$COMMIT_MSG_FILE"

        # Success indicator (optional, for debugging)
        # echo "Catalyst: Prefixed commit with [$TICKET]" >&2

        exit 0
        """
    }

    // MARK: - Installation

    private func installHook(_ script: String) throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let hookPath = "\(currentPath)/.git/hooks/\(hookFileName)"

        if dryRun {
            Console.printDryRun("Would install hook at: \(hookPath)")
            Console.printDryRun("Hook script length: \(script.count) characters")
            return
        }

        // Check if hook already exists
        if FileManager.default.fileExists(atPath: hookPath) {
            if force {
                try backupExistingHook(hookPath)
                Console.print("⚠️  Backed up existing hook", type: .warning)
            } else {
                throw InstallError.hookAlreadyExists(hookPath)
            }
        }

        // Write the hook script
        try script.write(toFile: hookPath, atomically: true, encoding: .utf8)

        // Make it executable
        try Shell.run("chmod +x \(hookPath)", silent: !verbose)

        if verbose {
            Console.print("✓ Hook script written to: \(hookPath)", type: .detail)
            Console.print("✓ Hook made executable", type: .detail)
        }
    }

    private func backupExistingHook(_ hookPath: String) throws {
        let backupPath = hookPath + backupSuffix

        if FileManager.default.fileExists(atPath: backupPath) {
            try FileManager.default.removeItem(atPath: backupPath)
        }

        try FileManager.default.moveItem(atPath: hookPath, toPath: backupPath)

        if verbose {
            Console.print("✓ Backed up existing hook to: \(backupPath)", type: .detail)
        }
    }

    // MARK: - Verification

    private func verifyInstallation() throws {
        let currentPath = FileManager.default.currentDirectoryPath
        let hookPath = "\(currentPath)/.git/hooks/\(hookFileName)"

        if dryRun {
            Console.printDryRun("Would verify hook installation at: \(hookPath)")
            return
        }

        guard FileManager.default.fileExists(atPath: hookPath) else {
            throw InstallError.installationFailed("Hook file not found after installation")
        }

        // Check if executable
        let attributes = try FileManager.default.attributesOfItem(atPath: hookPath)
        let permissions = attributes[.posixPermissions] as? NSNumber
        let isExecutable = (permissions?.uint16Value ?? 0) & 0o111 != 0

        guard isExecutable else {
            throw InstallError.installationFailed("Hook is not executable")
        }

        if verbose {
            Console.print("✓ Hook installation verified", type: .detail)
            Console.print("✓ Hook is executable", type: .detail)
        }
    }
}

// MARK: - Errors

public enum InstallError: LocalizedError {
    case notGitRepository
    case gitHooksDirectoryMissing
    case hookAlreadyExists(String)
    case installationFailed(String)
    case permissionDenied(String)

    public var errorDescription: String? {
        switch self {
        case .notGitRepository:
            return "Current directory is not a git repository. Run 'git init' first or navigate to a git repository."
        case .gitHooksDirectoryMissing:
            return "Git hooks directory not found. This shouldn't happen in a valid git repository."
        case .hookAlreadyExists(let path):
            return """
            Git hook already exists at: \(path)
            Use --force to overwrite, or remove the existing hook manually.
            """
        case .installationFailed(let reason):
            return "Installation failed: \(reason)"
        case .permissionDenied(let path):
            return "Permission denied when writing to: \(path)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .notGitRepository:
            return "Navigate to a git repository or initialize one with 'git init'"
        case .gitHooksDirectoryMissing:
            return "Try reinitializing the git repository"
        case .hookAlreadyExists:
            return "Use 'catalyst install git-message --force' to overwrite"
        case .installationFailed:
            return "Check file permissions and try again"
        case .permissionDenied:
            return "Check that you have write permissions to the .git/hooks directory"
        }
    }
}

// MARK: - Packages Command

public struct PackagesCommand: AsyncParsableCommand {
    public static let configuration = CommandConfiguration(
        commandName: "packages",
        abstract: "Install and update Homebrew packages from configuration",
        discussion: """
        Install Homebrew (if not already installed) and manage packages listed in your
        .catalyst.yml configuration file.

        This command will:
        • Install Homebrew if not present
        • Read package list from .catalyst.yml (brewPackages section)
        • Install missing packages
        • Update existing packages to latest versions

        Default packages: swiftlint, swiftformat, xcodes

        Examples:
          catalyst install packages              # Install/update all configured packages
          catalyst install packages --dry-run   # Preview what would be done
          catalyst install packages --force     # Force reinstall existing packages
        """
    )

    @Flag(name: .shortAndLong, help: "Preview actions without making changes")
    var dryRun = false

    @Flag(name: .shortAndLong, help: "Force reinstall packages even if already installed")
    var force = false

    @Flag(name: .shortAndLong, help: "Show detailed output during operations")
    var verbose = false

    public init() {}

    public mutating func run() async throws {
        Console.printHeader("📦 Package Installation")

        let brewManager = BrewManager()
        let configManager = ConfigurationManager()

        // Load configuration
        let config: CatalystConfiguration
        do {
            config = try configManager.loadConfiguration()
        } catch {
            if verbose {
                Console.print("Could not load configuration, using defaults: \(error.localizedDescription)", type: .detail)
            }
            config = .default
        }

        let packages = config.brewPackages ?? CatalystConfiguration.default.brewPackages ?? []

        if packages.isEmpty {
            Console.print("No packages configured for installation", type: .warning)
            return
        }

        Console.print("Target packages: \(packages.joined(separator: ", "))", type: .info)

        // Check and install Homebrew
        try await ensureHomebrewInstalled(brewManager)

        // Analyze packages
        let packageInfos = packages.map { brewManager.getPackageInfo($0) }

        if verbose {
            Console.printStep(1, total: 3, message: "Package analysis complete")
            for info in packageInfos {
                let status = info.isInstalled ? (info.isOutdated ? "outdated" : "installed") : "missing"
                let version = info.version ?? "unknown"
                Console.print("  • \(info.name): \(status) (\(version))", type: .detail)
            }
        }

        // Show installation plan
        let toInstall = packageInfos.filter { !$0.isInstalled }
        let toUpdate = packageInfos.filter { $0.isInstalled && ($0.isOutdated || force) }

        if toInstall.isEmpty && toUpdate.isEmpty {
            Console.print("🎉 All packages are up to date!", type: .success)
            return
        }

        if dryRun {
            Console.printBoxed("🔍 DRY RUN - No packages will be modified", style: .rounded)
            if !toInstall.isEmpty {
                Console.print("Would install: \(toInstall.map { $0.name }.joined(separator: ", "))", type: .info)
            }
            if !toUpdate.isEmpty {
                Console.print("Would update: \(toUpdate.map { $0.name }.joined(separator: ", "))", type: .info)
            }
            return
        }

        // Get user confirmation
        if !force && (!toInstall.isEmpty || !toUpdate.isEmpty) {
            Console.newLine()
            var message = "Proceed with package operations?"
            if !toInstall.isEmpty {
                message += "\n  Install: \(toInstall.map { $0.name }.joined(separator: ", "))"
            }
            if !toUpdate.isEmpty {
                message += "\n  Update: \(toUpdate.map { $0.name }.joined(separator: ", "))"
            }

            Console.print("\(message) (y/N): ", type: .info)
            if let input = readLine(), input.lowercased() != "y" && input.lowercased() != "yes" {
                Console.print("Operation cancelled", type: .info)
                return
            }
        }

        // Install missing packages
        if !toInstall.isEmpty {
            Console.printStep(2, total: 3, message: "Installing packages...")
            for package in toInstall {
                do {
                    if verbose {
                        Console.print("Installing \(package.name)...", type: .progress)
                    }
                    try await brewManager.installPackage(package.name)
                    Console.print("✅ Installed \(package.name)", type: .success)
                } catch {
                    Console.print("❌ Failed to install \(package.name): \(error.localizedDescription)", type: .error)
                }
            }
        }

        // Update existing packages
        if !toUpdate.isEmpty {
            Console.printStep(3, total: 3, message: "Updating packages...")
            for package in toUpdate {
                do {
                    if verbose {
                        Console.print("Updating \(package.name)...", type: .progress)
                    }
                    try await brewManager.updatePackage(package.name)
                    Console.print("✅ Updated \(package.name)", type: .success)
                } catch {
                    Console.print("❌ Failed to update \(package.name): \(error.localizedDescription)", type: .error)
                }
            }
        }

        Console.newLine()
        Console.print("🎉 Package installation complete!", type: .success)

        // Show next steps
        Console.newLine()
        Console.print("📋 Installed tools:", type: .info)
        let finalInfos = packages.map { brewManager.getPackageInfo($0) }
        for info in finalInfos where info.isInstalled {
            let version = info.version ?? "unknown"
            Console.print("  • \(info.name) (\(version))", type: .detail)
        }
    }

    private func ensureHomebrewInstalled(_ brewManager: BrewManager) async throws {
        if brewManager.isBrewInstalled() {
            if verbose {
                Console.print("✅ Homebrew is installed", type: .success)
                if let version = brewManager.getBrewVersion() {
                    Console.print("  Version: \(version)", type: .detail)
                }
            }
            return
        }

        Console.print("🍺 Homebrew not found", type: .warning)

        if dryRun {
            Console.printDryRun("Would install Homebrew")
            return
        }

        Console.print("Homebrew is required to install packages. Install now? (y/N): ", type: .info)
        if let input = readLine(), input.lowercased() == "y" || input.lowercased() == "yes" {
            Console.print("Installing Homebrew... This may take a few minutes.", type: .progress)

            do {
                try await brewManager.installBrew()
                Console.print("🎉 Homebrew installed successfully!", type: .success)
            } catch {
                Console.print("❌ Failed to install Homebrew: \(error.localizedDescription)", type: .error)
                throw error
            }
        } else {
            Console.print("Operation cancelled. Homebrew is required for package installation.", type: .info)
            throw BrewManager.BrewError.brewNotFound
        }
    }
}