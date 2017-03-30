//
//  TealiumRemoteCommand.swift
//  SegueCatalog
//
//  Created by Jason Koo on 3/14/17.
//  Copyright © 2017 Apple, Inc. All rights reserved.
//

import Foundation

enum TealiumRemoteCommandStatusCode : Int {
    case unknown = 0
    case success = 200
    case noContent = 204
    case malformed = 400
    case failure = 404
}

class TealiumRemoteCommand {
    
    let commandId : String
    let queue : DispatchQueue?
    var description : String?
    
    internal let _completion : ((_ response:TealiumRemoteCommandResponse)->Void)

    /// Constructor for a Tealium Remote Command.
    ///
    /// - Parameters:
    ///   - commandId: String identifier for command block.
    ///   - description: Optional string description of command.
    ///   - queue: Optional target queue to run command block on. Nil to specify
    ///         running on the existing thread.
    ///   - completion: The completion block to run when this remote command is
    ///         triggered.
    init(commandId: String,
         description : String?,
         queue: DispatchQueue?,
         completion : @escaping ((_ response:TealiumRemoteCommandResponse)->Void)){
        
        self.commandId = commandId
        self.description = description
        self._completion = completion
        self.queue = queue
    }
    
    func completeWith(response: TealiumRemoteCommandResponse) {
        
        // Run completion on current queue
        if queue == nil {
            self._completion(response)
            return
        }
        
        // Run completion on a specified queue
        queue?.async {
            self._completion(response)
        }
    }
    
}


