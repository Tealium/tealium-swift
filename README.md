## Tealium Swift Library

[![License](https://img.shields.io/badge/license-Proprietary-blue.svg?style=flat
           )](https://github.com/Tealium/tealium-swift/blob/master/LICENSE.txt)
[![Platform](https://img.shields.io/badge/platform-iOS%20macOS%20tvOS%20watchOS-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/)
[![Language](https://img.shields.io/badge/language-Swift-orange.svg?style=flat
             )](https://developer.apple.com/swift)

This guide shows how to add, configure, and track events for a Swift application utilizing the Tealium Swift Integration library.

Before you begin, here's a video introduction to the platform:

[![Swift Implementation Video](http://res.cloudinary.com/dfpz40r7j/image/upload/v1498576899/SwiftVideo_zmp8un.png)](https://youtu.be/JMrIbuY1mA0)

# Features
The following [features](https://community.tealiumiq.com/t5/Mobile-Libraries/Installation-Libraries-Feature-List/ta-p/18159) are available with the Swift library:
* App Data
* Collect Dispatch Service
* TagManagement Dispatch Service
* Lifecycle autotracking
* Limited UI autotracking
* Custom Persistence
* Tealium Data


NOTE: 
Recently removed variables / event-attribute keys. Use the newer *tealium_event* instead:
- event_name


# INSTALLATION

## Requirements
Before proceeding, ensure you have satisfied the following requirements:
* Tealium account enabled for [Cloud Delivery](https://community.tealiumiq.com/t5/Universal-Data-Hub/Cloud-Delivery-Connectors/ta-p/13889)
* Swift 3.0+
* Xcode 8.0+

Platforms supported:
* iOS 9.0+
* macOS 10.11+
* tvOS 9.2+
* watchOS 3.0+
* server-side deployments

## Dependency manager

### Modules Included

### Carthage
Carthage is a simple way to manage dependencies in Swift. Install [Carthage from Github](https://github.com/Carthage/Carthage) or via [Homebrew](https://brew.sh/) with the following terminal command:

```
$ brew install carthage
```
Then add the following entry to the [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile) in your project:
```
github "tealium/tealium-swift" 
```
Then update from the terminal with:
```
$ carthage update
```
This will produce frameworks for the following platforms:
* iOS
* macOS
* tvOS
* watchOS 

To build only for a particular platform, use Carthage's *--platform* argument:
```
$ carthage update --platform ios
```

See the [Modules List](#modules-list) section to see which modules are included with the current library via Carthage.


## Manual Import
Import the Tealium folder into your project.

Watch this video for an overview of the installation and setup of the code:

[![Swift Implementation Video](http://res.cloudinary.com/dfpz40r7j/image/upload/v1498577063/SwiftImplementation_fhnnyx.png)](https://youtu.be/yPecyFKQLuA)

### Disabling Modules
* For Manual Import ONLY: Remove the target module files from the build target. This will prevent the modules from being compiled into the release product (most code optimal)
* Use the TealiumModulesList property that may be assigned to a [TealiumConfig](/support/docs/swift_tealiumconfig.md) object to explicitly white or black list modules for enablement. This is the recommmended way to enable or disable modules. 
```swift
// Sample
// This will load all modules except the TagManagement module.
let list = TealiumModulesList(isWhitelist: false, 
moduleNames: ["TagManagement"])
let config = // See TealiumConfig example below
config.setModulesList(list)
```

## Initialization
Once the Tealium for Swift is installed you are ready to start coding. A Tealium instance must be configured with an instance of a TealiumConfig with the following parameters:
* account - the name of your iQ account
* profile - the name of the mobile profile within your iQ account
* environment - typically "dev", "qa", or "prod"
* datasource - (optional) data source key from UDH
``` swift
    var tealConfig = TealiumConfig(account: "your_account",
                                             profile: "your_profile",
                                             environment: "prod",
                                             datasource: "abc123")

    let tealium = Tealium(config: tealConfig)
```

## Tracking
All tracking is done with the track() method, which takes the following parameters:
* title - the name of the screen view or event to be tracked
* data - (optional) [String:Any] dictionary of additional/custom tracking data
* completion - (optional) a closure to be run upon completion of the tracking call

NOTE: A dispatch service module ([**collect**](#modules-list) or [**tagmanagement**](#modules-list)) must be enabled to deliver track calls.
```swift

    // With optional parameters - any optional param may take *nil*
    let customData = [ "someKey" : "someValue" ]
    tealium.track(title:"someEventWithOptionalArgs", 
                  data: customData,
                  completion: { (success, info, error) in

        // Any follow-up code here

    })
```


## Modules

This library is built with the capability to easily add or remove feature sets during compile time (manual imports) or at initialization time. Sets of features are separated into subclasses of the TealiumModule class, and are currently contained in individually titled subfolders.

### Required Components

The core folder contains all the required classes of the library. Additionally, one Dispatch Service module, Collect or [TagManagement](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-TagManagement/ta-p/16857) is required to process and deliver track calls to Tealium.

### Modules List

The following table lists the currently available modules and related details.  
* *Module Name:* Name id of Module.
* *Feature:* What enhancement the module provides.
* *Included in Frameworks:* Is the module included in framework builds via dependency managers (ie [Carthage](https://github.com/Carthage/Carthage)) for a given platform.
* *Notes:* Any additional information.
NOTE: The order modules are enabled and process events are listed in order below (Logger first to Remote Comands last).

**Module Name**  | **Feature** | **Included in Frameworks** | **Notes**
--------- | ----------- | ------------ | ----------
Logger | Debug logging | iOS, macOs, tvOS, watchOs | - 
[Lifecycle](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Lifecycle/ta-p/16916) | Tracks launches, wakes, sleeps, and crash instances. Auto or manually. | iOS, macOS, tvOS, watchOS | -
Async | Moves all library processing to a background thread.  | iOS, macOS, tvOS, watchOS | -
[Autotracking](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Autotracking/ta-p/16856) | Prepares & sends dispatches for most UI, including viewDidAppear, events. | iOS, tvOS | -
FileStorage | Adds general persistence capability for any module. Replaces the PersistenData module. | iOS, macOS, watchOS
Attribution | Adds IDFA to track data.  | iOS, tvOS | Requires additional entitlements from Apple
AppData | Adds app_uuid to track data. | iOS, macOS, tvOS, watchOS | -
Datasource | Adds an additional config init option for datasource ids. | iOS, macOS, tvOS, watchOS | -
PersistentData | Adds ability to add persistent data to all track data. | iOS, macOS, tvOS, watchOS | -
VolatileData | Adds ability to add session persistent data to all track data - clears upon app termination/close. | iOS, macOS, tvOS, watchOS | Will supercede any Persistent value with the same key(s)
[Delegate](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Delegate/ta-p/17300) | Adds multicast delegates to monitor or suppress track dispatches. | iOS, macOS, tvOS, watchOS | -
Connectivity | Adds ability to flag track messages for delayed delivery due to connectivity loss.  | iOS, macOS, tvOS | Requires SystemConfiguration
Collect | Packages and delivers track call to Tealium Collect or other custom URL endpoint.  | iOS, macOS, tvOS, watchOS | -
[TagManagement](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-TagManagement/ta-p/16857) | UIWebview based dispatch service that permits library to run TIQ/utag.js. | iOS | Requires UIWebView
[RemoteCommands](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Remote-Commands/ta-p/17523) | Permits configurable remote code block execution via URLScheme, UIWebView, or TagManagement. | iOS, macOS, tvOS, watchOS | -


## Additional Resources
* This readme is mirrored in a [TLC Getting Started Guide](https://community.tealiumiq.com/t5/Tealium-for-Swift/Adding-Tealium-to-Your-Swift-App/ta-p/15489).  

## Contact Us
* If you have **code questions** or have experienced **errors** please post an issue in the [issues page](../../issues)
* If you have **general questions** or want to network with other users please visit the [Tealium Learning Community](https://community.tealiumiq.com)
* If you have **account specific questions** please contact your Tealium account manager


# Change Log

- 1.3.1
    - Builder (used by Carthage) updated to include previously missing TealiumMulticastDelegate & TealiumLifecyclePersistentData classes in build target.
    - AppData Module (build 3) fix for app_version & added new key-value:
        - app_build (application build number)
    - Async Module (build 4) added os x version check for dispatch queue assignment.
    - Delegate Module (build 3) removed unused code.

- 1.3.0
    - All modules updated to make use of simplified modules base class + new internal TealiumRequest structs that replaces the TealiumProcess & TealiumTrack structs
    - Most module related files have been aggregated into single module class files for faster reference & future removal of the module subfolders.
    - Added Connectivity module (build 1). Queues track calls if connectivity not available. Resends in FIFO order when connectivity again available when another track occurrs. Adds following auto variable:
        - was_queued (true if call was queued)
    - Added DataStorage module (build 1) that replaces the persistent data module's internal functions. Primarily for tvOS.
    - Added FileStorage module (build 1) that replaces the persistent data modules internal functions. For all other target platforms.
    - Added TealiumModulesList that can be assigned to TealiumConfig to explicit enable or disable modules. Struct has following properties:
        - isWhitelist: Bool
        - modulesName: Set<String>
    - Added additional core internal classes:  
        - TealiumModules
        - TealiumMulticastDelegate
        - TealiumRequestArray
    - Updated Core Tealium (build 3) with track type call marked deprecated in favor of simpler track method. Updated to use internal TealiumTrackRequest over TealiumTrack. Added new APIs to update library instance with newer configuration:
        - update(config: TealiumConfig)
    - Updated Core TealiumConfig (build 2) convenience constructor added. 1.0.1 Deprecated legacy methods removed.
    - Updated Core Constants (build 2) replaced internal track & process struct with new request protocol and request types.
    - Updated Core TealiumModule base class (build 3) to support new request structs.Made equatable & hashable. ModuleConfig made a class level func for better init performance. Simplified process completion methods. Removed an internal protocol requirement.
    - Updated Core TealiumModuleManager (build 3) to support updated request structs.
    - Updated Core TealiumUtils (build 2) updated multicast delegate to take explicit delegate type at init time.
    - Updated AppData module (build 2) to support new persistence related requests & to provide required new data in event no persistent modules enabled. Remaining app data key-values added:
        - app_name
        - app_rdns
        - app_version
    - Updated Attribution module (build 3) to use new internal request structs.
    - Updated Autotracking module (build 3) to use new internal request structs.
    - Updated Async module (build 3) removed Tealium extensions for completion callbacks.
    - Updated Collect module (build 3) to use new internal request structs. Files aggregated into a single TealiumCollectModule.swift file.
    - Updated DataSource module (build 2) to use new internal request structs.
    - Updated Delegate module (build 2) to store multicast delegate in config instead of within module. Prepares it for further delegate options moving forward.
    - Updated Lifecycle module (build 2) to use new internal request structs. Most files aggregated into TealiumLifecycleModule.swift file. Guard statements added in place of explicit optional unwraps.
    - Updated Logger module (build 2) Extension to set log levels via TealiumConfig re-enabled. Logs success or failures of save, load, & track requests + use new internal request structs. LogLevel renamed TealiumLogLevel to avoid namespace collisions for manually imported implementations.
    - Updated PersistentData module (build 2) to use new internal structs.
    - Updated RemoteCommands module (build 2) to use new internal structs. Files aggregated into a single TealiumRemoteCommandsModule.swift file.
    - Updated TagManagement module (build 2) to use new internal structs. Files aggregated into a single TealiumTagManagementModule.swift file.
    - Updated VolatileData module (build 2) to use new internal structs.

- 1.2.0
    - Added Datasource module (build 1), which makes available:
        - tealium_datasource
    - Added RemoteCommands module (build 1).
    - Added TagManagement module (build 1).
    - Added TealiumUtils to core module.
    - Refactor of TealiumDelegateModule (build 2) to use generic mulitcast delegate.
    - Refactored TealiumModuleManager (build 3) removed track pre-processing and added a defer block protection within the getClassList() method.
    - Updated Tealium.swift (build 2) added class function to do track pre-processing.
    - Updated Lifecycle module (build 2) to properly return tealium_event & tealium_event_type with auto triggered lifecycle calls.

- 1.1.3
    - Added Lifecycle module (build 1). Adds the following auto variables:
        - lifecycle_diddetectcrash
        - lifecycle_dayofweek_local
        - lifecycle_dayssincelaunch
        - lifecycle_dayssinceupdate
        - lifecycle_dayssincelastwake
        - lifecycle_firstlaunchdate
        - lifecycle_firstlaunchdate_MMDDYYYY
        - lifecycle_hourofday_local
        - lifecycle_isfirstlaunch
        - lifecycle_isfirstlaunchupdate
        - lifecycle_isfirstwakemonth
        - lifecycle_isfirstwaketoday
        - lifecycle_lastlaunchdate
        - lifecycle_lastsleepdate
        - lifecycle_lastwakedate
        - lifecycle_lastupdatedate
        - lifecycle_launchcount
        - lifecycle_priorsecondsawake
        - lifecycle_secondsawake
        - lifecycle_sleepcount
        - lifecycle_type
        - lifecycle_totalcrashcount
        - lifecycle_totallaunchcount
        - lifecycle_totalwakecount
        - lifecycle_totalsleepcount
        - lifecycle_totalsecondsawake
        - lifecycle_updatelaunchdate
        - lifecycle_wakecount
    - Added Delegate module (build 1)
    - Fix Collect module (build 3) to correctly report problematic sends
    - Updated Attribution module (build 2) with minor refactor
    - Updated Autotracking module (build 2) by deprecating autotrackingDelegate protocols - use the Delegate module instead
    - Updated Logger module (build 3) with cleaner error output.
    - Updated Module base (build 2) with a isEnabled property
    - Updated ModuleManager (build 2) with an internal allModulesEnabled() function

- 1.1.2
    - Optional Autotracking module (build 1) added. Additional variables with module:
           - autotracked : true/false
    - Async module updated (build 2). Adds following convenience method:
        - init(config: TealiumConfig, completion:((_)->Void))
    - Logger module updated (build 2). Reporting chain fix.
    - Collect module updated (build 2): didFinish pushes updated track data fix.
- 1.1.1
    - Async module added
    - [String:AnyObject] dictionary usage replaced with more convenient [String:Any]
    - iOS Sample app updated
    - macOS Sample app updated
    - tvOS Sample app updated
    - watchOS Sample app updated
- 1.1.0
    - New track with type API added
    - New auto Tealium variable added:
        - app_uuid
        - tealium_event_type
    - Drag & Drop Module Architecture implemented
    - iOS Sample app added
    - macOS Sample app added
    - tvOS Sample app added
    - watchOS Sample app added
    - Additional Tests added
- 1.0.1 Swift 3 Syntax Update 
    - Support for Swift 3.0
- 1.0.0 Initial Release
    - 2.x Swift support. In XCode 8, can safely update to syntax 2.3 (no code changes will be suggested + will be usable in a 3.x app)
    - Tealium universal data sources added for all dispatches:
        - event_name (transitionary - will be deprecated)
        - tealium_account
        - tealium_environment
        - tealium_event
        - tealium_library_name
        - tealium_library_version
        - tealium_profile
        - tealium_random
        - tealium_session_id
        - tealium_timestamp_epoch
        - tealium_visitor_id
        - tealium_vid (legacy support - will be deprecated)


## License

Use of this software is subject to the terms and conditions of the license agreement contained in the file titled "LICENSE.txt".  Please read the license before downloading or using any of the files contained in this repository. By downloading or using any of these files, you are agreeing to be bound by and comply with the license agreement.

 
---
Copyright (C) 2012-2017, Tealium Inc.
