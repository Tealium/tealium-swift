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
    let queue : DispatchQueue
    var description : String?
    
    internal let _completion : ((_ response:TealiumRemoteCommandResponse)->Void)

    init(commandId: String,
         description : String?,
         queue: DispatchQueue?,
         completion : @escaping ((_ response:TealiumRemoteCommandResponse)->Void)){
        
        self.commandId = commandId
        self.description = description
        self._completion = completion
        self.queue = (queue != nil) ? queue! : DispatchQueue.main
    }
    
    func completeWith(response: TealiumRemoteCommandResponse) {
        self._completion(response)
    }
    
}


