//
//  TealiumRequests.swift
//  tealium-swift
//
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

// Requests are internal notification types used between the modules and
//  modules manager to enable, disable, load, save, delete, and process
//  track data. All request types most conform to the TealiumRequest protocol.
//  The module base class will respond by default to enable, disable, and track
//  but subclasses are expected to override these and/or implement handling of
//  any of the following additional requests or to a module's own custom request
//  type.

import Foundation

/// Request protocol
public protocol TealiumRequest {
    var typeId: String { get set }

    static func instanceTypeId() -> String
}

// MARK: Update Config Request
public struct TealiumUpdateConfigRequest: TealiumRequest {
    public var typeId = TealiumUpdateConfigRequest.instanceTypeId()
    public let config: TealiumConfig

    public init(config: TealiumConfig) {
        self.config = config
    }

    public static func instanceTypeId() -> String {
        return "updateconfig"
    }
}

// MARK: Enqueue Request
/// Request to queue a track call
public struct TealiumEnqueueRequest: TealiumRequest {
    public var typeId = TealiumEnqueueRequest.instanceTypeId()
    public var data: [TealiumTrackRequest]
    var queueReason: String? {
        willSet {
            guard let newValue = newValue else {
                return
            }
            self.data = data.map {
                var data = $0.trackDictionary
                data[TealiumKey.queueReason] = newValue
                return TealiumTrackRequest(data: data)
            }
        }
    }

    public init(data: TealiumTrackRequest,
                queueReason: String? = nil) {
        self.data = [data]
        self.queueReason = queueReason
    }

    public init(data: TealiumBatchTrackRequest,
                queueReason: String? = nil) {
        self.data = data.trackRequests
        self.queueReason = queueReason
    }

    public static func instanceTypeId() -> String {
        return "enqueue"
    }
}

// MARK: Remote API Request
public struct TealiumRemoteAPIRequest: TealiumRequest {
    public var typeId = TealiumRemoteAPIRequest.instanceTypeId()
    public var trackRequest: TealiumTrackRequest

    public init(trackRequest: TealiumTrackRequest) {
        var trackRequestData = trackRequest.trackDictionary
        trackRequestData[TealiumKey.callType] = TealiumKey.remoteAPICallType
        self.trackRequest = TealiumTrackRequest(data: trackRequestData)
    }

    public static func instanceTypeId() -> String {
        return "remote_api"
    }

}

// MARK: Remote Notification Request
public struct TealiumRemoteCommandRequest: TealiumRequest {
    public var typeId = TealiumRemoteCommandRequest.instanceTypeId()
    public var data: [String: Any]

    public init(data: [String: Any]) {
        self.data = data
    }

    public static func instanceTypeId() -> String {
        return "remote_command_request"
    }

}

// MARK: Remote Notification Response
public struct TealiumRemoteCommandRequestResponse: TealiumRequest {
    public var typeId = TealiumRemoteCommandRequestResponse.instanceTypeId()
    public var data: [String: Any]

    public init(data: [String: Any]) {
        self.data = data
    }

    public static func instanceTypeId() -> String {
        return "remote_command_response"
    }

}

// MARK: Track Request
/// Request to deliver data.
public struct TealiumTrackRequest: TealiumRequest, Codable, Comparable {
    public static func < (lhs: TealiumTrackRequest, rhs: TealiumTrackRequest) -> Bool {
        guard let lhsTimestamp = lhs.trackDictionary[TealiumKey.timestampUnixMilliseconds] as? String,
              let rhsTimestamp = rhs.trackDictionary[TealiumKey.timestampUnixMilliseconds] as? String else {
            return false
        }
        guard let lhsTimestampInt = Int64(lhsTimestamp),
              let rhsTimestampInt = Int64(rhsTimestamp) else {
            return false
        }
        return lhsTimestampInt < rhsTimestampInt
    }

    public static func == (lhs: TealiumTrackRequest, rhs: TealiumTrackRequest) -> Bool {
        lhs.trackDictionary == rhs.trackDictionary
    }

    public var uuid: String {
        willSet {
            var data = self.trackDictionary
            data[TealiumKey.requestUUID] = newValue
            self.data = data.encodable
        }
    }
    public var typeId = TealiumTrackRequest.instanceTypeId()

    public var data: AnyEncodable

    public var trackDictionary: [String: Any] {
        if let data = data.value as? [String: Any] {
            return data
        }
        return ["": ""]
    }

    enum CodingKeys: String, CodingKey {
        case typeId
        case data
    }

    public init(data: [String: Any]) {
        self.uuid = data[TealiumKey.requestUUID] as? String ?? UUID().uuidString
        var data = data
        data[TealiumKey.requestUUID] = uuid
        self.data = data.encodable
    }

    public static func instanceTypeId() -> String {
        return "track"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(typeId, forKey: .typeId)
        try container.encode(data, forKey: .data)
    }

    public var visitorId: String? {
        return self.trackDictionary[TealiumKey.visitorId] as? String
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let decoded = try values.decode(AnyDecodable.self, forKey: .data)
        var trackData = decoded.value as? [String: Any]
        if let uuid = trackData?[TealiumKey.requestUUID] as? String {
            self.uuid = uuid
        } else {
            self.uuid = UUID().uuidString
            trackData?[TealiumKey.requestUUID] = self.uuid
        }
        data = AnyEncodable(trackData)
        typeId = try values.decode(String.self, forKey: .typeId)
    }

    public mutating func deleteKey(_ key: String) {
        var dictionary = self.trackDictionary
        dictionary.removeValue(forKey: key)
        self.data = dictionary.encodable
    }

    public var event: String? {
        self.trackDictionary[TealiumKey.event] as? String
    }

}

// MARK: Batch track request
public struct TealiumBatchTrackRequest: TealiumRequest, Codable {
    public var typeId = TealiumTrackRequest.instanceTypeId()
    public var uuid: String
    let sharedKeys = [TealiumKey.account,
                      TealiumKey.profile,
                      TealiumKey.dataSource,
                      TealiumKey.libraryName,
                      TealiumKey.libraryVersion,
                      TealiumKey.uuid,
                      TealiumKey.device,
                      TealiumKey.simpleModel,
                      TealiumKey.architecture,
                      TealiumKey.cpuType,
                      TealiumKey.language,
                      TealiumKey.resolution,
                      TealiumKey.platform,
                      TealiumKey.osName,
                      TealiumKey.fullModel,
                      TealiumKey.visitorId
    ]
    public var trackRequests: [TealiumTrackRequest]

    enum CodingKeys: String, CodingKey {
        case typeId
        case trackRequests
    }

    public static func instanceTypeId() -> String {
        return "batchtrack"
    }

    public init(trackRequests: [TealiumTrackRequest]) {
        self.trackRequests = trackRequests
        self.uuid = UUID().uuidString
    }

    public init(from decoder: Decoder) throws {
        self.uuid = UUID().uuidString
        let values = try decoder.container(keyedBy: CodingKeys.self)

        trackRequests = try values.decode([TealiumTrackRequest].self, forKey: CodingKeys.trackRequests)
        typeId = try values.decode(String.self, forKey: .typeId)
    }

    /// - Returns: `[String: Any]?` containing the batched payload with shared keys extracted into `shared` object ``
    public func compressed() -> [String: Any]? {
        var events = [[String: Any]]()
        guard let firstRequest = trackRequests.first else {
            return nil
        }

        let shared = extractSharedKeys(from: firstRequest.trackDictionary)

        for request in trackRequests {
            let newRequest = request.trackDictionary.filter { !sharedKeys.contains($0.key) }
            events.append(newRequest)
        }

        return ["events": events, "shared": shared]
    }

    func extractSharedKeys(from dictionary: [String: Any]) -> [String: Any] {
        var newSharedDictionary = [String: Any]()

        sharedKeys.forEach { key in
            if dictionary[key] != nil {
                newSharedDictionary[key] = dictionary[key]
            }
        }

        return newSharedDictionary
    }

}

public protocol TealiumDispatch {
    var trackRequest: TealiumTrackRequest { get }
}

public struct TealiumEvent: TealiumDispatch {
    internal var eventName: String
    internal var dataLayer: [String: Any]?

    public init(_ eventName: String,
                dataLayer: [String: Any]? = nil) {
        self.eventName = eventName
        self.dataLayer = dataLayer
    }

    public var trackRequest: TealiumTrackRequest {
        var data = dataLayer ?? [String: Any]()
        data[TealiumKey.event] = eventName
        return TealiumTrackRequest(data: data)
    }
}

public struct TealiumView: TealiumDispatch {
    internal var viewName: String
    internal var dataLayer: [String: Any]?

    public init(_ viewName: String,
                dataLayer: [String: Any]? = nil) {
        self.viewName = viewName
        self.dataLayer = dataLayer
    }

    public var trackRequest: TealiumTrackRequest {
        var data = dataLayer ?? [String: Any]()
        data[TealiumKey.event] = viewName
        data[TealiumKey.callType] = TealiumTrackType.view.description
        data[TealiumKey.screenTitle] = viewName
        return TealiumTrackRequest(data: data)
    }
}

public extension TealiumTrackRequest {

    func extractKey(lookup: [String: String]?) -> String? {
        guard let keys = lookup else {
            return nil
        }
        guard let event = self.event else {
            return nil
        }
        guard let dispatchKey = keys[event] else {
            return nil
        }
        return dispatchKey
    }

    func extractLookupValue(for key: String) -> Any? {
        var item: Any?
        guard let lookupValue = self.trackDictionary[key] else {
            return nil
        }
        if let arrayItem = lookupValue as? [Any] {
            guard arrayItem.count > 0 else {
                return nil
            }
            item = arrayItem[0]
        } else {
            item = lookupValue
        }
        return item
    }
}
