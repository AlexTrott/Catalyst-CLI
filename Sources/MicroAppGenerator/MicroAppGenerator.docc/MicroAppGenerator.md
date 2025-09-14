# ``MicroAppGenerator``

Generates iOS MicroApps for isolated feature testing and development.

## Overview

MicroAppGenerator creates standalone iOS applications that serve as isolated testing environments for features and modules. It leverages XcodeGenKit programmatically to generate complete Xcode projects without requiring external CLI tools.

## Topics

### MicroApp Generation

- ``MicroAppGenerator/MicroAppGenerator``

### What are MicroApps?

MicroApps are lightweight iOS applications designed for:
- **Isolated Testing**: Test features in isolation from the main app
- **Rapid Development**: Faster build times and iteration cycles
- **Feature Demos**: Showcase specific features to stakeholders
- **Integration Testing**: Test module integration without full app complexity
- **UI Development**: Design and refine UI components independently

### MicroApp Structure

A generated MicroApp includes:

```
FeatureNameApp/
├── project.yml                 # XcodeGen configuration
├── FeatureNameApp.xcodeproj   # Generated Xcode project
├── FeatureNameApp/
│   ├── AppDelegate.swift      # App lifecycle management
│   ├── SceneDelegate.swift    # Scene lifecycle management
│   ├── ContentView.swift      # Main SwiftUI view
│   ├── DependencyContainer.swift # Dependency injection setup
│   └── Resources/
│       ├── Assets.xcassets    # App icons and images
│       ├── LaunchScreen.storyboard # Launch screen
│       └── Info.plist          # App configuration
└── README.md                   # MicroApp documentation
```

### Key Features

#### Automatic Project Generation

MicroAppGenerator uses XcodeGenKit programmatically to create complete Xcode projects:
- No external dependencies required
- Consistent project structure
- Modern project settings and configurations
- Support for both SwiftUI and UIKit

#### Feature Module Integration

MicroApps automatically integrate with their companion feature modules:
- Automatic Swift Package Manager integration
- Dependency resolution
- Module importing and initialization

#### Dependency Injection

Each MicroApp includes a dependency container for:
- Service registration
- Mock data injection
- Environment configuration
- Testing scenarios

#### Customizable Templates

MicroApps are generated from customizable templates that support:
- Different UI frameworks (SwiftUI/UIKit)
- Custom dependency configurations
- Branded assets and styling
- Environment-specific settings

### Generation Process

1. **Template Selection**: Choose appropriate template based on feature type
2. **Variable Resolution**: Populate template variables with configuration values
3. **File Generation**: Create project structure and source files
4. **Project Creation**: Use XcodeGenKit to generate Xcode project
5. **Workspace Integration**: Optionally add to existing workspace

### Integration with Features

When creating a feature module with `catalyst new feature`, a companion MicroApp is automatically generated:

```bash
catalyst new feature ShoppingCart
```

Creates:
```
Features/ShoppingCart/
├── ShoppingCart/        # Feature module package
└── ShoppingCartApp/     # Companion MicroApp
```

### Standalone MicroApps

For testing multiple features or creating demo apps:

```bash
catalyst new microapp DemoApp
```

### Configuration

MicroApps respect Catalyst configuration for:
- Bundle identifier prefix
- Organization name
- Minimum iOS version
- Development team settings

### Best Practices

1. **Keep MicroApps Focused**: Each MicroApp should demonstrate specific functionality
2. **Use Mock Data**: Include realistic test data for better demos
3. **Document Usage**: Add README files explaining the MicroApp's purpose
4. **Version Control**: Commit MicroApps for team collaboration
5. **CI Integration**: Use MicroApps in continuous integration for isolated testing

### Advanced Usage

#### Custom Entry Points

MicroApps can have custom entry points for different scenarios:
```swift
// DependencyContainer.swift
func setupForTesting() {
    // Configure for automated testing
}

func setupForDemo() {
    // Configure with demo data
}
```

#### Environment Configuration

Support multiple environments through configuration:
```swift
enum Environment {
    case development
    case staging
    case production
}
```

#### Feature Flags

Integrate feature flags for testing variations:
```swift
FeatureFlags.shared.enable(.newCheckoutFlow)
```

## See Also

- ``PackageGenerator``
- ``WorkspaceManager``
- ``TemplateEngine``
- ``CatalystCore/NewCommand``
- ``CatalystCore/MicroAppCommand``