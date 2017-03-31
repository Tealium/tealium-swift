# Tealium Swift Library

[![License](https://img.shields.io/badge/license-Proprietary-blue.svg?style=flat
           )](https://github.com/Tealium/tealium-swift/blob/master/LICENSE.txt)
[![Platform](https://img.shields.io/badge/platform-iOS%20macOS%20tvOS%20watchOS-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/)
[![Language](https://img.shields.io/badge/language-Swift-orange.svg?style=flat
             )](https://developer.apple.com/swift)

This library leverages the power of Tealium's [AudienceStream™](http://tealium.com/products/audiencestream/) making them natively available to Swift applications. 

Please contact your Account Manager first to verify your agreement(s) for licensed products.


### What is Audience Stream ?

Tealium AudienceStream™ is the leading omnichannel customer segmentation and action engine, combining robust audience management and profile enrichment capabilities with the ability to take immediate, relevant action.

AudienceStream allows you to create a unified view of your customers, correlating data across every customer touchpoint, and then leverage that comprehensive customer profile across your entire digital marketing stack.


## How To Get Started

* Check out the [Getting Started](https://community.tealiumiq.com/t5/Mobile-Libraries/Mobile-170-Getting-Started-with-Swift/ta-p/15489) guide for a step by step walkthough of adding Tealium to an extisting project.  
* The public API can viewed online [here](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-APIs/ta-p/15492), it is also provided in the Documentation directory of this repo as html and docset for Xcode and Dash integration.
* There are many other useful articles on our [community site](https://community.tealiumiq.com).


## Tealium Swift Library Modules

This library employs a drag-and-drop modular architecture when the source files are referenced directly (vs. using a dependency manager).

### What is a module?

Each subfolder within this Tealium folder contains all the files related to one module. Each folder is made up of one or more files, where at least one is a subclass of TealiumModule. 

The core module looks for these module files at init time.  So module folders can be added and removed (or referenced and derefenced) without requiring code updates (unless module specific APIs are used).


### Required Modules

The core module is the only required component of the library.  Howevever, no dispatch calls will be made without a dispatch service module, ie the 'collect' module.


### Optionally Auto-included Modules

These modules are included with current .framework builds of the library for dependency managers (ie Carthage):

- appdata
- async
- collect
- [delegate](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Delegate/ta-p/17300)
- [lifecycle](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Lifecycle/ta-p/16916)
- logger
- persistentdata
- volatiledata


### Optionally Manual-include Modules

These modules may be added manually to projects but are NOT included with .framework builds for dependency managers, because they require additional entitlements, services, or are not necessary in the majority of use cases.

- attribution
- [autotracking](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Autotracking/ta-p/16856)


### Default Module Priority List
Module chaining goes from lower-to-higher priority value. The following is the order by which modules will spin up and process track calls based on the default priority setting in their TealiumModuleConfigs:

- 100 Logger (provides debug logging)
- 175 Lifecycle (tracks launches, wakes, sleeps, and crash instances)
- 200 Async (moves all library processing to a background thread)
- 300 Autotracking (prepares & sends dispatches for most UI & viewDidAppear events)
- 400 Attribution (adds IDFA to track data)
- 500 AppData (add app_uuid to track data)
- 550 Datasource (adds datasource arg to config)
- 600 PersistentData (adds ability to add persistent data to all track data)
- 700 VolatileData (adds ability to add session persistent data to all track data - clears upon app termination)
- 900 Delegate (adds multicast delegates to filter or monitor dispatches)
- 1000 Collect (packages and delivers track call to Tealium or custom endpoint)
- 1100 TagManagement (webview based dispatch service for supporting utag.js)
- 1200 RemoteCommands (permit remote code block execution via webview instances)

## Contact Us

* If you have **code questions** or have experienced **errors** please post an issue in the [issues page](../../issues)
* If you have **general questions** or want to network with other users please visit the [Tealium Learning Community](https://community.tealiumiq.com)
* If you have **account specific questions** please contact your Tealium account manager


## Change Log

- 1.2.0
    - Added Datasource module (build 1), which makes available:
        - tealium_datasource
    - Added RemoteCommands module (build 1).
    - Added TagManagement module (build 1).
    - Added TealiumUtils to core module.
    - Refactor of TealiumDelegateModule (build 2) to use generic mulitcast delegate.
    - Refactored TealiumModuleManager (build 3) removed track pre-processing.
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
