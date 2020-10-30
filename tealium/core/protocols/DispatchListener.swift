//
//  DispatchListener.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol DispatchListener {
    func willTrack(request: TealiumRequest)
}
