//
//  TealiumCollectProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/1/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol TealiumCollectProtocol {
    func dispatch(data: [String: Any],
                  completion: TealiumCompletion?)
}
