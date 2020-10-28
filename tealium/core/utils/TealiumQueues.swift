//
//  TealiumQueues.swift
//  tealium-swift
//
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public class TealiumQueues {

    public static let backgroundConcurrentQueue = {
        return ReadWrite("com.tealium.backgroundconcurrentqueue")
    }()

    public static let mainQueue = DispatchQueue.main

    public static let backgroundSerialQueue = DispatchQueue(label: "com.tealium.backgroundserialqueue",
                                                            qos: .utility,
                                                            attributes: [],
                                                            autoreleaseFrequency: .inherit,
                                                            target: .global(qos: .utility))
}
