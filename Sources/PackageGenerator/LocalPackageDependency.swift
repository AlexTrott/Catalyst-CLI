import Foundation

public struct LocalPackageDependency {
    public let packageName: String
    public let packagePath: String
    public var productNames: [String]
    public let availableProducts: [String]

    public init(packageName: String, packagePath: String, productNames: [String], availableProducts: [String]) {
        self.packageName = packageName
        self.packagePath = packagePath
        self.productNames = productNames
        self.availableProducts = availableProducts
    }
}
