import Foundation
@preconcurrency import Stencil

public struct StencilHelpers {

    public static let catalystExtension: Extension = {
        let ext = Extension()

        // Add custom filters for Catalyst templates
        ext.registerFilter("camelCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.camelCased
        }

        ext.registerFilter("pascalCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.pascalCased
        }

        ext.registerFilter("snakeCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.snakeCased
        }

        ext.registerFilter("kebabCase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.kebabCased
        }

        ext.registerFilter("uppercase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.uppercased()
        }

        ext.registerFilter("lowercase") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.lowercased()
        }

        ext.registerFilter("capitalize") { (value: Any?) in
            guard let string = value as? String else { return value }
            return string.capitalized
        }

        // Date formatting filters
        ext.registerFilter("date") { (value: Any?, arguments: [Any?]) in
            guard let dateString = value as? String,
                  let format = arguments.first as? String else { return value }

            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: dateString) else { return value }

            let displayFormatter = DateFormatter()
            displayFormatter.dateFormat = format
            return displayFormatter.string(from: date)
        }

        ext.registerFilter("year") { (value: Any?) in
            if let dateString = value as? String,
               let date = ISO8601DateFormatter().date(from: dateString) {
                return Calendar.current.component(.year, from: date)
            }
            return Calendar.current.component(.year, from: Date())
        }

        // Array and collection filters
        ext.registerFilter("join") { (value: Any?, arguments: [Any?]) in
            guard let array = value as? [Any],
                  let separator = arguments.first as? String else { return value }

            let strings = array.compactMap { $0 as? String }
            return strings.joined(separator: separator)
        }

        ext.registerFilter("first") { (value: Any?) in
            guard let array = value as? [Any], !array.isEmpty else { return value }
            return array.first
        }

        ext.registerFilter("last") { (value: Any?) in
            guard let array = value as? [Any], !array.isEmpty else { return value }
            return array.last
        }

        ext.registerFilter("count") { (value: Any?) in
            if let array = value as? [Any] {
                return array.count
            } else if let string = value as? String {
                return string.count
            }
            return 0
        }

        // String manipulation filters
        ext.registerFilter("prefix") { (value: Any?, arguments: [Any?]) in
            guard let string = value as? String,
                  let prefix = arguments.first as? String else { return value }
            return prefix + string
        }

        ext.registerFilter("suffix") { (value: Any?, arguments: [Any?]) in
            guard let string = value as? String,
                  let suffix = arguments.first as? String else { return value }
            return string + suffix
        }

        ext.registerFilter("replace") { (value: Any?, arguments: [Any?]) in
            guard let string = value as? String,
                  arguments.count >= 2,
                  let target = arguments[0] as? String,
                  let replacement = arguments[1] as? String else { return value }
            return string.replacingOccurrences(of: target, with: replacement)
        }

        // Custom Catalyst-specific filters
        ext.registerFilter("moduleFileName") { (value: Any?) in
            guard let moduleName = value as? String else { return value }
            return "\(moduleName).swift"
        }

        ext.registerFilter("testFileName") { (value: Any?) in
            guard let moduleName = value as? String else { return value }
            return "\(moduleName)Tests.swift"
        }

        ext.registerFilter("bundleIdentifier") { (value: Any?, arguments: [Any?]) in
            guard let moduleName = value as? String else { return value }
            let organization = (arguments.first as? String) ?? "com.example"
            return "\(organization).\(moduleName)"
        }

        return ext
    }()
}

// String extension for case conversions
extension String {
    var camelCased: String {
        guard !isEmpty else { return "" }
        let components = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        guard !components.isEmpty else { return "" }

        let first = components.first!.lowercased()
        let rest = components.dropFirst().map { $0.capitalized }

        return first + rest.joined()
    }

    var pascalCased: String {
        guard !isEmpty else { return "" }
        let components = self.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }

        return components.map { $0.capitalized }.joined()
    }

    var snakeCased: String {
        guard !isEmpty else { return "" }

        let acronymPattern = "([A-Z]+)([A-Z][a-z]|[0-9])"
        let normalPattern = "([a-z0-9])([A-Z])"

        let processedString = self
            .replacingOccurrences(of: acronymPattern, with: "$1_$2", options: .regularExpression)
            .replacingOccurrences(of: normalPattern, with: "$1_$2", options: .regularExpression)

        return processedString.lowercased()
    }

    var kebabCased: String {
        return snakeCased.replacingOccurrences(of: "_", with: "-")
    }
}