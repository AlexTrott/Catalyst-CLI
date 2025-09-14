# Contributing to Catalyst CLI

Thank you for your interest in contributing to Catalyst CLI! We welcome contributions from the community and are excited to work with you.

## Table of Contents

- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Code Style Guidelines](#code-style-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)
- [Reporting Issues](#reporting-issues)
- [Community Guidelines](#community-guidelines)

## Getting Started

Before contributing, please:

1. Read our [README](README.md) to understand the project
2. Check existing [issues](https://github.com/alextrott/Catalyst-CLI/issues) and [pull requests](https://github.com/alextrott/Catalyst-CLI/pulls)
3. Review this contributing guide

## Development Setup

### Prerequisites

- macOS 15.0+
- Xcode 16.0+
- Swift 6.0+
- Git

### Setting Up Your Development Environment

1. **Fork and Clone the Repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/Catalyst-CLI.git
   cd Catalyst-CLI
   ```

2. **Create a Development Branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Build the Project**
   ```bash
   swift build
   ```

4. **Run Tests**
   ```bash
   swift test
   ```

5. **Build for Release (Optional)**
   ```bash
   swift build -c release
   ```

6. **Install Locally for Testing**
   ```bash
   swift build -c release
   cp .build/release/catalyst /usr/local/bin/catalyst-dev
   ```

### Project Structure

```
Catalyst-CLI/
├── Sources/
│   ├── CatalystCLI/           # Main executable
│   ├── CatalystCore/          # Core command logic
│   ├── ConfigurationManager/  # YAML configuration
│   ├── MicroAppGenerator/     # MicroApp creation
│   ├── PackageGenerator/      # Swift package generation
│   ├── TemplateEngine/        # Stencil integration
│   ├── Utilities/             # Shared utilities
│   └── WorkspaceManager/      # Xcode workspace handling
├── Templates/                  # Built-in templates
├── Tests/                      # Test suites
└── Package.swift              # Swift package manifest
```

## How to Contribute

### Types of Contributions

We welcome various types of contributions:

- **Bug Fixes**: Fix existing issues or report new bugs
- **Features**: Implement new features or enhance existing ones
- **Documentation**: Improve documentation, add examples, fix typos
- **Templates**: Create new templates or improve existing ones
- **Tests**: Add test coverage or improve test quality
- **Performance**: Optimize performance and reduce resource usage

### Contribution Workflow

1. **Find or Create an Issue**
   - Check existing issues for something you'd like to work on
   - Create a new issue if you have a new idea or found a bug
   - Comment on the issue to let others know you're working on it

2. **Make Your Changes**
   - Write clean, well-documented code
   - Follow our code style guidelines
   - Add tests for new functionality
   - Update documentation as needed

3. **Test Your Changes**
   - Run the full test suite: `swift test`
   - Test the CLI manually with various commands
   - Verify your changes work on both Intel and Apple Silicon Macs

4. **Submit a Pull Request**
   - Push your changes to your fork
   - Create a pull request with a clear description
   - Reference any related issues

## Code Style Guidelines

### Swift Style

We follow the [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/) with these specific conventions:

- **Indentation**: Use 4 spaces (no tabs)
- **Line Length**: Aim for 100 characters, hard limit at 120
- **Naming**: Use descriptive, clear names
  - Types: `PascalCase`
  - Functions/Variables: `camelCase`
  - Constants: `camelCase` (not `SCREAMING_SNAKE_CASE`)
- **Comments**: Use `///` for documentation comments
- **Error Handling**: Prefer throwing errors over optionals for error cases
- **Access Control**: Be explicit about access levels

### Code Organization

- Group related functionality together
- Use `// MARK: -` comments to organize code sections
- Keep files focused and under 500 lines when possible
- Extract complex logic into separate types or extensions

### Example

```swift
/// Manages the generation of Swift packages from templates
public final class PackageGenerator {
    // MARK: - Properties

    private let templateEngine: TemplateEngine
    private let fileManager: FileManager

    // MARK: - Initialization

    /// Creates a new package generator
    /// - Parameters:
    ///   - templateEngine: The template engine to use
    ///   - fileManager: The file manager for file operations
    public init(
        templateEngine: TemplateEngine,
        fileManager: FileManager = .default
    ) {
        self.templateEngine = templateEngine
        self.fileManager = fileManager
    }

    // MARK: - Public Methods

    /// Generates a new Swift package
    /// - Parameters:
    ///   - name: The name of the package
    ///   - type: The type of package to generate
    ///   - path: The path where the package should be created
    /// - Throws: `CatalystError` if generation fails
    public func generatePackage(
        named name: String,
        type: PackageType,
        at path: String
    ) throws {
        // Implementation
    }
}
```

## Testing

### Writing Tests

- Write tests for all new functionality
- Follow the Arrange-Act-Assert pattern
- Use descriptive test names that explain what is being tested
- Group related tests in test extensions or separate files
- Mock external dependencies when appropriate

### Test Structure

```swift
final class PackageGeneratorTests: XCTestCase {
    func testGeneratePackage_WithValidInput_CreatesPackage() throws {
        // Arrange
        let generator = PackageGenerator()
        let packageName = "TestPackage"

        // Act
        try generator.generatePackage(
            named: packageName,
            type: .core,
            at: "/tmp/test"
        )

        // Assert
        XCTAssertTrue(FileManager.default.fileExists(atPath: "/tmp/test/TestPackage"))
    }
}
```

### Running Tests

```bash
# Run all tests
swift test

# Run specific test
swift test --filter PackageGeneratorTests

# Run with verbose output
swift test --verbose

# Run tests in parallel
swift test --parallel
```

## Documentation

### Code Documentation

- Document all public APIs with DocC comments
- Include parameter descriptions and return values
- Add code examples where helpful
- Keep documentation up-to-date with code changes

### DocC Documentation

When adding new modules or significant features:

1. Create a DocC catalog if one doesn't exist:
   ```
   Sources/YourModule/YourModule.docc/
   ├── YourModule.md
   └── Resources/
   ```

2. Write comprehensive documentation including:
   - Module overview
   - Getting started guide
   - API reference
   - Code examples

3. Generate and preview documentation:
   ```bash
   swift package --disable-sandbox preview-documentation --target YourModule
   ```

### README Updates

Update the README when:
- Adding new commands or options
- Changing installation procedures
- Modifying configuration options
- Adding significant features

## Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **Run all checks**
   ```bash
   swift test
   swift build -c release
   ```

3. **Update documentation**
   - Add/update DocC documentation
   - Update README if needed
   - Add entries to CHANGELOG.md

### Pull Request Guidelines

- **Title**: Use a clear, descriptive title
  - Good: "Add support for custom template directories"
  - Bad: "Fix bug"

- **Description**: Include:
  - What changes were made and why
  - How to test the changes
  - Screenshots for UI changes (if applicable)
  - Related issue numbers

- **Commits**:
  - Use clear, descriptive commit messages
  - Squash minor commits before submitting
  - Follow conventional commit format if possible

### Review Process

1. Maintainers will review your PR
2. Address any feedback or requested changes
3. Once approved, your PR will be merged

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

- **Environment**: macOS version, Xcode version, Swift version
- **Description**: Clear description of the issue
- **Steps to Reproduce**: Detailed steps to reproduce the issue
- **Expected Behavior**: What you expected to happen
- **Actual Behavior**: What actually happened
- **Error Messages**: Any error messages or logs
- **Screenshots**: If applicable

### Feature Requests

For feature requests, please include:

- **Use Case**: Describe the problem you're trying to solve
- **Proposed Solution**: Your idea for how to solve it
- **Alternatives**: Any alternative solutions you've considered
- **Additional Context**: Any other relevant information

## Community Guidelines

### Code of Conduct

- Be respectful and inclusive
- Welcome newcomers and help them get started
- Focus on constructive criticism
- Respect differing opinions and experiences
- Accept responsibility for mistakes

### Getting Help

- Check the [documentation](README.md) first
- Search existing issues and discussions
- Ask questions in issues or discussions
- Be patient and respectful when seeking help

## Areas for Contribution

Looking for something to work on? Here are some areas where we'd love help:

### High Priority

- Additional template types (e.g., SDK modules, UI component libraries)
- Integration with more IDEs (VS Code, AppCode)
- Improved error messages and diagnostics
- Performance optimizations

### Good First Issues

- Documentation improvements
- Adding more code examples
- Fixing typos and small bugs
- Improving test coverage
- Adding validation for edge cases

### Future Enhancements

- Plugin system for extensibility
- Web-based template editor
- Integration with CI/CD systems
- Multi-platform support (Linux, Windows)
- Template marketplace/sharing

## Recognition

Contributors will be recognized in:
- The project's README
- Release notes
- GitHub contributors page

## Questions?

If you have questions about contributing, feel free to:
- Open an issue with the "question" label
- Start a discussion in the GitHub Discussions tab
- Reach out to the maintainers

Thank you for contributing to Catalyst CLI! Your efforts help make iOS development faster and more enjoyable for everyone.