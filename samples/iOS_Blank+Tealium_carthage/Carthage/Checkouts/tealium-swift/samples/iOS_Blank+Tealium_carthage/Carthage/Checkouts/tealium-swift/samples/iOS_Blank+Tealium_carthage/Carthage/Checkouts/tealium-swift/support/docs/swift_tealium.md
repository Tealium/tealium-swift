# Swift Class: Tealium
This guide specifies the syntax of the functions available in the Tealium class of the Tealium for Swift library.

## Tealium
Constructor for a Tealium object.
```swift
init(config: TealiumConfig)

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

### Enable
Used after a [*disable()*](#disable) used, to re-enable a Tealium instance.

```swift
func enable()

```
```swift
    // Sample
    tealium.enable()
```

### Disable
To disable a Tealium instance from responding to or processing track events. Internal modules may deallocate resources to free up memory.
```swift
func disable()

```
```swift
    // Sample
    tealium.disable()
```

### Update
Used to reconfigure an active Tealium instance.
```swift
func update(config: TealiumConfig)
```
**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
config | TealiumConfig object to use. | - 
```swift
    // Sample
    let newConfig = TealiumConfig(account:"anotherAccount",
                                  profile:"anotherProfile",
                                  environment:"anotherEnvironment",
                                  datasource:"anotherDatasource")
    tealium.update(config: newConfig)

```

### Track
Tracks an event with associated data and, optionally, triggers a callback function.
```swift
func track(title: String)

func track(title: String,
           data: [String:Any]?,
           completion: ((_ successful:Bool, _ info:[String:Any]?, _ error: Error?) -> Void)?)
```
**Parameters**  | **Description** | **Example Value**
------------- | ------------- | ------------------
title | TealiumConfig object to use. | - 
data | |
completion | |
```swift
    // Simple sample
    tealium.track(title:"mySimpleEvent")

    // Sample using custom args
    let customTitle = "myEvent"
    let customData = ["customKey":"customValue"]
    let customCompletion = { (success, info, error) in
                        
                // Optional track processing
        })

    tealium.track(title: customTitle,
                  data: customData,
                  completion: customCompletion)

```
