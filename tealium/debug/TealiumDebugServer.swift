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
    var queueMax = 100 {
        didSet {
            if queueMax < 1 {
                queueMax = TealiumDebugKey.defaultQueueMax
                return
            }
           
            if queueMax > TealiumDebugKey.overrideQueueSizeLimit {
                queueMax = TealiumDebugKey.overrideQueueSizeLimit
                return
            
            }
            
        }
    }
  
    
    public func startWithPort(port: Int) throws {
        
        do {
            
            try server.start(in_port_t(port))
            
            server.delegate = self
            
            self.setupSockets()
            
        } catch {
            
            throw TealiumDebugError.couldNotStartServer
            
        }
        
    }
    
    public func stop() {
        currentSession = nil
        server.stop()
    }
    
    public func add(_ data: [String:Any]) {

        if debugQueue.count < queueMax {
            debugQueue.append(data)
        
        }else {
            debugQueue.removeFirst()
            self.add(data)
        
        }
        sendQueue()

    }
    
    internal func setupSockets() {
        
        server[""] =  websocket({ (session, text ) in
            
        }, { (session, binary) in
            session.writeBinary(binary)
        })
        
    }
    
    internal func sendQueue() {
        
        if currentSession == nil{
            return
        }
        
        for item in debugQueue {
            send(item)            
        }
        
        debugQueue.removeAll()
        
    }
    
    internal func send(_ data: [String:Any]) {
        
        guard let jsonItem = try? encodeDictToJson(dict: data) else {
            
            return
        }
        
        currentSession?.writeText(jsonItem as String)
        
    }
    
    
    internal func encodeDictToJson(dict: [String: Any]) throws -> String {
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
        
        self.sendQueue()
        
    }
    
}
