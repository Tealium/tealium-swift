# Tealium Swift Library

[![License](https://img.shields.io/badge/license-Proprietary-blue.svg?style=flat
           )](https://github.com/Tealium/tealium-swift/blob/master/LICENSE.txt)
[![Platform](https://img.shields.io/badge/platform-ios%20osx%20tvos%20watchos-lightgrey.svg?style=flat
             )](https://developer.apple.com/resources/)
[![Language](https://img.shields.io/badge/language-swift-orange.svg?style=flat
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

These modules are included with .framework builds of the library for dependency managers (ie Carthage):

- appdata
- async
- collect
- logger
- persistentdata
- volatiledata


### Optionally Manual-include Modules

These modules may be added manually to projects but are NOT included with .framework builds for dependency managers, because they require additional entitlements, services, or are not necessary in the majority of use cases.

- attribution
- [debug](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-Module-Debug/ta-p/16849)


### Default Module Priority List
Module chaining goes from lower-to-higher priority value. The following is the order by which modules will spin up and process track calls based on the default priority setting in their TealiumModuleConfigs:

- 100 Logger (provides debug logging)
- 150 Debug (allows a browser to monitor library configuration and dispatch data)
- 200 Async (moves all library processing to a background thread)
- 400 Attribution (adds IDFA to track data)
- 500 AppData (add app_uuid to track data)
- 600 PersistentData (adds ability to add persistent data to all track data)
- 700 VolatileData (adds ability to add session persistent data to all track data - clears upon app termination)
- 1000 Collect (packages and delivers track call to Tealium or custom endpoint)

## Contact Us

* If you have **code questions** or have experienced **errors** please post an issue in the [issues page](../../issues)
* If you have **general questions** or want to network with other users please visit the [Tealium Learning Community](https://community.tealiumiq.com)
* If you have **account specific questions** please contact your Tealium account manager


## Change Log

- 1.1.2
    - Optional Debug module added
    - Logger module updated to properly continue reporting chain
    - Collect module fix: didFinish pushes updated track data
    - Minor Unit Test updates
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
