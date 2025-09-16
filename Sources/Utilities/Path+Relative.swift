import PathKit

public func relativePath(from base: Path, to target: Path) -> String {
    let baseNormalized = base.normalize()
    let targetNormalized = target.normalize()

    let baseComponents = baseNormalized.components
    let targetComponents = targetNormalized.components

    var commonIndex = 0
    while commonIndex < baseComponents.count &&
          commonIndex < targetComponents.count &&
          baseComponents[commonIndex] == targetComponents[commonIndex] {
        commonIndex += 1
    }

    var components: [String] = []
    let upCount = baseComponents.count - commonIndex
    if upCount > 0 {
        components.append(contentsOf: Array(repeating: "..", count: upCount))
    }

    if commonIndex < targetComponents.count {
        components.append(contentsOf: targetComponents[commonIndex...])
    }

    if components.isEmpty {
        return "."
    }

    return components.joined(separator: Path.separator)
}
