//
//  TealiumCollectProtocol.swift
//  tealium-swift
//
//  Created by Craig Rouse on 11/1/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation
#if collect
import TealiumCore
#endif

public protocol TealiumCollectProtocol {
    func dispatch(data: [String: Any],
                  completion: TealiumCompletion?)
}
