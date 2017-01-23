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
        
        let filteredData = TealiumDebugServer.stringOnly(dictionary: data)
        
        guard let jsonItem = TealiumDebugServer.encodeToJsonString(dict: filteredData) else {
            // Data failed encoding attempt
            return
        }
        
        currentSession?.writeText(jsonItem)
        
    }
    
    internal class func stringOnly(dictionary: [String:Any]) -> [String:Any] {
        
        var filteredDictionary = [String:Any]()
        
        for key in dictionary.keys {
            
            if key == TealiumDebugKey.debugPasskey {
                continue
            }
            
            var value = dictionary[key]
            
            // Recursively filter dictionary [String:Any] values
            if value is [String:Any] {
                value = TealiumDebugServer.stringOnly(dictionary: value as! [String:Any])
            }
            
            // Going to only pass strings in for safety
            if value is String {
                // No change
            } else if value is [String] {
                // No change
            } else {
                // Convert to string value
                value = "\(value!)"
            }
            
            filteredDictionary[key] = value
            
        }

        return filteredDictionary
    }
    
    
    internal class func encodeToJsonString(dict: [String: Any]) -> String? {
        
        // Need to check dictionary here or even the try-catch will fail
        //  with an invalid object
        if JSONSerialization.isValidJSONObject(dict) == false {
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: dict,
                                                  options: JSONSerialization.WritingOptions())
            
            let jsonString = NSString(data: data,
                                      encoding: String.Encoding.ascii.rawValue)
            
            return (jsonString as! String)
            
        } catch  {
            return nil
        }

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
