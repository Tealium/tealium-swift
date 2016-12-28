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
    
            do {
                let encodedText = try encode(dictionary: item)
                currentSession.writeText(encodedText as String)

            } catch {
                print("Error when trying to encode the dictionary")
            }

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
    
    
    func encode(dictionary: [String: Any]) -> String {
       
        let keys = dictionary.keys
        let sortedKeys = keys.sorted { $0 < $1 }
        var encodedArray = [String]()
        
        for key in sortedKeys {
            
            let encodedKey = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            var value = dictionary[key]
            
            if let valueString = value as? String{
                
                value = valueString
            } else if let stringArray = value as? [String]{
                value = "\(stringArray)"
            } else {
                continue
            }
            
            guard let valueString = value as? String else {
                continue
            }
            let encodedValue = valueString.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
            
            let encodedElement = "\(encodedKey)=\(encodedValue)"
            encodedArray.append(encodedElement)
        }
        
        return encodedArray.joined(separator: "&")

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
