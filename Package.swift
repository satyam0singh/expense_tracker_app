// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ExpenseTracker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "ExpenseTrackerCore",
            targets: ["ExpenseTrackerCore"]
        )
    ],
    dependencies: [],
    targets: [
        // Pure domain logic, repository protocols, and calculation engine
        .target(
            name: "ExpenseTrackerCore",
            dependencies: [],
            path: "Sources/ExpenseTrackerCore"
        ),
        // Domain and calculation unit tests (14 test suites)
        .testTarget(
            name: "ExpenseTrackerTests",
            dependencies: ["ExpenseTrackerCore"],
            path: "Tests/ExpenseTrackerTests"
        )
    ]
)
