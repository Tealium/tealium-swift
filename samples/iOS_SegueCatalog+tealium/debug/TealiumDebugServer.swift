//
//  TealiumDebugServer.swift
//  tealium-swift
//
//  Created by Jason Koo on 10/5/16.
//  Copyright © 2016 tealium. All rights reserved.
//

import Foundation

class TealiumDebugServer {
    
    let server = HttpServer()
    var debugQueue = [[String:AnyObject]]()
    
    var mps =   ["mps"          : ["collect": "true",
                                   "tagmangement": false],
                 "libconfig"     : ["collect": "true",
                                    "priority": 1],
                 "collect_url"   : "test",
                 "tag_mgmt_url"  : "test",
                 "mps_url"       : "test",
                 "instance_name" : "tealium1",
                 "account"       : "a",
                 "profile"       : "b",
                 "environment"   : "c"] as Dictionary
    
    
    func start()  {

        server["/websocket-echo/"] = websocket({ (session, text) in
            session.writeText("connection success")
           
            if (!self.debugQueue.isEmpty){
                session.writeText(self.debugQueue.description)
                self.debugQueue.removeAll()
            }
            
        }, { (session, binary) in
                session.writeBinary(binary)
        })
        do {
            try server.start()
            print("Server started.")
        } catch {
            print("Unable to start server.")
        }
        
    }
    
    func addToDebugQueue(_ trackData: [String: AnyObject]) {
        
        debugQueue.append(trackData)
    }
    
    func stop() {
        server.stop()
    }
    
    
    func encode(parameters: [String: AnyObject]) throws -> Data? {
        let data = try JSONSerialization.data(
            withJSONObject: parameters,
            options: JSONSerialization.WritingOptions())
        
        return data
    }
    
}

