# Changelog

All notable changes to Catalyst CLI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- GitHub Actions workflow for automated releases
- Installation script with architecture auto-detection
- Build script for creating release binaries
- Checksum verification for downloads
- Cross-platform macOS support (Intel + Apple Silicon)
- Comprehensive DocC documentation for all modules
- MIT LICENSE file
- CONTRIBUTING.md with detailed contribution guidelines
- DocC catalogs for CatalystCLI, ConfigurationManager, MicroAppGenerator, PackageGenerator, TemplateEngine, Utilities, and WorkspaceManager modules

### Documentation
- Added complete DocC documentation for all Swift modules
- Created detailed API documentation with usage examples
- Added module overview and integration guides
- Improved inline code documentation
- Fixed GitHub repository URLs in documentation

## [1.0.0] - 2024-09-14

### Added
- Initial release of Catalyst CLI
- Core module generation with Swift Package Manager
- Feature module generation with automatic companion MicroApps
- MicroApp creation for isolated testing environments
- Git integration with automatic JIRA ticket commit prefixing
- SPM dependency conflict resolution with `reset-spm` command
- Comprehensive configuration management (global and local)
- Template system with Stencil templating engine
- Workspace integration with automatic Xcode project management
- Environment validation with `doctor` command
- Colorful CLI output with progress indicators and fancy banners
- DocC documentation generation
- Comprehensive test suite

### Features
- **Module Types**: Core, Feature, and MicroApp generation
- **Templates**: Customizable Stencil-based templates
- **Configuration**: YAML-based local and global settings
- **Git Hooks**: Automatic JIRA ticket prefixing for commits
- **Workspace Management**: Automatic Xcode workspace integration
- **Developer Tools**: Environment diagnostics and validation
- **Modern CLI**: Beautiful output with colors, progress bars, and animations

### Commands
- `catalyst new` - Create new Swift modules
- `catalyst install` - Install development tools and git hooks
- `catalyst reset-spm` - Clean Package.resolved files
- `catalyst list` - List modules and packages
- `catalyst config` - Manage configuration settings
- `catalyst template` - Manage templates
- `catalyst doctor` - Diagnose environment
- `catalyst microapp` - Create MicroApps (deprecated, use `new microapp`)

### System Requirements
- macOS 15.0+
- Swift 6.0+
- Xcode 16.0+ (for development)

### Dependencies
- Swift Argument Parser 1.6.1+
- Stencil 0.15.1+ (templating)
- XcodeProj 8.27.7 (workspace management)
- XcodeGen 2.44.1 (project generation)
- Rainbow 4.0.0+ (colorful output)
- PathKit 1.0.1+ (file operations)
- Yams 5.0.0+ (YAML parsing)
- SwiftShell 5.1.0+ (shell integration)
- Files 4.3.0+ (file system API)

[Unreleased]: https://github.com/alextrott/Catalyst-CLI/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/alextrott/Catalyst-CLI/releases/tag/v1.0.0