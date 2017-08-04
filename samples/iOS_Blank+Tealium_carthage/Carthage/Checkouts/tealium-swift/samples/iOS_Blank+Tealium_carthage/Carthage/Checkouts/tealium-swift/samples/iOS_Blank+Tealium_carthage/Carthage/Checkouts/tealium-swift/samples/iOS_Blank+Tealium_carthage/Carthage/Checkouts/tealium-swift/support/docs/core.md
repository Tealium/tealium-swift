## Tealium Core Classes & Functions


# CONSTANTS
## TealiumModulesList
White or black list of module names to enable.

```swift
struct TealiumModulesList {
    let isWhitelist: Bool
    let moduleNames: Set<String>
}
```

**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
isWhitelist | If this list of modules should ONLY include those in the moduleNames property. List is a blacklist if false | true 
moduleNames | Set of lowercased modulenames. | ["collect"]

```swift
// Sample
    let list = TealiumModulesList(isWhiltelist: true, 
                                  moduleNames: ["collect"])
    let config = // See TealiumConfig example below
    config.setModulesList(list)
```

## TealiumModuleResponse




## TealiumConfig()
Configuration object that can be passed into the Tealium class during init or an update request.

```swift
public convenience init(account: String,
                        profile: String,
                        enviroment: String,
                        optionalData: [String:Any]?)
```

**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
account | Tealium Account | tealium 
profile | Tealium profile | mobile_division
environment | Tealium environment. Currently optional.| prod
optionalData | Optional dictionary [String:Any] for module use. Nil acceptable. Value only needed if implementing a custom module | -

```swift
    // Simple Sample
    let config = TealiumConfig( account: "account", 
                                profile: "profile", 
                                environment: "environment")
```

## Tealium()
Primary interface class for the library.

```swift
public convenience init(config: TealiumConfig)

```

**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
config | TealiumConfig object to use. | - 

```swift
// Simple Sample
    let config = // See TealiumConfig above
    let tealium = Tealium(config: config)
```

```swift
public enable()

```

**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
config | TealiumConfig object to use. | - 

```swift
// Simple Sample
let config = // See TealiumConfig above
let tealium = Tealium(config: config)
```


## License

Use of this software is subject to the terms and conditions of the license agreement contained in the file titled "LICENSE.txt".  Please read the license before downloading or using any of the files contained in this repository. By downloading or using any of these files, you are agreeing to be bound by and comply with the license agreement.

 
---
Copyright (C) 2012-2017, Tealium Inc.
