import Foundation
import TemplateEngine
import PathKit

// Import the types we need from CatalystCore
public enum ModuleType: String, CaseIterable {
    case core
    case feature
    case microapp
    case shared

    public var displayName: String {
        switch self {
        case .core:
            return "Core Module"
        case .feature:
            return "Feature Module"
        case .microapp:
            return "MicroApp"
        case .shared:
            return "Shared Module"
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
        case .shared:
            return "A shared module containing utilities, extensions, and common components"
        }
    }

    public var templateName: String {
        switch self {
        case .core, .feature, .shared:
            return rawValue.capitalized + "Module"
        case .microapp:
            return "MicroApp"
        }
    }

    /// Directory structure for dry-run preview only
    /// Note: Actual structure is defined by templates, not this array
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
        case .shared:
            return [
                "Sources/{{ModuleName}}/",
                "Sources/{{ModuleName}}/Extensions/",
                "Sources/{{ModuleName}}/Utilities/",
                "Sources/{{ModuleName}}/Protocols/",
                "Sources/{{ModuleName}}/Models/",
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

    /// Source files for dry-run preview only
    /// Note: Actual files are defined by templates, not this array
    public var sourceFiles: [String] {
        switch self {
        case .core:
            return [
                "Sources/{{ModuleName}}/{{ModuleName}}.swift",
                "Sources/{{ModuleName}}/{{ModuleName}}Service.swift",
                "Sources/{{ModuleName}}/Models/{{ModuleName}}Model.swift"
            ]
        case .shared:
            return [
                "Sources/{{ModuleName}}/{{ModuleName}}.swift",
                "Sources/{{ModuleName}}/Extensions/Foundation+Extensions.swift",
                "Sources/{{ModuleName}}/Utilities/{{ModuleName}}Utilities.swift"
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

    /// Test files for dry-run preview only
    /// Note: Actual files are defined by templates, not this array
    public var testFiles: [String] {
        switch self {
        case .core:
            return [
                "Tests/{{ModuleName}}Tests/{{ModuleName}}Tests.swift",
                "Tests/{{ModuleName}}Tests/{{ModuleName}}ServiceTests.swift"
            ]
        case .shared:
            return [
                "Tests/{{ModuleName}}Tests/{{ModuleName}}Tests.swift",
                "Tests/{{ModuleName}}Tests/UtilitiesTests.swift"
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
        case .shared:
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

    public init(templateEngine: TemplateEngine = TemplateEngine()) {
        self.templateEngine = templateEngine
    }

    public func generatePackage(_ configuration: ModuleConfiguration) throws {
        let packagePath = Path(configuration.path) + configuration.name

        // Create package directory
        try packagePath.mkpath()

        // Generate from template - templates now handle everything
        try generateFromTemplate(configuration, at: packagePath)
    }

    private func generateFromTemplate(_ configuration: ModuleConfiguration, at packagePath: Path) throws {
        let templateName = configuration.type.templateName

        // Process template directory - all module types should have templates now
        try templateEngine.processTemplateDirectory(
            named: templateName,
            with: configuration.templateContext,
            to: packagePath.string
        )
    }



















}