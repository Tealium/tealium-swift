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
    

    
    func start()  {


      server[""] =  websocket({ (session, text ) in
            session.writeText("blah")
            do {
            let socket = try session.socket.acceptClientSocket()
                
                //set a bool here?
                print(socket)
            } catch {
                print(SocketError.listenFailed("bummer"))
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
    

    func clientDidConnect() -> Bool {

    
        return true
    }
    
    
    func serveTrack() {

        //.write
        server[""] = websocket({ (session, text) in
            session.writeText("connection success")
         //   let socketSession =  try? session.socket.acceptClientSocket()
            
//            if (!self.debugQueue.isEmpty){
//              
//                session.writeText(self.debugQueue.description)
//                //self.debugQueue.removeAll()
//            }
            
        }, { (session, binary) in
            session.writeBinary(binary)
        })
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

