# Swift Class: TealiumConfig
This guide specifies the syntax of the functions available in the TealiumConfig class and associated argument objects of the Tealium for Swift library.

## TealiumConfig
Configuration object that can be passed into the Tealium class during init or an update request.
```swift
public convenience init(account: String,
                        profile: String,
                        enviroment: String,
                        datasource: String)
```
**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
account | Tealium Account | tealium 
profile | Tealium profile | mobile_division
environment | Tealium environment. Currently optional.| prod
datasource | Tealium UDH Datasource Id | abc123
```swift
    // Sample with datasource id.
    let config = TealiumConfig( account: "account", 
                                profile: "profile", 
                                environment: "environment",
                                datasource: "datasource")
```

## TealiumModulesList()
Struct for defining an optional white OR black list of modules to enable.
```swift
struct TealiumModulesList {
    let isWhitelist: Bool
    let moduleNames: Set<String>
}
```

**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
isWhitelist | If this list of modules should ONLY include those in the moduleNames property. List is a blacklist if false | true 
moduleNames | Set of module names. No white spaces. Case insensitive | ["Collect"]
```swift
// Sample
    // Only enable the Collect module - no others
    let whitelist = TealiumModulesList(isWhitelist: true, 
                                  moduleNames: ["Collect"])
    let config = // See TealiumConfig example above
    config.setModulesList(whitelist)

    // Only disable the Logger and TagManagement modules - initialize all others.
    let blacklist = TealiumModulesList(isWhitelist: false, 
    moduleNames: ["Logger, TagManagement"])
    let anotherConfig = // See TealiumConfig example above
    anotherConfig.setModulesList(list)

```
