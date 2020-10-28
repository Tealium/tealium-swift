//
//  MockWebViewRemoteCommand.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumRemoteCommands

class MockWebViewRemoteCommand: RemoteCommandProtocol {

    var commandId: String
    var type: RemoteCommandType
    var config: RemoteCommandConfig?
    var completion: (_ response: RemoteCommandResponseProtocol) -> Void
    weak var delegate: RemoteCommandDelegate?
    var description: String?

    var completeWithResponseCount = 0

    init() {
        commandId = "mockCommand"
        description = "mockDescription"
        type = .webview
        config = RemoteCommandConfig(config: ["test": "test"],
                                     mappings: ["test": "test"],
                                     apiCommands: ["test": "test"],
                                     commandName: nil,
                                     commandURL: nil)
        completion = { _ in
            print("stub")
        }
    }

    func complete(with trackData: [String: Any], config: RemoteCommandConfig, completion: ModuleCompletion?) {

    }

    func completeWith(response: RemoteCommandResponseProtocol) {
        completeWithResponseCount += 1
    }

    static func sendRemoteCommandResponse(for commandId: String, response: RemoteCommandResponseProtocol, delegate: ModuleDelegate?) {

    }

}
