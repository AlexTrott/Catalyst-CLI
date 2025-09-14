# Catalyst CLI

A modern Swift CLI tool for iOS module generation and management.

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

Catalyst accelerates iOS development by automating the creation of modular Swift packages and isolated testing environments (MicroApps). It ensures consistency and reduces development overhead through configurable templates and workspace management.

### Key Features

- 🚀 **Rapid Module Creation**: Generate Core and Feature modules in seconds
- 📱 **MicroApp Support**: Create isolated testing environments for features
- 🏗️ **Workspace Integration**: Automatically manage Xcode workspaces
- 🎨 **Customizable Templates**: Use built-in templates or create your own
- ⚙️ **Flexible Configuration**: Project-specific and global settings
- 🩺 **Environment Validation**: Built-in diagnostics and health checks
- 🎯 **Developer-Friendly**: Colorful output and helpful error messages

## Installation

### Prerequisites

- macOS 12.0+
- Xcode 14.0+
- Swift 5.9+

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

# With options
catalyst new feature ShoppingCart \
  --author "John Doe" \
  --organization "MyCompany" \
  --path "./Modules"

# Preview without creating
catalyst new core DataLayer --dry-run
```

**Module Types:**
- `core`: Business logic, services, and models
- `feature`: UI components, view controllers, and coordinators

### `catalyst list`

List modules and packages in your workspace.

```bash
# Basic listing
catalyst list

# Detailed information
catalyst list --verbose

# Filter by type
catalyst list --type packages
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

### `catalyst microapp` (Coming Soon)

Create MicroApps for isolated feature testing.

```bash
# Create a MicroApp for a feature
catalyst microapp create AuthenticationFeature

# List existing MicroApps
catalyst microapp list
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

# Module defaults
swiftVersion: "5.9"
defaultPlatforms:
  - ".iOS(.v16)"
  - ".macOS(.v12)"

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
defaultModulesPath: "./Modules"
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
├── MyApp/                  # Main app target
├── Modules/               # Generated modules
│   ├── NetworkingCore/    # Core module
│   ├── AuthFeature/      # Feature module
│   └── DataLayer/        # Another core module
├── MicroApps/            # Isolated test apps
│   ├── AuthApp/         # MicroApp for AuthFeature
│   └── NetworkApp/      # MicroApp for NetworkingCore
└── .catalyst.yml         # Local configuration
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

### Project Structure

```
Sources/
├── CatalystCLI/           # Main executable
├── CatalystCore/          # Core command logic
├── TemplateEngine/        # Stencil integration
├── WorkspaceManager/      # Xcode workspace handling
├── PackageGenerator/      # Swift package creation
├── ConfigurationManager/  # YAML configuration
└── Utilities/            # Shared utilities

Templates/
├── CoreModule/           # Core module templates
└── FeatureModule/       # Feature module templates
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