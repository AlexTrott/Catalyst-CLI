import Foundation
import XCTest
@testable import ConfigurationManager

final class ConfigurationManagerTests: XCTestCase {

    func testLoadConfigurationRespectsSkipDependencyResolverFlag() throws {
        let tempDirectoryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: tempDirectoryURL) }

        try FileManager.default.createDirectory(at: tempDirectoryURL, withIntermediateDirectories: true)

        let configURL = tempDirectoryURL.appendingPathComponent(".catalyst.yml")
        let yaml = """
        skipDependencyResolver: true
        paths:
          coreModules: "."
        """
        try yaml.write(to: configURL, atomically: true, encoding: .utf8)

        let manager = ConfigurationManager()
        let configuration = try manager.loadConfiguration(from: configURL.path)

        XCTAssertEqual(configuration.skipDependencyResolver, true)
    }

    func testMergedConfigurationPrefersOverrideSkipDependencyResolverFlag() {
        let base = CatalystConfiguration(skipDependencyResolver: false)
        let override = CatalystConfiguration(skipDependencyResolver: true)

        let merged = base.merged(with: override)

        XCTAssertEqual(merged.skipDependencyResolver, true)
    }

    func testMergedConfigurationPrefersOverrideDependencyExclusions() {
        let base = CatalystConfiguration(dependencyExclusions: ["PackageA"])
        let override = CatalystConfiguration(dependencyExclusions: ["PackageB"])

        let merged = base.merged(with: override)

        XCTAssertEqual(merged.dependencyExclusions, ["PackageB"])
    }

    func testGetValueRetrievesNestedTemplateVariable() {
        let configuration = CatalystConfiguration(
            defaultTemplateVariables: ["environment": "staging"]
        )

        XCTAssertEqual(configuration.getValue(for: "defaultTemplateVariables.environment"), "staging")
    }

    func testSetValueUpdatesNestedTemplateVariable() {
        var configuration = CatalystConfiguration()
        configuration.setValue("production", for: "defaultTemplateVariables.environment")

        XCTAssertEqual(configuration.defaultTemplateVariables?["environment"], "production")
    }

    func testSetValueParsesDependencyExclusions() {
        var configuration = CatalystConfiguration()
        configuration.setValue("PackageA, PackageB", for: "dependencyExclusions")

        XCTAssertEqual(configuration.dependencyExclusions ?? [], ["PackageA", "PackageB"])
    }

    func testAllSettingsIncludesConfiguredValues() {
        var configuration = CatalystConfiguration(
            author: "Jane",
            organizationName: "ACME",
            bundleIdentifierPrefix: "com.acme",
            templatesPath: ["Templates"],
            defaultTemplateVariables: ["environment": "test"],
            swiftVersion: "6.0",
            defaultPlatforms: [".iOS(.v17)"],
            verbose: true,
            colorOutput: false,
            dependencyExclusions: ["PackageA"],
            defaultModulesPath: "Modules"
        )
        configuration.setValue("true", for: "verbose")

        let settings = configuration.allSettings
        XCTAssertEqual(settings["author"], "Jane")
        XCTAssertEqual(settings["defaultTemplateVariables.environment"], "test")
        XCTAssertEqual(settings["defaultPlatforms"], ".iOS(.v17)")
        XCTAssertEqual(settings["verbose"], "true")
        XCTAssertEqual(settings["dependencyExclusions"], "PackageA")
    }

    func testSaveAndLoadConfigurationRoundTrip() throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let configuration = CatalystConfiguration(author: "Sam", skipDependencyResolver: true, dependencyExclusions: ["PackageA"])
        let manager = ConfigurationManager()
        let path = tempURL.appendingPathComponent("config.yml").path

        try manager.saveConfiguration(configuration, to: path)
        let loaded = try manager.loadConfiguration(from: path)

        XCTAssertEqual(loaded.author, "Sam")
        XCTAssertEqual(loaded.skipDependencyResolver, true)
        XCTAssertEqual(loaded.dependencyExclusions, ["PackageA"])
    }

    func testValidationResultIsValidConvenienceProperty() {
        XCTAssertTrue(ValidationResult.valid.isValid)
        XCTAssertFalse(ValidationResult.invalid(reason: "oops").isValid)
    }
}
