import XCTest
import PathKit
@testable import PackageGenerator
import Utilities

final class PackageGeneratorTests: XCTestCase {

    func testModuleTypeMetadata() {
        XCTAssertEqual(ModuleType.core.displayName, "Core Module")
        XCTAssertEqual(ModuleType.feature.description, "A module containing UI components with automatic companion MicroApp")
        XCTAssertEqual(ModuleType.shared.templateName, "SharedModule")
        XCTAssertEqual(ModuleType.microapp.templateName, "MicroApp")
        XCTAssertFalse(ModuleType.feature.directoryStructure.isEmpty)
        XCTAssertFalse(ModuleType.microapp.sourceFiles.isEmpty)
        XCTAssertFalse(ModuleType.shared.testFiles.isEmpty)
        XCTAssertTrue(ModuleType.core.dependencies.contains("Foundation"))
    }

    func testModuleTypeFromStringIsCaseInsensitive() {
        XCTAssertEqual(ModuleType.from(string: "CoRe"), .core)
        XCTAssertEqual(ModuleType.from(string: "feature"), .feature)
        XCTAssertNil(ModuleType.from(string: "unknown"))
    }

    func testPlatformDescriptionMatchesExpectedValues() {
        XCTAssertEqual(Platform.iOS(.v16).description, ".iOS(.v16)")
        XCTAssertEqual(Platform.macOS(.v15).description, ".macOS(.v15)")
    }

    func testModuleConfigurationTemplateContextIncludesDependencies() {
        let localDependency = LocalPackageDependency(
            packageName: "Awesome",
            packagePath: "/tmp/Dependencies/Awesome",
            productNames: ["AwesomeKit"],
            availableProducts: ["AwesomeKit", "AwesomeSupport"]
        )
        let remoteDependency = Dependency(name: "Rainbow", url: "https://example.com/Rainbow.git", version: "1.2.3")

        let configuration = ModuleConfiguration(
            name: "FeatureKit",
            type: .feature,
            path: "/tmp/CatalystTests",
            author: "Jane Developer",
            organizationName: "ACME",
            bundleIdentifier: "com.acme.featurekit",
            swiftVersion: "6.0",
            platforms: [.iOS(.v17)],
            dependencies: [remoteDependency],
            customTemplateVariables: ["Custom": "Value"],
            localDependencies: [localDependency]
        )

        let context = configuration.templateContext

        XCTAssertEqual(context["ModuleName"] as? String, "FeatureKit")
        XCTAssertEqual(context["SwiftVersion"] as? String, "6.0")
        XCTAssertEqual(context["Author"] as? String, "Jane Developer")
        XCTAssertEqual(context["OrganizationName"] as? String, "ACME")
        XCTAssertEqual(context["BundleIdentifier"] as? String, "com.acme.featurekit")
        XCTAssertEqual(context["Custom"] as? String, "Value")

        let platforms = context["Platforms"] as? [String]
        XCTAssertEqual(platforms, [".iOS(.v17)"])

        let packagePath = (Path(configuration.path) + configuration.name).absolute()
        let expectedRelative = relativePath(from: packagePath, to: Path(localDependency.packagePath).absolute())

        let packageDependencies = context["PackageDependencies"] as? [String]
        XCTAssertEqual(packageDependencies, [".package(name: \"Awesome\", path: \"\(expectedRelative)\")", ".package(url: \"https://example.com/Rainbow.git\", from: \"1.2.3\")"])

        let mainDependencies = context["MainTargetDependencies"] as? [String]
        XCTAssertEqual(mainDependencies, [
            ".product(name: \"AwesomeKit\", package: \"Awesome\")",
            "\"Rainbow\"",
            "\"FeatureKitInterface\""
        ])

        let localDependencies = context["LocalDependencies"] as? [[String: Any]]
        XCTAssertEqual(localDependencies?.count, 1)
        let dependencyContext = localDependencies?.first
        XCTAssertEqual(dependencyContext?["name"] as? String, "Awesome")
        XCTAssertEqual(dependencyContext?["path"] as? String, expectedRelative)
        XCTAssertEqual(dependencyContext?["products"] as? [String], ["AwesomeKit"])

        XCTAssertNotNil(context["Date"] as? String)
        XCTAssertNotNil(context["Year"] as? Int)
    }

    func testWithLocalDependenciesReturnsUpdatedConfiguration() {
        let configuration = ModuleConfiguration(
            name: "CoreKit",
            type: .core,
            localDependencies: []
        )

        let newDependency = LocalPackageDependency(
            packageName: "Analytics",
            packagePath: "/Modules/Analytics",
            productNames: ["AnalyticsKit"],
            availableProducts: ["AnalyticsKit"]
        )

        let updated = configuration.withLocalDependencies([newDependency])

        XCTAssertTrue(configuration.localDependencies.isEmpty)
        XCTAssertEqual(updated.localDependencies.count, 1)
        XCTAssertEqual(updated.localDependencies.first?.packageName, "Analytics")
    }
}
