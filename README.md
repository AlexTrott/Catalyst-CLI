# Catalyst CLI

A modern Swift CLI tool for iOS module generation and management.

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015+-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

Catalyst accelerates iOS development by automating the creation of modular Swift packages and isolated testing environments (MicroApps). It ensures consistency and reduces development overhead through configurable templates and workspace management.

### Key Features

- 🚀 **Rapid Module Creation**: Generate Core and Feature modules in seconds
- 📱 **MicroApp Support**: Create isolated testing environments for features with programmatic XcodeGen integration
- 🏗️ **Workspace Integration**: Automatically manage Xcode workspaces and projects
- 🎨 **Customizable Templates**: Use built-in templates or create your own with Stencil templating
- ⚙️ **Flexible Configuration**: Project-specific and global YAML-based settings
- 🩺 **Environment Validation**: Built-in diagnostics and health checks with automatic fixes
- 🎯 **Developer-Friendly**: Colorful output, progress indicators, and helpful error messages
- 🔧 **Zero External Dependencies**: Uses XcodeGenKit programmatically - no CLI installations required

## Installation

### Prerequisites

- macOS 15.0+
- Xcode 16.0+
- Swift 6.0+

### Install from Source

```bash
git clone https://github.com/[org]/catalyst-cli.git
cd catalyst-cli
swift build -c release
sudo cp .build/release/catalyst /usr/local/bin/
```

### Verify Installation

```bash
catalyst --version
catalyst doctor  # Run diagnostics
```

## Quick Start

### 1. Check Your Environment

```bash
catalyst doctor
```

### 2. Create Your First Module

```bash
# Create a Core module for business logic
catalyst new core NetworkingCore

# Create a Feature module for UI components
catalyst new feature AuthenticationFeature
```

### 3. Configure Defaults (Optional)

```bash
catalyst config set author "Your Name"
catalyst config set organizationName "Your Company"
```

### 4. List Your Modules

```bash
catalyst list --verbose
```

## Commands

### `catalyst new`

Create new Swift modules from templates.

```bash
# Basic usage
catalyst new <type> <name>

# Examples
catalyst new core UserManagement
catalyst new feature LoginFlow
catalyst new microapp TestFeature

# With options
catalyst new feature ShoppingCart \
  --author "John Doe" \
  --organization "MyCompany" \
  --path "./Modules"

# Preview without creating
catalyst new core DataLayer --dry-run

# Force overwrite existing modules
catalyst new feature ExistingFeature --force
```

**Module Types:**
- `core`: Business logic, services, and models
- `feature`: UI components, view controllers, and coordinators
- `microapp`: Complete iOS applications for isolated testing

### `catalyst list`

List modules and packages in your workspace.

```bash
# Basic listing
catalyst list

# Detailed information
catalyst list --verbose

# Filter by type
catalyst list --type packages

# Show full paths instead of relative
catalyst list --full-paths

# Recursive search through nested folders
catalyst list --recursive
```

### `catalyst config`

Manage configuration settings.

```bash
# View all settings
catalyst config list

# Get a specific value
catalyst config get author

# Set a value locally
catalyst config set author "Jane Doe"

# Set globally (across all projects)
catalyst config set author "Jane Doe" --global

# Initialize configuration file
catalyst config init
```

### `catalyst template`

Manage templates for module generation.

```bash
# List available templates
catalyst template list

# Show template details
catalyst template show CoreModule

# Validate template syntax
catalyst template validate FeatureModule
```

### `catalyst microapp`

Create and manage MicroApps for isolated feature testing. **Note**: This command is deprecated. Use `catalyst new microapp` instead.

```bash
# Create a MicroApp for a feature (deprecated)
catalyst microapp create AuthenticationFeature --output ./MicroApps

# List existing MicroApps
catalyst microapp list --verbose

# Preview creation without making changes
catalyst microapp create TestFeature --dry-run
```

### `catalyst doctor`

Diagnose and validate your environment.

```bash
# Run all checks
catalyst doctor

# Detailed diagnostics
catalyst doctor --verbose

# Attempt automatic fixes
catalyst doctor --fix
```

## Configuration

Catalyst supports both project-local and global configuration through YAML files.

### Configuration Locations

- **Local**: `.catalyst.yml` (project directory)
- **Global**: `~/.catalyst.yml` (user home directory)

Local configuration overrides global settings.

### Configuration Options

```yaml
# Author information
author: "John Doe"
organizationName: "MyCompany"
bundleIdentifierPrefix: "com.mycompany"

# Module paths (overrides default locations)
paths:
  coreModules: "./Core"
  featureModules: "./Features"
  microApps: "./MicroApps"

# Template settings
templatesPath:
  - "./CustomTemplates"
  - "~/.catalyst/templates"

defaultTemplateVariables:
  company: "MyCompany"
  license: "MIT"

# Output settings
verbose: false
colorOutput: true
```

### Example Workflow

```bash
# Set up your preferences
catalyst config set author "Jane Smith"
catalyst config set organizationName "Acme Corp"

# Create modules with your defaults
catalyst new core DataManager
catalyst new feature ProductCatalog

# Check what you've created
catalyst list --verbose
```

## Templates

Catalyst uses [Stencil](https://github.com/stencil-project/Stencil) for template processing.

### Built-in Templates

- **CoreModule**: Business logic and services
- **FeatureModule**: UI components and coordinators

### Template Variables

Common variables available in templates:

- `{{ModuleName}}`: The module name
- `{{Author}}`: Author from configuration
- `{{Date}}`: Current date
- `{{Year}}`: Current year
- `{{OrganizationName}}`: Organization from config
- `{{SwiftVersion}}`: Swift version to use

### Template Filters

Catalyst provides additional Stencil filters:

```stencil
{{ModuleName|camelCase}}        # myModuleName
{{ModuleName|pascalCase}}       # MyModuleName
{{ModuleName|snakeCase}}        # my_module_name
{{ModuleName|kebabCase}}        # my-module-name
```

### Custom Templates

1. Create a template directory:
```
MyTemplate/
├── Package.swift.stencil
├── Sources/
│   └── {{ModuleName}}/
│       └── {{ModuleName}}.swift.stencil
└── Tests/
    └── {{ModuleName}}Tests/
        └── {{ModuleName}}Tests.swift.stencil
```

2. Configure template path:
```bash
catalyst config set templatesPath ./CustomTemplates
```

3. Validate your template:
```bash
catalyst template validate MyTemplate
```

## Project Structure

Catalyst works well with modular iOS project structures:

```
MyApp/
├── MyApp.xcworkspace
├── MyApp/                    # Main app target
├── Modules/                 # Generated modules
│   ├── NetworkingCore/      # Core module
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   └── Tests/
│   ├── AuthFeature/        # Feature module
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   └── Tests/
│   └── DataLayer/          # Another core module
├── MicroApps/              # Isolated test apps
│   ├── AuthFeatureApp/     # MicroApp for AuthFeature
│   │   ├── project.yml     # XcodeGen configuration
│   │   ├── AuthFeatureApp.xcodeproj
│   │   ├── AuthFeatureApp/
│   │   │   ├── AppDelegate.swift
│   │   │   ├── SceneDelegate.swift
│   │   │   ├── ContentView.swift
│   │   │   └── DependencyContainer.swift
│   │   ├── Assets.xcassets/
│   │   ├── LaunchScreen.storyboard
│   │   └── Info.plist
│   └── NetworkingCoreApp/  # MicroApp for NetworkingCore
└── .catalyst.yml           # Local configuration
```

## Best Practices

### Module Organization

- **Core Modules**: Pure business logic, no UI dependencies
- **Feature Modules**: Complete user-facing features
- Keep modules focused and single-purpose
- Use clear, descriptive names

### Template Customization

- Start with built-in templates
- Customize gradually based on your needs
- Share custom templates across your team
- Validate templates before using in production

### Configuration Management

- Set up global defaults for personal preferences
- Use local config for project-specific settings
- Commit `.catalyst.yml` to version control
- Document team conventions in your README

## Troubleshooting

### Common Issues

**"No workspace found"**
- Create an Xcode workspace first, or modules will be created without workspace integration

**"Template not found"**
- Check available templates: `catalyst template list`
- Verify template path configuration: `catalyst config get templatesPath`

**"Invalid module name"**
- Module names must start with a letter and contain only alphanumeric characters and underscores

### Getting Help

```bash
# General help
catalyst --help

# Command-specific help
catalyst new --help
catalyst config --help

# Environment diagnostics
catalyst doctor --verbose
```

## Development

### Building from Source

```bash
git clone https://github.com/[org]/catalyst-cli.git
cd catalyst-cli
swift build
```

### Running Tests

```bash
swift test
```

### Generating Documentation

Catalyst CLI includes comprehensive DocC documentation. Generate and view the documentation with these commands:

#### Generate Documentation

```bash
# Generate documentation for all modules
swift package generate-documentation

# Generate documentation for a specific target
swift package generate-documentation --target CatalystCore
```

#### Preview Documentation Locally

```bash
# Start local documentation server
swift package --disable-sandbox preview-documentation --target CatalystCore

# This will start a local server (typically at http://localhost:8080)
# and automatically open the documentation in your default browser
```

#### Build Static Documentation

```bash
# Generate static HTML documentation
swift package generate-documentation --target CatalystCore \
  --output-path ./docs \
  --hosting-base-path /catalyst-cli/

# This creates a ./docs directory with standalone HTML files
# suitable for hosting on GitHub Pages or other static hosting
```

#### View Documentation

The documentation includes:

- **Getting Started Guide**: Complete setup and usage instructions
- **Configuration Reference**: Detailed configuration options
- **Template System**: Custom template creation and usage
- **API Reference**: Complete programmatic interface documentation
- **Command Reference**: All CLI commands with examples

**Key Documentation Sections:**
- [Getting Started](http://localhost:8080/documentation/catalystcore/gettingstarted) - Your first steps with Catalyst
- [Configuration](http://localhost:8080/documentation/catalystcore/configuration) - Customizing Catalyst for your project
- [Templates](http://localhost:8080/documentation/catalystcore/templates) - Creating and using custom templates
- [API Reference](http://localhost:8080/documentation/catalystcore) - Complete API documentation

#### Documentation Development

When contributing to documentation:

```bash
# Start preview server for live editing
swift package --disable-sandbox preview-documentation --target CatalystCore

# Edit .md files in Sources/CatalystCore/CatalystCore.docc/
# Documentation updates automatically as you save files
```

### Project Structure

```
Sources/
├── CatalystCLI/           # Main executable
├── CatalystCore/          # Core command logic
├── TemplateEngine/        # Stencil integration
├── WorkspaceManager/      # Xcode workspace handling
├── PackageGenerator/      # Swift package creation
├── MicroAppGenerator/     # MicroApp creation with XcodeGenKit
├── ConfigurationManager/  # YAML configuration
└── Utilities/            # Shared utilities

Templates/
├── CoreModule/           # Core module templates
├── FeatureModule/       # Feature module templates
└── MicroAppTemplates/   # MicroApp templates
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Areas for Contribution

- MicroApp generation implementation
- Additional template types
- IDE integrations
- Documentation improvements
- Bug fixes and optimizations

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- [Stencil](https://github.com/stencil-project/Stencil) for template processing
- [XcodeProj](https://github.com/tuist/XcodeProj) for workspace manipulation
- The Swift community for inspiration and feedback