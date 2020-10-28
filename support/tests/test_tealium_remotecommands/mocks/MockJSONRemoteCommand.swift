//
//  MockJSONRemoteCommand.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumRemoteCommands

class MockJSONRemoteCommand: RemoteCommandProtocol {

    var commandId: String
    var type: RemoteCommandType
    var config: RemoteCommandConfig?
    var completion: (_ response: RemoteCommandResponseProtocol) -> Void
    weak var delegate: RemoteCommandDelegate?
    var description: String?

    init(config: RemoteCommandConfig? = nil) {
        commandId = "mockCommand"
        description = "mockDescription"
        type = RemoteCommandType.remote(url: "test")
        self.config = config ?? RemoteCommandConfig(config: ["test": "test"],
                                                    mappings: ["test": "test"],
                                                    apiCommands: ["test": "test"],
                                                    commandName: "initialize",
                                                    commandURL: URL(string: "https://some.custom.server/firebase.json"))
        completion = { _ in
            print("stub")
        }
    }

    func complete(with trackData: [String: Any], config: RemoteCommandConfig, completion: ModuleCompletion?) {

    }

    func completeWith(response: RemoteCommandResponseProtocol) {

    }

    static func sendRemoteCommandResponse(for commandId: String, response: RemoteCommandResponseProtocol, delegate: ModuleDelegate?) {

    }

}
