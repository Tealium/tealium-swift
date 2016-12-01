//
//  TealiumDataManagerConstants.swift
//  SegueCatalog
//
//  Created by Jason Koo on 11/16/16.
//  Copyright © 2016 Apple, Inc. All rights reserved.
//

enum TealiumPersistentDataKey {
    static let moduleName = "persistentdata"
    static let uuid = "app_uuid"
    static let legacyVid = "tealium_vid"                            // deprecating
    static let visitorId = "tealium_visitor_id"
}

enum TealiumPersistentDataModuleError: Error {
    case didNotInitialize
    case cannotPersistData
}

enum TealiumPersistentMode {
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
