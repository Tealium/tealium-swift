// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "TealiumSwift",
    platforms: [ .iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v3) ],
    products: [
        .library(
            name: "TealiumAttribution",
            targets: ["TealiumAttribution"]),
        .library(
            name: "TealiumCore",
            targets: ["TealiumCore"]),
        .library(
            name: "TealiumCollect",
            targets: ["TealiumCollect"]),
        .library(
            name: "TealiumLifecycle",
            targets: ["TealiumLifecycle"]),
        .library(
            name: "TealiumLocation",
            targets: ["TealiumLocation"]),
        .library(
            name: "TealiumRemoteCommands",
            targets: ["TealiumRemoteCommands"]),
        .library(
            name: "TealiumTagManagement",
            targets: ["TealiumTagManagement"]),
        .library(
            name: "TealiumVisitorService",
            targets: ["TealiumVisitorService"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TealiumCore",
            path: "tealium/core/"
        ),
        .target(
            name: "TealiumAttribution",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/attribution/",
            swiftSettings: [.define("attribution")]
        ),
        .target(
            name: "TealiumCollect",
            dependencies: ["TealiumCore"],
            path: "tealium/dispatchers/collect/",
            swiftSettings: [.define("collect")]
        ),
        .target(
            name: "TealiumLifecycle",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/lifecycle/",
            swiftSettings: [.define("lifecycle")]
        ),
        .target(
            name: "TealiumLocation",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/location/",
            swiftSettings: [.define("location")]
        ),
        .target(
            name: "TealiumRemoteCommands",
            dependencies: ["TealiumCore"],
            path: "tealium/dispatchers/remotecommands/",
            swiftSettings: [.define("remotecommands")]
        ),
        .target(
            name: "TealiumTagManagement",
            dependencies: ["TealiumCore"],
            path: "tealium/dispatchers/tagmanagement/",
            swiftSettings: [.define("tagmanagement")]
        ),
        .target(
            name: "TealiumVisitorService",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/visitorservice/",
            swiftSettings: [.define("visitorservice")]
        ),
    ]
)
