//
//  TealiumQueues.swift
//  tealium-swift
//
//  Created by Craig Rouse on 27/06/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumQueues {

    public static let backgroundConcurrent = {
        return ReadWrite("com.tealium.backgroundconcurrentqueue")
    }()
    
    public static let backgroundSerial = {
        return ReadWriteSerial("com.tealium.backgroundserialqueue")
    }()

    public static let main = DispatchQueue.main

    public static let backgroundDispatch = DispatchQueue(label: "com.tealium.backgroundserialdispatchqueue",
                                                            qos: .utility,
                                                            attributes: [],
                                                            autoreleaseFrequency: .inherit,
                                                            target: .global(qos: .utility))
}
