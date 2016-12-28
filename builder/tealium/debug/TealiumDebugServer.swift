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
    var debugQueue = [[String: Any]]()
    var currentSession : WebSocketSession?
    
    func start()  {
        
        do {
            
            try server.start()
            
            server.delegate = self
            
            self.setupSockets()
            
        } catch {
            print("Unable to start server.")
        }
        
    }
    
    func setupSockets() {
        
        server[""] =  websocket({ (session, text ) in
            
            
        }, { (session, binary) in
            session.writeBinary(binary)
        })
        
    }
    
    func serveTrack() {
        
        guard let currentSession = currentSession else{
         
            return
        }
        
        for item in debugQueue {
            
            guard let jsonItem = try? encodeDictToJson(dict: item) else {
                
                return
            }
            
            currentSession.writeText(jsonItem as String)
        }
        
        debugQueue.removeAll()
    }
    
    func addToDebugQueue(_ trackData: [String: Any]) {
        
        debugQueue.append(trackData)
        
    }
    
    func stop() {
        currentSession = nil
        server.stop()
    }
    
    
    func encodeDictToJson(dict: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: dict,
                                              options: JSONSerialization.WritingOptions())
        
        let jsonString = NSString(data: data,
                                  encoding: String.Encoding.ascii.rawValue)
        
        return jsonString as! String
        
    }
    
}

extension TealiumDebugServer : HttpServerIODelegate {
    
    func socketConnectionReceived(socket: Socket) {
        
        if currentSession == nil {
            
            let newSession = WebSocketSession.init(socket)
            currentSession = newSession
            
            
        }
        
    }
    
}
