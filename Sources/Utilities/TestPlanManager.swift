import Foundation
import PathKit

public enum TestPlanError: LocalizedError {
    case planNotFound(String)
    case invalidFormat(String)

    public var errorDescription: String? {
        switch self {
        case .planNotFound(let path):
            return "XCTest plan not found at path: \(path)"
        case .invalidFormat(let reason):
            return "Invalid XCTest plan format: \(reason)"
        }
    }
}

public final class TestPlanManager {
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    /// Enable (or add) a test target entry inside the specified XCTest plan.
    /// - Parameters:
    ///   - targetName: The name of the test target that should be enabled.
    ///   - planPath: Path to the `.xctestplan` file. Relative paths are resolved from the current working directory.
    ///   - targetPath: Optional absolute or relative path to the target container (package directory or project file).
    ///   - identifier: Optional identifier to associate with the target within the plan.
    ///   - entryAttributes: Additional attributes to apply directly to the plan entry (e.g., `parallelizable`).
    public func enableTestTarget(
        named targetName: String,
        in planPath: String,
        targetPath: String? = nil,
        identifier: String? = nil,
        entryAttributes: [String: Any] = [:]
    ) throws {
        let resolvedPath = resolve(path: planPath)

        guard fileManager.fileExists(atPath: resolvedPath) else {
            throw TestPlanError.planNotFound(planPath)
        }

        let url = URL(fileURLWithPath: resolvedPath)
        let data = try Data(contentsOf: url)
        guard var plan = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw TestPlanError.invalidFormat("Root object is not a dictionary")
        }

        var testTargets = plan["testTargets"] as? [[String: Any]] ?? []
        var didUpdateExistingTarget = false

        let resolvedTargetPath = targetPath.map { resolve(path: $0) }
        let computedContainer = resolvedContainerPath(
            targetPath: resolvedTargetPath,
            planPath: resolvedPath
        )

        for index in testTargets.indices {
            let entry = testTargets[index]
            guard let target = entry["target"] as? [String: Any],
                  let name = target["name"] as? String else { continue }

            if name == targetName {
                testTargets[index] = updateEntry(
                    entry,
                    targetName: targetName,
                    containerPath: computedContainer,
                    identifier: identifier,
                    entryAttributes: entryAttributes,
                    shouldForceEnable: entry["enabled"] != nil
                )
                didUpdateExistingTarget = true
                break
            }
        }

        if !didUpdateExistingTarget {
            var newTarget: [String: Any] = ["name": targetName]
            if let identifier = identifier {
                newTarget["identifier"] = identifier
            }
            if let containerPath = computedContainer {
                newTarget["containerPath"] = containerPath
            }

            var newEntry: [String: Any] = ["target": newTarget]
            for (key, value) in entryAttributes {
                newEntry[key] = value
            }
            testTargets.append(newEntry)
        }

        plan["testTargets"] = testTargets

        let updatedData = try JSONSerialization.data(withJSONObject: plan, options: [.prettyPrinted, .sortedKeys])
        try updatedData.write(to: url, options: .atomic)
    }

    private func resolve(path: String) -> String {
        if path.hasPrefix("/") {
            return path
        } else if path.hasPrefix("~") {
            return (path as NSString).expandingTildeInPath
        }
        let cwd = fileManager.currentDirectoryPath
        return (cwd as NSString).appendingPathComponent(path)
    }

    private func resolvedContainerPath(targetPath: String?, planPath: String) -> String? {
        guard let targetPath = targetPath else { return nil }

        let planDir = (planPath as NSString).deletingLastPathComponent
        let planDirPath = Path(planDir)
        let target = Path(targetPath)
        let relative = relativePath(from: planDirPath.normalize(), to: target.normalize())

        let formatted: String
        if relative == "." {
            formatted = target.lastComponent
        } else {
            formatted = relative
        }

        return "container:\(formatted)"
    }

    private func updateEntry(
        _ entry: [String: Any],
        targetName: String,
        containerPath: String?,
        identifier: String?,
        entryAttributes: [String: Any],
        shouldForceEnable: Bool
    ) -> [String: Any] {
        var updatedEntry = entry
        var target = (entry["target"] as? [String: Any]) ?? [:]
        target["name"] = targetName

        if let identifier = identifier {
            target["identifier"] = identifier
        }

        if let containerPath = containerPath {
            target["containerPath"] = containerPath
        }

        updatedEntry["target"] = target

        for (key, value) in entryAttributes {
            updatedEntry[key] = value
        }

        if shouldForceEnable {
            updatedEntry["enabled"] = true
        }

        return updatedEntry
    }
}
