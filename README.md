# Catalyst CLI

A modern Swift CLI tool for iOS module generation and management.

[![Swift](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-macOS%2015+-blue.svg)](https://developer.apple.com/macos/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/alextrott/Catalyst-CLI)](https://github.com/alextrott/Catalyst-CLI/releases)
[![Downloads](https://img.shields.io/github/downloads/alextrott/Catalyst-CLI/total)](https://github.com/alextrott/Catalyst-CLI/releases)

## Overview

Catalyst accelerates iOS development by automating the creation of modular Swift packages and isolated testing environments (MicroApps). It ensures consistency and reduces development overhead through configurable templates and workspace management.

### Key Features

- 🚀 **Rapid Module Creation**: Generate Core and Feature modules in seconds
- 📱 **Automatic MicroApp Generation**: Feature modules now include companion MicroApps automatically
- 🔗 **Git Integration**: Auto-prefix commits with JIRA tickets from branch names
- 🏗️ **Workspace Integration**: Automatically manage Xcode workspaces and projects
- 🎨 **Customizable Templates**: Use built-in templates or create your own with Stencil templating
- ⚙️ **Flexible Configuration**: Project-specific and global YAML-based settings
- 🩺 **Environment Validation**: Built-in diagnostics and health checks with automatic fixes
- 🎯 **Developer-Friendly**: Colorful output, progress indicators, and helpful error messages
- 🔧 **Zero External Dependencies**: Uses XcodeGenKit programmatically - no CLI installations required

## Installation

### Quick Install (Recommended)

```bash
curl -sSL https://raw.githubusercontent.com/alextrott/Catalyst-CLI/main/install.sh | bash
```

This script will:
- ✅ Auto-detect your Mac architecture (Intel/Apple Silicon)
- ✅ Download and verify the latest release binary
- ✅ Install to `/usr/local/bin` or `~/.local/bin`
- ✅ Update your shell configuration
- ✅ Verify the installation works

### Manual Installation

#### Download Pre-built Binary

1. Visit [Releases](https://github.com/alextrott/Catalyst-CLI/releases)
2. Download the appropriate binary for your system:
   - **Apple Silicon (M1/M2/M3)**: `catalyst-*-arm64-apple-macos.tar.gz`
   - **Intel Mac**: `catalyst-*-x86_64-apple-macos.tar.gz`
3. Extract and install:

```bash
tar -xzf catalyst-*.tar.gz
sudo mv catalyst /usr/local/bin/
```

#### Install from Source

```bash
git clone https://github.com/alextrott/Catalyst-CLI.git
cd Catalyst-CLI
swift build -c release
sudo cp .build/release/catalyst /usr/local/bin/
```

### Verify Installation

```bash
catalyst --version
catalyst doctor  # Run diagnostics
```

### Prerequisites

- macOS 15.0+
- Xcode 16.0+ (for development only)
- Swift 6.0+ (for building from source only)

### Updating

To update to the latest version:

```bash
# Using the install script
curl -sSL https://raw.githubusercontent.com/alextrott/Catalyst-CLI/main/install.sh | bash

# Or manually download the latest release
```

### Uninstalling

```bash
# Remove binary
sudo rm /usr/local/bin/catalyst
# Or if installed in user directory
rm ~/.local/bin/catalyst

# Remove configuration (optional)
rm -rf ~/.catalyst.yml
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

# Create a Feature module with companion MicroApp
catalyst new feature AuthenticationFeature

# Install git hook for JIRA ticket prefixing
catalyst install git-message

# Install development packages (swiftlint, swiftformat, xcodes)
catalyst install packages

# Clean Package.resolved conflicts
catalyst reset-spm
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
- `feature`: UI components with automatic companion MicroApp for testing
- `microapp`: Standalone iOS applications for isolated testing

**Note:** When creating a feature module, Catalyst automatically generates both the reusable Swift Package and a companion MicroApp in a structured folder:
```
FeatureName/
├── FeatureName/        # The Feature Module package
└── FeatureNameApp/     # The companion MicroApp
```

### `catalyst install`

Install development tools and workflow enhancements.

#### Git Message Hook

```bash
# Install git hook for automatic JIRA ticket prefixing
catalyst install git-message

# Preview installation without making changes
catalyst install git-message --dry-run

# Force overwrite existing hooks
catalyst install git-message --force

# Verbose output during installation
catalyst install git-message --verbose
```

#### Package Management

```bash
# Install/update Homebrew packages from configuration
catalyst install packages

# Preview what would be installed/updated
catalyst install packages --dry-run

# Force reinstall packages even if already installed
catalyst install packages --force

# Show detailed output during operations
catalyst install packages --verbose
```

**Package Management Features:**
- Automatic Homebrew installation if not present
- Reads package list from `.catalyst.yml` (brewPackages section)
- Default packages: `swiftlint`, `swiftformat`, `xcodes`
- Smart update detection - only updates outdated packages
- Interactive confirmation before making changes

**Configuration Example:**
```yaml
# .catalyst.yml
author: "Your Name"
organizationName: "Your Company"

# Homebrew packages to manage
brewPackages:
  - swiftlint
  - swiftformat
  - xcodes
  - mint          # Add additional packages as needed
```

### `catalyst reset-spm`

Find and delete Package.resolved files to resolve SPM dependency conflicts.

```bash
# Find and delete with confirmation
catalyst reset-spm

# Preview what would be deleted without actually deleting
catalyst reset-spm --dry-run

# Delete without confirmation prompt
catalyst reset-spm --force

# Show detailed output during operation
catalyst reset-spm --verbose

# Search in specific directory
catalyst reset-spm --path ./MyProject

# Search only in specified directory (no recursion)
catalyst reset-spm --no-recursive
```

**Use Cases:**
- Resolve SPM dependency version conflicts across modules
- Force fresh dependency resolution after modular changes
- Clean up stale Package.resolved files in complex project structures
- Troubleshoot "unable to resolve dependencies" errors

**Safety Features:**
- User confirmation before deletion (unless `--force` used)
- Dry-run mode to preview changes
- Excludes common build/cache directories (.build, DerivedData, etc.)
- Detailed error reporting for failed deletions

**Git Message Hook:**
- Automatically prefix commit messages with JIRA tickets from branch names
- Supports patterns like: `JIRA-123`, `ABC-999`, `PROJECT-1234`
- Falls back to `[NO-TICKET]` if no ticket found in branch name
- Smart handling: skips merges, rebases, and already-prefixed messages

**Examples:**
```bash
# Branch: feature/JIRA-123-new-login
$ git commit -m "Add OAuth integration"
# Result: [JIRA-123] Add OAuth integration

# Branch: hotfix/emergency-fix
$ git commit -m "Fix critical bug"
# Result: [NO-TICKET] Fix critical bug
```

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

Create and manage MicroApps for isolated feature testing.

**Note**: This command is deprecated. For new projects:
- Use `catalyst new feature` to create a feature with automatic MicroApp
- Use `catalyst new microapp` for standalone MicroApps

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

# Homebrew packages to install/update
brewPackages:
  - swiftlint
  - swiftformat
  - xcodes
  - mint

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

# Install git hooks for better workflow
catalyst install git-message

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
- **FeatureModule**: UI components and coordinators (includes automatic MicroApp generation)
- **MicroApp**: Standalone iOS application template

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
├── Core/                    # Core modules
│   ├── NetworkingCore/      # Core module
│   │   ├── Package.swift
│   │   ├── Sources/
│   │   └── Tests/
│   └── DataLayer/          # Another core module
├── Features/               # Feature modules with MicroApps
│   └── AuthFeature/        # Feature wrapper folder
│       ├── AuthFeature/    # Feature module package
│       │   ├── Package.swift
│       │   ├── Sources/
│       │   └── Tests/
│       └── AuthFeatureApp/  # Companion MicroApp
│           ├── project.yml     # XcodeGen configuration
│           ├── AuthFeatureApp.xcodeproj
│           ├── AuthFeatureApp/
│           │   ├── AppDelegate.swift
│           │   ├── SceneDelegate.swift
│           │   ├── ContentView.swift
│           │   └── DependencyContainer.swift
│           ├── Assets.xcassets/
│           ├── LaunchScreen.storyboard
│           └── Info.plist
├── MicroApps/              # Standalone test apps
│   └── TestApp/            # Standalone MicroApp
└── .catalyst.yml           # Local configuration
```

## Best Practices

### Module Organization

- **Core Modules**: Pure business logic, no UI dependencies
- **Feature Modules**: Complete user-facing features with automatic companion MicroApps
- **MicroApps**: Automatically created for features, or standalone for testing
- Keep modules focused and single-purpose
- Use clear, descriptive names

### Feature Development Workflow

1. Set up git hooks for better commit hygiene:
   ```bash
   catalyst install git-message
   ```

2. Create a new feature with automatic MicroApp:
   ```bash
   catalyst new feature ShoppingCart --path ./Features
   ```

3. Navigate to the generated structure:
   ```
   Features/ShoppingCart/
   ├── ShoppingCart/        # Your feature module
   └── ShoppingCartApp/     # Ready-to-run test app
   ```

4. Work on a properly named branch for automatic ticket prefixing:
   ```bash
   git checkout -b feature/SHOP-456-implement-cart-logic
   ```

5. Your commits will automatically be prefixed:
   ```bash
   git commit -m "Add item validation"
   # Result: [SHOP-456] Add item validation
   ```

6. Open the MicroApp's Xcode project to test your feature in isolation:
   ```bash
   open Features/ShoppingCart/ShoppingCartApp/ShoppingCartApp.xcodeproj
   ```

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

**"Git hook already exists"**
- Use `catalyst install git-message --force` to overwrite existing hooks
- Catalyst will automatically backup your existing hook

**"Not a git repository"**
- Navigate to a git repository or run `git init` first
- Git hooks can only be installed in git repositories

**"JIRA tickets not being detected"**
- Ensure branch names contain patterns like `ABC-123`, `PROJECT-456`
- Tickets must be uppercase letters followed by hyphen and numbers
- Use `[NO-TICKET]` branches for commits without associated tickets

**"SPM dependency conflicts"**
- Run `catalyst reset-spm` to clean Package.resolved files
- Use `--dry-run` to preview files that would be deleted
- After cleanup, run `swift package resolve` in affected modules
- Consider using specific paths with `--path` for targeted cleaning

### Getting Help

```bash
# General help
catalyst --help

# Command-specific help
catalyst new --help
catalyst config --help
catalyst reset-spm --help

# Environment diagnostics
catalyst doctor --verbose
```

## Development

### Building from Source

```bash
git clone https://github.com/alextrott/Catalyst-CLI.git
cd Catalyst-CLI
swift build
```

### Building Release Binaries

Use the included build script to create release binaries:

```bash
# Build for current architecture
./scripts/build-release.sh

# Build for all supported architectures
./scripts/build-release.sh --arch all

# Build with specific version
./scripts/build-release.sh --version v1.0.0
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

- Additional template types
- IDE integrations
- Documentation improvements
- Bug fixes and optimizations
- Enhanced MicroApp features

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Swift Argument Parser](https://github.com/apple/swift-argument-parser)
- [Stencil](https://github.com/stencil-project/Stencil) for template processing
- [XcodeProj](https://github.com/tuist/XcodeProj) for workspace manipulation
- The Swift community for inspiration and feedback