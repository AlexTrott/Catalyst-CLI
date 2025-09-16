import Foundation
import SwiftShell

/// Manages Homebrew installation and package operations
public class BrewManager {

    public enum BrewError: LocalizedError {
        case brewNotFound
        case installationFailed(String)
        case packageOperationFailed(package: String, operation: String, reason: String)
        case networkError

        public var errorDescription: String? {
            switch self {
            case .brewNotFound:
                return "Homebrew not found. Please install Homebrew first."
            case .installationFailed(let reason):
                return "Homebrew installation failed: \(reason)"
            case .packageOperationFailed(let package, let operation, let reason):
                return "Failed to \(operation) package '\(package)': \(reason)"
            case .networkError:
                return "Network connection required for Homebrew operations. Please check your internet connection."
            }
        }
    }

    /// Possible Homebrew installation paths
    private let possibleBrewPaths = [
        "/opt/homebrew/bin/brew",  // Apple Silicon
        "/usr/local/bin/brew",     // Intel Mac
        "/home/linuxbrew/.linuxbrew/bin/brew"  // Linux (future support)
    ]

    public init() {}

    // MARK: - Homebrew Detection and Installation

    /// Check if Homebrew is installed
    public func isBrewInstalled() -> Bool {
        return getBrewPath() != nil
    }

    /// Get the path to the brew executable
    private func getBrewPath() -> String? {
        // First try which command
        if let whichResult = try? Shell.run("which brew", silent: true),
           !whichResult.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return whichResult.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Then try common paths
        for path in possibleBrewPaths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    /// Install Homebrew using the official installation script
    public func installBrew(force: Bool = false) async throws {
        guard !isBrewInstalled() || force else {
            return // Already installed
        }

        // Check network connectivity
        try await checkNetworkConnectivity()

        let installScript = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""

        do {
            let _ = try Shell.run(installScript, timeout: 300) // 5 minutes timeout
            // If we get here, the command succeeded (Shell.run throws on non-zero exit codes)
        } catch {
            throw BrewError.installationFailed(error.localizedDescription)
        }

        // Verify installation
        if !isBrewInstalled() {
            throw BrewError.installationFailed("Installation completed but brew command not found")
        }
    }

    // MARK: - Package Operations

    /// Check if a package is installed
    public func isPackageInstalled(_ package: String) -> Bool {
        guard let brewPath = getBrewPath() else { return false }

        do {
            let _ = try Shell.run("\(brewPath) list \(package)", silent: true)
            return true // If we get here, command succeeded
        } catch {
            return false // Command failed (package not installed)
        }
    }

    /// Get installed version of a package
    public func getInstalledVersion(_ package: String) -> String? {
        guard let brewPath = getBrewPath() else { return nil }

        do {
            let output = try Shell.run("\(brewPath) list --versions \(package)", silent: true)
            // Extract version from output like "swiftlint 0.50.3"
            let components = output.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: " ")
            return components.count > 1 ? components[1] : "unknown"
        } catch {
            // Package not installed
        }

        return nil
    }

    /// Install a package
    public func installPackage(_ package: String) async throws {
        guard let brewPath = getBrewPath() else {
            throw BrewError.brewNotFound
        }

        try await checkNetworkConnectivity()

        do {
            let _ = try Shell.run("\(brewPath) install \(package)", timeout: 600) // 10 minutes timeout
            // If we get here, installation succeeded
        } catch {
            throw BrewError.packageOperationFailed(
                package: package,
                operation: "install",
                reason: error.localizedDescription
            )
        }
    }

    /// Update a package
    public func updatePackage(_ package: String) async throws {
        guard let brewPath = getBrewPath() else {
            throw BrewError.brewNotFound
        }

        try await checkNetworkConnectivity()

        do {
            let _ = try Shell.run("\(brewPath) upgrade \(package)", timeout: 600) // 10 minutes timeout
            // If we get here, upgrade succeeded
        } catch {
            // Check if the error indicates package is already up-to-date
            if error.localizedDescription.contains("already installed") ||
               error.localizedDescription.contains("up-to-date") ||
               error.localizedDescription.contains("already up-to-date") {
                return // Success - package is already up-to-date
            }
            throw BrewError.packageOperationFailed(
                package: package,
                operation: "update",
                reason: error.localizedDescription
            )
        }
    }

    /// Update Homebrew itself
    public func updateBrew() async throws {
        guard let brewPath = getBrewPath() else {
            throw BrewError.brewNotFound
        }

        try await checkNetworkConnectivity()

        do {
            let _ = try Shell.run("\(brewPath) update", timeout: 300) // 5 minutes timeout
            // If we get here, update succeeded
        } catch {
            throw BrewError.packageOperationFailed(
                package: "homebrew",
                operation: "update",
                reason: error.localizedDescription
            )
        }
    }

    /// Get information about a package
    public func getPackageInfo(_ package: String) -> PackageInfo {
        guard getBrewPath() != nil else {
            return PackageInfo(name: package, isInstalled: false, version: nil, isOutdated: false)
        }

        let isInstalled = isPackageInstalled(package)
        let version = getInstalledVersion(package)
        let isOutdated = isPackageOutdated(package)

        return PackageInfo(name: package, isInstalled: isInstalled, version: version, isOutdated: isOutdated)
    }

    /// Check if a package has updates available
    private func isPackageOutdated(_ package: String) -> Bool {
        guard let brewPath = getBrewPath() else { return false }

        do {
            let output = try Shell.run("\(brewPath) outdated \(package)", silent: true)
            return !output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false // Command failed or package not outdated
        }
    }

    /// Get list of all outdated packages
    public func getOutdatedPackages() -> [String] {
        guard let brewPath = getBrewPath() else { return [] }

        do {
            let output = try Shell.run("\(brewPath) outdated", silent: true)
            return output
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: .newlines)
                .compactMap { line in
                    let components = line.components(separatedBy: " ")
                    return components.isEmpty ? nil : components[0]
                }
                .filter { !$0.isEmpty }
        } catch {
            // Return empty array on error
        }

        return []
    }

    // MARK: - Utility Methods

    /// Check network connectivity
    private func checkNetworkConnectivity() async throws {
        guard Shell.exists("curl") else { return }

        do {
            let probe = "curl -Is https://github.com --max-time 5"
            _ = try Shell.run(probe, timeout: 10, silent: true)
        } catch {
            Console.print("Unable to verify network connectivity (\(error.localizedDescription)). Continuing and letting Homebrew surface any issues.", type: .warning)
        }
    }

    /// Get Homebrew version
    public func getBrewVersion() -> String? {
        guard let brewPath = getBrewPath() else { return nil }

        do {
            let output = try Shell.run("\(brewPath) --version", silent: true)
            let lines = output.components(separatedBy: .newlines)
            return lines.first?.replacingOccurrences(of: "Homebrew ", with: "")
        } catch {
            // Return nil on error
        }

        return nil
    }
}

// MARK: - Supporting Types

/// Information about a package
public struct PackageInfo {
    public let name: String
    public let isInstalled: Bool
    public let version: String?
    public let isOutdated: Bool

    public init(name: String, isInstalled: Bool, version: String?, isOutdated: Bool) {
        self.name = name
        self.isInstalled = isInstalled
        self.version = version
        self.isOutdated = isOutdated
    }
}
