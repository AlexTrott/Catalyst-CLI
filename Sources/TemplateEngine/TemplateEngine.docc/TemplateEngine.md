# ``TemplateEngine``

A powerful template processing engine built on Stencil for code generation.

## Overview

TemplateEngine provides sophisticated template processing capabilities for Catalyst CLI, enabling flexible and customizable code generation. It extends Stencil with custom filters and functionality specifically designed for Swift module generation.

## Topics

### Core Components

- ``TemplateEngine/TemplateEngine``
- ``TemplateEngine/TemplateLoader``
- ``TemplateEngine/StencilHelpers``

### Template Processing

TemplateEngine processes templates using the Stencil templating language, which provides:
- Variable substitution
- Control flow (conditionals and loops)
- Custom filters for string transformation
- Template inheritance and includes

### Custom Filters

TemplateEngine extends Stencil with custom filters for code generation:

#### Case Conversion Filters

```stencil
{{ModuleName|camelCase}}     # networkingCore
{{ModuleName|pascalCase}}    # NetworkingCore
{{ModuleName|snakeCase}}     # networking_core
{{ModuleName|kebabCase}}     # networking-core
{{ModuleName|lowercased}}    # networkingcore
{{ModuleName|uppercased}}    # NETWORKINGCORE
```

#### String Manipulation

```stencil
{{text|trimmed}}            # Remove leading/trailing whitespace
{{path|basename}}           # Extract filename from path
{{path|dirname}}            # Extract directory from path
```

### Template Structure

Templates follow a specific structure for optimal processing:

```
TemplateFolder/
├── Package.swift.stencil           # Package manifest template
├── README.md.stencil               # Documentation template
├── Sources/
│   └── {{ModuleName}}/
│       ├── {{ModuleName}}.swift.stencil
│       └── Models/
│           └── Model.swift.stencil
└── Tests/
    └── {{ModuleName}}Tests/
        └── {{ModuleName}}Tests.swift.stencil
```

### Template Variables

Standard variables available in all templates:

```swift
[
    "ModuleName": "NetworkingCore",
    "Author": "John Doe",
    "Date": "2024-09-14",
    "Year": "2024",
    "OrganizationName": "Acme Corp",
    "BundleIdentifierPrefix": "com.acme",
    "SwiftVersion": "6.0",
    "MinimumIOSVersion": "15.0"
]
```

Custom variables from configuration:
```swift
[
    "license": "MIT",
    "company": "Tech Corp",
    "customVariable": "value"
]
```

### Template Loading

TemplateLoader manages template discovery and loading:

#### Template Search Paths

1. User-specified paths from configuration
2. Project-local template directories
3. Global template directories
4. Built-in templates

#### Template Resolution

Templates are resolved in order of precedence:
1. Explicitly specified template path
2. Named templates in configured paths
3. Built-in templates

### Processing Pipeline

1. **Load Template**: Read template files from disk
2. **Parse Template**: Parse Stencil syntax
3. **Prepare Context**: Gather variables and configuration
4. **Render Template**: Process template with context
5. **Write Output**: Save generated files

### Advanced Features

#### Template Inheritance

Create base templates for common structure:

```stencil
{# base.swift.stencil #}
//
//  {{FileName}}
//  {{ModuleName}}
//
//  Created by {{Author}} on {{Date}}.
//  Copyright © {{Year}} {{OrganizationName}}. All rights reserved.
//

{% block imports %}
import Foundation
{% endblock %}

{% block content %}
{% endblock %}
```

Extend base templates:
```stencil
{% extends "base.swift.stencil" %}

{% block content %}
public struct {{ModuleName}} {
    // Implementation
}
{% endblock %}
```

#### Conditional Generation

Generate code based on conditions:

```stencil
{% if includeSwiftUI %}
import SwiftUI
{% else %}
import UIKit
{% endif %}

{% if isTestable %}
@testable import {{ModuleName}}
{% endif %}
```

#### Loops and Iteration

Generate repeated content:

```stencil
{% for dependency in dependencies %}
.package(url: "{{dependency.url}}", from: "{{dependency.version}}"),
{% endfor %}

{% for property in properties %}
    public let {{property.name}}: {{property.type}}
{% endfor %}
```

#### Custom Functions

TemplateEngine supports custom functions:

```stencil
{{ generateUUID() }}
{{ timestamp() }}
{{ randomString(length: 10) }}
```

### Template Validation

TemplateEngine provides validation to ensure templates are correct:

- Syntax validation for Stencil templates
- Variable existence checking
- Path resolution verification
- Output structure validation

### Best Practices

1. **Keep Templates Simple**: Avoid complex logic in templates
2. **Use Descriptive Names**: Clear variable and template names
3. **Document Variables**: List required variables in template comments
4. **Test Templates**: Validate output with different inputs
5. **Version Templates**: Track template changes over time

### Error Handling

TemplateEngine provides detailed error messages for:
- Template syntax errors
- Missing variables
- File system errors
- Invalid filter usage

Example error:
```
Template Error: Variable 'ModuleName' not found in context
  File: Package.swift.stencil
  Line: 5
  Column: 12
```

### Performance Optimization

TemplateEngine optimizes performance through:
- Template caching
- Lazy loading of templates
- Parallel processing where possible
- Minimal file I/O operations

## See Also

- [Stencil Documentation](https://stencil.fuller.li/)
- ``PackageGenerator``
- ``MicroAppGenerator``
- ``CatalystCore/TemplateCommand``
- <doc:Templates>