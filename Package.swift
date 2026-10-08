// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExpenseTracker",
    defaultLocalization: "en",
    platforms: [
        // Provisional deployment target: iOS 17.0
        // Subject to product-owner confirmation per OQ-02 and ADR-008.
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ExpenseTrackerCore",
            targets: ["ExpenseTrackerCore"]
        ),
        .executable(
            name: "ExpenseTrackerApp",
            targets: ["ExpenseTrackerApp"]
        )
    ],
    dependencies: [],
    targets: [
        // Pure domain logic, repository protocols, and calculation engine (no UI/Persistence dependencies)
        .target(
            name: "ExpenseTrackerCore",
            dependencies: [],
            path: "Sources/ExpenseTrackerCore"
        ),
        // Minimal SwiftUI shell
        .target(
            name: "ExpenseTrackerApp",
            dependencies: ["ExpenseTrackerCore"],
            path: "Sources/ExpenseTrackerApp"
        ),
        // Domain and calculation unit tests
        .testTarget(
            name: "ExpenseTrackerTests",
            dependencies: ["ExpenseTrackerCore"],
            path: "Tests/ExpenseTrackerTests"
        )
    ]
)
