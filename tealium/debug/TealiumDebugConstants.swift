//
//  TealiumDebugConstants.swift
//  tealium-swift
//
//  Created by Merritt Tidwell on 12/9/16.
//  Copyright © 2016 tealium. All rights reserved.
//


enum TealiumDebugKey {

    static let moduleName = "debug"
    static let debugPort = "debug_port"
    static let debugQueueSize = "debug_queue_size"
    static let overrideQueueSizeLimit = 1000
    static var defaultQueueMax = 100

}

enum TealiumDebugError: Error {
    
    case couldNotStartServer
    
}
