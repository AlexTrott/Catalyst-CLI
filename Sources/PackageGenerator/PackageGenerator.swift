import Foundation
import TemplateEngine
import PathKit
import Files

// Import the types we need from CatalystCore
public enum ModuleType: String, CaseIterable {
    case core
    case feature
    case microapp

    public var displayName: String {
        switch self {
        case .core:
            return "Core Module"
        case .feature:
            return "Feature Module"
        case .microapp:
            return "MicroApp"
        }
    }

    public var description: String {
        switch self {
        case .core:
            return "A module containing business logic, services, and models"
        case .feature:
            return "A module containing UI components with automatic companion MicroApp"
        case .microapp:
            return "A standalone iOS app for testing a single feature in isolation"
        }
    }

    public var templateName: String {
        switch self {
        case .core, .feature:
            return rawValue.capitalized + "Module"
        case .microapp:
            return "MicroApp"
        }
    }

    public var directoryStructure: [String] {
        switch self {
        case .core:
            return [
                "Sources/{{ModuleName}}/",
                "Sources/{{ModuleName}}/Models/",
                "Sources/{{ModuleName}}/Services/",
                "Sources/{{ModuleName}}/Extensions/",
                "Tests/{{ModuleName}}Tests/",
                "Tests/{{ModuleName}}Tests/Mocks/"
            ]
        case .feature:
            return [
                "Sources/{{ModuleName}}/",
                "Sources/{{ModuleName}}/Views/",
                "Sources/{{ModuleName}}/ViewModels/",
                "Sources/{{ModuleName}}/Coordinators/",
                "Sources/{{ModuleName}}/Models/",
                "Tests/{{ModuleName}}Tests/",
                "Tests/{{ModuleName}}Tests/ViewTests/",
                "Tests/{{ModuleName}}Tests/ViewModelTests/"
            ]
        case .microapp:
            return [
                "{{ModuleName}}/",
                "{{ModuleName}}/Supporting Files/",
                "Assets.xcassets/",
                "Assets.xcassets/AppIcon.appiconset/",
            ]
        }
    }

    public var sourceFiles: [String] {
        switch self {
        case .core:
            return [
                "Sources/{{ModuleName}}/{{ModuleName}}.swift",
                "Sources/{{ModuleName}}/{{ModuleName}}Service.swift",
                "Sources/{{ModuleName}}/Models/{{ModuleName}}Model.swift"
            ]
        case .feature:
            return [
                "Sources/{{ModuleName}}/{{ModuleName}}.swift",
                "Sources/{{ModuleName}}/Views/{{ModuleName}}View.swift",
                "Sources/{{ModuleName}}/ViewModels/{{ModuleName}}ViewModel.swift",
                "Sources/{{ModuleName}}/Coordinators/{{ModuleName}}Coordinator.swift"
            ]
        case .microapp:
            return [
                "{{ModuleName}}/AppDelegate.swift",
                "{{ModuleName}}/SceneDelegate.swift",
                "{{ModuleName}}/ContentView.swift",
                "{{ModuleName}}/DependencyContainer.swift",
                "{{ModuleName}}/Supporting Files/Info.plist",
                "{{ModuleName}}/Supporting Files/LaunchScreen.storyboard"
            ]
        }
    }

    public var testFiles: [String] {
        switch self {
        case .core:
            return [
                "Tests/{{ModuleName}}Tests/{{ModuleName}}Tests.swift",
                "Tests/{{ModuleName}}Tests/{{ModuleName}}ServiceTests.swift"
            ]
        case .feature:
            return [
                "Tests/{{ModuleName}}Tests/{{ModuleName}}Tests.swift",
                "Tests/{{ModuleName}}Tests/ViewTests/{{ModuleName}}ViewTests.swift",
                "Tests/{{ModuleName}}Tests/ViewModelTests/{{ModuleName}}ViewModelTests.swift"
            ]
        case .microapp:
            return [
                "{{ModuleName}}Tests/{{ModuleName}}Tests.swift"
            ]
        }
    }

    public var dependencies: [String] {
        switch self {
        case .core:
            return ["Foundation"]
        case .feature:
            return ["Foundation", "UIKit", "SwiftUI"]
        case .microapp:
            return ["UIKit", "SwiftUI"]
        }
    }

    public static func from(string: String) -> ModuleType? {
        return ModuleType(rawValue: string.lowercased())
    }
}

public enum Platform {
    case iOS(Version)
    case macOS(Version)

    public enum Version {
        case v16, v17, v12, v13, v14, v15

        public var stringValue: String {
            switch self {
            case .v12: return "12.0"
            case .v13: return "13.0"
            case .v14: return "14.0"
            case .v15: return "15.0"
            case .v16: return "16.0"
            case .v17: return "17.0"
            }
        }
    }

    public var description: String {
        switch self {
        case .iOS(let version):
            return ".iOS(.v\(version.stringValue.replacingOccurrences(of: ".0", with: "")))"
        case .macOS(let version):
            return ".macOS(.v\(version.stringValue.replacingOccurrences(of: ".0", with: "")))"
        }
    }
}

public struct Dependency {
    public let name: String
    public let url: String?
    public let version: String?

    public init(name: String, url: String? = nil, version: String? = nil) {
        self.name = name
        self.url = url
        self.version = version
    }
}

public struct ModuleConfiguration {
    public let name: String
    public let type: ModuleType
    public let path: String
    public let author: String?
    public let organizationName: String?
    public let bundleIdentifier: String?
    public let swiftVersion: String
    public let platforms: [Platform]
    public let dependencies: [Dependency]
    public let customTemplateVariables: [String: String]

    public init(
        name: String,
        type: ModuleType,
        path: String = ".",
        author: String? = nil,
        organizationName: String? = nil,
        bundleIdentifier: String? = nil,
        swiftVersion: String = "5.9",
        platforms: [Platform] = [.iOS(.v16)],
        dependencies: [Dependency] = [],
        customTemplateVariables: [String: String] = [:]
    ) {
        self.name = name
        self.type = type
        self.path = path
        self.author = author
        self.organizationName = organizationName
        self.bundleIdentifier = bundleIdentifier
        self.swiftVersion = swiftVersion
        self.platforms = platforms
        self.dependencies = dependencies
        self.customTemplateVariables = customTemplateVariables
    }

    public var templateContext: [String: Any] {
        var context: [String: Any] = [
            "ModuleName": name,
            "ModuleType": type.rawValue,
            "SwiftVersion": swiftVersion,
            "Platforms": platforms.map { $0.description },
            "Dependencies": dependencies.map { dep in
                ["name": dep.name, "url": dep.url ?? "", "version": dep.version ?? "1.0.0"]
            },
            "Date": ISO8601DateFormatter().string(from: Date()),
            "Year": Calendar.current.component(.year, from: Date())
        ]

        if let author = author {
            context["Author"] = author
        }

        if let organizationName = organizationName {
            context["OrganizationName"] = organizationName
        }

        if let bundleIdentifier = bundleIdentifier {
            context["BundleIdentifier"] = bundleIdentifier
        }

        context.merge(customTemplateVariables) { (_, new) in new }

        return context
    }
}

public class PackageGenerator {
    private let templateEngine: TemplateEngine
    private let fileManager: FileManager

    public init(templateEngine: TemplateEngine = TemplateEngine()) {
        self.templateEngine = templateEngine
        self.fileManager = FileManager.default
    }

    public func generatePackage(_ configuration: ModuleConfiguration) throws {
        let packagePath = Path(configuration.path) + configuration.name

        // Create package directory
        try packagePath.mkpath()

        // Generate from template
        try generateFromTemplate(configuration, at: packagePath)

        // Create additional directory structure if needed
        try createDirectoryStructure(configuration, at: packagePath)

        // Generate Package.swift
        try generatePackageManifest(configuration, at: packagePath)

        // Generate source files
        try generateSourceFiles(configuration, at: packagePath)

        // Generate test files
        try generateTestFiles(configuration, at: packagePath)

        // Create README
        try generateReadme(configuration, at: packagePath)
    }

    private func generateFromTemplate(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        let templateName = configuration.type.templateName

        // Check if template directory exists
        do {
            try templateEngine.processTemplateDirectory(
                named: templateName,
                with: configuration.templateContext,
                to: packagePath.string
            )
        } catch TemplateEngineError.directoryNotFound(_) {
            // Template directory doesn't exist, create from built-in structure
            try createFromBuiltInTemplate(configuration, at: packagePath)
        }
    }

    private func createFromBuiltInTemplate(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        // Create basic structure when no template is available
        let sourcesPath = packagePath + "Sources" + configuration.name
        let testsPath = packagePath + "Tests" + "\(configuration.name)Tests"

        try sourcesPath.mkpath()
        try testsPath.mkpath()

        // Create basic source file
        let mainSourceContent = generateMainSourceFile(configuration)
        let mainSourcePath = sourcesPath + "\(configuration.name).swift"
        try mainSourceContent.write(to: mainSourcePath.url, atomically: true, encoding: String.Encoding.utf8)

        // Create basic test file
        let testContent = generateMainTestFile(configuration)
        let testPath = testsPath + "\(configuration.name)Tests.swift"
        try testContent.write(to: testPath.url, atomically: true, encoding: String.Encoding.utf8)
    }

    private func createDirectoryStructure(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        for directory in configuration.type.directoryStructure {
            let processedDirectory = directory.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
            let directoryPath = packagePath + processedDirectory
            try directoryPath.mkpath()
        }
    }

    private func generatePackageManifest(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        let packageManifest = generatePackageSwiftContent(configuration)
        let packagePath = packagePath + "Package.swift"

        try packageManifest.write(to: packagePath.url, atomically: true, encoding: String.Encoding.utf8)
    }

    private func generateSourceFiles(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        for sourceFile in configuration.type.sourceFiles {
            let processedPath = sourceFile.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
            let filePath = packagePath + processedPath

            // Ensure directory exists
            try filePath.parent().mkpath()

            let content = generateSourceFileContent(for: sourceFile, configuration: configuration)
            try content.write(to: filePath.url, atomically: true, encoding: String.Encoding.utf8)
        }
    }

    private func generateTestFiles(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        for testFile in configuration.type.testFiles {
            let processedPath = testFile.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
            let filePath = packagePath + processedPath

            // Ensure directory exists
            try filePath.parent().mkpath()

            let content = generateTestFileContent(for: testFile, configuration: configuration)
            try content.write(to: filePath.url, atomically: true, encoding: String.Encoding.utf8)
        }
    }

    private func generateReadme(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        let readmeContent = generateReadmeContent(configuration)
        let readmePath = packagePath + "README.md"

        try readmeContent.write(to: readmePath.url, atomically: true, encoding: String.Encoding.utf8)
    }

    // MARK: - Content Generation

    private func generatePackageSwiftContent(_ configuration: ModuleConfiguration) -> String {
        let platforms = configuration.platforms.map { $0.description }.joined(separator: ", ")
        let dependencies = configuration.dependencies.map { dep in
            if let url = dep.url {
                return """
        .package(url: "\(url)", from: "\(dep.version ?? "1.0.0")")
"""
            } else {
                return """
        .package(path: "../\(dep.name)")
"""
            }
        }.joined(separator: ",\n")

        let targetDependencies = configuration.dependencies.map { "\"\($0.name)\"" }.joined(separator: ", ")

        return """
// swift-tools-version: \(configuration.swiftVersion)
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "\(configuration.name)",
    platforms: [\(platforms)],
    products: [
        .library(
            name: "\(configuration.name)",
            targets: ["\(configuration.name)"]
        )
    ],
    dependencies: [\(dependencies.isEmpty ? "" : "\n" + dependencies + "\n    ")],
    targets: [
        .target(
            name: "\(configuration.name)",
            dependencies: [\(targetDependencies)]
        ),
        .testTarget(
            name: "\(configuration.name)Tests",
            dependencies: ["\(configuration.name)"]
        )
    ]
)
"""
    }

    private func generateMainSourceFile(_ configuration: ModuleConfiguration) -> String {
        let author = configuration.author ?? "Unknown"
        let date = DateFormatter.shortDateFormatter.string(from: Date())

        switch configuration.type {
        case .core:
            return """
//
//  \(configuration.name).swift
//  \(configuration.name)
//
//  Created by \(author) on \(date).
//

import Foundation

/// Main interface for the \(configuration.name) module
public struct \(configuration.name) {

    /// Initialize the \(configuration.name) module
    public init() {}

    /// Example function - replace with your actual implementation
    public func performOperation() -> String {
        return "Operation completed successfully"
    }
}
"""

        case .microapp:
            // MicroApp is handled by MicroAppGenerator, not PackageGenerator
            return ""

        case .feature:
            return """
//
//  \(configuration.name).swift
//  \(configuration.name)
//
//  Created by \(author) on \(date).
//

import Foundation
import UIKit

/// Main interface for the \(configuration.name) feature module
public struct \(configuration.name) {

    /// Initialize the \(configuration.name) feature
    public init() {}

    /// Create the main view controller for this feature
    public func createViewController() -> UIViewController {
        return \(configuration.name)ViewController()
    }
}
"""
        }
    }

    private func generateMainTestFile(_ configuration: ModuleConfiguration) -> String {
        let author = configuration.author ?? "Unknown"
        let date = DateFormatter.shortDateFormatter.string(from: Date())

        return """
//
//  \(configuration.name)Tests.swift
//  \(configuration.name)Tests
//
//  Created by \(author) on \(date).
//

import XCTest
@testable import \(configuration.name)

final class \(configuration.name)Tests: XCTestCase {

    var sut: \(configuration.name)!

    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = \(configuration.name)()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertNotNil(sut)
    }
}
"""
    }

    private func generateSourceFileContent(for filePath: String, configuration: ModuleConfiguration) -> String {
        let fileName = (filePath as NSString).lastPathComponent.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
        let author = configuration.author ?? "Unknown"
        let date = DateFormatter.shortDateFormatter.string(from: Date())

        let header = """
//
//  \(fileName)
//  \(configuration.name)
//
//  Created by \(author) on \(date).
//

"""

        // Generate content based on file type
        if fileName.contains("Service") {
            return header + generateServiceContent(configuration)
        } else if fileName.contains("ViewModel") {
            return header + generateViewModelContent(configuration)
        } else if fileName.contains("View") {
            return header + generateViewContent(configuration)
        } else if fileName.contains("Coordinator") {
            return header + generateCoordinatorContent(configuration)
        } else if fileName.contains("Model") {
            return header + generateModelContent(configuration)
        } else {
            return header + generateMainSourceFile(configuration)
        }
    }

    private func generateTestFileContent(for filePath: String, configuration: ModuleConfiguration) -> String {
        let fileName = (filePath as NSString).lastPathComponent.replacingOccurrences(of: "{{ModuleName}}", with: configuration.name)
        let author = configuration.author ?? "Unknown"
        let date = DateFormatter.shortDateFormatter.string(from: Date())

        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        let testTarget = className.replacingOccurrences(of: "Tests", with: "")

        return """
//
//  \(fileName)
//  \(configuration.name)Tests
//
//  Created by \(author) on \(date).
//

import XCTest
@testable import \(configuration.name)

final class \(className): XCTestCase {

    var sut: \(testTarget)!

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Initialize your system under test here
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testExample() throws {
        // Add your test here
        XCTAssertNotNil(sut)
    }
}
"""
    }

    private func generateReadmeContent(_ configuration: ModuleConfiguration) -> String {
        let moduleDescription = configuration.type.description

        return """
# \(configuration.name)

\(moduleDescription)

## Installation

Add this package to your Swift Package Manager dependencies:

```swift
.package(path: "../\(configuration.name)")
```

## Usage

```swift
import \(configuration.name)

let module = \(configuration.name)()
// Use the module functionality here
```

## Requirements

- iOS \(configuration.platforms.first?.description.contains("iOS") == true ? "16.0+" : "N/A")
- Swift \(configuration.swiftVersion)+
- Xcode 14.0+

## License

<!-- Add your license information here -->
"""
    }

    // MARK: - Specific Content Generators

    private func generateServiceContent(_ configuration: ModuleConfiguration) -> String {
        return """
import Foundation

/// Service for \(configuration.name) business logic
public class \(configuration.name)Service {

    public init() {}

    /// Example service method
    public func performService() async throws -> String {
        // Implement your service logic here
        return "Service operation completed"
    }
}
"""
    }

    private func generateViewModelContent(_ configuration: ModuleConfiguration) -> String {
        return """
import Foundation
import Combine

/// ViewModel for \(configuration.name)
@MainActor
public class \(configuration.name)ViewModel: ObservableObject {

    @Published public var isLoading = false
    @Published public var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    public init() {}

    /// Example action method
    public func performAction() {
        isLoading = true

        // Implement your business logic here

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
        }
    }
}
"""
    }

    private func generateViewContent(_ configuration: ModuleConfiguration) -> String {
        return """
import SwiftUI

/// Main view for \(configuration.name)
public struct \(configuration.name)View: View {

    @StateObject private var viewModel = \(configuration.name)ViewModel()

    public init() {}

    public var body: some View {
        VStack {
            Text("\(configuration.name) View")
                .font(.title)
                .padding()

            if viewModel.isLoading {
                ProgressView()
            } else {
                Button("Perform Action") {
                    viewModel.performAction()
                }
                .padding()
            }
        }
        .navigationTitle("\(configuration.name)")
    }
}

#Preview {
    \(configuration.name)View()
}
"""
    }

    private func generateCoordinatorContent(_ configuration: ModuleConfiguration) -> String {
        return """
import UIKit

/// Coordinator for \(configuration.name) navigation flow
public class \(configuration.name)Coordinator {

    private weak var navigationController: UINavigationController?

    public init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    /// Start the \(configuration.name) flow
    public func start() {
        let viewController = \(configuration.name)ViewController()
        navigationController?.pushViewController(viewController, animated: true)
    }
}
"""
    }

    private func generateModelContent(_ configuration: ModuleConfiguration) -> String {
        return """
import Foundation

/// Model representing \(configuration.name) data
public struct \(configuration.name)Model: Codable, Equatable {

    public let id: UUID
    public var name: String
    public let createdAt: Date

    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
    }
}
"""
    }
}

// MARK: - Extensions

private extension DateFormatter {
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}