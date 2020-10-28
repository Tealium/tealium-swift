//
//  MockRemoteCommandsManager.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumCore
@testable import TealiumRemoteCommands

class MockRemoteCommandsManager: RemoteCommandsManagerProtocol {

    var jsonCommands = [RemoteCommandProtocol]()
    var mockJSONCommand = MockJSONRemoteCommand()
    var webviewCommands = [RemoteCommandProtocol]()
    weak var moduleDelegate: ModuleDelegate?

    var addCount = 0
    var removeCommandWithIdCount = 0
    var removeJSONCommandCount = 0
    var triggerCount = 0
    var refreshCount = 0

    init(jsonCommand: MockJSONRemoteCommand? = nil) {
        moduleDelegate = self
        jsonCommands.append(jsonCommand ?? mockJSONCommand)
    }

    func refresh(_ command: RemoteCommandProtocol, url: URL, file: String) {
        refreshCount += 1
    }

    func remove(commandWithId: String) {
        removeCommandWithIdCount += 1
    }

    func remove(jsonCommand name: String) {
        removeJSONCommandCount += 1
    }

    func removeAll() {

    }

    func trigger(command type: SimpleCommandType, with data: [String: Any], completion: ModuleCompletion?) {
        triggerCount += 1
    }

    func triggerCommand(from request: URLRequest) -> TealiumRemoteCommandsError? {
        nil
    }

    func add(_ remoteCommand: RemoteCommandProtocol) {
        addCount += 1
    }

    func disable() {

    }

}

extension MockRemoteCommandsManager: ModuleDelegate {
    func requestDequeue(reason: String) {

    }

    func requestTrack(_ track: TealiumTrackRequest) {

    }

    func processRemoteCommandRequest(_ request: TealiumRequest) {

    }

}
