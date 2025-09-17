# ``Utilities``

Shared utilities and helper functions for Catalyst CLI.

## Overview

The Utilities module provides common functionality used throughout Catalyst CLI, including console output formatting, shell command execution, file system operations, validation, and package management.

## Topics

### Console Output

- ``Utilities/Console``

The Console class provides rich terminal output capabilities:
- Colored text output using ANSI escape codes
- Progress indicators and spinners
- Formatted tables and lists
- Interactive prompts and confirmations
- ASCII art banners and separators

### Shell Integration

- ``Utilities/Shell``

Shell utilities for executing system commands:
- Safe command execution with error handling
- Output capture and streaming
- Environment variable management
- Process control and timeout handling

### File System Operations

- ``Utilities/FileManager+Extensions``

Extensions to FileManager providing:
- Safe file and directory creation
- Recursive directory operations
- Path validation and normalization
- Template file copying
- Temporary file management

### Package Management

- ``Utilities/BrewManager``

Homebrew package management integration:
- Package installation and updates
- Version checking
- Dependency resolution
- Brew command execution

### Validation

- ``Utilities/Validators``

Input validation utilities:
- Module name validation
- Path validation
- Configuration value validation
- Template syntax validation

## Console Features

### Colored Output

```swift
Console.print("Operation completed successfully", type: .success)
Console.print("An error occurred", type: .error)
Console.print("Warning: Check configuration", type: .warning)
Console.print("Processing files...", type: .info)
```

### Progress Indicators

```swift
let progress = Console.progress(total: 3, message: "Generating modules")
progress.advance(message: "Scaffolding sources")
progress.advance(message: "Creating tests")
progress.finish(message: "Generation complete")

// Legacy spinner for longer running work
Console.printSpinner(message: "Building project", duration: 1.5)
```

### Interactive Prompts

```swift
// Yes/No confirmation with default
let proceed = Console.confirm("Continue with operation?", defaultAnswer: true)

// Text input with default value
let name = Console.prompt("Enter module name", defaultValue: "MyFeature")

// Choice selection
let option = Console.select(
    "Choose template",
    options: ["Core", "Feature", "Custom"]
)
```

### Styled Sections

```swift
Console.printHeader("Workspace Contents")
Console.printDivider()
Console.printBoxed("Installation Complete!", style: .double)
```

## Shell Operations

### Command Execution

```swift
// Simple command
let output = try Shell.run("swift", "--version")

// Command with arguments
let files = try Shell.run("ls", "-la", at: "/path/to/directory")

// Capture both stdout and stderr
let result = Shell.execute(command: "git", arguments: ["status"])
if result.exitCode == 0 {
    print(result.output)
} else {
    print(result.error)
}
```

### Environment Management

```swift
// Run with custom environment
Shell.run(
    "swift", "build",
    environment: ["SWIFT_DETERMINISTIC_HASHING": "1"]
)
```

## File Operations

### Safe File Creation

```swift
// Create directory with intermediate directories
try FileManager.default.createDirectoryIfNeeded(at: path)

// Copy with overwrite protection
try FileManager.default.safeCopy(from: source, to: destination)

// Atomic write operations
try FileManager.default.atomicWrite(data, to: filePath)
```

### Path Operations

```swift
// Resolve relative paths
let absolutePath = FileManager.default.absolutePath(for: "~/Documents")

// Check path validity
let isValid = FileManager.default.isValidPath(path)

// Find files matching pattern
let files = try FileManager.default.findFiles(matching: "*.swift", in: directory)
```

## Brew Management

### Package Operations

```swift
let brew = BrewManager()

// Check if Homebrew is installed
if brew.isInstalled {
    // Install packages
    try brew.install(packages: ["swiftlint", "swiftformat"])

    // Update packages
    try brew.update(packages: ["xcodes"])

    // Check installed versions
    let version = try brew.version(of: "swiftlint")
}
```

### Installation Detection

```swift
// Check for required tools
let hasSwiftLint = brew.isPackageInstalled("swiftlint")
let hasXcodes = brew.isPackageInstalled("xcodes")

// Get list of outdated packages
let outdated = try brew.outdatedPackages()
```

## Validation

### Input Validation

```swift
// Validate module names
Validators.validateModuleName("NetworkingCore") // Valid
Validators.validateModuleName("123Invalid") // Throws error

// Validate paths
Validators.validatePath("/usr/local/bin") // Valid
Validators.validatePath("../../../etc/passwd") // Throws error

// Validate configuration
Validators.validateConfiguration(config) // Comprehensive validation
```

### Custom Validators

```swift
// Create custom validators
let emailValidator = Validator { input in
    guard input.contains("@") else {
        throw ValidationError.invalid("Invalid email format")
    }
}
```

## Best Practices

1. **Error Handling**: Always handle errors gracefully with informative messages
2. **User Feedback**: Provide clear progress indicators for long operations
3. **Color Usage**: Use colors consistently (red for errors, green for success)
4. **Path Safety**: Always validate and sanitize user-provided paths
5. **Shell Safety**: Escape shell arguments to prevent injection

## Integration

Utilities module is used throughout Catalyst CLI:

- **Console**: All commands use Console for output
- **Shell**: Package installation, git operations, build commands
- **FileManager**: Template copying, module creation, workspace management
- **BrewManager**: Development tool installation
- **Validators**: Input validation across all commands

## See Also

- ``CatalystCore``
- ``ConfigurationManager``
- ``PackageGenerator``
- ``WorkspaceManager``
