# ``ConfigurationManager``

Manages YAML-based configuration for Catalyst CLI.

## Overview

ConfigurationManager provides a flexible configuration system for Catalyst CLI, supporting both global (user-level) and local (project-level) configuration files. It handles loading, merging, and managing configuration values with a clear precedence order.

## Topics

### Configuration Management

- ``ConfigurationManager/ConfigurationManager``

### Configuration Files

ConfigurationManager supports two configuration file locations:

1. **Global Configuration**: `~/.catalyst.yml`
   - User-wide settings that apply to all projects
   - Personal preferences like author name and organization

2. **Local Configuration**: `.catalyst.yml`
   - Project-specific settings
   - Overrides global configuration
   - Should be committed to version control for team consistency

### Configuration Precedence

Configuration values are loaded and merged in the following order:
1. Built-in defaults
2. Global configuration (`~/.catalyst.yml`)
3. Local configuration (`.catalyst.yml`)

Each level overrides the previous, allowing for flexible configuration management.

### Configuration Schema

```yaml
# Author information
author: "Your Name"
organizationName: "Your Company"
bundleIdentifierPrefix: "com.yourcompany"

# Module paths
paths:
  coreModules: "./Core"
  featureModules: "./Features"
  microApps: "./MicroApps"

# Homebrew packages to manage
brewPackages:
  - swiftlint
  - swiftformat
  - xcodes

# Template configuration
templatesPath:
  - "./CustomTemplates"
  - "~/.catalyst/templates"

defaultTemplateVariables:
  license: "MIT"
  company: "Your Company"
  minimumIOSVersion: "15.0"

# Output settings
verbose: false
colorOutput: true
```

### Key Features

#### Automatic Loading

ConfigurationManager automatically discovers and loads configuration files from the appropriate locations, merging them according to the precedence rules.

#### Type-Safe Access

Configuration values are accessed through type-safe methods that handle missing values gracefully:

```swift
let author = config.getString("author") ?? "Unknown"
let verbose = config.getBool("verbose") ?? false
let packages = config.getArray("brewPackages") ?? []
```

#### Dynamic Updates

Configuration can be updated programmatically, with changes automatically persisted to the appropriate configuration file:

```swift
try config.set("author", value: "Jane Doe", global: false)
```

#### Path Resolution

ConfigurationManager automatically resolves paths, expanding tildes and creating absolute paths:

```swift
let templatePaths = config.getTemplatePaths()
// Returns fully resolved paths like ["/Users/jane/CustomTemplates"]
```

### Integration with Commands

ConfigurationManager is used throughout Catalyst CLI to provide consistent configuration across all commands:

- **NewCommand**: Uses author, organization, and path settings
- **InstallCommand**: Reads brewPackages for package management
- **TemplateCommand**: Uses templatesPath for template discovery
- **ConfigCommand**: Provides direct configuration management

### Best Practices

1. **Global vs Local**: Use global config for personal preferences, local for project settings
2. **Version Control**: Commit `.catalyst.yml` to share team settings
3. **Sensitive Data**: Never store passwords or API keys in configuration
4. **Documentation**: Document custom configuration keys in your README
5. **Validation**: Validate configuration values before use

## See Also

- ``CatalystCore/ConfigCommand``
- <doc:Configuration>
- ``Utilities/Validators``