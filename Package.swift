// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "TealiumSwift",
  platforms: [ .iOS(.v9), .macOS(.v10_11), .tvOS(.v9), .watchOS(.v3) ],
  products: [
    .library(
      name: "TealiumAppData",
      targets: ["TealiumAppData"]),
    .library(
      name: "TealiumAttribution",
      targets: ["TealiumAttribution"]),
    // not supported - SPM limitation
    // .library(
    //   name: "TealiumAutotracking",
    //   targets: ["TealiumAutotracking"]),
    .library(
      name: "TealiumCore",
      targets: ["TealiumCore"]),
    .library(
      name: "TealiumCollect",
      targets: ["TealiumCollect"]),
    .library(
      name: "TealiumConnectivity",
      targets: ["TealiumConnectivity"]),
    .library(
      name: "TealiumConsentManager",
      targets: ["TealiumConsentManager"]),
//    .library(
//      name: "TealiumCrash",
//      targets: ["TealiumCrash"]),
    .library(
      name: "TealiumDelegate",
      targets: ["TealiumDelegate"]),
    .library(
      name: "TealiumDeviceData",
      targets: ["TealiumDeviceData"]),
    .library(
      name: "TealiumDispatchQueue",
      targets: ["TealiumDispatchQueue"]),
    .library(
      name: "TealiumLifecycle",
      targets: ["TealiumLifecycle"]),
    .library(
      name: "TealiumLocation",
      targets: ["TealiumLocation"]),
    .library(
      name: "TealiumLogger",
      targets: ["TealiumLogger"]),
    .library(
      name: "TealiumPersistentData",
      targets: ["TealiumPersistentData"]),
    .library(
      name: "TealiumRemoteCommands",
      targets: ["TealiumRemoteCommands"]),
    .library(
      name: "TealiumTagManagement",
      targets: ["TealiumTagManagement"]),
    .library(
      name: "TealiumVisitorService",
      targets: ["TealiumVisitorService"]),
    .library(
      name: "TealiumVolatileData",
      targets: ["TealiumVolatileData"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
      name: "TealiumCore",
      path: "tealium/core/"
    ),
    .target(
      name: "TealiumAppData",
      dependencies: ["TealiumCore"],
      path: "tealium/appdata/",
      swiftSettings: [.define("appdata")]
    ),
    // .target(
    //   name: "TealiumAutotracking",
    //   dependencies: ["TealiumCore"],
    //   path: "tealium/autotracking/"
    // ),
    .target(
      name: "TealiumAttribution",
      dependencies: ["TealiumCore"],
      path: "tealium/attribution/",
      swiftSettings: [.define("attribution")]
    ),
    .target(
      name: "TealiumCollect",
      dependencies: ["TealiumCore"],
      path: "tealium/collect/",
      swiftSettings: [.define("collect")]
    ),
    .target(
      name: "TealiumConnectivity",
      dependencies: ["TealiumCore"],
      path: "tealium/connectivity/",
      swiftSettings: [.define("connectivity")]
    ),
    .target(
      name: "TealiumConsentManager",
      dependencies: ["TealiumCore"],
      path: "tealium/consentmanager/",
      swiftSettings: [.define("consentmanager")]
    ),
//    .target(
//      name: "TealiumCrash",
//      dependencies: ["TealiumCore"],
//      path: "tealium/crash/",
//      swiftSettings: [.define("crash")]
//    ),
    .target(
      name: "TealiumDelegate",
      dependencies: ["TealiumCore"],
      path: "tealium/delegate/",
      swiftSettings: [.define("delegate")]
    ),
    .target(
      name: "TealiumDeviceData",
      dependencies: ["TealiumCore"],
      path: "tealium/devicedata/",
      swiftSettings: [.define("devicedata")]
    ),
    .target(
      name: "TealiumDispatchQueue",
      dependencies: ["TealiumCore"],
      path: "tealium/dispatchqueue/",
      swiftSettings: [.define("dispatchqueue")]
    ),
    .target(
      name: "TealiumLifecycle",
      dependencies: ["TealiumCore"],
      path: "tealium/lifecycle/",
      swiftSettings: [.define("lifecycle")]
    ),
    .target(
      name: "TealiumLocation",
      dependencies: ["TealiumCore"],
      path: "tealium/location/",
      swiftSettings: [.define("location")]
    ),
    .target(
      name: "TealiumLogger",
      dependencies: ["TealiumCore"],
      path: "tealium/logger/",
      swiftSettings: [.define("logger")]
    ),
    .target(
      name: "TealiumPersistentData",
      dependencies: ["TealiumCore"],
      path: "tealium/persistentdata/",
      swiftSettings: [.define("persistentdata")]
    ),
  .target(
      name: "TealiumRemoteCommands",
      dependencies: ["TealiumCore"],
      path: "tealium/remotecommands/",
      swiftSettings: [.define("remotecommands")]
    ),
  .target(
      name: "TealiumTagManagement",
      dependencies: ["TealiumCore"],
      path: "tealium/tagmanagement/",
      swiftSettings: [.define("tagmanagement")]
    ),
  .target(
      name: "TealiumVisitorService",
      dependencies: ["TealiumCore"],
      path: "tealium/visitorservice/",
      swiftSettings: [.define("visitorservice")]
    ),    
  .target(
      name: "TealiumVolatileData",
      dependencies: ["TealiumCore"],
      path: "tealium/volatiledata/",
      swiftSettings: [.define("volatiledata")]
    ),
  ]
)
