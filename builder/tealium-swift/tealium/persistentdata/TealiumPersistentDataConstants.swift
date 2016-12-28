//
//  TealiumDataManagerConstants.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Tealium, Inc. All rights reserved.
//

enum TealiumPersistentDataKey {
    static let moduleName = "persistentdata"
}

enum TealiumPersistentDataModuleError: Error {
    case didNotInitialize
    case cannotPersistData
}

public enum TealiumPersistentMode {
    case none
    case file
    case defaults
    
    var description: String {
        switch self {
        case .file:
            return "file"
        case .defaults:
            return "defaults"
        default:
            return "none"
        }
    }
}
