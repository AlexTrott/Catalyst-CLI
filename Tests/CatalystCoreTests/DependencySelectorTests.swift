import XCTest
@testable import CatalystCore
import ConfigurationManager

final class DependencySelectorTests: XCTestCase {

    func testMakeOrderedOptionsPrioritizesInterfaceProducts() {
        let analyticsPackage = DiscoveredPackage(
            name: "Analytics",
            path: "/tmp/Modules/Analytics",
            products: [
                LocalPackageProduct(name: "AnalyticsInterface", targets: ["Analytics"]),
                LocalPackageProduct(name: "Analytics", targets: ["Analytics"])
            ],
            targets: [
                LocalPackageTarget(name: "Analytics", type: "regular")
            ]
        )

        let selector = DependencySelector(configuration: CatalystConfiguration())
        let options = selector.makeOrderedOptions(from: [analyticsPackage])

        XCTAssertEqual(options.map { $0.productName }, ["AnalyticsInterface", "Analytics"])
    }

    func testMakeOrderedOptionsRespectsDependencyExclusions() {
        let paymentsPackage = DiscoveredPackage(
            name: "Payments",
            path: "/tmp/Modules/Payments",
            products: [
                LocalPackageProduct(name: "PaymentsInterface", targets: ["Payments"])
            ],
            targets: [
                LocalPackageTarget(name: "Payments", type: "regular")
            ]
        )

        let legacyPackage = DiscoveredPackage(
            name: "LegacyAnalytics",
            path: "/tmp/Modules/LegacyAnalytics",
            products: [
                LocalPackageProduct(name: "LegacyAnalytics", targets: ["LegacyAnalytics"])
            ],
            targets: [
                LocalPackageTarget(name: "LegacyAnalytics", type: "regular")
            ]
        )

        let configuration = CatalystConfiguration(dependencyExclusions: ["LegacyAnalytics"])
        let selector = DependencySelector(configuration: configuration)
        let options = selector.makeOrderedOptions(from: [paymentsPackage, legacyPackage])

        XCTAssertEqual(options.map { $0.packageName }, ["Payments"])
    }
}
