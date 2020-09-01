//
//  MockTealiumRemoteCommandResponse.swift
//  TealiumRemoteCommandsTests-iOS
//
//  Created by Christina S on 6/17/20.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation
@testable import TealiumRemoteCommands

class MockTealiumRemoteCommandResponse: RemoteCommandResponseProtocol {
    
    var responseId: String?
    
    var status: Int = 200
    
    var urlResponse: URLResponse?
    
    var error: Error?
    
    var data: Data?
    
    private var customCompletionBacking = false
    
    var payload: [String : Any]? {
        get {
          return ["test": "payload"]
        }
        set {
            
        }
    }
    
    var hasCustomCompletionHandler: Bool {
        get {
            customCompletionBacking
        }
        set {
            customCompletionBacking = newValue
        }
    }
    
}
