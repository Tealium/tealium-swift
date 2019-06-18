//
//  Tealium.swift
//  tealium-swift
//
//  Created by Jason Koo, Merritt Tidwell, Chad Hartman, Karen Tamayo, Chris Anderberg  on 8/31/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//
//

import Foundation

public typealias TealiumEnableCompletion = ((_ responses: [TealiumModuleResponse?]) -> Void)

///  Public interface for the Tealium library.
public class Tealium {

    public var config: TealiumConfig
    /// Mediator for all Tealium modules.
    public let modulesManager: TealiumModulesManager
    public var enableCompletion: TealiumEnableCompletion?

    // MARK: PUBLIC
    /// Initializer.
    ///
    /// - Parameters:
    /// - tealiumConfig: Object created with Tealium account, profile, environment, optional loglevel)
    public init(config: TealiumConfig,
                enableCompletion: TealiumEnableCompletion?) {
        self.config = config
        self.enableCompletion = enableCompletion
        modulesManager = TealiumModulesManager()
        self.enable()
        TealiumInstanceManager.shared.addInstance(self, config: config)
    }

    public convenience init(config: TealiumConfig) {
        self.init(config: config, enableCompletion: nil)
    }

    /// Enablement call used after disable() to re-enable library activites. Unnecessary to call after
    /// initial init. Does NOT override individual module enabled flags.
    public func enable() {
        self.modulesManager.enable(config: self.config, enableCompletion: enableCompletion)
    }

    /// Update an actively running library with new configuration object.
    ///
    /// - Parameter config: TealiumConfiguration to update library with.
    public func update(config: TealiumConfig) {
        self.config = config
        self.modulesManager.update(config: self.config)
    }

    /// Suspends all library activity, may release internal objects.
    public func disable() {
        self.modulesManager.disable()
    }

    /// Convenience track method with only a title argument.
    ///
    /// - Parameter title: String name of the event. This converts to 'tealium_event'
    public func track(title: String) {
        self.track(title: title,
                   data: nil,
                   completion: nil)
    }

    /// Primary track method - equivalent to utag.track('link',{}) call.
    ///
    /// - Parameters:
    /// - event Title: Required title of event.
    /// - data: Optional dictionary for additional data sources to pass with call.
    /// - completion: Optional callback that is returned IF a dispatch service has delivered a call. Note this callback will be returned for every dispatch service module enabled.
    /// - successful: Wether completion succeeded or encountered a failure.
    /// - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
    /// - error: Error encountered, if any.
    public func track(title: String,
                      data: [String: Any]?,
                      completion: ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)?) {
        let trackData = Tealium.trackDataFor(title: title,
                                             optionalData: data)
        let track = TealiumTrackRequest(data: trackData,
                                        completion: completion)

        self.modulesManager.track(track)
    }

    /// Track method for specifying view appearances - equivalent to a utag.track('view',{}) call.
    ///
    /// - Parameters:
    /// - event Title: Required title of event.
    /// - data: Optional dictionary for additional data sources to pass with call.
    /// - completion: Optional callback that is returned IF a dispatch service has delivered a call. Note this callback will be returned for every dispatch service module enabled.
    /// - successful: Wether completion succeeded or encountered a failure.
    /// - info: Optional dictionary of data from call (ie encoded URL string, response headers, etc.).
    /// - error: Error encountered, if any.
    public func trackView(title: String,
                          data: [String: Any]?,
                          completion: ((_ successful: Bool, _ info: [String: Any]?, _ error: Error?) -> Void)?) {
        var newData = [String: Any]()

        if let data = data {
            newData += data
        }

        newData[TealiumKey.callType] = TealiumTrackType.view.description()
        newData[TealiumKey.screenTitle] = title // added for backwards-compatibility

        self.track(title: title,
                   data: newData,
                   completion: completion)
    }

    /// Packages a track title and any custom client data for Tealium track requests.
    ///     Calling this method directly generally not needed but could be used to
    ///     confirm the client added data payload that will be added to the Tealium
    ///     data layer prior to dispatch.
    ///
    /// - Parameters:
    /// - type: TealiumTrackType to use.
    /// - title: String description for track name.
    /// - optionalData: Optional key-values for TIQ variables / UDH attributes
    /// - Returns: Dictionary of type [String:Any]
    public class func trackDataFor(title: String,
                                   optionalData: [String: Any]?) -> [String: Any] {
        let newTitle = title
        let newOptionalData = optionalData

        var trackData: [String: Any] = [TealiumKey.event: newTitle]

        if let clientOptionalVariables = newOptionalData {
            trackData += clientOptionalVariables
        }

        return trackData
    }
}
