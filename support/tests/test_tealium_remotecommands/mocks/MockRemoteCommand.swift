//
//  MockRemoteCommand.swift
//  TestHost
//
//  Created by Christina S on 6/4/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumRemoteCommands

class MockRemoteCommand: RemoteCommandProtocol {

    var commandId: String
    var remoteCommandCompletion: TealiumRemoteCommandCompletion
    weak var delegate: RemoteCommandDelegate?
    var description: String?
    var completionRunCount = 0

    init() {
        commandId = "mockCommand"
        description = "mockDescription"
        remoteCommandCompletion = { _ in
            print("stub")
        }
    }

    func complete(with response: RemoteCommandResponseProtocol) {

    }
    
    static func sendRemoteCommandResponse(for commandId: String, response: RemoteCommandResponseProtocol, delegate: ModuleDelegate?) {
        
    }

}
