# ``CatalystCLI``

The main executable for the Catalyst command-line interface.

## Overview

CatalystCLI is the entry point for the Catalyst command-line tool. It provides the main command structure and delegates to specialized commands in the CatalystCore module for actual functionality.

This module sets up the command-line interface using Swift Argument Parser and provides:
- Command routing and execution
- Version information
- Help text generation
- Error handling and user feedback

## Topics

### Main Entry Point

The CatalystCLI executable serves as the main entry point for all Catalyst commands. It uses Swift Argument Parser to provide a modern, type-safe command-line interface with automatic help generation and validation.

### Command Structure

The CLI follows a subcommand pattern where each major feature is accessed through a specific subcommand:

```bash
catalyst <subcommand> [options]
```

Available subcommands include:
- `new` - Create new Swift modules
- `install` - Install development tools and configurations
- `reset-spm` - Clean Package.resolved files
- `list` - List modules and packages
- `config` - Manage configuration settings
- `template` - Manage templates
- `doctor` - Diagnose environment issues
- `microapp` - Manage MicroApps (deprecated)

### Integration with CatalystCore

CatalystCLI is intentionally minimal, delegating all business logic to the CatalystCore module. This separation allows:
- Better testability of core functionality
- Reusability of commands in other contexts
- Clear separation between CLI concerns and business logic

### Error Handling

The CLI provides user-friendly error messages by:
- Catching and formatting CatalystError exceptions
- Providing helpful suggestions for common issues
- Using colored output for better readability
- Offering verbose mode for debugging

## See Also

- ``CatalystCore``
- ``CatalystCore/NewCommand``
- ``CatalystCore/ConfigCommand``
- ``CatalystCore/DoctorCommand``