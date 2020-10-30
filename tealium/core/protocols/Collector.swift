//
//  Collector.swift
//  tealium-swift
//
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public protocol Collector: TealiumModule {
    var data: [String: Any]? { get }
    init(context: TealiumContext,
         delegate: ModuleDelegate?,
         diskStorage: TealiumDiskStorageProtocol?,
         completion: ModuleCompletion)
}
