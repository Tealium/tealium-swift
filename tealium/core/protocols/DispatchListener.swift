//
//  DispatchListenerProtocol.swift
//  TealiumCore
//
//  Created by Craig Rouse on 06/05/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DispatchListener {
    func willTrack(request: TealiumRequest)
}
