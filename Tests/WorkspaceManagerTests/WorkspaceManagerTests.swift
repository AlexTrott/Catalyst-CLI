import XCTest
@testable import WorkspaceManager

final class WorkspaceManagerTests: XCTestCase {

    func testCreateWorkspaceAndValidate() throws {
        let manager = WorkspaceManager()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try manager.createWorkspace(at: tempURL.path, name: "TestWorkspace")
        let workspacePath = tempURL.appendingPathComponent("TestWorkspace.xcworkspace").path

        XCTAssertTrue(FileManager.default.fileExists(atPath: workspacePath))

        let validation = try manager.validateWorkspace(at: workspacePath)
        switch validation {
        case .valid(let count):
            XCTAssertGreaterThanOrEqual(count, 0)
        case .invalid(let reason):
            XCTFail("Expected valid workspace but found: \(reason)")
        }
    }

    func testAddAndRemovePackageFromWorkspace() throws {
        let manager = WorkspaceManager()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        try manager.createWorkspace(at: tempURL.path, name: "Modules")
        let workspacePath = tempURL.appendingPathComponent("Modules.xcworkspace").path

        let packageURL = tempURL.appendingPathComponent("Modules/Feature")
        try FileManager.default.createDirectory(at: packageURL, withIntermediateDirectories: true)
        let packageSwiftPath = packageURL.appendingPathComponent("Package.swift")
        FileManager.default.createFile(atPath: packageSwiftPath.path, contents: Data("// swift package".utf8), attributes: nil)

        let initialPackages = try manager.listPackagesInWorkspace(workspacePath: workspacePath)

        try manager.addPackageToWorkspace(packagePath: packageURL.path, workspacePath: workspacePath)

        var packages = try manager.listPackagesInWorkspace(workspacePath: workspacePath)
        XCTAssertEqual(packages.count, initialPackages.count + 1)

        let featurePackage = packages.first { $0.name == "Feature" }
        XCTAssertNotNil(featurePackage)
        XCTAssertEqual(featurePackage?.type, .swiftPackage)

        try manager.removePackageFromWorkspace(packagePath: packageURL.path, workspacePath: workspacePath)
        packages = try manager.listPackagesInWorkspace(workspacePath: workspacePath)
        XCTAssertEqual(packages.count, initialPackages.count)
    }
}
