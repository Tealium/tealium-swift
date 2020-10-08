//
//  JSONRemoteCommandResponse.swift
//  TealiumRemoteCommands
//
//  Created by Christina S on 6/15/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public class JSONRemoteCommandResponse: RemoteCommandResponseProtocol {

    public var payload: [String: Any]?
    public var error: Error?
    public var status: Int?
    public var data: Data?
    public var hasCustomCompletionHandler: Bool = false

    public init(with payload: [String: Any]) {
        self.payload = payload
    }

}
