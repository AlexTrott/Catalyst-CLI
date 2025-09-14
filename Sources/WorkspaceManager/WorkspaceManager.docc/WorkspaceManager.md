# ``WorkspaceManager``

Manages Xcode workspace integration and project organization.

## Overview

WorkspaceManager handles the integration of generated modules and MicroApps with existing Xcode workspaces. It provides automatic workspace discovery, project addition, and scheme management to ensure seamless integration with your development environment.

## Topics

### Workspace Management

- ``WorkspaceManager/WorkspaceManager``

### Workspace Operations

WorkspaceManager provides comprehensive workspace management capabilities:

#### Workspace Discovery

Automatically finds and identifies Xcode workspaces:
```swift
let manager = WorkspaceManager()
if let workspace = manager.findWorkspace(in: projectPath) {
    print("Found workspace: \(workspace.name)")
}
```

#### Project Integration

Add projects to workspaces automatically:
```swift
try manager.addProject(
    at: "Features/AuthFeature/AuthFeature",
    to: workspace,
    group: "Features"
)
```

#### Scheme Management

Create and configure build schemes:
```swift
try manager.createScheme(
    name: "AuthFeature",
    for: project,
    in: workspace
)
```

### Workspace Structure

WorkspaceManager understands and maintains Xcode workspace structure:

```
MyApp.xcworkspace/
├── contents.xcworkspacedata       # Workspace configuration
├── xcshareddata/
│   └── xcschemes/                # Shared schemes
└── xcuserdata/
    └── username.xcuserdatad/
        └── xcschemes/            # User schemes
```

### Integration Strategies

#### Automatic Integration

When creating new modules, WorkspaceManager automatically:
1. Searches for existing workspaces
2. Determines appropriate group placement
3. Adds projects to workspace
4. Updates workspace configuration
5. Creates build schemes if needed

#### Manual Integration

For custom setups, WorkspaceManager provides fine control:
```swift
let manager = WorkspaceManager()

// Custom workspace creation
let workspace = try manager.createWorkspace(
    name: "CustomWorkspace",
    at: customPath
)

// Selective project addition
try manager.addProjects(
    projects,
    to: workspace,
    groupedBy: .moduleType
)
```

### Group Organization

WorkspaceManager organizes projects into logical groups:

```swift
enum GroupingStrategy {
    case flat              // All projects at root level
    case byType            // Group by Core/Feature/MicroApp
    case byFeature         // Group related modules together
    case custom(String)    // Custom group name
}
```

Example workspace organization:
```
MyApp.xcworkspace
├── MyApp (Main App)
├── Core
│   ├── NetworkingCore
│   ├── DataCore
│   └── AnalyticsCore
├── Features
│   ├── AuthenticationFeature
│   ├── ProfileFeature
│   └── SettingsFeature
└── MicroApps
    ├── AuthenticationApp
    └── DemoApp
```

### Workspace Discovery

WorkspaceManager uses intelligent discovery to find workspaces:

1. **Current Directory**: Check for .xcworkspace files
2. **Parent Directories**: Search up the directory tree
3. **Common Locations**: Check standard iOS project structures
4. **User Preference**: Use configured workspace path

### Project File Management

#### XcodeProj Integration

WorkspaceManager uses XcodeProj library for:
- Reading and writing workspace files
- Parsing project references
- Managing file references
- Updating configurations

#### Safe Modifications

All workspace modifications are performed safely:
- Backup existing files before modification
- Validate changes before writing
- Rollback on errors
- Preserve custom user settings

### Scheme Configuration

WorkspaceManager can create various scheme types:

#### Development Schemes
```swift
try manager.createDevelopmentScheme(
    for: module,
    with: [.build, .test, .profile, .analyze]
)
```

#### Test Schemes
```swift
try manager.createTestScheme(
    for: module,
    testTargets: ["ModuleTests", "ModuleUITests"]
)
```

#### CI/CD Schemes
```swift
try manager.createCIScheme(
    for: module,
    with: .allActions,
    shared: true
)
```

### Error Handling

WorkspaceManager provides detailed error information:

```swift
enum WorkspaceError: Error {
    case workspaceNotFound(path: String)
    case invalidWorkspaceFormat
    case projectAlreadyExists(name: String)
    case schemeCreationFailed(reason: String)
    case permissionDenied(path: String)
}
```

### Best Practices

1. **Workspace Backup**: Always backup workspaces before modification
2. **Group Organization**: Use consistent grouping strategies
3. **Scheme Naming**: Follow naming conventions for schemes
4. **Shared Schemes**: Share schemes for team consistency
5. **Version Control**: Commit workspace changes separately

### Performance Optimization

WorkspaceManager optimizes operations through:
- Lazy loading of workspace data
- Caching of parsed structures
- Batch operations for multiple projects
- Minimal file I/O operations

### Advanced Features

#### Workspace Templates

Create workspace templates for new projects:
```swift
let template = WorkspaceTemplate(
    structure: .modular,
    groups: ["Core", "Features", "Tests"],
    schemes: [.development, .release]
)
try manager.createWorkspace(from: template)
```

#### Dependency Management

Manage inter-project dependencies:
```swift
try manager.addDependency(
    from: "AppTarget",
    to: "CoreModule",
    type: .staticLibrary
)
```

#### Build Configuration

Configure build settings:
```swift
try manager.updateBuildSettings(
    for: project,
    configuration: "Release",
    settings: ["SWIFT_OPTIMIZATION_LEVEL": "-O"]
)
```

### Integration with Other Components

#### PackageGenerator
After generating packages, WorkspaceManager:
- Adds package references to workspace
- Creates appropriate groups
- Sets up build dependencies

#### MicroAppGenerator
For MicroApps, WorkspaceManager:
- Adds Xcode projects to workspace
- Creates run schemes
- Configures app targets

#### ConfigurationManager
Uses configuration for:
- Default workspace paths
- Group organization preferences
- Scheme templates

## See Also

- ``PackageGenerator``
- ``MicroAppGenerator``
- ``ConfigurationManager``
- ``CatalystCore/NewCommand``
- ``CatalystCore/ListCommand``