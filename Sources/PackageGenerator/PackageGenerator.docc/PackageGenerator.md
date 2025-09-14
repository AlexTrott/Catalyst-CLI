# ``PackageGenerator``

Generates Swift packages for modular iOS development.

## Overview

PackageGenerator creates Swift packages from templates, providing the foundation for Catalyst's module generation capabilities. It handles the creation of Core and Feature modules with proper structure, dependencies, and test configurations.

## Topics

### Package Generation

- ``PackageGenerator/PackageGenerator``

### Package Types

PackageGenerator supports two primary package types:

#### Core Modules

Business logic packages that:
- Contain pure Swift code without UI dependencies
- Provide services, models, and utilities
- Can be shared across multiple features
- Are highly testable and reusable

Example structure:
```
NetworkingCore/
├── Package.swift
├── README.md
├── Sources/
│   └── NetworkingCore/
│       ├── NetworkingCore.swift
│       ├── Models/
│       ├── Services/
│       └── Utilities/
└── Tests/
    └── NetworkingCoreTests/
        └── NetworkingCoreTests.swift
```

#### Feature Modules

UI-focused packages that:
- Implement complete user-facing features
- Can depend on Core modules
- Include SwiftUI or UIKit components
- Provide coordinators for navigation

Example structure:
```
AuthenticationFeature/
├── Package.swift
├── README.md
├── Sources/
│   └── AuthenticationFeature/
│       ├── AuthenticationFeature.swift
│       ├── Views/
│       ├── ViewModels/
│       ├── Coordinators/
│       └── Resources/
└── Tests/
    └── AuthenticationFeatureTests/
        └── AuthenticationFeatureTests.swift
```

### Package Generation Process

1. **Template Selection**: Choose template based on module type
2. **Variable Preparation**: Gather configuration and user inputs
3. **Template Processing**: Use TemplateEngine to process Stencil templates
4. **File Creation**: Write generated files to disk
5. **Git Integration**: Initialize git repository if needed
6. **Workspace Integration**: Add to Xcode workspace if available

### Package.swift Generation

PackageGenerator creates modern Swift package manifests with:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ModuleName",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ModuleName",
            targets: ["ModuleName"]
        ),
    ],
    dependencies: [
        // External dependencies
    ],
    targets: [
        .target(
            name: "ModuleName",
            dependencies: []
        ),
        .testTarget(
            name: "ModuleNameTests",
            dependencies: ["ModuleName"]
        ),
    ]
)
```

### Dependency Management

PackageGenerator intelligently manages dependencies:

#### For Core Modules
- Minimal external dependencies
- Focus on Swift standard library
- Optional integration with common utilities

#### For Feature Modules
- UI framework dependencies (SwiftUI/UIKit)
- Core module dependencies
- Navigation and routing libraries
- Asset management

### Template Variables

PackageGenerator provides rich template variables:

```swift
let variables = [
    "ModuleName": moduleName,
    "Author": config.author,
    "Date": ISO8601DateFormatter().string(from: Date()),
    "Year": Calendar.current.component(.year, from: Date()),
    "OrganizationName": config.organizationName,
    "BundleIdentifierPrefix": config.bundleIdentifierPrefix,
    "SwiftVersion": "6.0",
    "MinimumIOSVersion": "15.0"
]
```

### Integration with Other Components

#### TemplateEngine
PackageGenerator uses TemplateEngine for:
- Loading templates from disk
- Processing Stencil templates
- Applying custom filters

#### WorkspaceManager
After generation, packages can be:
- Added to existing workspaces
- Linked with other modules
- Configured for build schemes

#### ConfigurationManager
Configuration provides:
- Default author and organization
- Path preferences
- Template locations
- Custom variables

### Best Practices

1. **Module Naming**: Use descriptive names ending with module type (Core/Feature)
2. **Dependencies**: Keep dependencies minimal and well-defined
3. **Testing**: Always include test targets and initial test files
4. **Documentation**: Generate README files with module descriptions
5. **Version Control**: Initialize git repositories for tracking changes

### Advanced Features

#### Custom Templates

Create custom package templates:
```
CustomTemplates/
└── CustomCore/
    ├── Package.swift.stencil
    ├── Sources/
    │   └── {{ModuleName}}/
    │       └── {{ModuleName}}.swift.stencil
    └── Tests/
        └── {{ModuleName}}Tests/
            └── {{ModuleName}}Tests.swift.stencil
```

#### Conditional Generation

Templates can include conditional logic:
```stencil
{% if includeNetworking %}
.package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.0.0"),
{% endif %}
```

#### Post-Generation Hooks

Execute actions after package generation:
- Run swift build to verify compilation
- Generate documentation
- Set up CI/CD configurations

## See Also

- ``TemplateEngine``
- ``WorkspaceManager``
- ``ConfigurationManager``
- ``CatalystCore/NewCommand``
- <doc:Templates>