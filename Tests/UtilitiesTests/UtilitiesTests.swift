import Foundation
import XCTest
import PathKit
@testable import Utilities

final class UtilitiesTests: XCTestCase {
    private let fileManager = FileManager.default

    func testValidateModuleNameAcceptsValidName() throws {
        XCTAssertNoThrow(try Validators.validateModuleName("Valid_Module1"))
    }

    func testValidateModuleNameRejectsReservedKeyword() {
        XCTAssertThrowsError(try Validators.validateModuleName("swift")) { error in
            guard case ValidationError.invalidModuleName(let name, let reason) = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertEqual(name, "swift")
            XCTAssertTrue(reason.lowercased().contains("reserved"))
        }
    }

    func testValidateModuleNameRejectsInvalidCharacters() {
        XCTAssertThrowsError(try Validators.validateModuleName("Invalid-Name")) { error in
            guard case ValidationError.invalidModuleName(_, let reason) = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertTrue(reason.contains("letters, numbers"))
        }
    }

    func testValidatePathRejectsEmptyString() {
        XCTAssertThrowsError(try Validators.validatePath(""))
    }

    func testValidatePathAcceptsAbsolutePath() {
        XCTAssertNoThrow(try Validators.validatePath("/tmp"))
    }

    func testValidateDirectoryExistsDetectsMissingDirectory() {
        let tempPath = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        XCTAssertThrowsError(try Validators.validateDirectoryExists(tempPath)) { error in
            guard case ValidationError.directoryNotFound(let path) = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertEqual(path, tempPath)
        }
    }

    func testValidateDirectoryExistsAllowsExistingDirectory() throws {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempURL) }

        XCTAssertNoThrow(try Validators.validateDirectoryExists(tempURL.path))
    }

    func testValidateFileDoesNotExistHonorsOverwriteFlag() throws {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: tempURL) }

        let filePath = tempURL.appendingPathComponent("file.txt").path
        fileManager.createFile(atPath: filePath, contents: Data(), attributes: nil)

        XCTAssertThrowsError(try Validators.validateFileDoesNotExist(filePath))
        XCTAssertNoThrow(try Validators.validateFileDoesNotExist(filePath, allowOverwrite: true))
    }

    func testValidateModuleTypeSupportsCoreAndFeature() {
        XCTAssertNoThrow(try Validators.validateModuleType("core"))
        XCTAssertNoThrow(try Validators.validateModuleType("FEATURE"))
        XCTAssertThrowsError(try Validators.validateModuleType("shared")) { error in
            guard case ValidationError.unsupportedModuleType(let type) = error else {
                return XCTFail("Unexpected error type: \(error)")
            }
            XCTAssertEqual(type, "shared")
        }
    }

    func testRelativePathWithinNestedDirectories() {
        let base = Path("/tmp/Project/Modules").absolute()
        let target = Path("/tmp/Project/Modules/FeatureA/Source").absolute()
        let result = relativePath(from: base, to: target)
        XCTAssertEqual(result, "FeatureA/Source")
    }

    func testRelativePathForSameLocationReturnsDot() {
        let base = Path("/tmp/Project").absolute()
        let result = relativePath(from: base, to: base)
        XCTAssertEqual(result, ".")
    }

    func testCreateDirectoryIfNeededAndIsDirectory() throws {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let path = tempURL.appendingPathComponent("Nested").path
        defer { try? fileManager.removeItem(at: tempURL) }

        try fileManager.createDirectoryIfNeeded(at: path)
        XCTAssertTrue(fileManager.isDirectory(at: path))
    }

    func testCreateFileIfNeededWritesContentsOnce() throws {
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fileManager.removeItem(at: tempURL) }

        let filePath = tempURL.appendingPathComponent("output.txt").path
        try fileManager.createFileIfNeeded(at: filePath, contents: "initial")

        let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
        XCTAssertEqual(String(decoding: data, as: UTF8.self), "initial")

        try fileManager.createFileIfNeeded(at: filePath, contents: "ignored")
        let reread = try Data(contentsOf: URL(fileURLWithPath: filePath))
        XCTAssertEqual(String(decoding: reread, as: UTF8.self), "initial")
    }

    func testSanitizeFileNameReplacesInvalidCharacters() {
        let sanitized = fileManager.sanitizeFileName("Invalid:/Name?")
        XCTAssertEqual(sanitized, "Invalid__Name_")
    }

    func testValidationErrorRecoverySuggestions() {
        let reservedError = ValidationError.invalidModuleName("swift", reason: "reserved")
        XCTAssertTrue(reservedError.recoverySuggestion?.contains("Module names") ?? false)

        let missingDir = ValidationError.directoryNotFound("/tmp/nowhere")
        XCTAssertTrue(missingDir.recoverySuggestion?.contains("directory") ?? false)
    }

    func testEnableTestTargetUpdatesExistingEntry() throws {
        let directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let planURL = directory.appendingPathComponent("Plan.xctestplan")
        let plan: [String: Any] = [
            "testTargets": [
                [
                    "target": [
                        "name": "ExistingTests",
                        "identifier": "ExistingTests",
                        "containerPath": "container:OldPath"
                    ],
                    "enabled": false
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: plan, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: planURL)

        let manager = TestPlanManager(fileManager: fileManager)
        let targetDirectory = directory.appendingPathComponent("Modules/Shared/Existing")
        try fileManager.createDirectory(at: targetDirectory, withIntermediateDirectories: true)

        try manager.enableTestTarget(
            named: "ExistingTests",
            in: planURL.path,
            targetPath: targetDirectory.path,
            identifier: "ExistingTests",
            entryAttributes: ["parallelizable": true]
        )

        let updatedData = try Data(contentsOf: planURL)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: updatedData, options: []) as? [String: Any])
        let targets = try XCTUnwrap(json["testTargets"] as? [[String: Any]])
        let entry = try XCTUnwrap(targets.first)
        let target = try XCTUnwrap(entry["target"] as? [String: Any])
        XCTAssertEqual(target["name"] as? String, "ExistingTests")
        XCTAssertEqual(target["identifier"] as? String, "ExistingTests")
        XCTAssertEqual(target["containerPath"] as? String, "container:Modules/Shared/Existing")
        XCTAssertEqual(entry["parallelizable"] as? Bool, true)
        XCTAssertEqual(entry["enabled"] as? Bool, true)
    }

    func testEnableTestTargetAppendsWhenMissing() throws {
        let directory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? fileManager.removeItem(at: directory) }

        let planURL = directory.appendingPathComponent("Plan.xctestplan")
        let plan: [String: Any] = [
            "testTargets": [
                [
                    "target": [
                        "name": "ExistingTests",
                        "identifier": "ExistingTests",
                        "containerPath": "container:Modules/Shared/Existing"
                    ],
                    "parallelizable": true
                ]
            ]
        ]
        let data = try JSONSerialization.data(withJSONObject: plan, options: [.prettyPrinted, .sortedKeys])
        try data.write(to: planURL)

        let manager = TestPlanManager(fileManager: fileManager)
        let newTargetDirectory = directory.appendingPathComponent("Modules/Shared/New")
        try fileManager.createDirectory(at: newTargetDirectory, withIntermediateDirectories: true)

        try manager.enableTestTarget(
            named: "NewTests",
            in: planURL.path,
            targetPath: newTargetDirectory.path,
            identifier: "NewTests",
            entryAttributes: ["parallelizable": true]
        )

        let updatedData = try Data(contentsOf: planURL)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: updatedData, options: []) as? [String: Any])
        let targets = try XCTUnwrap(json["testTargets"] as? [[String: Any]])
        let names = targets.compactMap { ($0["target"] as? [String: Any])?["name"] as? String }
        XCTAssertTrue(names.contains("ExistingTests"))
        XCTAssertTrue(names.contains("NewTests"))

        let newEntry = try XCTUnwrap(targets.first { ($0["target"] as? [String: Any])?["name"] as? String == "NewTests" })
        XCTAssertNil(newEntry["enabled"])
        XCTAssertEqual(newEntry["parallelizable"] as? Bool, true)
        let target = try XCTUnwrap(newEntry["target"] as? [String: Any])
        XCTAssertEqual(target["name"] as? String, "NewTests")
        XCTAssertEqual(target["identifier"] as? String, "NewTests")
        XCTAssertEqual(target["containerPath"] as? String, "container:Modules/Shared/New")
    }
}
