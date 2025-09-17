import XCTest
@testable import TemplateEngine

final class TemplateEngineTests: XCTestCase {

    func testRenderCoreModulePackageTemplateProducesExpectedContent() throws {
        let engine = TemplateEngine()
        let context: [String: Any] = [
            "ModuleName": "SampleModule",
            "SwiftVersion": "6.0",
            "Platforms": [".iOS(.v17)"],
            "PackageDependencies": [],
            "MainTargetDependencies": ["\"SampleModuleInterface\""]
        ]

        let output = try engine.renderTemplate(named: "CoreModule/Package.swift.stencil", with: context)
        XCTAssertTrue(output.contains("name: \"SampleModule\""))
        XCTAssertTrue(output.contains("SampleModuleInterface"))
        XCTAssertTrue(output.contains("swift-tools-version: 6.0"))
    }

    func testRenderTemplateThrowsForUnknownTemplate() {
        let engine = TemplateEngine()
        XCTAssertThrowsError(try engine.renderTemplate(named: "UnknownTemplate", with: [:])) { error in
            guard case TemplateEngineError.templateNotFound(let name, let available) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(name, "UnknownTemplate")
            XCTAssertFalse(available.isEmpty)
        }
    }

    func testTemplateLoaderListsBuiltInTemplates() {
        let loader = TemplateLoader()
        let templates = loader.availableTemplates
        XCTAssertTrue(templates.contains("CoreModule"))
        XCTAssertTrue(templates.contains("FeatureModule"))
    }
}
