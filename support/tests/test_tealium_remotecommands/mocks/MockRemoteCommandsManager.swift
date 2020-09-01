//
//  MockRemoteCommandsManager.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/3/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumRemoteCommands

class MockRemoteCommandsManager: RemoteCommandsManagerProtocol {
    
    var addCount = 0
    var removeCommandWithIdCount = 0
    var triggerCount = 0
    
    var moduleDelegate: ModuleDelegate?
    var commands = RemoteCommandArray()
    
    init() {
        moduleDelegate = self
    }

    func add(_ remoteCommand: RemoteCommandProtocol) {
        addCount += 1
    }

    func removeAll() {
        
    }

    func remove(commandWithId: String) {
        removeCommandWithIdCount += 1
    }

    func triggerCommand(with data: [String : Any]) {
        triggerCount +=  1
    }
    
    func triggerCommand(from request: URLRequest) -> TealiumRemoteCommandsError? {
        return TealiumRemoteCommandsError.invalidScheme
    }

}

extension MockRemoteCommandsManager: ModuleDelegate {
    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func requestDequeue(reason: String) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

}
