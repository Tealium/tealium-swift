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
            
            do {
                let socket = try session.socket.acceptClientSocket()
                
                self.currentSession = session
                
                session.writeText("Socket connection made.")

                print(socket)
            } catch {
//                print(SocketError.listenFailed("bummer"))
            }
            
        }, { (session, binary) in
            session.writeBinary(binary)
        })
        
    }

    func clientDidConnect() -> Bool {

    
        return true
    }
    
    
    func serveTrack() {

        currentSession?.writeText("connection success")

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

extension TealiumDebugServer : HttpServerIODelegate {
    
    func socketConnectionReceived(socket: Socket) {
        
        if currentSession == nil {
            
            let newSession = WebSocketSession.init(socket)
            currentSession = newSession
            
            
        }
        
    }
    
}
