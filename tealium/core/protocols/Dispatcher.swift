//
//  Dispatcher.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Dispatcher: TealiumModule {

    init(config: TealiumConfig,
         delegate: ModuleDelegate,
         completion: ModuleCompletion?)

    func dynamicTrack(_ request: TealiumRequest,
                      completion: ModuleCompletion?)
}
