import XCTest
@testable import CatalystCore

final class CatalystCoreTests: XCTestCase {

    func testNonTestProductOptionsFiltersOutTestTargets() {
        let packagePath = "/tmp/Project/Modules/Analytics"
        let package = DiscoveredPackage(
            name: "Analytics",
            path: packagePath,
            products: [
                LocalPackageProduct(name: "AnalyticsKit", targets: ["Analytics"]),
                LocalPackageProduct(name: "AnalyticsKitPreview", targets: ["Analytics", "AnalyticsPreview"]),
                LocalPackageProduct(name: "AnalyticsTests", targets: ["AnalyticsTests"])
            ],
            targets: [
                LocalPackageTarget(name: "Analytics", type: "regular"),
                LocalPackageTarget(name: "AnalyticsPreview", type: "regular"),
                LocalPackageTarget(name: "AnalyticsTests", type: "test")
            ]
        )

        let options = package.nonTestProductOptions(relativeTo: "/tmp/Project")

        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options.map { $0.productName }.sorted(), ["AnalyticsKit", "AnalyticsKitPreview"])
        XCTAssertEqual(Set(options.first?.availableProducts ?? []), ["AnalyticsKit", "AnalyticsKitPreview"])
        XCTAssertEqual(options.first?.packageName, "Analytics")
        XCTAssertEqual(options.first?.packagePath, packagePath)
        XCTAssertEqual(options.first?.displayPath, "Modules/Analytics")
    }

    func testNonTestProductOptionsReturnsEmptyWhenOnlyTests() {
        let package = DiscoveredPackage(
            name: "TestsOnly",
            path: "/tmp/Project/Modules/TestsOnly",
            products: [
                LocalPackageProduct(name: "TestsOnlyTests", targets: ["TestsOnlyTests"])
            ],
            targets: [
                LocalPackageTarget(name: "TestsOnlyTests", type: "test")
            ]
        )

        let options = package.nonTestProductOptions(relativeTo: "/tmp/Project")
        XCTAssertTrue(options.isEmpty)
    }
}
