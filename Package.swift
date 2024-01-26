// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "TealiumSwift",
    platforms: [ .iOS(.v11), .macOS(.v10_13), .tvOS(.v11), .watchOS(.v4) ],
    products: [
        .library(
            name: "TealiumAttribution",
            targets: ["TealiumAttribution"]),
        .library(
            name: "TealiumAutotracking",
            targets: ["TealiumAutotracking", "TealiumAutotrackingObjC"]),
        .library(
            name: "TealiumCore",
            targets: ["TealiumCore", "TealiumCoreObjC"]),
        .library(
            name: "TealiumCollect",
            targets: ["TealiumCollect"]),
        .library(
            name: "TealiumInAppPurchase",
            targets: ["TealiumInAppPurchase"]),
        .library(
            name: "TealiumLifecycle",
            targets: ["TealiumLifecycle"]),
        .library(
            name: "TealiumLocation",
            targets: ["TealiumLocation"]),
        .library(
            name: "TealiumMedia",
            targets: ["TealiumMedia"]),
        .library(
            name: "TealiumRemoteCommands",
            targets: ["TealiumRemoteCommands"]),
        .library(
            name: "TealiumTagManagement",
            targets: ["TealiumTagManagement"]),
        .library(
            name: "TealiumVisitorService",
            targets: ["TealiumVisitorService"])
                
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "TealiumCore",
            path: "tealium/core/",
            exclude: ["objc"],
            resources: [
                .process("devicedata/device-names.json")
            ]
        ),
        .target(
            name: "TealiumCoreObjC",
            dependencies: ["TealiumCore"],
            path: "tealium/core/objc/"
        ),
        .target(
            name: "TealiumAttribution",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/attribution/",
            swiftSettings: [.define("attribution")]
        ),
        .target(
            name: "TealiumAutotracking",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/autotracking",
            exclude: ["objc"],
            swiftSettings: [.define("autotracking")]
        ),
        .target(
            name: "TealiumAutotrackingObjC",
            dependencies: ["TealiumAutotracking"],
            path: "tealium/collectors/autotracking/objc/"
        ),
        .target(
            name: "TealiumCollect",
            dependencies: ["TealiumCore"],
            path: "tealium/dispatchers/collect/",
            swiftSettings: [.define("collect")]
        ),
        .target(
            name: "TealiumInAppPurchase",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/inapppurchase/",
            swiftSettings: [.define("inapppurchase")]
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
            name: "TealiumMedia",
            dependencies: ["TealiumCore"],
            path: "tealium/collectors/media/",
            swiftSettings: [.define("media")]
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
