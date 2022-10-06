//
//  MockInMemoryDataLayer.swift
//  tealium-swift
//
//  Created by Enrico Zannini on 06/09/21.
//  Copyright © 2021 Tealium, Inc. All rights reserved.
//

import Foundation
import TealiumCore


class MockInMemoryDataLayer: DataLayerManagerProtocol {
    var onDataRemoved: TealiumObservable<[String]> = TealiumPublisher<[String]>().asObservable()
    
    var onDataUpdated: TealiumObservable<[String : Any]> = TealiumPublisher<[String:Any]>().asObservable()
    
    
    var all: [String : Any] = [:] {
        didSet {
            print("a")
        }
    }
    
    var allSessionData: [String : Any] {
        get {
            all
        }
        set {
            print("a")
        }
    }
    
    var sessionId: String?
    
    var sessionData: [String : Any] {
        get {
            all
        }
        set {
            print("a")
        }
    }
    
    func add(data: [String : Any], expiry: Expiry) {
        all += data
    }
    
    func add(key: String, value: Any, expiry: Expiry) {
        add(data: [key: value], expiry: expiry)
    }
    
    func joinTrace(id: String) {
        
    }
    
    func leaveTrace() {
            
    }
    
    func delete(for keys: [String]) {
        
    }
    
    func delete(for key: String) {
        all.removeValue(forKey: key)
    }
    
    func deleteAll() {
        all.removeAll()
    }
    
    
}

