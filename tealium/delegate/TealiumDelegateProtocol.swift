//
//  TealiumDelegateProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 20/08/2019.
//  Copyright © 2019 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumDelegate: class {

    func tealiumShouldTrack(data: [String: Any]) -> Bool
    func tealiumTrackCompleted(success: Bool, info: [String: Any]?, error: Error?)
}
