//
//  ModuleResult.swift
//  TealiumCore
//
//  Created by Craig Rouse on 29/04/2020.
//  Copyright © 2020 Tealium, Inc. All rights reserved.
//

import Foundation

public typealias ModuleCompletion = (((Result<Bool, Error>, [String: Any]?)) -> Void)
