# Tealium Swift Library 1.0.0

This library leverages the power of Tealium's [AudienceStream™](http://tealium.com/products/audiencestream/) making them natively available to Swift applications. Please contact your Account Manager first to verify your agreement(s) for licensed products.


## What does Tealium do?

Tealium provides the platform for crafting a modern, scalable and flexible marketing technology stack so you can easily connect and integrate all of your best-in-class solutions.


### What is Audience Stream ?

Tealium AudienceStream is the leading omnichannel customer segmentation and action engine, combining robust audience management and profile enrichment capabilities with the ability to take immediate, relevant action.

AudienceStream allows you to create a unified view of your customers, correlating data across every customer touchpoint, and then leverage that comprehensive customer profile across your entire digital marketing stack.


## How To Get Started

* Check out the [Getting Started](https://community.tealiumiq.com/t5/Mobile-Libraries/Mobile-170-Getting-Started-with-Swift/ta-p/15489) guide for a step by step walkthough of adding Tealium to an extisting project.  
* The public API can viewed online [here](https://community.tealiumiq.com/t5/Mobile-Libraries/Tealium-Swift-APIs/ta-p/15492), it is also provided in the Documentation directory of this repo as html and docset for Xcode and Dash integration.
* There are many other useful articles on our [community site](https://community.tealiumiq.com).


## Contact Us

* If you have **code questions** or have experienced **errors** please post an issue in the [issues page](../../issues)
* If you have **general questions** or want to network with other users please visit the [Tealium Learning Community](https://community.tealiumiq.com)
* If you have **account specific questions** please contact your Tealium account manager


## Change Log

- 1.0.0 Initial Release
    - Tealium universal data sources added for all dispatches:
        - event_name (transitionary - will be deprecated)
        - tealium_account
        - tealium_environment
        - tealium_event
        - tealium_library_name
        - tealium_library_version
        - tealium_profile
        - tealium_random (different 16 digit long number for each track event)
        - tealium_session_id
        - tealium_timestamp_epoch (previously timestamp_unix)
        - tealium_visitor_id (previously tealium_vid)


## License

Use of this software is subject to the terms and conditions of the license agreement contained in the file titled "LICENSE.txt".  Please read the license before downloading or using any of the files contained in this repository. By downloading or using any of these files, you are agreeing to be bound by and comply with the license agreement.


---
Copyright (C) 2012-2016, Tealium Inc.
