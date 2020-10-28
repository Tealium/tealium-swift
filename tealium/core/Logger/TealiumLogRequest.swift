//
//  TealiumLogRequest.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol LogRequest {
    var logLevel: TealiumLogLevel { get set }
    var title: String { get set }
    var messages: [String] { get set }
    var info: [String: Any]? { get set }
    var logCategory: TealiumLogCategory? { get set }
    var formattedString: String { get }

}

public enum TealiumLogCategory {
    case `init`
    case track
    case general
}

public struct TealiumLogRequest: LogRequest {
    public var messages: [String]

    public var logLevel: TealiumLogLevel

    public var title: String

    public var logCategory: TealiumLogCategory?

    public var info: [String: Any]?

    public var formattedString: String {
        var message = """

        =====================================
        ▶️ Tealium Log: \(title)
        =====================================
        Severity: \(logLevel.description)


        """

        if messages.count > 0 {
            message += "Log Messages:\n"
            for (index, messageItem) in messages.enumerated() {
                message += "\(index): \(messageItem)\n"
            }
        }

        if let info = info?.toJSONString {
            message += "\nAdditional Info:\n"
            message += "\(info)\n"
        }
        message += "[Log End: \(title)] ⏹"
        return message
    }

    public init(title: String = "Tealium Log",
                messages: [String],
                info: [String: Any]? = nil,
                logLevel: TealiumLogLevel = .info,
                category: TealiumLogCategory? = nil) {
        self.title = title
        self.messages = messages
        self.info = info
        self.logLevel = logLevel
        self.logCategory = category
    }

    public init(title: String = "Tealium Log",
                message: String,
                info: [String: Any]? = nil,
                logLevel: TealiumLogLevel = .info,
                category: TealiumLogCategory? = nil) {
        self.init(title: title, messages: [message], info: info, logLevel: logLevel, category: category)
    }

}
