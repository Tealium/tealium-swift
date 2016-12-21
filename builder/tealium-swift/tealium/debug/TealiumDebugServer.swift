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
         
            guard let encodedItem = try? encode(parameters: item) else {
            
                return
            }
           
            guard let jsonText = NSString(data: encodedItem!,
                                         encoding: String.Encoding.ascii.rawValue) else {
            return
                                            
            }
          
            currentSession.writeText(jsonText as String)
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
    
    
    func encode(parameters: [String: Any]) throws -> Data? {
        let data = try JSONSerialization.data(
            withJSONObject: parameters,
            options: JSONSerialization.WritingOptions())
        
         return data
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
