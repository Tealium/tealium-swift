//
//  TealiumRequests.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

// Requests are internal notification types used between the modules and
//  modules manager to enable, disable, load, save, delete, and process
//  track data. All request types most conform to the TealiumRequest protocol.
//  The module base class will respond by default to enable, disable, and track
//  but subclasses are expected to override these and/or implement handling of
//  any of the following additional requests or to a module's own custom request
//  type.

/// Request protocol
public protocol TealiumRequest {
    var typeId: String { get set }
    var moduleResponses: [TealiumModuleResponse] { get set }
    var completion: TealiumCompletion? { get set }

    static func instanceTypeId() -> String
}

/// Request to delete persistent data
public struct TealiumDeleteRequest: TealiumRequest {
    public var typeId = TealiumDeleteRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    let name: String

    init(name: String) {
        self.name = name
        self.completion = nil
    }

    public static func instanceTypeId() -> String {
        return "delete"
    }
}

/// Request to disable.
public struct TealiumDisableRequest: TealiumRequest {
    public var typeId = TealiumDisableRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    public init() {}

    public static func instanceTypeId() -> String {
        return "disable"
    }
}

/// Request to enable.
public struct TealiumEnableRequest: TealiumRequest {
    public var typeId = TealiumEnableRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    let config: TealiumConfig

    public init(config: TealiumConfig) {
        self.config = config
    }

    public static func instanceTypeId() -> String {
        return "enable"
    }
}

/// Request to load persistent data.
public struct TealiumLoadRequest: TealiumRequest {
    public var typeId = TealiumLoadRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?
    let name: String

    init(name: String,
         completion: TealiumCompletion?) {
        self.name = name
        self.completion = completion
    }

    public static func instanceTypeId() -> String {
        return "load"
    }
}

// Module wants to report status to any listening modules
public struct TealiumReportRequest: TealiumRequest {
    public var typeId = TealiumReportNotificationsRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    let message: String

    init(message: String) {
        self.message = message
    }

    public static func instanceTypeId() -> String {
        return "report"
    }
}

// Module requests to be notified of any reports or when all modules finished
//  processing a request.
public struct TealiumReportNotificationsRequest: TealiumRequest {
    public var typeId = TealiumReportNotificationsRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    public static func instanceTypeId() -> String {
        return "reportnotification"
    }
}

/// Request to send any queued data.
public struct TealiumReleaseQueuesRequest: TealiumRequest {
    public var typeId = TealiumReleaseQueuesRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    public static func instanceTypeId() -> String {
        return "queuerelease"
    }
}

/// Request to queue a track call
public struct TealiumEnqueueRequest: TealiumRequest {
    public var typeId = TealiumEnqueueRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    let data: TealiumTrackRequest

    public init(data: TealiumTrackRequest,
                completion: TealiumCompletion?) {
        self.data = data
        self.completion = completion
    }

    public static func instanceTypeId() -> String {
        return "enqueue"
    }
}

/// Request to send any queued data.
public struct TealiumClearQueuesRequest: TealiumRequest {
    public var typeId = TealiumClearQueuesRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    public static func instanceTypeId() -> String {
        return "queuedelete"
    }
}

/// Request to save persistent data.
public struct TealiumSaveRequest: TealiumRequest {
    public var typeId = TealiumSaveRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    let name: String
    let data: [String: Any]

    init(name: String,
         data: [String: Any]) {
        self.name = name
        self.data = data
        self.completion = nil
    }

    public static func instanceTypeId() -> String {
        return "save"
    }
}

/// Request to deliver data.
public struct TealiumTrackRequest: TealiumRequest {
    public var typeId = TealiumTrackRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    public let data: [String: Any]

    public init(data: [String: Any],
                completion: TealiumCompletion?) {
        self.data = data
        self.completion = completion
    }

    public static func instanceTypeId() -> String {
        return "track"
    }
}

public struct TealiumDeviceDataRequest: TealiumRequest {
    public var typeId = TealiumDeviceDataRequest.instanceTypeId()
    public var moduleResponses = [TealiumModuleResponse]()
    public var completion: TealiumCompletion?

    public static func instanceTypeId() -> String {
        return "devicedata"
    }
}
