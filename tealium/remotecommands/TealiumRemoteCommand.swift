//
//  TealiumRemoteCommand.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/31/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

open class TealiumRemoteCommand {

    let commandId: String
    weak var delegate: TealiumRemoteCommandDelegate?
    var description: String?

    let remoteCommandCompletion : ((_ response: TealiumRemoteCommandResponse) -> Void)

    /// Deprecated Constructor for a Tealium Remote Command.
    ///
    /// - Parameters:
    ///   - commandId: String identifier for command block.
    ///   - description: Optional string description of command.
    ///   - queue: Optional target queue to run command block on. Nil to specify
    ///         running on the existing thread.
    ///   - completion: The completion block to run when this remote command is
    ///         triggered.
    @available(*, deprecated, message: "No longer supported. Use the init(commandId:description:completion) constructor instead.")
    public init(commandId: String,
                description: String?,
                queue: DispatchQueue?,
                completion : @escaping ((_ response: TealiumRemoteCommandResponse) -> Void)) {

        self.commandId = commandId
        self.description = description
        self.remoteCommandCompletion = completion
    }

    /// Constructor for a Tealium Remote Command.
    ///
    /// - Parameters:
    ///   - commandId: String identifier for command block.
    ///   - description: Optional string description of command.
    ///   - queue: Optional target queue to run command block on. Nil to specify
    ///         running on the existing thread.
    ///   - completion: The completion block to run when this remote command is
    ///         triggered.
    public init(commandId: String,
                description: String?,
                completion : @escaping ((_ response: TealiumRemoteCommandResponse) -> Void)) {

        self.commandId = commandId
        self.description = description
        self.remoteCommandCompletion = completion
    }

    func completeWith(response: TealiumRemoteCommandResponse) {

        delegate?.tealiumRemoteCommandRequestsExecution(self,
                                                        response: response)

    }

}
