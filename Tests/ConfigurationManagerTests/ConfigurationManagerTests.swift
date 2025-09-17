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
}
