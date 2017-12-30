// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XCProjectManager",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "xcproj-manager",
            targets: ["XCProjectManager"]),
        .library(
            name: "XCProjectManagerCore",
            targets: ["XCProjectManager"]),
        ],
    dependencies:  [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
        .package(url: "https://github.com/yonaskolb/XcodeGen.git", from: "1.0.0"),
        .package(url: "https://github.com/kylef/Commander.git", from: "0.8.0"),
        .package(url: "https://github.com/onevcat/Rainbow.git", from: "3.0.0"),
        ],
    targets: [
        .target(
            name: "XCProjectManager",
            dependencies: [
                "XCProjectManagerCore",
                "Commander",
                "Rainbow"
            ]),
        .target(
            name: "XCProjectManagerCore",
            dependencies: [
                "Utility",
                "XcodeGenKit"]),
        .testTarget(
            name: "XCProjectManagerTests",
            dependencies: ["XCProjectManager"]),
        ]
)
