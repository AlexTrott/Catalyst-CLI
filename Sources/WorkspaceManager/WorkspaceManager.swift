import Foundation
import XcodeProj
import PathKit

public class WorkspaceManager {

    public init() {}

    public func addPackageToWorkspace(packagePath: String, workspacePath: String) throws {
        let workspaceURL = URL(fileURLWithPath: workspacePath)
        let workspace = try XCWorkspace(pathString: workspacePath)

        // Create relative path from workspace to package
        let workspaceDir = workspaceURL.deletingLastPathComponent().path
        let relativePath = try createRelativePath(from: workspaceDir, to: packagePath)

        // Check if package is already in workspace
        if isPackageInWorkspace(packagePath: relativePath, workspace: workspace) {
            return // Package already exists
        }

        // Add package reference
        let packageReference = XCWorkspaceDataFileRef(location: .group(relativePath))
        workspace.data.children.append(XCWorkspaceDataElement.file(packageReference))

        // Save workspace
        try workspace.write(pathString: workspacePath, override: true)
    }

    public func removePackageFromWorkspace(packagePath: String, workspacePath: String) throws {
        let workspace = try XCWorkspace(pathString: workspacePath)
        let workspaceDir = URL(fileURLWithPath: workspacePath).deletingLastPathComponent().path
        let relativePath = try createRelativePath(from: workspaceDir, to: packagePath)

        // Remove package reference
        workspace.data.children.removeAll { element in
            switch element {
            case .file(let fileRef):
                return fileRef.location.path == relativePath
            case .group(let group):
                return group.location.path == relativePath
            }
        }

        // Save workspace
        try workspace.write(pathString: workspacePath, override: true)
    }

    public func listPackagesInWorkspace(workspacePath: String) throws -> [WorkspacePackage] {
        let workspace = try XCWorkspace(pathString: workspacePath)
        var packages: [WorkspacePackage] = []

        for element in workspace.data.children {
            switch element {
            case .file(let fileRef):
                if let package = try createWorkspacePackage(from: fileRef, workspacePath: workspacePath) {
                    packages.append(package)
                }
            case .group(let group):
                packages.append(contentsOf: try extractPackagesFromGroup(group, workspacePath: workspacePath))
            }
        }

        return packages.sorted { $0.name < $1.name }
    }

    public func createWorkspace(at path: String, name: String) throws {
        let workspacePath = (path as NSString).appendingPathComponent("\(name).xcworkspace")

        // Create workspace directory
        try FileManager.default.createDirectory(atPath: workspacePath, withIntermediateDirectories: true, attributes: nil)

        // Create workspace data
        let workspace = XCWorkspace()

        // Save workspace
        try workspace.write(pathString: workspacePath, override: true)
    }

    public func validateWorkspace(at path: String) throws -> WorkspaceValidationResult {
        guard FileManager.default.fileExists(atPath: path) else {
            return .invalid(reason: "Workspace file does not exist")
        }

        do {
            _ = try XCWorkspace(pathString: path)
            let packages = try listPackagesInWorkspace(workspacePath: path)

            return .valid(packageCount: packages.count)
        } catch {
            return .invalid(reason: "Failed to read workspace: \(error.localizedDescription)")
        }
    }

    // MARK: - Private Methods

    private func createRelativePath(from sourcePath: String, to targetPath: String) throws -> String {
        let sourceURL = URL(fileURLWithPath: sourcePath)
        let targetURL = URL(fileURLWithPath: targetPath)

        let sourceComponents = sourceURL.pathComponents
        let targetComponents = targetURL.pathComponents

        // Find common path prefix
        let commonPrefixLength = zip(sourceComponents, targetComponents)
            .prefix { $0.0 == $0.1 }
            .count

        let sourceRemainder = Array(sourceComponents.dropFirst(commonPrefixLength))
        let targetRemainder = Array(targetComponents.dropFirst(commonPrefixLength))

        // Build relative path
        let upLevels = Array(repeating: "..", count: sourceRemainder.count)
        let relativePath = (upLevels + targetRemainder).joined(separator: "/")

        return relativePath.isEmpty ? "." : relativePath
    }

    private func isPackageInWorkspace(packagePath: String, workspace: XCWorkspace) -> Bool {
        for element in workspace.data.children {
            switch element {
            case .file(let fileRef):
                if fileRef.location.path == packagePath {
                    return true
                }
            case .group(let group):
                if isPackageInGroup(packagePath: packagePath, group: group) {
                    return true
                }
            }
        }
        return false
    }

    private func isPackageInGroup(packagePath: String, group: XCWorkspaceDataGroup) -> Bool {
        for element in group.children {
            switch element {
            case .file(let fileRef):
                if fileRef.location.path == packagePath {
                    return true
                }
            case .group(let nestedGroup):
                if isPackageInGroup(packagePath: packagePath, group: nestedGroup) {
                    return true
                }
            }
        }
        return false
    }

    private func createWorkspacePackage(from fileRef: XCWorkspaceDataFileRef, workspacePath: String) throws -> WorkspacePackage? {
        let workspaceDir = URL(fileURLWithPath: workspacePath).deletingLastPathComponent().path
        let fullPath = (workspaceDir as NSString).appendingPathComponent(fileRef.location.path)

        guard FileManager.default.fileExists(atPath: fullPath) else {
            return nil
        }

        let name = (fileRef.location.path as NSString).lastPathComponent
        let type = determinePackageType(at: fullPath)

        return WorkspacePackage(
            name: name,
            path: fileRef.location.path,
            fullPath: fullPath,
            type: type
        )
    }

    private func extractPackagesFromGroup(_ group: XCWorkspaceDataGroup, workspacePath: String) throws -> [WorkspacePackage] {
        var packages: [WorkspacePackage] = []

        for element in group.children {
            switch element {
            case .file(let fileRef):
                if let package = try createWorkspacePackage(from: fileRef, workspacePath: workspacePath) {
                    packages.append(package)
                }
            case .group(let nestedGroup):
                packages.append(contentsOf: try extractPackagesFromGroup(nestedGroup, workspacePath: workspacePath))
            }
        }

        return packages
    }

    private func determinePackageType(at path: String) -> WorkspacePackage.PackageType {
        let packageSwiftPath = (path as NSString).appendingPathComponent("Package.swift")
        let xcodeproj = findProject(in: path)

        if FileManager.default.fileExists(atPath: packageSwiftPath) {
            return .swiftPackage
        } else if xcodeproj != nil {
            return .xcodeProject
        } else {
            return .folder
        }
    }

    private func findProject(in directory: String) -> String? {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: directory) else {
            return nil
        }

        for item in contents {
            if item.hasSuffix(".xcodeproj") {
                return (directory as NSString).appendingPathComponent(item)
            }
        }

        return nil
    }
}

// MARK: - Supporting Types

public struct WorkspacePackage {
    public let name: String
    public let path: String
    public let fullPath: String
    public let type: PackageType

    public init(name: String, path: String, fullPath: String, type: PackageType) {
        self.name = name
        self.path = path
        self.fullPath = fullPath
        self.type = type
    }

    public enum PackageType {
        case swiftPackage
        case xcodeProject
        case folder
    }
}

public enum WorkspaceValidationResult {
    case valid(packageCount: Int)
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

// MARK: - Errors

public enum WorkspaceError: LocalizedError {
    case workspaceNotFound(String)
    case invalidWorkspace(String)
    case packageNotFound(String)
    case packageAlreadyExists(String)

    public var errorDescription: String? {
        switch self {
        case .workspaceNotFound(let path):
            return "Workspace not found at path: \(path)"
        case .invalidWorkspace(let reason):
            return "Invalid workspace: \(reason)"
        case .packageNotFound(let name):
            return "Package '\(name)' not found in workspace"
        case .packageAlreadyExists(let name):
            return "Package '\(name)' already exists in workspace"
        }
    }
}