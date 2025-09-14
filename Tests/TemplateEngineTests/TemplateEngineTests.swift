import XCTest
@testable import TemplateEngine

final class TemplateEngineTests: XCTestCase {

    func testTemplateRendering() throws {
        let templateEngine = TemplateEngine()
        let context = ["ModuleName": "TestModule"]
        let result = try templateEngine.renderTemplate(named: "test", with: context)
        // Add actual test logic
    }
}