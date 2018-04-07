//
//  TealiumModuleResponse.swift
//  tealium-swift
//
//  Created by Jonathan Wong on 1/10/18.
//  Copyright © 2018 Tealium, Inc. All rights reserved.
//

import Foundation

/// Feedback from modules for internal requests (such as an enabling).
public struct TealiumModuleResponse {
    public let moduleName: String
    public let success: Bool
    public var info: [String: Any]?
    public var error: Error?

    init(moduleName: String,
         success: Bool,
         error: Error?) {
        self.moduleName = moduleName
        self.success = success
        self.error = error
        self.info = nil
    }
}
